import { createFileRoute, useNavigate, redirect } from "@tanstack/react-router";
import { useState } from "react";
import { apiPostPublic } from "@/lib/api";
import { setSession, isAuthenticated } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { toast } from "sonner";
import { ShieldCheck } from "lucide-react";

export const Route = createFileRoute("/login")({
  beforeLoad: () => {
    // Already signed in - no need to show the login form again.
    if (isAuthenticated()) {
      throw redirect({ to: "/dashboard" });
    }
  },
  head: () => ({
    meta: [{ title: "Sign In — Maha Maintain Pro Admin" }],
  }),
  component: LoginPage,
});

function LoginPage() {
  const navigate = useNavigate();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!username.trim() || !password) {
      toast.error("Enter both username and password.");
      return;
    }

    setLoading(true);
    try {
      const data = await apiPostPublic<{
        success: boolean;
        token: string;
        username: string;
        role: string;
      }>("admin-login.php", { username: username.trim(), password });

      setSession(data.token, { username: data.username, role: data.role });
      toast.success(`Welcome back, ${data.username}`);
      navigate({ to: "/dashboard" });
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="text-center">
          <div className="mx-auto mb-2 flex size-11 items-center justify-center rounded-full bg-primary/10">
            <ShieldCheck className="size-5 text-primary" />
          </div>
          <CardTitle className="text-xl">Maha Maintain Pro</CardTitle>
          <CardDescription>Sign in to the admin panel</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                autoComplete="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="superadmin"
                disabled={loading}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                disabled={loading}
              />
            </div>
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Signing in…" : "Sign In"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
