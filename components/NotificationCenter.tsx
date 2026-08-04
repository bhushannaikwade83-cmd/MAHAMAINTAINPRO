'use client';

import { useAppStore } from '@/stores/app-store';
import { X, AlertCircle, CheckCircle, Info, AlertTriangle } from 'lucide-react';

export function NotificationCenter() {
  const { notifications, removeNotification } = useAppStore();

  const getIcon = (type: string) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'error':
        return <AlertCircle className="w-5 h-5 text-red-500" />;
      case 'warning':
        return <AlertTriangle className="w-5 h-5 text-yellow-500" />;
      default:
        return <Info className="w-5 h-5 text-blue-500" />;
    }
  };

  const getBackgroundColor = (type: string) => {
    switch (type) {
      case 'success':
        return 'bg-green-50 dark:bg-green-900';
      case 'error':
        return 'bg-red-50 dark:bg-red-900';
      case 'warning':
        return 'bg-yellow-50 dark:bg-yellow-900';
      default:
        return 'bg-blue-50 dark:bg-blue-900';
    }
  };

  return (
    <div className="fixed bottom-0 right-0 p-6 space-y-3 max-w-sm z-50">
      {notifications.map((notification) => (
        <div
          key={notification.id}
          className={`${getBackgroundColor(notification.type)} rounded-lg shadow-lg p-4 flex items-start gap-3 animate-in slide-in-from-right`}
        >
          {getIcon(notification.type)}
          <div className="flex-1">
            <p className="text-sm font-medium text-gray-900 dark:text-white">{notification.message}</p>
          </div>
          <button onClick={() => removeNotification(notification.id)} className="text-gray-500 hover:text-gray-700">
            <X size={16} />
          </button>
        </div>
      ))}
    </div>
  );
}
