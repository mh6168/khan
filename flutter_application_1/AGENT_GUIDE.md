# KHAN Project Agent Guide

## Documentation status

- This guide describes the implementation visible in the repositories on 2026-11-22.
- The Flutter repository is `C:\Users\LENOVO\Documents\University\E-Business\khan\khan\flutter_application_1`.
- The PHP repository is `C:\xampp\htdocs\khan-mgmt\khan-mgmt`.
- The PHP repository is accessible and was inspected.
- Source code is authoritative. The PHP runtime-validation report records checks performed on 2026-11-05; it does not replace source inspection.

## 1. Project overview and business purpose

KHAN is an Egyptian jewelry marketplace and investment-related demo:

- Customers use the Flutter application to browse approved jewelers and available jewelry or watches.
- Approved jewelers use the PHP management system to submit application documents, maintain a paid subscription, and create/manage products.
- The admin management interface reviews jeweler applications and approves or rejects them.
- The management system includes a Master Dealer workspace for Lira/Para inventory, live prices, customer buybacks, finance, and transaction history.
- The Flutter app includes a Lira/Para customer investment screen, but some purchase and buyback paths are implemented as client-side Firestore/Spark-plan workflows and require the app plus PHP/Cloud Function checks to be evaluated together.

The application is a university e-business project. Keep changes simple and preserve the existing demo-friendly behavior unless a task explicitly requires production hardening.

## 2. Repository structures

### Flutter repository

The Flutter package root is `flutter_application_1/`.

Important locations:

- `pubspec.yaml`: Dart/Flutter dependencies and assets.
- `analysis_options.yaml`: `flutter_lints` analysis configuration.
- `lib/main.dart`: Firebase initialization, theme, authentication gate, and top-level role routing.
- `lib/firebase_options.dart`: generated platform Firebase configuration.
- `lib/khan_colors.dart`: KHAN palette constants.
- `lib/data/`: Firestore, product, jeweler, Supabase, GoldAPI, Paymob, and investment services.
- `lib/models/`: product, jeweler, customer, portfolio, and sell-request models.
- `lib/screens/`: customer, authentication, profile, product, jeweler, investment, Paymob return, and dashboard screens.
- `lib/widgets/`: reusable navigation, headers, cards, profile, jeweler, and investment widgets.
- `lib/utils/auth_helpers.dart`: authentication validation/error helpers.
- `firestore.rules`: deployed/deployment-ready Firestore authorization rules.
- `functions/index.js`: Cloud Functions for metal prices and Lira/Para purchase settlement.
- `functions/package.json`: Node 20 Firebase Functions dependencies.
- `test/`: widget and integration-style fake-Firestore tests.
- `android/app/google-services.json`: Android Firebase app configuration.
- `.env`: local runtime configuration loaded by `flutter_dotenv`; credentials must remain local.

### PHP management repository

- `public/`: Apache document root and entry pages.
- `public/index.php`: front controller for signup/login/auth/application routes.
- `public/.htaccess`: clean URL rewrites.
- `public/admin/`: demo admin login, dashboard, requests, and application review.
- `public/jeweler/`: approved/rejected/pending application status, subscription payment, and dashboard entry.
- `public/master-dealer/`: live pricing, inventory, buybacks, finance, and transactions.
- `public/master-dealer/api.php`: customer Firebase-token/API endpoints.
- `app/`: PHP services and controllers.
- `resources/views/jeweler/`: jeweler dashboard and partials.
- `resources/views/master-dealer/layout.php`: Master Dealer layout.
- `storage/`: runtime cache/certificate files and ignored service configuration where used.
- `tests/`: dependency-free PHP service tests.
- `.env.example`: configuration names only; never copy values or secrets into documentation.
- `README.md`: setup and architecture notes.
- `runtime-validation-report.md`: 2026-11-05 validation report.

Do not expose or document secret values. Use environment variables and ignored local files.

## 3. Technology stack and dependencies

### Flutter

