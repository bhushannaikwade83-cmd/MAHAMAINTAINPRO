import { getToken, clearSession } from "./auth";

export const API_BASE = "https://digitrixmedia.com/mahamaintainpro/api";

async function request<T>(file: string, init?: RequestInit): Promise<T> {
  // Cache-bust: server sends max-age=86400, so a stale 500 can stick in disk cache
  const url = `${API_BASE}/${file}${file.includes("?") ? "&" : "?"}_ts=${Date.now()}`;
  const isPost = init?.method === "POST";
  const token = getToken();

  const res = await fetch(url, {
    cache: "no-store",
    mode: "cors",
    headers: {
      // Every admin-*.php endpoint requires this now (requireAdminRole) -
      // without it every single call in this app 401s.
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      // GET stays a "simple request" (no Content-Type header) so no preflight is needed
      ...(isPost ? { "Content-Type": "application/json" } : {}),
    },
    ...init,
  });

  if (res.status === 401) {
    // Token missing/expired/invalid - the backend is the source of truth
    // here, not a client-side expiry guess. Bounce back to login.
    clearSession();
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    }
    throw new Error("Session expired - please sign in again");
  }

  const text = await res.text();
  let json: any;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`Invalid response from ${file}: ${text.slice(0, 120)}`);
  }
  if (!res.ok || json?.success === false) {
    throw new Error(json?.message || json?.error || `Request to ${file} failed`);
  }
  return json as T;
}

export const apiGet = <T,>(file: string) => request<T>(file);
export const apiPost = <T,>(file: string, body: unknown) =>
  request<T>(file, { method: "POST", body: JSON.stringify(body) });

/** Uploads an image file (multipart) to admin-upload-image.php, returns its stored path. */
export async function apiUploadImage(file: File): Promise<string> {
  const token = getToken();
  const formData = new FormData();
  formData.append("image", file);

  const res = await fetch(`${API_BASE}/admin-upload-image.php`, {
    method: "POST",
    mode: "cors",
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: formData,
  });

  if (res.status === 401) {
    clearSession();
    if (typeof window !== "undefined") window.location.href = "/login";
    throw new Error("Session expired - please sign in again");
  }

  const json = await res.json();
  if (!res.ok || json?.success === false) {
    throw new Error(json?.message || json?.error || "Image upload failed");
  }
  // admin-upload-image.php only returns the bare filename under
  // assets/services/ - the Flutter app's Image.network() calls expect a
  // full URL (see service_category_screen.dart), so build that here once
  // rather than in every caller.
  return `https://digitrixmedia.com/mahamaintainpro/assets/services/${json.image_path}`;
}

/** Unauthenticated request - only for admin-login.php itself. */
export async function apiPostPublic<T>(file: string, body: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}/${file}`, {
    method: "POST",
    cache: "no-store",
    mode: "cors",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json: any;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`Invalid response from ${file}: ${text.slice(0, 120)}`);
  }
  if (!res.ok || json?.success === false) {
    throw new Error(json?.message || `Request to ${file} failed`);
  }
  return json as T;
}
