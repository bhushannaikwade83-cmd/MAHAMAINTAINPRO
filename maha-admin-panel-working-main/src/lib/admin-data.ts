import { queryOptions } from "@tanstack/react-query";
import { apiGet } from "@/lib/api";

export type Society = {
  id: string;
  name: string;
  address: string | null;
  city: string | null;
  postal_code: string | null;
  created_at: string;
};

export type Member = {
  id: string;
  society_id: string | null;
  secretary_name: string;
  phone: string | null;
  is_committee: boolean;
  is_enabled: boolean;
  designation: string | null;
  approval_status: string;
  created_at: string;
};

type RawSociety = Record<string, unknown>;
type RawMember = Record<string, unknown>;

const str = (v: unknown) => (v === null || v === undefined ? null : String(v));
const bool = (v: unknown) => v === 1 || v === "1" || v === true;

export const societiesQuery = queryOptions({
  queryKey: ["societies"],
  queryFn: async (): Promise<Society[]> => {
    const json = await apiGet<{ societies?: RawSociety[] }>("admin-get-societies.php");
    return (json.societies ?? []).map((s) => ({
      id: String(s['id']),
      name: String(s['name'] ?? ""),
      address: str(s['address']),
      city: str(s['city']),
      postal_code: str(s['postal_code']),
      created_at: String(s['created_at'] ?? ""),
    }));
  },
});

export const membersQuery = queryOptions({
  queryKey: ["members"],
  queryFn: async (): Promise<Member[]> => {
    const json = await apiGet<{ members?: RawMember[] }>("admin-get-members.php");
    return (json.members ?? []).map((m) => ({
      id: String(m['id']),
      society_id: str(m['society_id']),
      secretary_name: String(m['secretary_name'] ?? ""),
      phone: str(m['phone']),
      is_committee: bool(m['is_committee']),
      is_enabled: bool(m['is_enabled']),
      designation: str(m['designation']),
      approval_status: String(m['approval_status'] ?? "pending"),
      created_at: String(m['created_at'] ?? ""),
    }));
  },
});

// --- Services (with categories, for price editing) ---

export type ServiceCategory = {
  id: string;
  name: string;
  color: string | null;
  description: string | null;
  image_path: string | null;
  services: Service[];
};

export type Service = {
  id: string;
  name: string;
  price: number;
  duration: string | null;
  rating: number | null;
  notes: string | null;
  image_path: string | null;
  is_active: boolean;
};

export const servicesQuery = queryOptions({
  queryKey: ["services"],
  queryFn: async (): Promise<ServiceCategory[]> => {
    const json = await apiGet<{ categories?: Record<string, unknown>[] }>("admin-get-services.php");
    return (json.categories ?? []).map((c) => ({
      id: String(c['id']),
      name: String(c['name'] ?? ""),
      color: str(c['color']),
      description: str(c['description']),
      image_path: str(c['image_path']),
      services: ((c['services'] as Record<string, unknown>[]) ?? []).map((s) => ({
        id: String(s['id']),
        name: String(s['name'] ?? ""),
        price: Number(s['price'] ?? 0),
        duration: str(s['duration']),
        rating: s['rating'] !== null && s['rating'] !== undefined ? Number(s['rating']) : null,
        notes: str(s['notes']),
        image_path: str(s['image_path']),
        is_active: bool(s['is_active']),
      })),
    }));
  },
});

// --- Banners ---

export type Banner = {
  id: string;
  title: string;
  image_path: string;
  link_type: string | null;
  link_value: string | null;
  sort_order: number;
  is_active: boolean;
};

export const bannersQuery = queryOptions({
  queryKey: ["banners"],
  queryFn: async (): Promise<Banner[]> => {
    const json = await apiGet<{ banners?: Record<string, unknown>[] }>("admin-get-banners.php");
    return (json.banners ?? []).map((b) => ({
      id: String(b['id']),
      title: String(b['title'] ?? ""),
      image_path: String(b['image_path'] ?? ""),
      link_type: str(b['link_type']),
      link_value: str(b['link_value']),
      sort_order: Number(b['sort_order'] ?? 0),
      is_active: bool(b['is_active']),
    }));
  },
});

// --- Packages ---

export type ServicePackage = {
  id: string;
  name: string;
  description: string | null;
  image_path: string | null;
  price: number;
  is_active: boolean;
  services: { service_id: string; service_name: string }[];
};

export const packagesQuery = queryOptions({
  queryKey: ["packages"],
  queryFn: async (): Promise<ServicePackage[]> => {
    const json = await apiGet<{ packages?: Record<string, unknown>[] }>("admin-get-packages.php");
    return (json.packages ?? []).map((p) => ({
      id: String(p['id']),
      name: String(p['name'] ?? ""),
      description: str(p['description']),
      image_path: str(p['image_path']),
      price: Number(p['price'] ?? 0),
      is_active: bool(p['is_active']),
      services: ((p['services'] as Record<string, unknown>[]) ?? []).map((s) => ({
        service_id: String(s['service_id']),
        service_name: String(s['service_name'] ?? ""),
      })),
    }));
  },
});

// --- Secretary inquiries ---

export type SecretaryInquiry = {
  id: string;
  secretary_id: string;
  society_id: string | null;
  society_name: string | null;
  name: string;
  phone: string;
  status: string;
  approval_status: string;
  created_at: string;
};

export const secretariesQuery = queryOptions({
  queryKey: ["secretaries"],
  queryFn: async (): Promise<SecretaryInquiry[]> => {
    const json = await apiGet<{ secretaries?: Record<string, unknown>[] }>("admin-get-secretaries.php");
    return (json.secretaries ?? []).map((s) => ({
      id: String(s['id']),
      secretary_id: String(s['secretary_id'] ?? ""),
      society_id: str(s['society_id']),
      society_name: str(s['society_name']),
      name: String(s['name'] ?? ""),
      phone: String(s['phone'] ?? ""),
      status: String(s['status'] ?? ""),
      approval_status: String(s['approval_status'] ?? "pending"),
      created_at: String(s['created_at'] ?? ""),
    }));
  },
});
