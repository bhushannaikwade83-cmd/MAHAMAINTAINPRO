'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useAuthStore } from '@/stores/auth-store';
import { useAppStore } from '@/stores/app-store';
import { Input } from '@/components/Input';
import { Button } from '@/components/Button';
import { Card, CardBody, CardHeader } from '@/components/Card';
import { Mail } from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const { resetPassword, isLoading } = useAuthStore();
  const { addNotification } = useAppStore();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!email || !email.includes('@')) {
      setError('Please enter a valid email address');
      return;
    }

    try {
      await resetPassword(email);
      addNotification({ type: 'success', message: 'Password reset email sent!' });
      setSubmitted(true);
    } catch (error: any) {
      addNotification({
        type: 'error',
        message: error.message || 'Failed to send reset email',
      });
    }
  };

  if (submitted) {
    return (
      <>
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-orange-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Mail className="text-white" size={32} />
          </div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Check Your Email</h1>
        </div>

        <Card className="shadow-xl">
          <CardBody className="text-center space-y-6">
            <p className="text-gray-600 dark:text-gray-400">
              We've sent a password reset link to <strong>{email}</strong>
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Check your email and follow the link to reset your password.
            </p>
            <Link href="/auth/login" className="text-orange-600 hover:text-orange-700 font-medium">
              Back to login
            </Link>
          </CardBody>
        </Card>
      </>
    );
  }

  return (
    <>
      <div className="text-center mb-8">
        <div className="w-16 h-16 bg-orange-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <span className="text-white text-2xl font-bold">M</span>
        </div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Reset Password</h1>
        <p className="text-gray-600 dark:text-gray-400">Enter your email to receive reset instructions</p>
      </div>

      <Card className="shadow-xl">
        <CardBody>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              label="Email Address"
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                setError('');
              }}
              error={error}
              placeholder="your@email.com"
            />

            <Button type="submit" className="w-full" isLoading={isLoading}>
              Send Reset Link
            </Button>
          </form>

          <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700 text-center">
            <Link href="/auth/login" className="text-sm text-orange-600 hover:text-orange-700">
              Back to login
            </Link>
          </div>
        </CardBody>
      </Card>
    </>
  );
}
