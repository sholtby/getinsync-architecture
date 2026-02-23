# 16: Multi-Workspace Portfolio UI

## Overview

When a Namespace Admin views "All Workspaces", the portfolio dropdown can contain duplicate names (e.g., multiple workspaces might have a "Finance" portfolio). This document specifies how to handle portfolio selection in the multi-workspace context.

---

## The Problem

```
Namespace: SaskBuilds
â”œâ”€â”€ Workspace: Ministry of Justice
â”‚   â”œâ”€â”€ Portfolio: Finance        â† Same name
â”‚   â”œâ”€â”€ Portfolio: Operations
â”‚   â””â”€â”€ Portfolio: Legacy Systems
â”œâ”€â”€ Workspace: Ministry of Finance
â”‚   â”œâ”€â”€ Portfolio: Finance        â† Same name
â”‚   â”œâ”€â”€ Portfolio: Treasury
â”‚   â””â”€â”€ Portfolio: General
â””â”€â”€ Workspace: Central IT
    â”œâ”€â”€ Portfolio: Finance        â† Same name
    â””â”€â”€ Portfolio: Infrastructure
```

**Current (confusing):**
```
Portfolio: [Finance â–¼]   â† Which Finance?!
```

---

## Solution: Hybrid Dropdown Behavior

**Rule:** The portfolio dropdown adapts based on workspace selection.

| Workspace Selection | Portfolio Dropdown Behavior |
|---------------------|----------------------------|
| Specific workspace | Simple flat list (no disambiguation needed) |
| All Workspaces | Grouped by workspace with headers |

---

## UI: Single Workspace Selected

When user selects a specific workspace, show simple portfolio list:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Ministry of Justice  â–¼  â”‚  â”‚ All Portfolios       â–¼  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘

Portfolio dropdown (simple):
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ All Portfolios          â”‚
â”‚ Finance                 â”‚
â”‚ Operations              â”‚
â”‚ Legacy Systems          â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

No changes needed here â€” current behavior works fine.

---

## UI: All Workspaces Selected

When Namespace Admin selects "All Workspaces", show grouped portfolio list:

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ All Workspaces       â–¼  â”‚  â”‚ All Portfolios               â–¼  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘

Portfolio dropdown (grouped):
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ All Portfolios                  â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚ MINISTRY OF JUSTICE             â”‚  â† Group header (not selectable)
â”‚   Finance                       â”‚
â”‚   Operations                    â”‚
â”‚   Legacy Systems                â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚ MINISTRY OF FINANCE             â”‚  â† Group header (not selectable)
â”‚   Finance                       â”‚
â”‚   Treasury                      â”‚
â”‚   General                       â”‚
â”‚ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ â”‚
â”‚ CENTRAL IT                      â”‚  â† Group header (not selectable)
â”‚   Finance                       â”‚
â”‚   Infrastructure                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Implementation: Native HTML optgroup

The simplest implementation uses native `<optgroup>`:

```tsx
// src/components/PortfolioSelector.tsx

interface Props {
  workspaces: Workspace[];
  portfolios: Portfolio[];
  selectedWorkspaceId: string | 'all';
  selectedPortfolioId: string | 'all';
  onPortfolioChange: (portfolioId: string) => void;
}

export function PortfolioSelector({
  workspaces,
  portfolios,
  selectedWorkspaceId,
  selectedPortfolioId,
  onPortfolioChange,
}: Props) {
  // If specific workspace selected, filter portfolios to that workspace
  const filteredPortfolios = selectedWorkspaceId === 'all'
    ? portfolios
    : portfolios.filter(p => p.workspace_id === selectedWorkspaceId);

  // Group portfolios by workspace (only needed for "All Workspaces" view)
  const groupedPortfolios = workspaces.map(ws => ({
    workspace: ws,
    portfolios: portfolios.filter(p => p.workspace_id === ws.id),
  })).filter(g => g.portfolios.length > 0);

  return (
    <select
      value={selectedPortfolioId}
      onChange={(e) => onPortfolioChange(e.target.value)}
      className="border rounded-lg px-3 py-2"
    >
      <option value="all">All Portfolios</option>

      {selectedWorkspaceId === 'all' ? (
        // Grouped view for "All Workspaces"
        groupedPortfolios.map(group => (
          <optgroup key={group.workspace.id} label={group.workspace.name}>
            {group.portfolios.map(portfolio => (
              <option key={portfolio.id} value={portfolio.id}>
                {portfolio.name}
              </option>
            ))}
          </optgroup>
        ))
      ) : (
        // Flat view for specific workspace
        filteredPortfolios.map(portfolio => (
          <option key={portfolio.id} value={portfolio.id}>
            {portfolio.name}
          </option>
        ))
      )}
    </select>
  );
}
```

