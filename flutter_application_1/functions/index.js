const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

async function paymobRequest(method, path, authToken, body) {
  const baseUrl = process.env.PAYMOB_API_BASE_URL || "https://accept.paymob.com/api";
  const headers = { Accept: "application/json", "Content-Type": "application/json" };
  if (authToken) headers.Authorization = `Bearer ${authToken}`;
  const response = await fetch(baseUrl + path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await response.json();
  if (!response.ok) throw new Error("Paymob request failed");
  return data;
}

async function paymobAuth() {
  const result = await paymobRequest("POST", "/auth/tokens", null, {
    api_key: process.env.PAYMOB_API_KEY,
  });
  if (!result.token) throw new Error("Paymob authentication failed");
  return result.token;
}

function decimalToMinor(value) {
  const text = String(value == null ? "" : value).trim();
  if (!/^\d+(?:\.\d{1,4})?$/.test(text)) return null;
  const [whole, decimal = ""] = text.split(".");
  const fraction = (decimal + "0000").slice(0, 4);
  const cents = Number(fraction.slice(0, 2));
  const roundUp = Number(fraction[2]) >= 5 ? 1 : 0;
  return Number(whole) * 100 + cents + roundUp;
}

function divideMinorHalfUp(value, divisor) {
  if (!Number.isSafeInteger(value) || divisor <= 0) return null;
  return Math.floor((value + Math.floor(divisor / 2)) / divisor);
}

exports.updateInvestmentPrices = onCall({ secrets: ["GOLD_API_KEY"] }, async () => {
  const goldApiKey = process.env.GOLD_API_KEY;
  if (!goldApiKey) throw new HttpsError("failed-precondition", "Gold API is not configured.");

  async function fetchMetal(metal) {
    const response = await fetch(
      `https://www.goldapi.io/api/price/${metal}/EGP?melt_price=true&currency_info=true`,
      { headers: { Accept: "application/json", "x-access-token": goldApiKey } }
    );
    if (!response.ok) throw new Error("Metal price is unavailable");
    return response.json();
  }

  const [gold, silver] = await Promise.all([fetchMetal("XAU"), fetchMetal("XAG")]);
  const goldPerGramMinor = decimalToMinor(
    gold.price_gram_24k || gold.price_per_unit?.gram
  );
  const silver925Value = silver.price_gram_925 ||
    silver.melt_price_per_gram?.["925"];
  let silver925Minor = decimalToMinor(silver925Value);
  if (!(silver925Minor > 0)) {
    const pureSilverMinor = decimalToMinor(silver.price_per_unit?.gram);
    silver925Minor = pureSilverMinor && pureSilverMinor > 0
      ? divideMinorHalfUp(pureSilverMinor * 925, 1000)
      : null;
  }
  if (!(goldPerGramMinor > 0) || !(silver925Minor > 0)) {
    throw new HttpsError("failed-precondition", "Metal prices are unavailable.");
  }
  const liraSpotMinor = divideMinorHalfUp(goldPerGramMinor, 100);
  const paraSpotMinor = silver925Minor;
  if (!(liraSpotMinor > 0) || !(paraSpotMinor > 0)) {
    throw new HttpsError("failed-precondition", "Metal prices are unavailable.");
  }
  const liraSellingMinor = liraSpotMinor + 500;
  const paraSellingMinor = paraSpotMinor + 500;
  const liraBuybackMinor = liraSpotMinor + 100;
  const paraBuybackMinor = paraSpotMinor + 100;
  const createdAt = FieldValue.serverTimestamp();
  const data = {
    liraSpotMinor,
    paraSpotMinor,
    liraSellingMinor,
    paraSellingMinor,
    liraBuybackMinor,
    paraBuybackMinor,
    updatedAt: createdAt,
  };
  await db.doc("masterDealerPrices/current").set(data, { merge: true });
  await db.collection("masterDealerPriceHistory").add({
    liraSellingMinor,
    paraSellingMinor,
    liraBuybackMinor,
    paraBuybackMinor,
    combinedLiquidationMinor: liraBuybackMinor + paraBuybackMinor,
    createdAt,
  });
  return data;
});

exports.createInvestmentPurchase = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const unit = request.data.unit;
  const quantity = Number(request.data.quantity);
  if (!["lira", "para"].includes(unit)) {
    throw new HttpsError("invalid-argument", "Choose LIRA or PARA.");
  }
  if (!Number.isInteger(quantity) || quantity <= 0 || quantity > 10000) {
    throw new HttpsError("invalid-argument", "Enter a valid quantity.");
  }

  const uid = request.auth.uid;
  const priceDoc = await db.doc("masterDealerPrices/current").get();
  const priceData = priceDoc.data();
  const priceMinor = unit === "lira"
    ? Number(priceData?.liraSellingMinor || 0)
    : Number(priceData?.paraSellingMinor || 0);
  if (!(priceMinor > 0)) {
    throw new HttpsError("failed-precondition", "The current price is unavailable.");
  }

  let orderId;
  const amountMinor = priceMinor * quantity;
  await db.runTransaction(async (transaction) => {
    const inventoryRef = db.doc(`masterDealerInventory/${unit}`);
    const inventoryDoc = await transaction.get(inventoryRef);
    const inventory = inventoryDoc.data() || {};
    const onHand = Math.max(0, Number(inventory.quantity || 0));
    const reserved = Math.max(0, Number(inventory.reserved || 0));
    if (quantity > onHand - reserved) {
      throw new HttpsError("failed-precondition", "Insufficient inventory.");
    }
    orderId = db.collection("masterDealerPurchaseOrders").doc().id;
    const now = new Date();
    const orderRef = db.doc(`masterDealerPurchaseOrders/${orderId}`);
    transaction.set(orderRef, {
      customerUid: uid,
      liraQuantity: unit === "lira" ? quantity : 0,
      paraQuantity: unit === "para" ? quantity : 0,
      liraUnitPriceMinor: unit === "lira" ? priceMinor : 0,
      paraUnitPriceMinor: unit === "para" ? priceMinor : 0,
      amountMinorUnits: amountMinor,
      currency: "EGP",
      status: "pending",
      createdAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + 15 * 60 * 1000).toISOString(),
      merchantOrderId: `khan-md-${orderId}`,
    });
    transaction.set(inventoryRef, {
      asset: unit,
      quantity: onHand,
      reserved: reserved + quantity,
      updatedAt: now.toISOString(),
    }, { merge: true });
  });

  if (!process.env.PAYMOB_API_KEY ||
      !process.env.PAYMOB_INTEGRATION_ID ||
      !process.env.PAYMOB_IFRAME_ID) {
    throw new HttpsError("failed-precondition", "Paymob is not configured.");
  }

  const authToken = await paymobAuth();
  const paymobOrder = await paymobRequest("POST", "/ecommerce/orders", authToken, {
    auth_token: authToken,
    delivery_needed: false,
    amount_cents: amountMinor,
    currency: "EGP",
    merchant_order_id: `khan-md-${orderId}`,
  });
  if (!paymobOrder.id) throw new Error("Paymob order was not created");

  let redirectionUrl = "";
  if (request.data.returnUrl) {
    const separator = String(request.data.returnUrl).includes("?") ? "&" : "?";
    redirectionUrl = `${String(request.data.returnUrl)}${separator}khan_reservation_order_id=${encodeURIComponent(orderId)}`;
  }
  const paymentKey = await paymobRequest("POST", "/acceptance/payment_keys", authToken, {
    auth_token: authToken,
    amount_cents: amountMinor,
    expiration: 3600,
    order_id: paymobOrder.id,
    billing_data: {
      apartment: "NA",
      email: request.auth.token.email || "customer@example.com",
      floor: "NA",
      first_name: "KHAN",
      street: "NA",
      building: "NA",
      phone_number: "NA",
      shipping_method: "NA",
      postal_code: "NA",
      city: "Cairo",
      country: "EG",
      last_name: "Customer",
      state: "Cairo",
    },
    currency: "EGP",
    integration_id: Number(process.env.PAYMOB_INTEGRATION_ID),
  });
  if (!paymentKey.token) throw new Error("Paymob payment key was not created");

  return {
    orderId,
    checkoutUrl:
      `https://accept.paymob.com/api/acceptance/iframes/${process.env.PAYMOB_IFRAME_ID}?payment_token=${paymentKey.token}`,
  };
});