- Flutter/Dart; `pubspec.yaml` declares SDK constraint `^3.13.4`.
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `flutter_dotenv`
- `http`
- `url_launcher`
- `cupertino_icons`
- Development: `flutter_lints`, `fake_cloud_firestore`, `flutter_test`
- The app is configured for Android and web; `lib/main.dart` explicitly reports Windows desktop Firebase plugins as unsupported.

### PHP

- PHP 8.2 and Apache/XAMPP
- Dependency-free Firebase REST Authentication/Firestore integration
- PHP cURL, fileinfo, JSON, mbstring, openssl, and session extensions
- Private REST clients for Supabase Storage and Paymob
- No Composer dependency is required by the current implementation

### Node

- Firebase Functions Node 20
- `firebase-admin ^13.0.0`
- `firebase-functions ^6.0.0`

## 4. Firebase Authentication and Firestore architecture

### Flutter Authentication

- `lib/main.dart` calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
- `FirebaseAuth.instance.authStateChanges()` is the authentication gate.
- An unauthenticated user is sent to `LoginScreen`.
- `users/{uid}` is read to route a `role == 'masterDealer'` user to `MasterDealerDashboardScreen`; all other users enter `CustomerHomeScreen`.
- `lib/screens/signup_screen.dart` creates an email/password account with `createUserWithEmailAndPassword`, then creates `users/{uid}` with `name`, `email`, `phone`, `uid`, and `FieldValue.serverTimestamp()`.
- The Flutter signup flow signs out after profile creation and requires the user to log in again.

### PHP Authentication

- `FirebaseAuthClient.php` uses Firebase Authentication REST signup/signin.
- `FirebaseIdTokenVerifier.php` verifies Firebase bearer tokens against cached Google public signing keys.
- `JewelerSession.php` stores the Firebase ID token and UID claims in the server-side PHP session.
- Jeweler routes require a valid session and re-read Firestore where application status/ownership must be enforced.
- `FirestoreClient.php` uses a verified Firebase ID token for jeweler/user REST operations.
- `FirestoreAdminClient.php` uses a server-only service account for admin and subscription operations.
- `MasterDealer` API purchase/buyback routes use `FirebaseIdTokenVerifier`.

## 5. Firestore collections and document structures

### `users/{uid}`

Implemented in both signup flows:

- `name`: string
- `email`: string
- `phone`: string
- `uid`: string
- `createdAt`: server timestamp or ISO/string, depending on writer
- `role`: optional, e.g. `masterDealer`

The role is not assigned by signup. It must be set by an authorized administrative process.

### `applications/{uid}`

Created by the PHP jeweler application flow. Main fields:

- `fullName`
- `storeName`
- `phone`
- `storeAddress`
- `uid`
- `nationalIdPath`
- `commercialRegisterPath`
- `taxCardPath`
- `goldLicensePath`
- `status`: `pending`, `approved`, or `rejected`
- `submittedAt`
- `rejectionReason` when rejected/resubmission is supported
- `subscriptionStatus`: `unpaid` or `active`
- `subscriptionPaidAt`
- `subscriptionExpiresAt`
- `subscriptionAmount`
- `paymentTransactionId`

`applications/{uid}` is both the onboarding record and the jeweler approval/subscription record.

### `products/{productId}`

Common fields:

- `jewelerId`: owner Firebase UID
- `productType`: `jewelry` or `watch`
- `availability`: `available` or `unavailable`
- `createdAt`
- `updatedAt`
- `threeDModelUrl`
- `photoPaths`: Supabase object paths

Jewelry fields:

- `title`
- `category`
- `totalWeight`
- `goldWeight`
- `goldKarat`: 24, 22, 21, or 18
- `goldColor`
- `countryOfOrigin`
- `currentPremium`
- `originalPremium`

Watch fields:

- `watchType`
- `brand`
- `model`
- `caseMaterial`
- `dialColor`
- `movementType`
- `price`
- `countryOfOrigin`

Jewelry prices are calculated from live/available GoldAPI karat prices plus `currentPremium * goldWeight`; the calculation is not persisted as a jewelry price. Watches use persisted `price`.