---

## Implementation: Custom Dropdown (if using shadcn/ui or similar)

If using a custom dropdown component:

```tsx
// src/components/PortfolioDropdown.tsx

import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

export function PortfolioDropdown({
  workspaces,
  portfolios,
  selectedWorkspaceId,
  selectedPortfolioId,
  onPortfolioChange,
}: Props) {
  const groupedPortfolios = workspaces.map(ws => ({
    workspace: ws,
    portfolios: portfolios.filter(p => p.workspace_id === ws.id),
  })).filter(g => g.portfolios.length > 0);

  return (
    <Select value={selectedPortfolioId} onValueChange={onPortfolioChange}>
      <SelectTrigger className="w-[200px]">
        <SelectValue placeholder="Select portfolio" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">All Portfolios</SelectItem>
        
        {selectedWorkspaceId === 'all' ? (
          // Grouped view
          groupedPortfolios.map(group => (
            <SelectGroup key={group.workspace.id}>
              <SelectLabel className="text-xs text-gray-500 uppercase tracking-wide">
                {group.workspace.name}
              </SelectLabel>
              {group.portfolios.map(portfolio => (
                <SelectItem key={portfolio.id} value={portfolio.id}>
                  {portfolio.name}
                </SelectItem>
              ))}
            </SelectGroup>
          ))
        ) : (
          // Flat view
          portfolios
            .filter(p => p.workspace_id === selectedWorkspaceId)
            .map(portfolio => (
              <SelectItem key={portfolio.id} value={portfolio.id}>
                {portfolio.name}
              </SelectItem>
            ))
        )}
      </SelectContent>
    </Select>
  );
}
```

---

## Selected Value Display

When a portfolio is selected in "All Workspaces" mode, the dropdown trigger should show workspace context:

**Option A: Show workspace prefix in trigger**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Justice Â· Finance              â–¼  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Option B: Show just portfolio name (simpler)**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Finance              â–¼  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**Recommendation:** Option B is fine because:
- The grouped dropdown makes selection unambiguous
- The dashboard/table will show workspace column anyway
- Simpler implementation

---

## Dashboard Table: Add Workspace Column

When viewing "All Workspaces", the applications table should include a Workspace column:

**Single Workspace View:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Application      â”‚ Portfolio   â”‚ TIME        â”‚ PAID      â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ Sage 300         â”‚ Finance     â”‚ Invest      â”‚ Plan      â”‚
â”‚ Case Management  â”‚ Operations  â”‚ Modernize   â”‚ Address   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

**All Workspaces View:**
```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┐
â”‚ Application      â”‚ Workspace           â”‚ Portfolio   â”‚ TIME      â”‚ PAID      â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┤
â”‚ Sage 300         â”‚ Ministry of Justice â”‚ Finance     â”‚ Invest    â”‚ Plan      â”‚
â”‚ Budget System    â”‚ Ministry of Finance â”‚ Finance     â”‚ Tolerate  â”‚ Ignore    â”‚
â”‚ Cloud Hosting    â”‚ Central IT          â”‚ Infra       â”‚ Invest    â”‚ Plan      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€┘
```

