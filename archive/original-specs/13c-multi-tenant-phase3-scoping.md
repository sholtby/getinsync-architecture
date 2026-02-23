# Multi-Tenant Phase 3: Workspace Data Scoping

## Overview

Update all database queries to filter by the current workspace. This ensures users only see data in their workspace.

**Prerequisites:** Phase 1 (schema) and Phase 2 (auth) must be complete.

**Goal:** Every query for applications, portfolios, contacts, and settings is scoped to the current workspace.

---

## Current State

After Phase 2:
- User can sign up/login
- AuthContext provides `currentWorkspace`
- Database has `workspace_id` on all tables
- RLS policies are in place

But the app's queries don't use `workspace_id` yet â€” they fetch all data.

---

## Query Updates Required

### Pattern: Add workspace_id to all queries

**Before:**
```typescript
const { data } = await supabase
  .from('applications')
  .select('*');
```

**After:**
```typescript
const { data } = await supabase
  .from('applications')
  .select('*')
  .eq('workspace_id', currentWorkspace.id);
```

---

## Create a Workspace-Scoped Supabase Hook

Instead of updating every query manually, create a hook that provides workspace-scoped queries:

```tsx
// src/hooks/useWorkspaceData.ts

import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

export function useWorkspaceData() {
  const { currentWorkspace } = useAuth();

  if (!currentWorkspace) {
    throw new Error('No workspace selected');
  }

  const workspaceId = currentWorkspace.id;

  return {
    // Applications
    async getApplications() {
      const { data, error } = await supabase
        .from('applications')
        .select('*, business_owner:contacts!business_owner_id(*), primary_support:contacts!primary_support_id(*)')
        .eq('workspace_id', workspaceId)
        .order('name');
      
      if (error) throw error;
      return data;
    },

    async getApplication(id: string) {
      const { data, error } = await supabase
        .from('applications')
        .select('*, business_owner:contacts!business_owner_id(*), primary_support:contacts!primary_support_id(*)')
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .single();
      
      if (error) throw error;
      return data;
    },

    async createApplication(application: Omit<Application, 'id' | 'workspace_id' | 'created_at'>) {
      const { data, error } = await supabase
        .from('applications')
        .insert({ ...application, workspace_id: workspaceId })
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async updateApplication(id: string, updates: Partial<Application>) {
      const { data, error } = await supabase
        .from('applications')
        .update(updates)
        .eq('id', id)
        .eq('workspace_id', workspaceId) // Extra safety
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async deleteApplication(id: string) {
      const { error } = await supabase
        .from('applications')
        .delete()
        .eq('id', id)
        .eq('workspace_id', workspaceId);
      
      if (error) throw error;
    },

    // Portfolios
    async getPortfolios() {
      const { data, error } = await supabase
        .from('portfolios')
        .select('*')
        .eq('workspace_id', workspaceId)
        .order('is_default', { ascending: false })
        .order('name');
      
      if (error) throw error;
      return data;
    },

    async getPortfolio(id: string) {
      const { data, error } = await supabase
        .from('portfolios')
        .select('*')
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .single();
      
      if (error) throw error;
      return data;
    },

    async createPortfolio(portfolio: { name: string; description?: string }) {
      const { data, error } = await supabase
        .from('portfolios')
        .insert({ ...portfolio, workspace_id: workspaceId, is_default: false })
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async updatePortfolio(id: string, updates: Partial<Portfolio>) {
      const { data, error } = await supabase
        .from('portfolios')
        .update(updates)
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async deletePortfolio(id: string) {
      // Don't allow deleting default portfolio
      const portfolio = await this.getPortfolio(id);
      if (portfolio.is_default) {
        throw new Error('Cannot delete the default portfolio');
      }

      const { error } = await supabase
        .from('portfolios')
        .delete()
        .eq('id', id)
        .eq('workspace_id', workspaceId);
      
      if (error) throw error;
    },

    // Portfolio Assignments
    async getPortfolioAssignments(portfolioId?: string) {
      let query = supabase
        .from('portfolio_assignments')
        .select(`
          *,
          application:applications(*),
          portfolio:portfolios(*)
        `)
        .eq('portfolio.workspace_id', workspaceId);

      if (portfolioId) {
        query = query.eq('portfolio_id', portfolioId);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },

    async createPortfolioAssignment(assignment: {
      portfolio_id: string;
      application_id: string;
    }) {
      const { data, error } = await supabase
        .from('portfolio_assignments')
        .insert(assignment)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async updatePortfolioAssignment(id: string, updates: Partial<PortfolioAssignment>) {
      const { data, error } = await supabase
        .from('portfolio_assignments')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    // Contacts
    async getContacts() {
      const { data, error } = await supabase
        .from('contacts')
        .select('*')
        .eq('workspace_id', workspaceId)
        .order('name');
      
      if (error) throw error;
      return data;
    },

    async createContact(contact: { name: string; email?: string; title?: string }) {
      const { data, error } = await supabase
        .from('contacts')
        .insert({ ...contact, workspace_id: workspaceId })
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    // Settings
    async getWorkspaceSettings() {
      const { data, error } = await supabase
        .from('workspace_settings')
        .select('*')
        .eq('workspace_id', workspaceId)
        .single();
      
      // Return default settings if none exist
      if (error && error.code === 'PGRST116') {
        return { max_project_budget: 1000000 };
      }
      if (error) throw error;
      return data;
    },

    async updateWorkspaceSettings(settings: Partial<WorkspaceSettings>) {
      const { data, error } = await supabase
        .from('workspace_settings')
        .upsert({ 
          workspace_id: workspaceId,
          ...settings,
          updated_at: new Date().toISOString()
        })
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    // Dashboard aggregations
    async getDashboardStats() {
      const [applications, portfolios, assignments] = await Promise.all([
        this.getApplications(),
        this.getPortfolios(),
        this.getPortfolioAssignments(),
      ]);

      const completedAssignments = assignments.filter(a => a.assessment_status === 'complete');
      
      return {
        totalApplications: applications.length,
        totalPortfolios: portfolios.length,
        totalAssessments: assignments.length,
        completedAssessments: completedAssignments.length,
        totalAnnualCost: applications.reduce((sum, app) => sum + (app.annual_cost || 0), 0),
        avgBusinessFit: completedAssignments.length > 0
          ? completedAssignments.reduce((sum, a) => sum + (a.business_fit || 0), 0) / completedAssignments.length
          : 0,
        avgTechHealth: completedAssignments.length > 0
          ? completedAssignments.reduce((sum, a) => sum + (a.tech_health || 0), 0) / completedAssignments.length
          : 0,
      };
    },
  };
}
```