### Master Dealer investment collections

- `masterDealerInventory/{lira|para}`:
  - `asset`
  - `quantity`
  - `reserved`
  - `updatedAt`
- `masterDealerPrices/current`:
  - `liraSpotMinor`
  - `paraSpotMinor`
  - `liraSellingMinor`
  - `paraSellingMinor`
  - `liraBuybackMinor`
  - `paraBuybackMinor`
  - `updatedAt`
- `masterDealerPriceHistory/{historyId}`:
  - selling/buyback unit prices
  - `combinedLiquidationMinor`
  - `createdAt`
- `customerPortfolios/{uid}`:
  - `liraQuantity`
  - `paraQuantity`
  - `reservedLiraQuantity`
  - `reservedParaQuantity`
  - `updatedAt`
- `masterDealerPurchaseOrders/{purchaseId}`:
  - customer UID/quantities/locked unit prices
  - `amountMinorUnits`
  - `currency`
  - `status`
  - `createdAt`, `expiresAt`
  - `merchantOrderId`
  - optional `paymobOrderId`, `paymentTransactionId`, `paidAt`, `cancelledAt`
- `masterDealerSellRequests/{requestId}`:
  - customer identity and phone fields
  - quantities and locked payout prices
  - `totalPayoutMinor`
  - `currency`
  - `status`
  - `instapayPhone`
  - timestamps and transfer metadata
- `masterDealerTransactions/{transactionId}`:
  - purchases, buybacks, and inventory adjustments
  - type/status/source, customer UID, quantities, prices, amount, and timestamps
- `masterDealerBuybacks/{requestId}`:
  - customer UID and quantities
  - InstaPay phone
  - locked prices and payout
  - status `pending`, `processing`, or `completed`
- `masterDealerFinance/account`:
  - `balanceMinorUnits`
  - `updatedAt`

Relationships:

- `applications.uid == users.uid == Firebase uid == jewelerId`.
- `products.jewelerId` owns a product and links to `applications/{uid}` and `users/{uid}`.
- `customerPortfolios.uid` and customer fields use the Firebase UID.
- Purchase/buyback/transaction records store `customerUid`.
- Master Dealer inventory and transactions are global shared documents/collections.

## 6. Firebase Cloud Functions

`functions/index.js` exports:

### `updateInvestmentPrices`

- Callable function requiring authentication is not itself role-restricted.
- Requires `GOLD_API_KEY`.
- Fetches XAU and XAG 24K/925 values from GoldAPI.
- Writes `masterDealerPrices/current`.
- Adds `masterDealerPriceHistory`.
- Lira spot is 24K gold per 0.01 gram; Para spot is 925 silver per gram.
- Selling is spot + 500 minor units (5 EGP).
- Buyback is spot + 100 minor units (1 EGP).

### `createInvestmentPurchase`

- Callable by signed-in users.
- Validates `lira` or `para`, positive quantity, and 1–10,000 range.
- Checks current price and inventory.
- Atomically reserves stock and creates `masterDealerPurchaseOrders/{orderId}`.
- Creates Paymob order and payment key and returns an iframe checkout URL.

### `confirmInvestmentPurchase`

- Callable by signed-in users.
- Verifies the Paymob transaction directly.
- Checks success/refund/void/pending state, EGP, exact amount, and merchant order ID.
- Settles inventory, portfolio holdings, order status, transaction, and finance/ledger inside a Firestore transaction.
- Uses `payment-{transactionId}` for idempotency.

The PHP `MasterDealerPaymentService` has a separate server-side Paymob confirmation implementation for the PHP purchase API. It must be kept aligned with these rules.

## 7. Paymob integration

### Flutter

- `lib/data/paymob_service.dart` implements authentication, Paymob order creation, payment-key creation, iframe URL generation, and transaction verification.
- The environment names are `PAYMOB_API_KEY`, `PAYMOB_INTEGRATION_ID`, `PAYMOB_IFRAME_ID`, `PAYMOB_API_BASE_URL`, and `PAYMOB_REDIRECT_URL`.
- Client callbacks are handled by `lib/screens/paymob_return_screen.dart`.
- `PaymobReturnData` reads `khan_order_id`, payment status/transaction parameters from `Uri.base`.
- On return, the app verifies the Paymob transaction before `completePurchase()` credits the portfolio.

