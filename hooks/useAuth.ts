import { useEffect, useState } from 'react';
import { useAuthStore } from '@/stores/auth-store';
import { getCurrentUser } from '@/lib/firebase/auth';

export function useAuth() {
  const { user, isLoading, error, setUser, setIsLoading } = useAuthStore();
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    setIsLoading(true);

    const checkAuth = async () => {
      try {
        const currentUser = await getCurrentUser();
        setUser(currentUser);
      } catch (error) {
        setUser(null);
      } finally {
        setIsLoading(false);
        setIsHydrated(true);
      }
    };

    checkAuth();
  }, [setUser, setIsLoading]);

  return { user, isLoading, error, isHydrated };
}
