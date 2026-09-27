import { createFileRoute, Outlet, Link, redirect, useNavigate } from "@tanstack/react-router";
import { LayoutDashboard, Building2, Users, Wrench, Image, Package, Inbox, LogOut } from "lucide-react";
import { isAuthenticated, getAdminUser, clearSession } from "@/lib/auth";

export const Route = createFileRoute("/_admin")({
  beforeLoad: () => {
    // Every page under here needs a valid admin session - the backend
    // enforces this too (requireAdminRole), this just avoids a
    // flash-of-broken-UI before every API call 401s.
    if (!isAuthenticated()) {
      throw redirect({ to: "/login" });
    }
  },
  component: AdminShell,
});

const nav = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/societies", label: "Add Societies", icon: Building2 },
  { to: "/members", label: "Members", icon: Users },
  { to: "/services", label: "Services", icon: Wrench },
  { to: "/packages", label: "Packages", icon: Package },
  { to: "/banners", label: "Banners & Ads", icon: Image },
  { to: "/inquiries", label: "Inquiries", icon: Inbox },
] as const;

function AdminShell() {
  const navigate = useNavigate();
  const user = getAdminUser();

  function handleLogout() {
    clearSession();
    navigate({ to: "/login" });
  }

  return (
    <div className="flex min-h-screen bg-background">
      <aside className="hidden w-64 shrink-0 flex-col border-r border-sidebar-border bg-sidebar p-4 md:flex">
        <div className="mb-8 px-2">
          <p className="text-lg font-semibold tracking-tight text-sidebar-foreground">
            Maha Maintain Pro
          </p>
          <p className="text-xs text-muted-foreground">Admin Panel</p>
        </div>
        <nav className="flex flex-1 flex-col gap-1">
          {nav.map(({ to, label, icon: Icon }) => (
            <Link
              key={to}
              to={to}
              className="flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-sidebar-foreground/80 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
              activeProps={{
                className:
                  "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium bg-sidebar-primary text-sidebar-primary-foreground",
              }}
            >
              <Icon className="size-4" />
              {label}
            </Link>
          ))}
        </nav>
        <div className="mt-auto border-t border-sidebar-border pt-3">
          {user && (
            <p className="px-2 pb-2 text-xs text-muted-foreground truncate">
              Signed in as <span className="font-medium text-sidebar-foreground">{user.username}</span>
            </p>
          )}
          <button
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-sidebar-foreground/80 transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
          >
            <LogOut className="size-4" />
            Sign Out
          </button>
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center gap-1 overflow-x-auto border-b border-border bg-card px-4 py-2 md:hidden">
          {nav.map(({ to, label, icon: Icon }) => (
            <Link
              key={to}
              to={to}
              className="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-muted-foreground"
              activeProps={{
                className:
                  "flex items-center gap-2 rounded-md px-3 py-2 text-sm bg-primary text-primary-foreground",
              }}
            >
              <Icon className="size-4" />
              {label}
            </Link>
          ))}
        </header>
        <main className="flex-1 p-6 md:p-10">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