### PHP jeweler subscriptions

- `app/PaymobClient.php` creates a 100,000-cent (1,000 EGP) subscription checkout.
- `public/jeweler/subscription-payment.php` starts the checkout for an approved jeweler.
- `public/jeweler/payment-success.php` verifies the transaction, EGP amount, transaction ID, and merchant-order ownership, then calls `FirestoreAdminClient::updateSubscription`.
- Subscriptions last 30 days:
  - `subscriptionStatus: active`
  - `subscriptionPaidAt`
  - `subscriptionExpiresAt`
  - `subscriptionAmount: 1000`
  - `paymentTransactionId`

### PHP Master Dealer API

- `public/master-dealer/api.php` exposes purchase, buyback, and server-side payment confirmation actions.
- Purchase and buyback require a Firebase bearer token and Idempotency-Key.
- `confirm-payment` verifies through Paymob independently and has no bearer-token requirement.
- Merchant order ID is `khan-md-{purchaseOrderId}`.
- Amount is the exact EGP minor-unit/piaster amount.

## 8. Existing Lira/Para workflow

### Unit and price rules

- Lira is based on 24K gold at 0.01 gram.
- Para is based on 925 silver at 1 gram.
- Prices are stored as integer minor units/EGP hundredths.
- Selling/add-to-cart price adds 5 EGP to spot.
- Buyback price adds 1 EGP to spot.
- Purchase quantities are limited to 1–10,000 units per operation.

### Purchase

- A purchase order reserves inventory for 15 minutes.
- Paymob checkout uses the exact order amount and `khan-md-{purchaseOrderId}` merchant ID.
- Successful verified settlement decreases inventory/on-hand and reserved stock, adds holdings to `customerPortfolios`, marks the order completed, adds a transaction, and updates the Master Dealer finance account.
- Cancellation/expiry releases the reservation.

### Buyback/sellback

- `InvestmentService.createSellRequest` creates a processing sell request and reserves the submitted quantities in the customer's portfolio.
- `InstaPay` phone number must match Egyptian mobile format `01[0125][0-9]{8}`.
- Locked unit prices and payout are written with the request.
- The Master Dealer dashboard can mark a request money transferred/completed.
- The PHP buyback service similarly locks prices and records atomic completion, but the PHP API README explicitly warns that it cannot independently prove that client-supplied quantities are owned.

## 9. Product creation, pricing, retrieval, and ownership

### Creation

The PHP jeweler dashboard creates:

- Watches: `watchType`, `brand`, `model`, `caseMaterial`, `dialColor`, `movementType`, `price`, `countryOfOrigin`, optional `threeDModelUrl`, photos.
- Jewelry: `title`, `category`, `totalWeight`, `goldWeight`, `goldKarat`, `goldColor`, `countryOfOrigin`, `currentPremium`, optional `originalPremium`, optional `threeDModelUrl`, photos.
- `jewelerId` is always taken from the verified session UID, never from browser input.
- Photos are uploaded to Supabase and object paths are stored in Firestore.
- Maximum 8 photos, JPG/JPEG/PNG/WebP, 10 MB per photo.

### Pricing

- Watch price is entered directly.
- Jewelry price is computed as `(karat gold price + current premium) * goldWeight`.
- Gold weight must not exceed total weight.
- Gold karat is limited to 24, 22, 21, or 18.

### Retrieval

- `ProductService.fetchAvailableProducts()` reads `products` where `availability == available`.
- `fetchAvailableProductsForJeweler()` filters by `jewelerId` and available status.
- The PHP dashboard lists only products whose `jewelerId` equals the authenticated jeweler UID.
- Before update, availability change, or delete, the PHP service re-checks `jewelerId`.

## 10. Jeweler onboarding and subscription workflows

