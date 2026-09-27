import { createFileRoute } from "@tanstack/react-router";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { useRef, useState } from "react";
import { bannersQuery, type Banner } from "@/lib/admin-data";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { apiPost, apiUploadImage } from "@/lib/api";
import { toast } from "sonner";
import { Trash2, ImagePlus } from "lucide-react";

export const Route = createFileRoute("/_admin/banners")({
  head: () => ({
    meta: [
      { title: "Banners & Ads — Maha Maintain Pro Admin" },
      { name: "description", content: "Manage the home screen banner/offer carousel." },
    ],
  }),
  component: BannersPage,
});

function BannersPage() {
  const qc = useQueryClient();
  const banners = useQuery(bannersQuery);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [form, setForm] = useState({ title: "", image_path: "", link_value: "", sort_order: "0" });

  const addBanner = useMutation({
    mutationFn: async () => {
      if (!form.title.trim()) throw new Error("Title is required");
      if (!form.image_path) throw new Error("Upload a banner image first");
      await apiPost("admin-add-banner.php", {
        title: form.title.trim(),
        image_path: form.image_path,
        link_type: form.link_value ? "url" : null,
        link_value: form.link_value || null,
        sort_order: Number(form.sort_order) || 0,
        is_active: 1,
      });
    },
    onSuccess: () => {
      toast.success("Banner added");
      setForm({ title: "", image_path: "", link_value: "", sort_order: "0" });
      qc.invalidateQueries({ queryKey: ["banners"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const toggleActive = useMutation({
    mutationFn: async ({ id, is_active }: { id: string; is_active: boolean }) => {
      await apiPost("admin-update-banner.php", { id, is_active: is_active ? 1 : 0 });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["banners"] }),
    onError: (e: Error) => toast.error(e.message),
  });

  const deleteBanner = useMutation({
    mutationFn: async (id: string) => {
      await apiPost("admin-delete-banner.php", { id });
    },
    onSuccess: () => {
      toast.success("Banner deleted");
      qc.invalidateQueries({ queryKey: ["banners"] });
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

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="text-2xl font-semibold tracking-tight text-foreground">Banners & Ads</h1>
      <p className="mt-1 text-sm text-muted-foreground">
        The images shown in the home screen offers carousel.
      </p>

      <section className="mt-6 rounded-xl border border-border bg-card p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-card-foreground mb-4">Add New Banner</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-1.5">
            <Label>Title</Label>
            <Input
              value={form.title}
              onChange={(e) => setForm((p) => ({ ...p, title: e.target.value }))}
              placeholder="e.g. Diwali Offer - 20% Off"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Link (optional)</Label>
            <Input
              value={form.link_value}
              onChange={(e) => setForm((p) => ({ ...p, link_value: e.target.value }))}
              placeholder="Category name or URL"
            />
          </div>
          <div className="space-y-1.5">
            <Label>Sort Order</Label>
            <Input
              type="number"
              value={form.sort_order}
              onChange={(e) => setForm((p) => ({ ...p, sort_order: e.target.value }))}
            />
          </div>
          <div className="space-y-1.5">
            <Label>Banner Image</Label>
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

        {form.image_path && (
          <img src={form.image_path} alt="Preview" className="mt-4 h-32 rounded-lg border border-border object-cover" />
        )}

        <Button className="mt-4" onClick={() => addBanner.mutate()} disabled={addBanner.isPending}>
          {addBanner.isPending ? "Saving…" : "Add Banner"}
        </Button>
      </section>

      <section className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {banners.isLoading && <p className="text-sm text-muted-foreground">Loading…</p>}
        {!banners.isLoading && banners.data?.length === 0 && (
          <p className="text-sm text-muted-foreground">No banners yet.</p>
        )}
        {banners.data?.map((b: Banner) => (
          <div key={b.id} className="overflow-hidden rounded-xl border border-border bg-card shadow-sm">
            <img src={b.image_path} alt={b.title} className="h-32 w-full object-cover" />
            <div className="p-4">
              <p className="font-medium text-card-foreground truncate">{b.title}</p>
              {b.link_value && <p className="mt-0.5 text-xs text-muted-foreground truncate">↳ {b.link_value}</p>}
              <div className="mt-3 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Switch
                    checked={b.is_active}
                    onCheckedChange={(v) => toggleActive.mutate({ id: b.id, is_active: v })}
                  />
                  <span className="text-xs text-muted-foreground">{b.is_active ? "Active" : "Hidden"}</span>
                </div>
                <button
                  className="text-destructive hover:text-destructive/80"
                  onClick={() => deleteBanner.mutate(b.id)}
                >
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