---

## Update Components to Use the Hook

### Example: Applications List

**Before:**
```tsx
function ApplicationsList() {
  const [applications, setApplications] = useState([]);

  useEffect(() => {
    async function fetch() {
      const { data } = await supabase.from('applications').select('*');
      setApplications(data || []);
    }
    fetch();
  }, []);

  // ...
}
```

**After:**
```tsx
function ApplicationsList() {
  const [applications, setApplications] = useState([]);
  const { currentWorkspace } = useAuth();
  const workspaceData = useWorkspaceData();

  useEffect(() => {
    async function fetch() {
      const data = await workspaceData.getApplications();
      setApplications(data || []);
    }
    if (currentWorkspace) {
      fetch();
    }
  }, [currentWorkspace]); // Re-fetch when workspace changes

  // ...
}
```

---

## Workspace Switcher Component

Add a dropdown to switch between workspaces:

```tsx
// src/components/WorkspaceSwitcher.tsx

import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

export function WorkspaceSwitcher() {
  const { workspaces, currentWorkspace, setCurrentWorkspace } = useAuth();
  const [open, setOpen] = useState(false);

  if (!currentWorkspace || workspaces.length <= 1) {
    // Don't show switcher if only one workspace
    return (
      <div className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700">
        <FolderIcon className="h-4 w-4" />
        {currentWorkspace?.name}
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 px-3 py-2 rounded hover:bg-gray-100"
      >
        <FolderIcon className="h-4 w-4" />
        <span className="font-medium">{currentWorkspace.name}</span>
        <ChevronDownIcon className="h-4 w-4" />
      </button>

      {open && (
        <div className="absolute left-0 mt-2 w-64 bg-white rounded-md shadow-lg py-1 z-50">
          <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">
            Workspaces
          </div>
          
          {workspaces.map((workspace) => (
            <button
              key={workspace.id}
              onClick={() => {
                setCurrentWorkspace(workspace);
                setOpen(false);
              }}
              className={`w-full text-left px-3 py-2 flex items-center gap-2 hover:bg-gray-100 ${
                workspace.id === currentWorkspace.id ? 'bg-teal-50 text-teal-700' : ''
              }`}
            >
              <FolderIcon className="h-4 w-4" />
              <span>{workspace.name}</span>
              {workspace.is_default && (
                <span className="ml-auto text-xs bg-gray-100 px-2 py-0.5 rounded">
                  Default
                </span>
              )}
              {workspace.id === currentWorkspace.id && (
                <CheckIcon className="h-4 w-4 ml-auto text-teal-600" />
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

## Update Header to Include Workspace Switcher

```tsx
// src/components/Header.tsx