1. Jeweler signs up through the PHP `signup` flow or Firebase Authentication.
2. The PHP user profile is written to `users/{uid}`.
3. The Jeweler application form requires full name, store name, phone, address, and four private documents:
   - national ID
   - commercial register
   - tax card
   - gold-license/precious-metals license
4. Documents are uploaded below `{uid}/` to the private Supabase `jeweler-documents` bucket.
5. `applications/{uid}` is created with status `pending`.
6. Pending/approved/rejected routing is reevaluated on every relevant page load.
7. An admin approves or rejects in `public/admin/application.php`.
8. Approved jewelers with no active subscription are redirected to the subscription payment page.
9. Paymob success is verified server-side and writes the active 30-day subscription fields.
10. Dashboard access requires both `status: approved` and an active, unexpired subscription.

Rejected applications support a resubmission path with a status reset/replacement flow.

## 11. Admin and jeweler dashboard functionality

### Admin

- Demo admin login uses `AdminAuth.php`.
- Dashboard and application statistics are in `public/admin/dashboard.php`, `requests.php`, and `application.php`.
- Admin pages list and review applications.
- Application details show account/application fields and signed Supabase document links.
- Admin can approve or reject an application.
- Credentials and CSRF protection are server-side.

### Jeweler dashboard

`JewelerDashboardController.php` reads the application and active subscription.

Views include:

- Overview
- My Products
- Reservations
- Sales & Analytics
- Account

Implemented product management includes create, edit, availability toggle, delete, live gold-pricing display, and signed photo URLs.

Reservations and sales/analytics currently display explicit empty states because reservation/sales records are not fully modeled. Account data is summary-oriented rather than a full customer-facing account system.

### Master Dealer dashboard

Implemented in `public/master-dealer/`:

- overview/dashboard
- live Gold/Silver/Lira/Para prices
- inventory adjustments
- buyback request review/transfer
- financial ledger
- transaction history

The demo Master Dealer login is development-only and must not be treated as a production authentication mechanism.

### Flutter dashboard

- Master-dealer-role users enter `MasterDealerDashboardScreen`.
- It lists customer sell requests and can mark requests as money transferred.
- Investment, purchase, portfolio, sell, and transaction views are present in `lib/screens/invest_screen.dart`, `investment_purchase_screen.dart`, and related widgets.

## 12. Supabase integration

- The PHP system uses `SupabaseStorageClient.php` for private object storage.
- Jeweler onboarding uses the private `jeweler-documents` bucket.
- Jeweler product photos use the configured private storage bucket.
- Supabase service-role key and URL are server-side environment values.
- Paths, rather than files, are stored in Firestore.
- The admin and dashboard create short-lived signed URLs.
- The Flutter helper `lib/data/supabase_storage.dart` constructs public Supabase object URLs from `SUPABASE_URL` and `SUPABASE_STORAGE_BUCKET`.
- This public-URL helper may not work for private buckets. PHP signed URLs are the implemented server-side viewer path.

Never add the Supabase service-role key to `.env` assets consumed by Flutter or to `public/`.

## 13. KHAN business rules

- Only available products are generally browseable.
- `jewelerId` is the authoritative product owner.
- A jeweler can manage only its own products.
- Jeweler dashboard access requires approved status and active paid subscription.
- Jeweler application is one record per UID.
- Admin status changes are separate from the application-owner data.
- Jewelry gold price is calculated live from gold weight and karat plus premium.
- Watches use explicit entered prices.
- Lira/Para are separate inventory assets.
- Purchase reservations expire after 15 minutes.
- Sell requests cannot exceed available customer holdings in the Flutter transaction path.
- InstaPay must be an Egyptian mobile number.
- Verified Paymob payments must match EGP amount and merchant order.
- A successful purchase/settlement must be idempotent.
- The PHP and Flutter implementations must not accept client-supplied success flags as payment proof.
- Master Dealer finance balance is an internal ledger, not evidence of a real external bank transfer.

## 14. Design system and color palette

Declared palette:

