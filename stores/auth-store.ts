import { create } from 'zustand';
import { AppUser } from '@/types/user';
import * as authService from '@/lib/firebase/auth';

interface AuthStore {
  user: AppUser | null;
  isLoading: boolean;
  error: string | null;
  setUser: (user: AppUser | null) => void;
  setIsLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  signUp: (email: string, password: string, name: string) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  getCurrentUser: () => Promise<void>;
}

export const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  isLoading: false,
  error: null,

  setUser: (user) => set({ user }),
  setIsLoading: (isLoading) => set({ isLoading }),
  setError: (error) => set({ error }),

  signUp: async (email, password, name) => {
    set({ isLoading: true, error: null });
    try {
      const user = await authService.signUpWithEmail(email, password, name);
      set({ user, isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Sign up failed', isLoading: false });
      throw error;
    }
  },

  signIn: async (email, password) => {
    set({ isLoading: true, error: null });
    try {
      const user = await authService.signInWithEmail(email, password);
      set({ user, isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Sign in failed', isLoading: false });
      throw error;
    }
  },

  logout: async () => {
    set({ isLoading: true, error: null });
    try {
      await authService.logOut();
      set({ user: null, isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Logout failed', isLoading: false });
      throw error;
    }
  },

  resetPassword: async (email) => {
    set({ isLoading: true, error: null });
    try {
      await authService.resetPassword(email);
      set({ isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Password reset failed', isLoading: false });
      throw error;
    }
  },

  getCurrentUser: async () => {
    set({ isLoading: true, error: null });
    try {
      const user = await authService.getCurrentUser();
      set({ user, isLoading: false });
    } catch (error: any) {
      set({ error: error.message || 'Failed to get current user', isLoading: false });
    }
  },
}));
