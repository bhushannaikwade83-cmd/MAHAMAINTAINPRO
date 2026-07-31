'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Simple hardcoded auth (replace with real API later)
    if (email === 'admin@maha.com' && password === 'admin123') {
      localStorage.setItem('adminAuth', 'true');
      router.push('/dashboard');
    } else {
      setError('❌ Invalid credentials. Use admin@maha.com / admin123');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-orange-50 to-teal-50">
      <div className="w-full max-w-md">
        <div className="bg-white rounded-lg shadow-xl p-8">
          {/* Logo & Title */}
          <div className="text-center mb-8">
            <div className="text-5xl mb-4">🏢</div>
            <h1 className="text-3xl font-bold text-gray-900">
              MahaMaintain <span className="text-amber-500">Pro</span>
            </h1>
            <p className="text-gray-500 mt-2 text-sm">Admin Panel</p>
          </div>

          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@maha.com"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                disabled={loading}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                disabled={loading}
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-orange-500 hover:bg-orange-600 disabled:bg-orange-400 text-white font-semibold py-2 rounded-lg transition"
            >
              {loading ? 'Logging in...' : 'Login'}
            </button>
          </form>

          {/* Demo Credentials */}
          <div className="mt-6 pt-6 border-t border-gray-200">
            <p className="text-xs text-gray-500 text-center mb-2">Demo Credentials:</p>
            <div className="bg-gray-50 p-3 rounded text-xs text-gray-600">
              <p>📧 admin@maha.com</p>
              <p>🔐 admin123</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