- Dark: `#111618`
- Gold: `#E5C158`
- Light gold: `#FBF2B5`
- Secondary dark: `#2B3539`
- Existing Flutter ivory background: `#FFFCF2`
- PHP dashboard variables reuse the dark, gold, light-gold, and secondary-dark colors.

Flutter constants are in `lib/khan_colors.dart`:

- `khanDark`
- `khanGold`
- `khanLightGold`
- `khanSecondaryDark`
- `khanBackground`

The global theme in `lib/main.dart` sets `_ivory` as scaffold background, `_dark` for app bars/buttons, and `_gold` for accents and input borders.

PHP uses a dark charcoal/gold visual style in dashboard CSS and inline JewelerSession styles.

## 15. Development conventions and coding standards

### Flutter

- Prefer existing `data/`, `models/`, `screens/`, `widgets/`, and `utils/` boundaries.
- Use `const` constructors where practical.
- Keep services injectable through constructor parameters for fake-Firestore tests.
- Use `firebase_auth`, `cloud_firestore`, and `flutter_dotenv` patterns already in the package.
- Run `flutter analyze` and targeted `flutter test` commands.
- Keep environment configuration in `.env`; do not put secrets in Dart source or generated documentation.

### PHP

- Files use `declare(strict_types=1)`.
- Most services are dependency-free classes with explicit exceptions.
- Firestore REST payloads use Firestore REST field value types.
- Verify ownership server-side for every mutating operation.
- Use CSRF tokens for dashboard/admin POSTs.
- Verify Firebase ID tokens before protected operations.
- Escape HTML output with existing session/admin helpers.
- Use PHP session cookies with HttpOnly, SameSite, strict mode, and Secure in HTTPS contexts.

### General

- Preserve merchant order IDs, quantity, price, status, and idempotency field names.
- Use integer minor units for Lira/Para and money calculations.
- Do not silently fabricate unavailable gold/silver prices.
- Keep secrets outside source control and public web roots.

## 16. Existing incomplete features and known limitations

### Implemented with limitations

- Jeweler Reservations and Sales/Analytics dashboard views are explicit empty states.
- Flutter profile menu includes placeholder screens for several account/support features.
- Flutter `investment_purchase_screen.dart` contains demo/credential warnings and direct-client Paymob configuration.
- PHP and Flutter purchase flows have parallel implementations. Aligning their APIs and settlement behavior requires care.
- Flutter Cloud Functions are callable client functions and are not the same as PHP's server-side REST/API settlement.
- PHP buyback cannot independently validate customer holdings from current Firestore portfolio data.
- The PHP README says its customer purchase/settlement API is an implementation contract that requires the mobile integration to use the exact PHP/Paymob flow.
- Firestore rules allow direct Spark-plan investment writes, while production would ideally move more of that state behind authenticated server/Cloud Function transactions.
- Supabase onboarding bucket is private, but Flutter's image helper assumes public object URLs. The PHP signed-URL path is the more complete viewer implementation.

### External-service validation gaps

The PHP runtime-validation report marks live onboarding mutations as unverified because it did not create persistent disposable external accounts or documents.

The Flutter test suite includes fake-Firestore Paymob, sell request, investment, product, profile, and navigation tests, but no end-to-end payment credentials are a substitute for live Paymob validation.

### Demo and placeholder areas

- The PHP admin and Master Dealer demo credentials are development-only.
- Some Ruby/English README text is historical and should not override current source where implementation differs.
- The PHP README contains setup-stage language but the repository now includes later dashboard and Master Dealer implementations.

## 17. Jewelry reservation and deposit implementation

### Flutter reservation files

- `lib/models/jewelry_reservation.dart`
  - Defines `JewelryReservation` and the customer-facing status label mapping.
- `lib/data/reservation_service.dart`
  - Calls trusted Cloud Functions for authoritative quotes, checkout creation, Paymob confirmation, and checkout cancellation.
  - Watches `jewelryReservations` for the authenticated UID.
- `lib/screens/reservation/reservation_payment_method_screen.dart`
  - Payment-method selection screen. Paymob is the implemented option and the UI is structured for later methods.