---

## Workspace Selector: "All Workspaces" Option

Only Namespace Admins should see the "All Workspaces" option:

```tsx
// src/components/WorkspaceSelector.tsx

export function WorkspaceSelector({
  workspaces,
  selectedWorkspaceId,
  onWorkspaceChange,
  isNamespaceAdmin,
}: Props) {
  return (
    <select
      value={selectedWorkspaceId}
      onChange={(e) => onWorkspaceChange(e.target.value)}
      className="border rounded-lg px-3 py-2"
    >
      {/* Only show "All Workspaces" for Namespace Admins */}
      {isNamespaceAdmin && (
        <option value="all">All Workspaces (Admin View)</option>
      )}
      
      {workspaces.map(workspace => (
        <option key={workspace.id} value={workspace.id}>
          {workspace.name}
        </option>
      ))}
    </select>
  );
}
```

---

## Data Fetching Logic

When "All Workspaces" is selected, fetch data across all workspaces:

```typescript
// src/hooks/usePortfolioAssignments.ts

export function usePortfolioAssignments(
  workspaceId: string | 'all',
  portfolioId: string | 'all'
) {
  const { profile } = useAuth();

  return useQuery({
    queryKey: ['portfolio-assignments', workspaceId, portfolioId],
    queryFn: async () => {
      let query = supabase
        .from('portfolio_assignments')
        .select(`
          *,
          application:applications!inner(
            *,
            workspace:workspaces(name)
          ),
          portfolio:portfolios!inner(
            *,
            workspace:workspaces(name)
          )
        `);

      // Filter by workspace if not "all"
      if (workspaceId !== 'all') {
        query = query.eq('portfolio.workspace_id', workspaceId);
      }

      // Filter by portfolio if not "all"
      if (portfolioId !== 'all') {
        query = query.eq('portfolio_id', portfolioId);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },
  });
}
```

---

## Edge Cases

### 1. Namespace Admin selects portfolio, then switches workspace

If admin selects "Justice Â· Finance" portfolio, then switches workspace to "Ministry of Finance":
- The selected portfolio is no longer valid for that workspace
- **Action:** Reset portfolio selection to "All Portfolios"

```tsx
useEffect(() => {
  if (selectedWorkspaceId !== 'all') {
    const portfolioInWorkspace = portfolios.find(
      p => p.id === selectedPortfolioId && p.workspace_id === selectedWorkspaceId
    );
    if (!portfolioInWorkspace) {
      setSelectedPortfolioId('all');
    }
  }
}, [selectedWorkspaceId]);
```

### 2. Empty workspaces

Some workspaces may have no portfolios yet:
- Don't show empty groups in the dropdown
- Already handled by `.filter(g => g.portfolios.length > 0)`

### 3. Many workspaces

If there are 20+ workspaces, the grouped dropdown could get long:
- Consider adding a search/filter input at the top of the dropdown
- Or limit to most recent/active workspaces with "Show all..." option

---

## Summary

| View | Workspace Dropdown | Portfolio Dropdown | Table Columns |
|------|-------------------|-------------------|---------------|
| Regular user | Their workspaces only | Flat list | No workspace column |
| Namespace Admin (single ws) | All workspaces + "All" option | Flat list | No workspace column |
| Namespace Admin (all ws) | All workspaces + "All" option | Grouped by workspace | Includes workspace column |

---

## Verification

1. Log in as Namespace Admin
2. Select "All Workspaces" from workspace dropdown
3. Open portfolio dropdown â†’ verify workspaces are grouped with headers
4. Select a portfolio from one workspace â†’ verify correct data loads
5. Verify table shows Workspace column
6. Switch to specific workspace â†’ verify portfolio dropdown is now flat
7. Verify table no longer shows Workspace column