import { WorkspaceSwitcher } from './WorkspaceSwitcher';
import { UserMenu } from './UserMenu';

export function Header() {
  return (
    <header className="bg-white border-b px-6 py-3 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <img src="/logo.svg" alt="GetInSync Lite" className="h-8" />
        <span className="text-lg font-semibold">GetInSync Lite</span>
      </div>

      <div className="flex items-center gap-4">
        <WorkspaceSwitcher />
        <UserMenu />
      </div>
    </header>
  );
}
```

---

## Persist Selected Workspace

Save the user's last selected workspace to localStorage:

```tsx
// In AuthContext.tsx, update setCurrentWorkspace:

const setCurrentWorkspaceWithPersist = (workspace: Workspace) => {
  setCurrentWorkspace(workspace);
  localStorage.setItem('lastWorkspaceId', workspace.id);
};

// When loading workspaces, check for saved preference:
const fetchUserData = async (userId: string) => {
  // ... fetch workspaces ...

  // Check for saved workspace preference
  const lastWorkspaceId = localStorage.getItem('lastWorkspaceId');
  const savedWorkspace = userWorkspaces.find((w: Workspace) => w.id === lastWorkspaceId);
  const defaultWs = savedWorkspace || userWorkspaces.find((w: Workspace) => w.is_default) || userWorkspaces[0];
  
  setCurrentWorkspace(defaultWs);
};
```

---

## Re-fetch Data on Workspace Change

Components need to re-fetch when workspace changes. Use a key on the main layout:

```tsx
// src/App.tsx

function AppContent() {
  const { currentWorkspace, loading } = useAuth();

  if (loading) return <LoadingSpinner />;
  if (!currentWorkspace) return <Navigate to="/login" />;

  return (
    // Key forces remount when workspace changes, triggering data re-fetch
    <div key={currentWorkspace.id}>
      <Header />
      <main>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/applications" element={<Applications />} />
          <Route path="/portfolios" element={<Portfolios />} />
          {/* ... */}
        </Routes>
      </main>
    </div>
  );
}
```

---

## Files to Update

Go through each file that queries the database and update:

1. **Dashboard.tsx** â€” Use `workspaceData.getDashboardStats()`
2. **ApplicationsList.tsx** â€” Use `workspaceData.getApplications()`
3. **ApplicationForm.tsx** â€” Use `workspaceData.createApplication()`
4. **PortfoliosList.tsx** â€” Use `workspaceData.getPortfolios()`
5. **PortfolioDetail.tsx** â€” Use `workspaceData.getPortfolioAssignments()`
6. **AssessmentModal.tsx** â€” Use `workspaceData.updatePortfolioAssignment()`
7. **ContactsDropdown.tsx** â€” Use `workspaceData.getContacts()`
8. **SettingsModal.tsx** â€” Use `workspaceData.getWorkspaceSettings()`

---

## Verification

After implementing:

1. **Create two workspaces** (via database or Phase 4 UI)
2. **Add applications to each workspace**
3. **Switch between workspaces**
4. **Verify data isolation:**
   - Workspace A apps should not appear in Workspace B
   - Switching workspace should show different data

---

## What's NOT in This Phase

- Creating new workspaces (UI)
- Inviting users to workspace
- User management

---

## Next Phase

Proceed to **Phase 4: User Management UI** to add workspace creation and user invitation.