exports.confirmInvestmentPurchase = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const orderId = String(request.data.orderId || "");
  const transactionId = String(request.data.paymobTransactionId || "");
  if (!/^[A-Za-z0-9_-]+$/.test(orderId) || !/^\d+$/.test(transactionId)) {
    throw new HttpsError("invalid-argument", "Payment details are invalid.");
  }

  const authToken = await paymobAuth();
  const payment = await paymobRequest(
    "GET",
    `/acceptance/transactions/${transactionId}`,
    authToken
  );
  if (!payment.success || payment.pending || payment.is_refunded || payment.is_voided) {
    throw new HttpsError("failed-precondition", "Payment was not successful.");
  }
  if (payment.currency !== "EGP" || Number(payment.amount_cents) <= 0) {
    throw new HttpsError("failed-precondition", "Payment details are invalid.");
  }

  let order = payment.order;
  if (!order) order = await paymobRequest("GET", `/ecommerce/orders/${payment.order_id}`, authToken);
  if (order.merchant_order_id !== `khan-md-${orderId}`) {
    throw new HttpsError("failed-precondition", "Payment does not match the order.");
  }

  let processed = false;
  await db.runTransaction(async (transaction) => {
    const orderRef = db.doc(`masterDealerPurchaseOrders/${orderId}`);
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) throw new HttpsError("not-found", "Purchase order not found.");
    const purchase = orderDoc.data();
    if (purchase.customerUid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "This order belongs to another customer.");
    }
    if (purchase.status === "completed") {
      processed = false;
      return;
    }
    if (purchase.status !== "pending") {
      throw new HttpsError("failed-precondition", "Purchase order is no longer pending.");
    }
    if (Number(purchase.amountMinorUnits) !== Number(payment.amount_cents)) {
      throw new HttpsError("failed-precondition", "Payment amount does not match.");
    }
    if (new Date(purchase.expiresAt) <= new Date()) {
      throw new HttpsError("failed-precondition", "Purchase order expired.");
    }

    const liraQty = Number(purchase.liraQuantity || 0);
    const paraQty = Number(purchase.paraQuantity || 0);
    const liraRef = db.doc("masterDealerInventory/lira");
    const paraRef = db.doc("masterDealerInventory/para");
    const [liraDoc, paraDoc] = await Promise.all([
      transaction.get(liraRef),
      transaction.get(paraRef),
    ]);
    const lira = liraDoc.data() || {};
    const para = paraDoc.data() || {};
    const liraQuantity = Math.max(0, Number(lira.quantity || 0) - liraQty);
    const paraQuantity = Math.max(0, Number(para.quantity || 0) - paraQty);
    const liraReserved = Math.max(0, Number(lira.reserved || 0) - liraQty);
    const paraReserved = Math.max(0, Number(para.reserved || 0) - paraQty);
    const now = new Date().toISOString();

    transaction.set(liraRef, {
      asset: "lira", quantity: liraQuantity,
      reserved: liraReserved, updatedAt: now,
    }, { merge: true });
    transaction.set(paraRef, {
      asset: "para", quantity: paraQuantity,
      reserved: paraReserved, updatedAt: now,
    }, { merge: true });
    transaction.update(orderRef, {
      status: "completed",
      paymentTransactionId: transactionId,
      paidAt: now,
    });

    transaction.set(db.doc(`masterDealerTransactions/payment-${transactionId}`), {
      type: "customer_purchase",
      status: "completed",
      source: "paymob",
      customerUid: request.auth.uid,
      purchaseOrderId: orderId,
      paymentTransactionId: transactionId,
      liraQuantity: liraQty,
      paraQuantity: paraQty,
      liraUnitPriceMinor: Number(purchase.liraUnitPriceMinor || 0),
      paraUnitPriceMinor: Number(purchase.paraUnitPriceMinor || 0),
      amountMinorUnits: Number(purchase.amountMinorUnits),
      createdAt: now,
    });

    const portfolioRef = db.doc(`customerPortfolios/${request.auth.uid}`);
    const portfolioDoc = await transaction.get(portfolioRef);
    const portfolio = portfolioDoc.data() || {};
    transaction.set(portfolioRef, {
      liraQuantity: Math.max(0, Number(portfolio.liraQuantity || 0) + liraQty),
      paraQuantity: Math.max(0, Number(portfolio.paraQuantity || 0) + paraQty),
      updatedAt: now,
    }, { merge: true });

    const financeRef = db.doc("masterDealerFinance/account");
    const financeDoc = await transaction.get(financeRef);
    const finance = financeDoc.data() || {};
    transaction.set(financeRef, {
      balanceMinorUnits:
        Number(finance.balanceMinorUnits || 0) + Number(purchase.amountMinorUnits),
      updatedAt: now,
    }, { merge: true });
    processed = true;
  });
  return { verified: true, processed };
});