- `lib/screens/reservation/reservation_checkout_screen.dart`
  - Loads a server-calculated 10%/90% quote and starts Paymob.
- `lib/screens/reservation/reservation_paymob_return_screen.dart`
  - Handles successful, pending, failed, and cancelled Paymob return states and asks the backend to verify again.
- `lib/screens/reservation/my_orders_screen.dart`
  - Real-time customer reservation list.
- `lib/screens/reservation/reservation_detail_screen.dart`
  - Reservation receipt/detail view.
- `lib/widgets/reservation_card.dart`
  - KHAN-styled reservation list card.

Existing product details and profile screens were modified:

- `lib/screens/product_details_screen.dart`
  - Displays **Reserve Now** for jewelry products and opens the reservation payment-method flow.
- `lib/screens/profile_screen.dart`
  - Replaced the My Orders placeholder with `MyOrdersScreen`.
- `lib/screens/customer_home_screen.dart`
  - Passes the authenticated customer ID into the profile/order flow.
- `lib/main.dart`
  - Recognizes `khan_reservation_order_id` in Paymob return URLs and routes to `ReservationPaymobReturnScreen`.

### Reservation Cloud Functions

The reservation implementation uses these callable functions in `functions/index.js`:

- `getJewelryReservationQuote`
  - Requires Firebase Authentication.
  - Reads the authoritative `products/{productId}` document.
  - Re-fetches the current GoldAPI XAU/EGP karat price for jewelry.
  - Reads the jeweler store name from `applications/{jewelerId}`.
  - Returns the current total, 10% deposit, and remaining 90% in integer minor units.
- `createJewelryReservationCheckout`
  - Requires Firebase Authentication.
  - Recalculates the authoritative quote instead of accepting Flutter-provided price or deposit values.
  - Creates `jewelryReservationOrders/{orderId}` and locks the product for 15 minutes.
  - Sets product `availability` to `reserved_pending` with `reservationLockOrderId` and `reservationLockExpiresAt`.
  - Creates the Paymob order/payment key using the exact server-calculated deposit.
  - Merchant order ID format: `khan-rsv-{orderId}`.
- `confirmJewelryReservationPayment`
  - Requires Firebase Authentication.
  - Fetches the transaction directly from Paymob and validates success, no refund/void, EGP currency, exact deposit amount, and merchant order ID.
  - Does not trust a checkout return or a Flutter success flag.
  - Atomically creates the reservation, marks the order complete, creates a payment idempotency record, and changes the product to unavailable.
  - Sets server-authored timestamps and a 48-hour expiry.
- `cancelJewelryReservationCheckout`
  - Cancels a pending checkout and releases the matching 15-minute product lock.

Paymob initiation and confirmation use the existing `PAYMOB_*` environment convention in Firebase Functions. Flutter never receives or stores Paymob API credentials. The checkout redirect includes `khan_reservation_order_id`; successful return still requires `confirmJewelryReservationPayment`.

### Reservation Firestore collections

`jewelryReservationOrders/{orderId}` contains pending/complete/cancelled checkout state:

- `orderId`
- `customerUid`
- `customerName`
- `customerEmail`
- `customerPhone`
- `productId`
- `productName`
- `productImagePath`
- `jewelerId`
- `jewelerStoreName`
- `totalPriceMinorUnits`
- `depositAmountMinorUnits`
- `remainingBalanceMinorUnits`
- `currency`
- `paymentGateway`
- `status`
- `createdAt`
- `expiresAt`
- `merchantOrderId`
- optional `paymobOrderId`, `paymobTransactionId`, `paymentTransactionId`, `paidAt`, `completedAt`, `cancelledAt`, `reservationId`

`jewelryReservations/{reservationId}` is the authoritative customer reservation:

