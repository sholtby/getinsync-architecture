# Multi-Tenant Phase 2: Authentication & Signup

## Overview

Implement user authentication with automatic Namespace and Workspace creation on signup.

**Prerequisites:** Phase 1 (schema) must be complete.

**Goal:** When a user signs up, automatically create their Namespace, default Workspace, and User record.

---

## Current State

- Supabase Auth is available but not fully integrated
- No signup/login UI
- No user context in the app

---

## Authentication Flow

### New User Signup

```
1. User enters email + password (or uses OAuth)
2. Supabase creates auth.users record
3. Database trigger fires
4. Trigger creates:
   - Namespace (named from email domain or user input)
   - Default Workspace ("General")
   - User record (linked to auth.users)
   - WorkspaceUser record (admin role)
5. User redirected to dashboard
```

### Existing User Login

```
1. User enters email + password
2. Supabase validates credentials
3. App fetches user's namespace and workspaces
4. User redirected to last workspace or default
```

---

## Database Trigger for Signup

Create a trigger that fires when a new user is created in `auth.users`:

```sql
-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_namespace_id UUID;
  new_workspace_id UUID;
  user_email TEXT;
  org_name TEXT;
  org_slug TEXT;
BEGIN
  user_email := NEW.email;
  
  -- Generate org name from email domain (e.g., "acme.com" -> "Acme")
  org_name := INITCAP(SPLIT_PART(SPLIT_PART(user_email, '@', 2), '.', 1));
  org_slug := LOWER(REPLACE(org_name, ' ', '-')) || '-' || SUBSTRING(NEW.id::TEXT, 1, 8);
  
  -- Create namespace
  INSERT INTO namespaces (name, slug, tier)
  VALUES (org_name, org_slug, 'free')
  RETURNING id INTO new_namespace_id;
  
  -- Create default workspace
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (new_namespace_id, 'General', 'general', TRUE)
  RETURNING id INTO new_workspace_id;
  
  -- Create user record
  INSERT INTO users (id, namespace_id, email, name, namespace_role)
  VALUES (NEW.id, new_namespace_id, user_email, COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(user_email, '@', 1)), 'admin');
  
  -- Add user to default workspace as admin
  INSERT INTO workspace_users (workspace_id, user_id, role)
  VALUES (new_workspace_id, NEW.id, 'admin');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## UI Components to Create

### 1. Login Page (`/login`)

```tsx
// src/pages/Login.tsx

import { useState } from 'react';
import { supabase } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';

export function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(error.message);
    } else {
      navigate('/');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full p-8 bg-white rounded-lg shadow">
        <div className="text-center mb-8">
          <img src="/logo.svg" alt="GetInSync Lite" className="h-12 mx-auto mb-4" />
          <h1 className="text-2xl font-bold">Sign in</h1>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          {error && (
            <div className="p-3 bg-red-50 text-red-700 rounded">{error}</div>
          )}

          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-2 border rounded"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full p-2 border rounded"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2 bg-teal-600 text-white rounded hover:bg-teal-700 disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <p className="mt-4 text-center text-sm text-gray-600">
          Don't have an account?{' '}
          <a href="/signup" className="text-teal-600 hover:underline">
            Sign up
          </a>
        </p>
      </div>
    </div>
  );
}
```

### 2. Signup Page (`/signup`)

```tsx
// src/pages/Signup.tsx

import { useState } from 'react';
import { supabase } from '../lib/supabase';
import { useNavigate } from 'react-router-dom';

export function Signup() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          name: name,
        },
      },
    });

    if (error) {
      setError(error.message);
    } else {
      // Redirect to dashboard - namespace/workspace created by trigger
      navigate('/');
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full p-8 bg-white rounded-lg shadow">
        <div className="text-center mb-8">
          <img src="/logo.svg" alt="GetInSync Lite" className="h-12 mx-auto mb-4" />
          <h1 className="text-2xl font-bold">Create your account</h1>
          <p className="text-gray-600 mt-2">Start managing your application portfolio</p>
        </div>

        <form onSubmit={handleSignup} className="space-y-4">
          {error && (
            <div className="p-3 bg-red-50 text-red-700 rounded">{error}</div>
          )}

          <div>
            <label className="block text-sm font-medium mb-1">Your name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full p-2 border rounded"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-2 border rounded"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full p-2 border rounded"
              minLength={8}
              required
            />
            <p className="text-xs text-gray-500 mt-1">Minimum 8 characters</p>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2 bg-teal-600 text-white rounded hover:bg-teal-700 disabled:opacity-50"
          >
            {loading ? 'Creating account...' : 'Create account'}
          </button>
        </form>

        <p className="mt-4 text-center text-sm text-gray-600">
          Already have an account?{' '}
          <a href="/login" className="text-teal-600 hover:underline">
            Sign in
          </a>
        </p>

        <p className="mt-6 text-center text-xs text-gray-500">
          By signing up, you agree to our Terms of Service and Privacy Policy.
        </p>
      </div>
    </div>
  );
}
```

### 3. Auth Context Provider

```tsx
// src/contexts/AuthContext.tsx

import { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface UserProfile {
  id: string;
  email: string;
  name: string;
  namespace_id: string;
  namespace_role: string;
}

interface Workspace {
  id: string;
  name: string;
  slug: string;
  is_default: boolean;
  role: string;
}

interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  workspaces: Workspace[];
  currentWorkspace: Workspace | null;
  setCurrentWorkspace: (workspace: Workspace) => void;
  loading: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [workspaces, setWorkspaces] = useState<Workspace[]>([]);
  const [currentWorkspace, setCurrentWorkspace] = useState<Workspace | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchUserData(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null);
        if (session?.user) {
          await fetchUserData(session.user.id);
        } else {
          setProfile(null);
          setWorkspaces([]);
          setCurrentWorkspace(null);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const fetchUserData = async (userId: string) => {
    try {
      // Fetch user profile
      const { data: profileData } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();

      setProfile(profileData);

      // Fetch user's workspaces
      const { data: workspaceData } = await supabase
        .from('workspace_users')
        .select(`
          role,
          workspace:workspaces (
            id,
            name,
            slug,
            is_default
          )
        `)
        .eq('user_id', userId);

      const userWorkspaces = workspaceData?.map((wu: any) => ({
        ...wu.workspace,
        role: wu.role,
      })) || [];

      setWorkspaces(userWorkspaces);

      // Set default workspace
      const defaultWs = userWorkspaces.find((w: Workspace) => w.is_default) || userWorkspaces[0];
      setCurrentWorkspace(defaultWs);

    } catch (error) {
      console.error('Error fetching user data:', error);
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
    setWorkspaces([]);
    setCurrentWorkspace(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        profile,
        workspaces,
        currentWorkspace,
        setCurrentWorkspace,
        loading,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
```

### 4. Protected Route Component

```tsx
// src/components/ProtectedRoute.tsx

import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
```

---

## Router Setup

Update the main router to include auth routes:

```tsx
// src/App.tsx or src/main.tsx

import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import { Login } from './pages/Login';
import { Signup } from './pages/Signup';
import { Dashboard } from './pages/Dashboard';
// ... other imports

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<Login />} />
          <Route path="/signup" element={<Signup />} />

          {/* Protected routes */}
          <Route
            path="/*"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
```

---

## Header User Menu

Add user menu to the header showing current user and logout:

```tsx
// src/components/UserMenu.tsx

import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

export function UserMenu() {
  const { profile, signOut } = useAuth();
  const [open, setOpen] = useState(false);

  if (!profile) return null;

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 p-2 rounded hover:bg-gray-100"
      >
        <div className="w-8 h-8 bg-teal-600 text-white rounded-full flex items-center justify-center">
          {profile.name?.charAt(0).toUpperCase() || profile.email.charAt(0).toUpperCase()}
        </div>
        <span className="text-sm font-medium">{profile.name || profile.email}</span>
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
          <div className="px-4 py-2 text-sm text-gray-500 border-b">
            {profile.email}
          </div>
          <button
            onClick={signOut}
            className="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  );
}
```

---

## Verification

After implementing:

1. **Test signup flow:**
   - Create new account
   - Verify namespace created
   - Verify default workspace created
   - Verify user lands on dashboard

2. **Test login flow:**
   - Login with existing account
   - Verify redirected to dashboard
   - Verify workspace data loads

3. **Test protected routes:**
   - Try accessing dashboard without login
   - Should redirect to login page

4. **Test logout:**
   - Click logout
   - Should clear session and redirect to login

---

## What's NOT in This Phase

- Workspace switcher UI (Phase 3)
- Invite users flow (Phase 4)
- Password reset
- OAuth providers (Google, Microsoft)

---

## Next Phase

Proceed to **Phase 3: Data Scoping** to update all queries to filter by current workspace.
