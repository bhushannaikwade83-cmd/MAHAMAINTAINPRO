import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { secretariesQuery } from "@/lib/admin-data";
import { Button } from "@/components/ui/button";
import { apiPost } from "@/lib/api";
import { toast } from "sonner";

export const Route = createFileRoute("/_admin/inquiries")({
  head: () => ({
    meta: [
      { title: "Inquiries — Maha Maintain Pro Admin" },
      {
        name: "description",
        content: "Society secretary registration requests awaiting approval.",
      },
    ],
  }),
  component: InquiriesPage,
});

function statusBadge(status: string) {
  const map: Record<string, string> = {
    pending: "bg-amber-100 text-amber-800",
    approved: "bg-green-100 text-green-800",
    rejected: "bg-red-100 text-red-800",
  };
  return map[status] ?? "bg-muted text-muted-foreground";
}

function InquiriesPage() {
  const qc = useQueryClient();
  const secretaries = useQuery(secretariesQuery);

  const updateStatus = useMutation({
    mutationFn: async ({ id, approval_status }: { id: string; approval_status: "approved" | "rejected" }) => {
      await apiPost("admin-update-secretary-status.php", { id, approval_status });
    },
    onSuccess: (_data, vars) => {
      toast.success(`Registration ${vars.approval_status}`);
      qc.invalidateQueries({ queryKey: ["secretaries"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const pending = secretaries.data?.filter((s) => s.approval_status === "pending") ?? [];
  const others = secretaries.data?.filter((s) => s.approval_status !== "pending") ?? [];

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">Inquiries</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Society secretary registration requests - the phone number they submitted to register their society.
      </p>

      <section className="mt-6">
        <h2 className="text-lg font-semibold text-foreground mb-3">
          Pending ({pending.length})
        </h2>
        <div className="overflow-hidden rounded-xl border border-border bg-card shadow-sm">
          <table className="w-full text-sm">
            <thead className="border-b border-border bg-muted/50 text-left text-muted-foreground">
              <tr>
                <th className="px-6 py-3 font-medium">Name</th>
                <th className="px-6 py-3 font-medium">Phone</th>
                <th className="px-6 py-3 font-medium">Society</th>
                <th className="px-6 py-3 font-medium">Requested</th>
                <th className="px-6 py-3 font-medium">Action</th>
              </tr>
            </thead>
            <tbody>
              {secretaries.isLoading && (
                <tr>
                  <td className="px-6 py-6 text-muted-foreground" colSpan={5}>Loading…</td>
                </tr>
              )}
              {!secretaries.isLoading && pending.length === 0 && (
                <tr>
                  <td className="px-6 py-6 text-muted-foreground" colSpan={5}>No pending inquiries.</td>
                </tr>
              )}
              {pending.map((s) => (
                <tr key={s.id} className="border-b border-border last:border-0">
                  <td className="px-6 py-3 font-medium text-card-foreground">{s.name}</td>
                  <td className="px-6 py-3 text-muted-foreground">{s.phone}</td>
                  <td className="px-6 py-3 text-muted-foreground">{s.society_name ?? "—"}</td>
                  <td className="px-6 py-3 text-muted-foreground">{new Date(s.created_at).toLocaleDateString()}</td>
                  <td className="px-6 py-3">
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        onClick={() => updateStatus.mutate({ id: s.id, approval_status: "approved" })}
                        disabled={updateStatus.isPending}
                      >
                        Approve
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => updateStatus.mutate({ id: s.id, approval_status: "rejected" })}
                        disabled={updateStatus.isPending}
                      >
                        Reject
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="mt-8">
        <h2 className="text-lg font-semibold text-foreground mb-3">History</h2>
        <div className="overflow-hidden rounded-xl border border-border bg-card shadow-sm">
          <table className="w-full text-sm">
            <thead className="border-b border-border bg-muted/50 text-left text-muted-foreground">
              <tr>
                <th className="px-6 py-3 font-medium">Name</th>
                <th className="px-6 py-3 font-medium">Phone</th>
                <th className="px-6 py-3 font-medium">Society</th>
                <th className="px-6 py-3 font-medium">Status</th>
              </tr>
            </thead>
            <tbody>
              {others.length === 0 && (
                <tr>
                  <td className="px-6 py-6 text-muted-foreground" colSpan={4}>Nothing here yet.</td>
                </tr>
              )}
              {others.map((s) => (
                <tr key={s.id} className="border-b border-border last:border-0">
                  <td className="px-6 py-3 font-medium text-card-foreground">{s.name}</td>
                  <td className="px-6 py-3 text-muted-foreground">{s.phone}</td>
                  <td className="px-6 py-3 text-muted-foreground">{s.society_name ?? "—"}</td>
                  <td className="px-6 py-3">
                    <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${statusBadge(s.approval_status)}`}>
                      {s.approval_status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
