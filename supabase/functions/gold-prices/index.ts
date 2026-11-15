const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

const cacheTtlMs = 30 * 60 * 1000;
const karatFields = {
  24: "price_gram_24k",
  22: "price_gram_22k",
  21: "price_gram_21k",
  18: "price_gram_18k",
} as const;

type CachedPrices = {
  expiresAt: number;
  payload: Record<string, unknown>;
};

let cache: CachedPrices | null = null;

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=1800",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "GET") {
    return jsonResponse({ success: false, error: "Method not allowed." }, 405);
  }

  if (cache !== null && cache.expiresAt > Date.now()) {
    return jsonResponse(cache.payload);
  }

  const apiKey = Deno.env.get("GOLD_API_KEY");
  if (apiKey === undefined || apiKey.trim() === "") {
    return jsonResponse(
      { success: false, error: "Gold price service is not configured." },
      503,
    );
  }

  try {
    const response = await fetch("https://www.goldapi.io/api/XAU/EGP", {
      headers: {
        Accept: "application/json",
        "x-access-token": apiKey,
      },
    });

    if (!response.ok) {
      return jsonResponse(
        { success: false, error: "GoldAPI request failed." },
        503,
      );
    }

    const data = await response.json() as Record<string, unknown>;
    const prices: Record<string, number> = {};

    for (const [karat, field] of Object.entries(karatFields)) {
      const value = data[field];
      if (typeof value === "number" && Number.isFinite(value) && value > 0) {
        prices[karat] = value;
      }
    }

    if (Object.keys(prices).length === 0) {
      return jsonResponse(
        { success: false, error: "GoldAPI returned no karat prices." },
        503,
      );
    }

    const timestamp = data.timestamp ?? data.updated_at ?? Date.now();
    const payload = {
      success: true,
      prices,
      currency: "EGP",
      updatedAt: typeof timestamp === "number"
        ? new Date(timestamp * 1000).toISOString()
        : String(timestamp),
      source: "GoldAPI",
    };

    cache = { expiresAt: Date.now() + cacheTtlMs, payload };
    return jsonResponse(payload);
  } catch (error) {
    console.error("GoldAPI request failed", error);
    return jsonResponse(
      { success: false, error: "Gold price service is temporarily unavailable." },
      503,
    );
  }
});