async function releaseReservationCheckout(orderId, customerUid) {
  await db.runTransaction(async (transaction) => {
    const orderRef = db.doc(`jewelryReservationOrders/${orderId}`);
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) return;
    const order = orderDoc.data();
    if (order.customerUid !== customerUid || order.status !== "pending") return;
    transaction.update(orderRef, {
      status: "cancelled",
      cancelledAt: new Date().toISOString(),
    });
    const productRef = db.doc(`products/${order.productId}`);
    const productDoc = await transaction.get(productRef);
    if (!productDoc.exists) return;
    const product = productDoc.data();
    if (product.reservationLockOrderId !== orderId) return;
    transaction.update(productRef, {
      availability: "available",
      reservationLockOrderId: FieldValue.delete(),
      reservationLockExpiresAt: FieldValue.delete(),
      updatedAt: new Date().toISOString(),
    });
  });
}

async function getReservationGoldKarats() {
  const goldApiKey = process.env.GOLD_API_KEY;
  if (!goldApiKey) throw new HttpsError("failed-precondition", "Gold API is not configured.");
  const response = await fetch("https://www.goldapi.io/api/XAU/EGP", {
    headers: { Accept: "application/json", "x-access-token": goldApiKey },
  });
  if (!response.ok) throw new HttpsError("failed-precondition", "The current jewelry price is unavailable.");
  const gold = await response.json();
  const karats = {};
  for (const karat of [24, 22, 21, 18]) {
    const value = decimalToMinor(gold[`price_gram_${karat}k`]);
    if (value > 0) karats[karat] = value;
  }
  return karats;
}