- `reservationId`
- `customerUid`
- `customerName`
- `customerEmail`
- `customerPhone`
- `productId`
- `productName`
- `productImagePath`
- `jewelerId`
- `jewelerStoreName`
- `originalTotalPriceMinorUnits`
- `originalTotalPriceEgp`
- `depositAmountMinorUnits`
- `depositAmountEgp`
- `remainingBalanceMinorUnits`
- `remainingBalanceEgp`
- `paymentGateway`
- `paymobTransactionId`
- `paymobOrderId`
- `reservationCreatedAt`
- `reservationExpiresAt`
- `status`
- `createdAt`
- `expiresAt`

Timestamp fields use Firestore `Timestamp` values or ISO values for existing fields. Reservation expiry is exactly 48 hours after successful server-side Paymob verification.

`jewelryReservationPayments/payment-{paymobTransactionId}` is the duplicate-payment idempotency record. It contains `reservationOrderId`, `reservationId`, `customerUid`, Paymob references, amount, currency, and timestamp.

Product documents gain reservation coordination fields:

- `availability`: `available`, `reserved_pending`, or `unavailable`
- `reservationLockOrderId`
- `reservationLockExpiresAt`
- `activeReservationId`
- `reservedAt`
- `reservedUntil`
- `reservationStatus`

### Reservation status values

- `reserved_for_48_hours`: Reserved for 48 hours
- `handed_to_user`: Handed to you
- `refunded_deposit`: Deposit refunded
- `user_didnt_pick_up`: Not collected

These values are read-only in Flutter. The future PHP jeweler dashboard owns status transitions.

### Reservation security and duplicate handling

- The Cloud Function owns authoritative price calculation and Paymob verification.
- Flutter receives no total/deposit amount from a client-supplied business calculation.
- Product checkout is locked for 15 minutes before Paymob and can be cancelled/released.
- Successful verification atomically checks the product lock and creates the reservation.
- Repeating a completed confirmation returns an idempotent success without duplicating the reservation.
- Paymob transactions are stored in `jewelryReservationPayments` and reject reuse by another order.
- Firestore rules deny direct client writes to reservations, checkout orders, and payment records.
- Customers can only read their own reservation/order documents.
- Public product browsing continues to require `availability == available`.

`firestore.rules` now contains matching read-only rules for `jewelryReservations`, `jewelryReservationOrders`, and `jewelryReservationPayments`.
`firestore.indexes.json` declares the `jewelryReservations` composite index on `customerUid ASC, createdAt DESC`.

### Deployment requirements

1. Deploy updated Cloud Functions:
   `firebase deploy --only functions`
2. Deploy Firestore rules and indexes:
   `firebase deploy --only firestore`
3. Configure Firebase Functions secrets/environment variables:
   - Paymob API key
   - Paymob integration ID
   - Paymob iframe ID
   - optional Paymob API base URL
   - existing GoldAPI key
4. Ensure `GOLD_API_KEY` and the Paymob values remain server-side.
5. Configure the Paymob redirect URL to allow the Flutter web URL and test callback parameters.
6. Android and web callback behavior must be tested in the deployed environment. No real Paymob transaction was performed by this implementation pass.

### Reservation limitations and remaining PHP work

- Automatic reservation expiration from `reserved_for_48_hours` to `user_didnt_pick_up` is not implemented.
- The 25% KHAN / 75% jeweler non-refund distribution is not implemented.
- PHP does not yet read or manage `jewelryReservations`; future integration should use the documented collection/status fields.
- PHP must remain read-only until the future jeweler-dashboard status workflow is explicitly implemented.
- Product images in reservations use `productImagePath`; Flutter currently displays a generic jewelry icon for My Orders and does not yet generate Supabase signed/public URLs from this path. PHP signed-URL integration may be reused later.
- Real Paymob success, pending, failure, cancellation, duplicate callback, and cross-device callback behavior require live credentials and an actual test transaction.

# FUTURE AI AGENT INSTRUCTIONS

- Always read `AGENT_GUIDE.md` before working on this project.
- Avoid repeatedly inspecting the entire repositories.
- Inspect specific files only when needed.
- Trust actual source code over outdated documentation or historical README text.
- Update `AGENT_GUIDE.md` after significant project changes.
- Preserve existing working functionality and business rules.
- Keep code simple and suitable for a university e-business project.
