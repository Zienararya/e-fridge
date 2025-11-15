// Supabase Edge Function: push
// Sends FCM HTTP v1 notifications to all tokens for a given user.
// Secrets needed (Project Settings → Functions → Secrets):
// - SUPABASE_URL
// - SUPABASE_SERVICE_ROLE_KEY
// - GOOGLE_SERVICE_ACCOUNT_JSON (Firebase service account JSON)
// - FIREBASE_PROJECT_ID
//
// Request body options:
// 1) { user_id, title, body, data? }
// 2) { notifikasi_id }  // the function will fetch RPL.notifikasi by id and use log as body
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
function base64Url(input) {
  let b64;
  if (typeof input === "string") {
    b64 = btoa(input);
  } else {
    const bytes = new Uint8Array(input);
    let s = "";
    for (const b of bytes)s += String.fromCharCode(b);
    b64 = btoa(s);
  }
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function pemToBuf(pem) {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(b64);
  const out = new Uint8Array(raw.length);
  for(let i = 0; i < raw.length; i++)out[i] = raw.charCodeAt(i);
  return out.buffer;
}
async function importPK(pem) {
  return crypto.subtle.importKey("pkcs8", pemToBuf(pem), {
    name: "RSASSA-PKCS1-v1_5",
    hash: "SHA-256"
  }, false, [
    "sign"
  ]);
}
async function getAccessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "RS256",
    typ: "JWT"
  };
  const claims = {
    iss: sa.client_email,
    sub: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600
  };
  const toSign = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(claims))}`;
  const key = await importPK(sa.private_key);
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(toSign));
  const assertion = `${toSign}.${base64Url(sig)}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "content-type": "application/x-www-form-urlencoded"
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion
    })
  });
  if (!res.ok) throw new Error(`OAuth token error: ${await res.text()}`);
  const json = await res.json();
  return json.access_token;
}
serve(async (req)=>{
  if (req.method !== "POST") return new Response("Method Not Allowed", {
    status: 405
  });
  try {
    // NOTE: Webhook payload (Database > Webhooks > Edge Function) structure example:
    // {
    //   type: 'INSERT',
    //   table: 'notifikasi',
    //   schema: 'rpl',
    //   record: { id, user_id, log, iswarning, timestamp, ... },
    //   old_record: null
    // }
    // We still also support direct JSON calls: { user_id, title, body, data?, notifikasi_id }
    const raw = await req.json();
    let body = raw;
    // Basic logging (visible in Function logs). Avoid logging secrets.
    console.log("push function invoked", {
      hasRecord: !!body.record,
      directFields: {
        user_id: body.user_id,
        title: body.title,
        body: body.body?.slice(0, 80),
        notifikasi_id: body.notifikasi_id
      },
      webhookMeta: body.record ? {
        type: body.type,
        table: body.table,
        schema: body.schema
      } : undefined
    });
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID");
    const SA_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !FIREBASE_PROJECT_ID || !SA_JSON) {
      return new Response(JSON.stringify({
        error: "Missing env"
      }), {
        status: 500,
        headers: {
          "content-type": "application/json"
        }
      });
    }
    const sa = JSON.parse(SA_JSON);
    const commonHeaders = {
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "Accept-Profile": "rpl",
      "Content-Type": "application/json"
    };
    let userId = body.user_id;
    let title = body.title;
    let message = body.body;
    const data = body.data ?? {};
    // 1. Webhook record path
    if (!userId && body.record && typeof body.record === "object") {
      const rec = body.record;
      // Only proceed if iswarning is true (boolean) or 'true' (string). If you want to allow all, remove this check.
      const isWarnVal = rec.iswarning;
      const isWarning = isWarnVal === true || isWarnVal === "true";
      if (isWarning) {
        userId = typeof rec.user_id === "number" ? rec.user_id : typeof rec.user_id === "string" ? parseInt(rec.user_id) : undefined;
        title = title ?? "Pemberitahuan";
        message = message ?? (typeof rec.log === "string" ? rec.log : "Anda memiliki notifikasi baru.");
      } else {
        console.log("Record received but iswarning is not true; skipping push.");
        return new Response(JSON.stringify({
          skipped: true,
          reason: "iswarning not true"
        }), {
          headers: {
            "content-type": "application/json"
          }
        });
      }
    }
    // 2. Direct notifikasi_id lookup path
    if (body.notifikasi_id) {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/notifikasi?id=eq.${body.notifikasi_id}&select=id,user_id,log,iswarning,timestamp&limit=1`, {
        headers: commonHeaders
      });
      if (!r.ok) {
        return new Response(JSON.stringify({
          error: `Fetch notifikasi failed: ${await r.text()}`
        }), {
          status: 500,
          headers: {
            "content-type": "application/json"
          }
        });
      }
      const rows = await r.json();
      if (!rows.length) {
        return new Response(JSON.stringify({
          error: "Notifikasi not found"
        }), {
          status: 404,
          headers: {
            "content-type": "application/json"
          }
        });
      }
      const rec = rows[0];
      // You can optionally enforce iswarning here too:
      userId = userId ?? rec.user_id;
      title = title ?? "Pemberitahuan";
      message = message ?? rec.log ?? "Anda memiliki notifikasi baru.";
    }
    if (!userId || !title || !message) {
      console.log("Missing required fields after all resolution attempts", {
        userId,
        title,
        hasMessage: !!message
      });
      return new Response(JSON.stringify({
        error: "Missing required fields (user_id/title/body)"
      }), {
        status: 400,
        headers: {
          "content-type": "application/json"
        }
      });
    }
    // Fetch all device tokens for this user
    const tRes = await fetch(`${SUPABASE_URL}/rest/v1/device_tokens?user_id=eq.${userId}&select=token`, {
      headers: commonHeaders
    });
    if (!tRes.ok) {
      return new Response(JSON.stringify({
        error: `Fetch tokens failed: ${await tRes.text()}`
      }), {
        status: 500,
        headers: {
          "content-type": "application/json"
        }
      });
    }
    const tokens = await tRes.json();
    if (!tokens.length) {
      return new Response(JSON.stringify({
        sent: 0,
        results: []
      }), {
        headers: {
          "content-type": "application/json"
        }
      });
    }
    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
    const results = [];
    for (const { token } of tokens){
      const payload = {
        message: {
          token,
          notification: {
            title,
            body: message
          },
          data
        }
      };
      const res = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "content-type": "application/json"
        },
        body: JSON.stringify(payload)
      });
      const txt = await res.text();
      let parsed = txt;
      try {
        parsed = JSON.parse(txt);
      } catch  {}
      results.push({
        token,
        ok: res.ok,
        status: res.status,
        body: parsed
      });
    }
    console.log("Push summary", {
      userId,
      title,
      message: message?.slice(0, 60),
      sent: results.length
    });
    return new Response(JSON.stringify({
      sent: results.length,
      results
    }), {
      headers: {
        "content-type": "application/json"
      }
    });
  } catch (e) {
    return new Response(JSON.stringify({
      error: String(e)
    }), {
      status: 500,
      headers: {
        "content-type": "application/json"
      }
    });
  }
});