async function calculateReservationQuote(productId) {
  if (!/^[A-Za-z0-9_-]+$/.test(String(productId || ""))) {
    throw new HttpsError("invalid-argument", "A valid product is required.");
  }
  const productDoc = await db.doc(`products/${productId}`).get();
  if (!productDoc.exists) throw new HttpsError("not-found", "Product not found.");
  const product = productDoc.data();
  if (product.availability === "reserved_pending") {
    const lockExpires = product.reservationLockExpiresAt
      ? new Date(product.reservationLockExpiresAt)
      : null;
    if (lockExpires instanceof Date && !Number.isNaN(lockExpires.getTime()) &&
        lockExpires <= new Date()) {
      await db.runTransaction(async (transaction) => {
        const lockedRef = db.doc(`products/${productId}`);
        const lockedDoc = await transaction.get(lockedRef);
        const locked = lockedDoc.data() || {};
        if (locked.availability !== "reserved_pending") return;
        const latestLock = locked.reservationLockExpiresAt
          ? new Date(locked.reservationLockExpiresAt)
          : null;
        if (latestLock instanceof Date && !Number.isNaN(latestLock.getTime()) &&
            latestLock > new Date()) return;
        const staleOrderId = String(locked.reservationLockOrderId || "");
        if (/^[A-Za-z0-9_-]+$/.test(staleOrderId)) {
          const staleOrderRef = db.doc(`jewelryReservationOrders/${staleOrderId}`);
          const staleOrderDoc = await transaction.get(staleOrderRef);
          if (staleOrderDoc.exists &&
              String(staleOrderDoc.data().status || "") === "pending") {
            transaction.update(staleOrderRef, {
              status: "expired",
              expiredAt: new Date().toISOString(),
            });
          }
        }
        transaction.update(lockedRef, {
          availability: "available",
          reservationLockOrderId: FieldValue.delete(),
          reservationLockExpiresAt: FieldValue.delete(),
          updatedAt: new Date().toISOString(),
        });
      });
      product.availability = "available";
    } else if (!(lockExpires instanceof Date) || Number.isNaN(lockExpires.getTime()) ||
        lockExpires > new Date()) {
      throw new HttpsError("failed-precondition", "This product is currently reserved for checkout.");
    }
  } else if (product.availability !== "available") {
    throw new HttpsError("failed-precondition", "This product is no longer available for reservation.");
  }
  if (!["jewelry", "watch"].includes(product.productType)) {
    throw new HttpsError("failed-precondition", "Only jewelry pieces and watches can be reserved.");
  }

  let totalMinor;
  if (product.productType === "jewelry") {
    const karats = await getReservationGoldKarats();
    const karat = Number(product.goldKarat);
    const weight = Number(product.goldWeight);
    const premium = Number(product.currentPremium);
    const perGramMinor = karats[karat];
    if (!(perGramMinor > 0) || !(weight > 0) || !(premium >= 0)) {
      throw new HttpsError("failed-precondition", "The current jewelry price is unavailable.");
    }
    totalMinor = Math.round((perGramMinor / 100 + premium) * weight * 100);
  } else {
    const watchPrice = Number(product.price);
    if (!(watchPrice > 0)) {
      throw new HttpsError("failed-precondition", "The watch price is unavailable.");
    }
    totalMinor = Math.round(watchPrice * 100);
  }
  if (!(totalMinor > 0)) {
    throw new HttpsError("failed-precondition", "The product price is unavailable.");
  }
  const depositMinor = Math.round(totalMinor * 0.10);
  let jewelerStoreName = "KHAN jeweler";
  if (String(product.jewelerId || "")) {
    const applicationDoc = await db.doc(`applications/${product.jewelerId}`).get();
    if (applicationDoc.exists) {
      const application = applicationDoc.data();
      jewelerStoreName = String(application.storeName || application.fullName || jewelerStoreName);
    }
  }
  return {
    productId,
    jewelerId: String(product.jewelerId || ""),
    jewelerStoreName,
    productName: product.productType === "watch"
      ? [String(product.brand || ""), String(product.model || "")].filter(Boolean).join(" ").trim() || "Watch"
      : String(product.title || "Jewelry piece"),
    productImagePath: Array.isArray(product.photoPaths) && product.photoPaths[0]
      ? String(product.photoPaths[0])
      : "",
    totalMinor,
    depositMinor,
    remainingMinor: totalMinor - depositMinor,
  };
}

