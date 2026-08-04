import { UserRole } from './common';

export interface AppUser {
  uid: string;
  name: string;
  email?: string;
  phone?: string;
  role: UserRole;
  isActive: boolean;
  photoUrl?: string;
  createdAt: Date;
  updatedAt?: Date;
}

export interface AuthState {
  user: AppUser | null;
  isLoading: boolean;
  error: string | null;
}
