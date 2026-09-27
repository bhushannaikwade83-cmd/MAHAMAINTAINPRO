import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { useRef, useState } from "react";
import { packagesQuery, servicesQuery, type ServicePackage } from "@/lib/admin-data";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Checkbox } from "@/components/ui/checkbox";
import { apiPost, apiUploadImage } from "@/lib/api";
import { toast } from "sonner";
import { Trash2, ImagePlus } from "lucide-react";

export const Route = createFileRoute("/_admin/packages")({
  head: () => ({
    meta: [
      { title: "Packages — Maha Maintain Pro Admin" },
      { name: "description", content: "Bundle services together into discounted packages." },
    ],
  }),
  component: PackagesPage,
});

function PackagesPage() {
  const qc = useQueryClient();
  const packages = useQuery(packagesQuery);
  const categories = useQuery(servicesQuery);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [form, setForm] = useState({ name: "", description: "", price: "", image_path: "" });
  const [selectedServiceIds, setSelectedServiceIds] = useState<string[]>([]);

  const allServices = (categories.data ?? []).flatMap((c) => c.services.map((s) => ({ ...s, categoryName: c.name })));

  const addPackage = useMutation({
    mutationFn: async () => {
      if (!form.name.trim()) throw new Error("Package name is required");
      if (!form.price) throw new Error("Price is required");
      if (selectedServiceIds.length === 0) throw new Error("Select at least one service to include");
      await apiPost("admin-add-package.php", {
        name: form.name.trim(),
        description: form.description || null,
        image_path: form.image_path || null,
        price: Number(form.price),
        service_ids: selectedServiceIds,
        is_active: 1,
      });
    },
    onSuccess: () => {
      toast.success("Package added");
      setForm({ name: "", description: "", price: "", image_path: "" });
      setSelectedServiceIds([]);
      qc.invalidateQueries({ queryKey: ["packages"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const toggleActive = useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      await apiPost("admin-update-package.php", { id, is_active: is_active ? 1 : 0 });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["packages"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const deletePackage = useMutation({
    mutationFn: async (id: string) => {
      await apiPost("admin-delete-package.php", { id });
    },
    onSuccess: () => {
      toast.success("Package deleted");
      qc.invalidateQueries({ queryKey: ["packages"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  async function handleFileSelected(file: File) {
    setUploading(true);
    try {
      const url = await apiUploadImage(file);
      setForm((p) => ({ ...p, image_path: url }));
      toast.success("Image uploaded");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  }

  function toggleService(id: string) {
    setSelectedServiceIds((p) => (p.includes(id) ? p.filter((x) => x !== id) : [...p, id]));
  }

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">Packages</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Bundle multiple services into a single package with its own price.
      </p>

      <section className="mt-6 rounded-xl border border-border bg-card p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-card-foreground mb-4">Add New Package</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label>Package Name</Label>
            <Input
              value={form.name}
              onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
              placeholder="e.g. Home Deep Clean Combo"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Package Price (₹)</Label>
            <Input
              type="number"
              value={form.price}
              onChange={(e) => setForm((p) => ({ ...p, price: e.target.value }))}
              placeholder="e.g. 2499"
            />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <Label>Description (optional)</Label>
            <Input
              value={form.description}
              onChange={(e) => setForm((p) => ({ ...p, description: e.target.value }))}
              placeholder="What's special about this package"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Package Image (optional)</Label>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFileSelected(file);
              }}
            />
            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={() => fileInputRef.current?.click()}
              disabled={uploading}
            >
              <ImagePlus className="size-4" />
              {uploading ? "Uploading…" : form.image_path ? "Change Image" : "Upload Image"}
            </Button>
          </div>
        </div>

        <div className="mt-5">
          <Label>Included Services</Label>
          <div className="mt-2 max-h-56 space-y-1.5 overflow-y-auto rounded-md border border-border p-3">
            {allServices.length === 0 && (
              <p className="text-sm text-muted-foreground">No services in the catalog yet.</p>
            )}
            {allServices.map((s) => (
              <label key={s.id} className="flex items-center gap-2 py-1 text-sm">
                <Checkbox checked={selectedServiceIds.includes(s.id)} onCheckedChange={() => toggleService(s.id)} />
                <span className="text-card-foreground">{s.name}</span>
                <span className="text-xs text-muted-foreground">({s.categoryName} · ₹{s.price})</span>
              </label>
            ))}
          </div>
        </div>

        <Button className="mt-4" onClick={() => addPackage.mutate()} disabled={addPackage.isPending}>
          {addPackage.isPending ? "Saving…" : "Add Package"}
        </Button>
      </section>

      <section className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {packages.isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
        {!packages.isLoading && packages.data?.length === 0 && (
          <p className="text-sm text-muted-foreground">No packages yet.</p>
        )}
        {packages.data?.map((p: ServicePackage) => (
          <div key={p.id} className="overflow-hidden rounded-xl border border-border bg-card shadow-sm">
            {p.image_path && <img src={p.image_path} alt={p.name} className="h-32 w-full object-cover" />}
            <div className="p-4">
              <div className="flex items-center justify-between">
                <p className="font-medium text-card-foreground">{p.name}</p>
                <span className="font-semibold text-primary">₹{p.price}</span>
              </div>
              {p.description && <p className="mt-1 text-xs text-muted-foreground">{p.description}</p>}
              <p className="mt-2 text-xs text-muted-foreground">
                {p.services.length} service{p.services.length === 1 ? "" : "s"}: {p.services.map((s) => s.service_name).join(", ")}
              </p>
              <div className="mt-3 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Switch
                    checked={p.is_active}
                    onCheckedChange={(v) => toggleActive.mutate({ id: p.id, is_active: v })}
                  />
                  <span className="text-xs text-muted-foreground">{p.is_active ? "Active" : "Hidden"}</span>
                </div>
                <button className="text-destructive hover:text-destructive/80" onClick={() => deletePackage.mutate(p.id)}>
                  <Trash2 className="size-4" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </section>
    </div>
  );
}
