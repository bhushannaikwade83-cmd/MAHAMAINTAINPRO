import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { servicesQuery, type Service } from "@/lib/admin-data";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { apiPost } from "@/lib/api";
import { toast } from "sonner";
import { Pencil, Check, X, Plus } from "lucide-react";

export const Route = createFileRoute("/_admin/services")({
  head: () => ({
    meta: [
      { title: "Services & Pricing — Maha Maintain Pro Admin" },
      { name: "description", content: "Edit service prices and add new services to the catalog." },
    ],
  }),
  component: ServicesPage,
});

function ServicesPage() {
  const qc = useQueryClient();
  const categories = useQuery(servicesQuery);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editPrice, setEditPrice] = useState("");
  const [addingToCategory, setAddingToCategory] = useState<string | null>(null);
  const [newService, setNewService] = useState({ name: "", price: "", duration: "1 hour", notes: "" });

  const updatePrice = useMutation({
    mutationFn: async ({ id, price }: { id: string; price: number }) => {
      await apiPost("admin-update-service.php", { id, price });
    },
    onSuccess: () => {
      toast.success("Price updated");
      setEditingId(null);
      qc.invalidateQueries({ queryKey: ["services"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const toggleActive = useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      await apiPost("admin-update-service.php", { id, is_active: is_active ? 1 : 0 });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["services"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const addService = useMutation({
    mutationFn: async (categoryId: string) => {
      if (!newService.name.trim()) throw new Error("Service name is required");
      await apiPost("admin-add-service.php", {
        category_id: categoryId,
        name: newService.name.trim(),
        price: Number(newService.price) || 0,
        duration: newService.duration,
        notes: newService.notes,
      });
    },
    onSuccess: () => {
      toast.success("Service added");
      setNewService({ name: "", price: "", duration: "1 hour", notes: "" });
      setAddingToCategory(null);
      qc.invalidateQueries({ queryKey: ["services"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  function startEdit(s: Service) {
    setEditingId(s.id);
    setEditPrice(String(s.price));
  }

  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">Services & Pricing</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Edit prices of existing services or add new ones to any category.
      </p>

      {categories.isLoading && <p className="mt-6 text-sm text-muted-foreground">Loading…</p>}

      <div className="mt-6 space-y-6">
        {categories.data?.map((cat) => (
          <section key={cat.id} className="overflow-hidden rounded-xl border border-border bg-card shadow-sm">
            <div className="flex items-center justify-between border-b border-border px-6 py-4">
              <h2 className="text-lg font-semibold text-card-foreground">{cat.name}</h2>
              <Button
                size="sm"
                variant="outline"
                onClick={() => setAddingToCategory(addingToCategory === cat.id ? null : cat.id)}
              >
                <Plus className="size-4" />
                Add Service
              </Button>
            </div>

            {addingToCategory === cat.id && (
              <div className="border-b border-border bg-muted/30 px-6 py-4">
                <div className="grid gap-3 sm:grid-cols-4">
                  <Input
                    placeholder="Service name"
                    value={newService.name}
                    onChange={(e) => setNewService((p) => ({ ...p, name: e.target.value }))}
                  />
                  <Input
                    type="number"
                    placeholder="Price (₹)"
                    value={newService.price}
                    onChange={(e) => setNewService((p) => ({ ...p, price: e.target.value }))}
                  />
                  <Input
                    placeholder="Duration (e.g. 45 min)"
                    value={newService.duration}
                    onChange={(e) => setNewService((p) => ({ ...p, duration: e.target.value }))}
                  />
                  <Button onClick={() => addService.mutate(cat.id)} disabled={addService.isPending}>
                    {addService.isPending ? "Adding…" : "Save"}
                  </Button>
                </div>
              </div>
            )}

            <table className="w-full text-sm">
              <thead className="border-b border-border bg-muted/50 text-left text-muted-foreground">
                <tr>
                  <th className="px-6 py-3 font-medium">Name</th>
                  <th className="px-6 py-3 font-medium">Price</th>
                  <th className="px-6 py-3 font-medium">Duration</th>
                  <th className="px-6 py-3 font-medium">Active</th>
                </tr>
              </thead>
              <tbody>
                {cat.services.length === 0 && (
                  <tr>
                    <td className="px-6 py-4 text-muted-foreground" colSpan={4}>
                      No services in this category yet.
                    </td>
                  </tr>
                )}
                {cat.services.map((s) => (
                  <tr key={s.id} className="border-b border-border last:border-0">
                    <td className="px-6 py-3 font-medium text-card-foreground">{s.name}</td>
                    <td className="px-6 py-3">
                      {editingId === s.id ? (
                        <div className="flex items-center gap-2">
                          <Input
                            type="number"
                            className="h-8 w-24"
                            value={editPrice}
                            onChange={(e) => setEditPrice(e.target.value)}
                            autoFocus
                          />
                          <button
                            className="text-green-600 hover:text-green-700"
                            onClick={() => updatePrice.mutate({ id: s.id, price: Number(editPrice) || 0 })}
                            disabled={updatePrice.isPending}
                          >
                            <Check className="size-4" />
                          </button>
                          <button className="text-muted-foreground hover:text-foreground" onClick={() => setEditingId(null)}>
                            <X className="size-4" />
                          </button>
                        </div>
                      ) : (
                        <button
                          className="flex items-center gap-2 text-card-foreground hover:text-primary"
                          onClick={() => startEdit(s)}
                        >
                          ₹{s.price}
                          <Pencil className="size-3.5 text-muted-foreground" />
                        </button>
                      )}
                    </td>
                    <td className="px-6 py-3 text-muted-foreground">{s.duration ?? "—"}</td>
                    <td className="px-6 py-3">
                      <Switch
                        checked={s.is_active}
                        onCheckedChange={(v) => toggleActive.mutate({ id: s.id, is_active: v })}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        ))}
      </div>
    </div>
  );
}
