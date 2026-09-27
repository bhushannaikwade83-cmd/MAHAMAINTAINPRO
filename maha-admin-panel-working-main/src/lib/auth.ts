const TOKEN_KEY = "admin_token";
const USER_KEY = "admin_user";

export type AdminUser = {
  username: string;
  role: string;
};

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function getAdminUser(): AdminUser | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminUser;
  } catch {
    return null;
  }
}

export function setSession(token: string, user: AdminUser) {
  window.localStorage.setItem(TOKEN_KEY, token);
  window.localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearSession() {
  window.localStorage.removeItem(TOKEN_KEY);
  window.localStorage.removeItem(USER_KEY);
}

export function isAuthenticated(): boolean {
  return !!getToken();
}
