'use client';

import { useAuth } from '@/hooks/useAuth';
import { useAuthStore } from '@/stores/auth-store';
import { useRouter } from 'next/navigation';
import { Bell, LogOut } from 'lucide-react';
import { Button } from './Button';

export function Header() {
  const { user } = useAuth();
  const { logout } = useAuthStore();
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await logout();
      router.push('/auth/login');
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  return (
    <header className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800 px-6 py-4 flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Welcome back, {user?.name}</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">Have a great day!</p>
      </div>

      <div className="flex items-center gap-4">
        <button className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg relative">
          <Bell size={20} className="text-gray-600 dark:text-gray-400" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        <Button variant="outline" size="sm" onClick={handleLogout} className="gap-2">
          <LogOut size={16} />
          Logout
        </Button>
      </div>
    </header>
  );
}