exports.getJewelryReservationQuote = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const quote = await calculateReservationQuote(request.data.productId);
  return {
    ...quote,
    totalEgp: quote.totalMinor / 100,
    depositEgp: quote.depositMinor / 100,
    remainingEgp: quote.remainingMinor / 100,
  };
});

exports.createJewelryReservationCheckout = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const quote = await calculateReservationQuote(request.data.productId);
  if (!quote.jewelerId) throw new HttpsError("failed-precondition", "The jeweler is unavailable.");
  if (!process.env.PAYMOB_API_KEY ||
      !process.env.PAYMOB_INTEGRATION_ID ||
      !process.env.PAYMOB_IFRAME_ID) {
    throw new HttpsError("failed-precondition", "Paymob is not configured.");
  }

  const applicationDoc = await db.doc(`applications/${quote.jewelerId}`).get();
  const application = applicationDoc.exists ? applicationDoc.data() : {};
  const customerDoc = await db.doc(`users/${request.auth.uid}`).get();
  const customer = customerDoc.exists ? customerDoc.data() : {};
  const storeName = String(application.storeName || application.fullName || "KHAN jeweler");
  const customerName = String(customer.name || request.auth.token.name || "KHAN customer");
  const customerEmail = String(customer.email || request.auth.token.email || "");
  const customerPhone = String(customer.phone || "");

  let orderId;
  let lockExpiresAt;
  await db.runTransaction(async (transaction) => {
    const productRef = db.doc(`products/${quote.productId}`);
    const productDoc = await transaction.get(productRef);
    const product = productDoc.data() || {};
    if (product.availability === "reserved_pending") {
      const lockExpires = product.reservationLockExpiresAt
        ? new Date(product.reservationLockExpiresAt)
        : null;
      if (lockExpires instanceof Date && !Number.isNaN(lockExpires.getTime()) &&
          lockExpires > new Date()) {
        throw new HttpsError("failed-precondition", "This product is currently reserved for checkout.");
      }
    } else if (product.availability !== "available") {
      throw new HttpsError("failed-precondition", "This product is no longer available.");
    }
    const existingActive = product.activeReservationId;
    if (existingActive) {
      throw new HttpsError("failed-precondition", "This product already has an active reservation.");
    }
    orderId = db.collection("jewelryReservationOrders").doc().id;
    const now = Date.now();
    lockExpiresAt = new Date(now + 15 * 60 * 1000).toISOString();
    const orderRef = db.doc(`jewelryReservationOrders/${orderId}`);
    transaction.set(orderRef, {
      orderId,
      customerUid: request.auth.uid,
      customerName,
      customerEmail,
      customerPhone,
      productId: quote.productId,
      productName: quote.productName,
      productImagePath: quote.productImagePath,
      jewelerId: quote.jewelerId,
      jewelerStoreName: storeName,
      totalPriceMinorUnits: quote.totalMinor,
      depositAmountMinorUnits: quote.depositMinor,
      remainingBalanceMinorUnits: quote.remainingMinor,
      currency: "EGP",
      paymentGateway: "paymob",
      status: "pending",
      createdAt: new Date(now).toISOString(),
      expiresAt: lockExpiresAt,
      merchantOrderId: `khan-rsv-${orderId}`,
    });
    transaction.update(productRef, {
      availability: "reserved_pending",
      reservationLockOrderId: orderId,
      reservationLockExpiresAt: lockExpiresAt,
      updatedAt: new Date(now).toISOString(),
    });
  });

  try {
    const authToken = await paymobAuth();
    const paymobOrder = await paymobRequest("POST", "/ecommerce/orders", authToken, {
      auth_token: authToken,
      delivery_needed: false,
      amount_cents: quote.depositMinor,
      currency: "EGP",
      merchant_order_id: `khan-rsv-${orderId}`,
    });
    if (!paymobOrder.id) throw new Error("Paymob order could not be created.");

    let redirectionUrl = "";
    if (request.data.returnUrl) {
      const separator = String(request.data.returnUrl).includes("?") ? "&" : "?";
      redirectionUrl = `${String(request.data.returnUrl)}${separator}khan_reservation_order_id=${encodeURIComponent(orderId)}`;
    }
    const paymentKey = await paymobRequest("POST", "/acceptance/payment_keys", authToken, {
      auth_token: authToken,
      amount_cents: quote.depositMinor,
      expiration: 15 * 60,
      order_id: paymobOrder.id,
      billing_data: {
        apartment: "NA",
        email: customerEmail || "customer@example.com",
        floor: "NA",
        first_name: customerName.split(" ")[0] || "KHAN",
        street: "NA",
        building: "NA",
        phone_number: customerPhone || "NA",
        shipping_method: "NA",
        postal_code: "NA",
        city: "Cairo",
        country: "EG",
        last_name: customerName.split(" ").slice(1).join(" ") || "Customer",
        state: "Cairo",
      },
      currency: "EGP",
      integration_id: Number(process.env.PAYMOB_INTEGRATION_ID),
      ...(redirectionUrl ? { redirection_url: redirectionUrl } : {}),
    });
    if (!paymentKey.token) throw new Error("Paymob payment key could not be created.");

    await db.doc(`jewelryReservationOrders/${orderId}`).set({
      paymobOrderId: String(paymobOrder.id),
    }, { merge: true });

    return {
      orderId,
      paymobOrderId: String(paymobOrder.id),
      merchantOrderId: `khan-rsv-${orderId}`,
      amountMinor: quote.depositMinor,
      checkoutUrl: `https://accept.paymob.com/api/acceptance/iframes/${process.env.PAYMOB_IFRAME_ID}?payment_token=${paymentKey.token}`,
    };
  } catch (error) {
    await releaseReservationCheckout(orderId, request.auth.uid);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Paymob checkout could not be created.");
  }
});

