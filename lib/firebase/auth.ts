import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendPasswordResetEmail,
  UserCredential,
  setPersistence,
  browserLocalPersistence,
} from 'firebase/auth';
import { doc, getDoc, setDoc, Timestamp } from 'firebase/firestore';
import { auth, db } from './config';
import { AppUser } from '@/types/user';
import { UserRole } from '@/types/common';

export async function signUpWithEmail(
  email: string,
  password: string,
  name: string
): Promise<AppUser> {
  try {
    // Demo mode - use localStorage
    const userData: AppUser = {
      uid: Math.random().toString(36).substring(7),
      email,
      name,
      role: UserRole.Customer,
      isActive: true,
      createdAt: new Date(),
    };

    if (typeof window !== 'undefined') {
      localStorage.setItem('demo_user', JSON.stringify(userData));
      localStorage.setItem('demo_auth_token', 'demo_token_' + Date.now());
    }

    return userData;
  } catch (error) {
    console.error('Sign up error:', error);
    throw error;
  }
}

export async function signInWithEmail(email: string, password: string): Promise<AppUser> {
  try {
    // Demo mode - accept any email/password
    const userData: AppUser = {
      uid: Math.random().toString(36).substring(7),
      email,
      name: email.split('@')[0],
      role: UserRole.SalesManager,
      isActive: true,
      createdAt: new Date(),
    };

    if (typeof window !== 'undefined') {
      localStorage.setItem('demo_user', JSON.stringify(userData));
      localStorage.setItem('demo_auth_token', 'demo_token_' + Date.now());
    }

    return userData;
  } catch (error) {
    console.error('Sign in error:', error);
    throw error;
  }
}

export async function logOut(): Promise<void> {
  try {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('demo_user');
      localStorage.removeItem('demo_auth_token');
    }
  } catch (error) {
    console.error('Sign out error:', error);
    throw error;
  }
}

export async function resetPassword(email: string): Promise<void> {
  try {
    // Demo mode - just log it
    console.log('Password reset requested for:', email);
  } catch (error) {
    console.error('Password reset error:', error);
    throw error;
  }
}

export async function getCurrentUser(): Promise<AppUser | null> {
  try {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('demo_auth_token');
      const userData = localStorage.getItem('demo_user');

      if (token && userData) {
        return JSON.parse(userData);
      }
    }
    return null;
  } catch (error) {
    console.error('Get current user error:', error);
    return null;
  }
}