exports.confirmJewelryReservationPayment = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const orderId = String(request.data.orderId || "");
  const transactionId = String(request.data.paymobTransactionId || "");
  if (!/^[A-Za-z0-9_-]+$/.test(orderId) || !/^\d+$/.test(transactionId)) {
    throw new HttpsError("invalid-argument", "Payment details are invalid.");
  }

  const authToken = await paymobAuth();
  const payment = await paymobRequest("GET", `/acceptance/transactions/${transactionId}`, authToken);
  if (payment.pending === true) {
    return { status: "pending", processed: false };
  }
  if (payment.success !== true || payment.is_refunded === true || payment.is_voided === true) {
    await db.runTransaction(async (transaction) => {
      const orderRef = db.doc(`jewelryReservationOrders/${orderId}`);
      const orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) return;
      const order = orderDoc.data();
      if (order.customerUid !== request.auth.uid || order.status !== "pending") return;
      transaction.update(orderRef, { status: "cancelled", cancelledAt: new Date().toISOString() });
      const productRef = db.doc(`products/${order.productId}`);
      const productDoc = await transaction.get(productRef);
      if (productDoc.exists && productDoc.data().reservationLockOrderId === orderId) {
        transaction.update(productRef, {
          availability: "available",
          reservationLockOrderId: FieldValue.delete(),
          reservationLockExpiresAt: FieldValue.delete(),
          updatedAt: new Date().toISOString(),
        });
      }
    });
    return { status: "failed", processed: false };
  }
  if (payment.currency !== "EGP" || Number(payment.amount_cents) <= 0) {
    throw new HttpsError("failed-precondition", "Payment details are invalid.");
  }
  let order = payment.order;
  if (!order) order = await paymobRequest("GET", `/ecommerce/orders/${payment.order_id}`, authToken);
  if (order.merchant_order_id !== `khan-rsv-${orderId}`) {
    throw new HttpsError("failed-precondition", "Payment does not belong to this reservation.");
  }

  let processed = false;
  let reservationId = orderId;
  await db.runTransaction(async (transaction) => {
    const orderRef = db.doc(`jewelryReservationOrders/${orderId}`);
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) throw new HttpsError("not-found", "Reservation order not found.");
    const pending = orderDoc.data();
    if (pending.customerUid !== request.auth.uid) {
      throw new HttpsError("permission-denied", "This reservation belongs to another customer.");
    }
    if (pending.status === "completed") {
      if (String(pending.paymobTransactionId || "") !== transactionId) {
        throw new HttpsError("failed-precondition", "This Paymob transaction does not match the reservation.");
      }
      const paymentRef = db.doc(`jewelryReservationPayments/payment-${transactionId}`);
      const paymentDoc = await transaction.get(paymentRef);
      if (!paymentDoc.exists ||
          String(paymentDoc.data().reservationOrderId || "") !== orderId) {
        throw new HttpsError("failed-precondition", "The completed reservation payment record is missing.");
      }
      processed = false;
      reservationId = pending.reservationId || orderId;
      return;
    }
    if (pending.status !== "pending") {
      throw new HttpsError("failed-precondition", "Reservation payment is no longer pending.");
    }
    if (Number(pending.totalPriceMinorUnits) <= 0 ||
        Number(payment.amount_cents) !== Number(pending.depositAmountMinorUnits)) {
      throw new HttpsError("failed-precondition", "Deposit amount does not match.");
    }
    if (new Date(pending.expiresAt) <= new Date()) {
      throw new HttpsError("failed-precondition", "Reservation checkout has expired.");
    }

    const paymentRef = db.doc(`jewelryReservationPayments/payment-${transactionId}`);
    const paymentDoc = await transaction.get(paymentRef);
    if (paymentDoc.exists) {
      const existing = paymentDoc.data();
      if (existing.reservationOrderId === orderId) {
        processed = false;
        return;
      }
      throw new HttpsError("failed-precondition", "This Paymob transaction was already used.");
    }

    const productRef = db.doc(`products/${pending.productId}`);
    const productDoc = await transaction.get(productRef);
    if (!productDoc.exists) throw new HttpsError("not-found", "Product not found.");
    const product = productDoc.data();
    if (product.availability !== "reserved_pending" ||
        product.reservationLockOrderId !== orderId) {
      throw new HttpsError("failed-precondition", "Product is no longer reserved for this checkout.");
    }

    const now = Timestamp.now();
    const expires = Timestamp.fromMillis(now.toMillis() + 48 * 60 * 60 * 1000);
    const reservationRef = db.doc(`jewelryReservations/${orderId}`);
    transaction.set(reservationRef, {
      reservationId: orderId,
      customerUid: pending.customerUid,
      customerName: pending.customerName,
      customerEmail: pending.customerEmail,
      customerPhone: pending.customerPhone,
      productId: pending.productId,
      productName: pending.productName,
      productImagePath: pending.productImagePath,
      jewelerId: pending.jewelerId,
      jewelerStoreName: pending.jewelerStoreName,
      originalTotalPriceMinorUnits: Number(pending.totalPriceMinorUnits),
      originalTotalPriceEgp: Number(pending.totalPriceMinorUnits) / 100,
      depositAmountMinorUnits: Number(pending.depositAmountMinorUnits),
      depositAmountEgp: Number(pending.depositAmountMinorUnits) / 100,
      remainingBalanceMinorUnits: Number(pending.remainingBalanceMinorUnits),
      remainingBalanceEgp: Number(pending.remainingBalanceMinorUnits) / 100,
      paymentGateway: "paymob",
      paymobTransactionId: transactionId,
      paymobOrderId: String(pending.paymobOrderId || payment.order_id || ""),
      reservationCreatedAt: now,
      reservationExpiresAt: expires,
      status: "reserved_for_48_hours",
      createdAt: now,
      expiresAt: expires,
    });
    transaction.update(orderRef, {
      status: "completed",
      reservationId: orderId,
      paymobTransactionId: transactionId,
      paymentTransactionId: transactionId,
      paidAt: now,
      completedAt: now,
    });
    transaction.set(paymentRef, {
      reservationOrderId: orderId,
      reservationId: orderId,
      customerUid: pending.customerUid,
      paymobTransactionId: transactionId,
      paymobOrderId: String(pending.paymobOrderId || payment.order_id || ""),
      amountMinorUnits: Number(payment.amount_cents),
      currency: "EGP",
      createdAt: now,
    });
    transaction.update(productRef, {
      availability: "unavailable",
      activeReservationId: orderId,
      reservedAt: now,
      reservedUntil: expires,
      reservationStatus: "reserved_for_48_hours",
      reservationLockOrderId: FieldValue.delete(),
      reservationLockExpiresAt: FieldValue.delete(),
      updatedAt: now,
    });
    processed = true;
  });
  return { status: "success", processed, reservationId };
});

exports.cancelJewelryReservationCheckout = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const orderId = String(request.data.orderId || "");
  if (!/^[A-Za-z0-9_-]+$/.test(orderId)) {
    throw new HttpsError("invalid-argument", "Reservation order is invalid.");
  }
  await db.runTransaction(async (transaction) => {
    const orderRef = db.doc(`jewelryReservationOrders/${orderId}`);
    const orderDoc = await transaction.get(orderRef);
    if (!orderDoc.exists) return;
    const order = orderDoc.data();
    if (order.customerUid !== request.auth.uid || order.status !== "pending") return;
    transaction.update(orderRef, { status: "cancelled", cancelledAt: new Date().toISOString() });
    const productRef = db.doc(`products/${order.productId}`);
    const productDoc = await transaction.get(productRef);
    if (productDoc.exists) {
      const product = productDoc.data();
      if (product.reservationLockOrderId === orderId) {
        transaction.update(productRef, {
          availability: "available",
          reservationLockOrderId: FieldValue.delete(),
          reservationLockExpiresAt: FieldValue.delete(),
          updatedAt: new Date().toISOString(),
        });
      }
    }
  });
  return { cancelled: true };
});
