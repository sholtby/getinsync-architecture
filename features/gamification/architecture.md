# GetInSync NextGen — Gamification Architecture

**Version:** 1.2  
**Date:** February 14, 2026  
**Status:** 🟡 AS-DESIGNED | Not yet deployed  
**Stack:** Supabase PostgreSQL + React/TypeScript + Resend (email) | Leverages existing audit_logs infrastructure  
**SOC2 Controls:** CC6.6 (flags table has audit trigger for data governance traceability)

---

## 1. Overview

GetInSync Gamification rewards users for completing meaningful actions within the platform — onboarding steps, data quality improvements, collaboration activities, and feature mastery. The system leverages the existing audit_logs infrastructure as its event source, avoiding new instrumentation.

### 1.1 Design Principles

| Principle | Rationale |
|-----------|-----------|
| **Audit-log-driven** | No new event instrumentation — achievements are computed from existing audit_logs entries |
| **Namespace-scoped** | Achievements are earned within a namespace context, matching the platform's tenant isolation model |
| **Tier-aligned** | Achievement visibility maps to tier features — Free users see but can't earn Enterprise achievements (gamified upgrade teasers) |
| **18-year-old test** | Achievement names and progress indicators must be immediately understandable without training |
| **Non-blocking** | Achievement computation never slows user actions — read from cache, compute in background |
| **QuickBooks simple** | LinkedIn profile completion meter, not World of Warcraft — subtle, professional, encouraging |
| **Silent computation** | Achievement engine runs even when user opts out — progress is always current for re-engagement and opt-back-in scenarios |
| **Three-level opt-out** | Namespace master switch → user gamification UI toggle → user email digest toggle — each level independent |
| **Contextual action** | Data quality flags turn passive observation into actionable governance — the feed becomes a call to action, not just a news ticker |

### 1.2 Strategic Goals

Gamification serves four product objectives:

1. **Activation** — Guide new users through onboarding without a tutorial wizard
2. **Data quality** — Incentivize the completeness that makes the platform valuable (government customers struggle to get staff to fill things in)
3. **Feature discovery** — Surface higher-tier capabilities through visible-but-locked achievements
4. **Stickiness** — Streaks and progress tracking create habitual engagement
5. **Re-engagement** — Achievement digest and "pick up where you left off" emails bring dormant users back with personalized context
6. **Data governance** — Quality flags give every user a voice to report stale data, wrong owners, and planned changes — turning passive consumers into active data stewards

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    LAYER 1: DEFINITIONS                  │
│              gamification_achievements                   │
│    (namespace-scoped config — what can be earned)        │
└──────────────────────┬──────────────────────────────────┘
                       │ defines rules
                       ▼
┌─────────────────────────────────────────────────────────┐
│                 LAYER 2: EVENT SOURCE                    │
│                    audit_logs                            │
│          (existing — 17+ triggers, 4 categories)        │
└──────────────────────┬──────────────────────────────────┘
                       │ queried by
                       ▼
┌─────────────────────────────────────────────────────────┐
│               LAYER 3: ACHIEVEMENT ENGINE                │
│           check_achievements() RPC function              │
│  (reads audit_logs, updates progress, awards badges)     │
└──────────────────────┬──────────────────────────────────┘
                       │ writes to
                       ▼
┌─────────────────────────────────────────────────────────┐
│                LAYER 4: USER STATE                       │
│   gamification_user_progress + gamification_user_stats   │
│        (per-user cache — read by UI cheaply)             │
└──────────────────────┬──────────────────────────────────┘
                       │ displayed by
                       ▼
┌─────────────────────────────────────────────────────────┐
│                  LAYER 5: UI                             │
│   Achievement toasts, profile badge wall, dashboard     │
│   progress meter, namespace leaderboard (optional)      │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Why Audit Logs (Not Direct Triggers)

**Option considered:** Add achievement-checking triggers directly on business tables (applications, deployment_profiles, etc.).

**Decision:** Read from audit_logs instead.

| Factor | Direct Triggers | Audit Log Queries |
|--------|----------------|-------------------|
| Write overhead | Adds to every INSERT/UPDATE | Zero overhead on user actions |
| Maintenance | New trigger per table per achievement | Single query engine reads one table |
| Retroactive | Can't award for past actions | Can compute from full history |
| Accuracy | Real-time but fragile | Slightly delayed but robust |
| SOC2 alignment | Separate infrastructure | Reuses existing compliance asset |

The audit_logs table already captures entity_type, event_type, user_id, namespace_id, changed_fields, and entity_name — everything the achievement engine needs.

---

## 3. Data Model

### 3.1 Entity Relationship

```
gamification_achievements (namespace-scoped definitions)
    │
    │ 1:N
    ▼
gamification_user_progress (per-user, per-achievement state)
    │
    │ N:1 (denormalized rollup)
    ▼
gamification_user_stats (per-user summary cache)
```

### 3.2 Table: gamification_achievements

Defines what can be earned. Namespace-scoped so each organization can eventually customize achievements (Phase 2). Seeded with platform defaults on namespace creation.

```sql
-- =============================================================================
-- TABLE: gamification_achievements
-- Purpose: Achievement definitions — what actions earn points/badges
-- Scope: Namespace-level (seeded from platform defaults)
-- =============================================================================

CREATE TABLE gamification_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    
    -- Identity
    code TEXT NOT NULL,                    -- Machine key, e.g. 'first_app_created'
    name TEXT NOT NULL,                    -- Display name, e.g. 'First Steps'
    description TEXT NOT NULL,             -- Plain English, e.g. 'Create your first application'
    icon TEXT,                             -- Icon key from src/constants/icons.ts
    
    -- Classification
    category TEXT NOT NULL CHECK (category IN (
        'onboarding',       -- First-time actions (create app, assess, invite)
        'data_quality',     -- Completeness actions (fill all fields, assign owners)
        'collaboration',    -- Multi-user/multi-workspace actions
        'mastery',          -- Advanced feature usage (cost model, IT services, integrations)
        'consistency'       -- Streak-based (login streaks, weekly assessment cadence)
    )),
    badge_tier TEXT NOT NULL DEFAULT 'bronze' CHECK (badge_tier IN (
        'bronze', 'silver', 'gold', 'platinum'
    )),
    
    -- Trigger condition (maps to audit_logs query)
    trigger_entity_type TEXT NOT NULL,     -- audit_logs.entity_type value, e.g. 'applications'
    trigger_event_type TEXT NOT NULL CHECK (trigger_event_type IN (
        'INSERT', 'UPDATE', 'DELETE', 'ANY'
    )),
    trigger_condition JSONB DEFAULT '{}',  -- Additional filters (see §3.3)
    
    -- Completion criteria
    threshold INT NOT NULL DEFAULT 1,      -- How many qualifying events to earn
    points INT NOT NULL DEFAULT 10,        -- Points awarded on completion
    
    -- Tier gating
    minimum_tier TEXT NOT NULL DEFAULT 'free' CHECK (minimum_tier IN (
        'free', 'pro', 'enterprise', 'full'
    )),
    
    -- Display
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    UNIQUE(namespace_id, code)
);

COMMENT ON TABLE gamification_achievements IS 
    'Achievement definitions — namespace-scoped, seeded from platform defaults. '
    'Each achievement maps to an audit_logs query pattern via trigger_entity_type, '
    'trigger_event_type, and trigger_condition.';
```

### 3.3 Trigger Condition JSONB Schema

The `trigger_condition` field provides flexible matching against audit_logs entries:

```jsonc
// Example: "Assessment completed" — UPDATE on deployment_profiles where assessment_status changed
{
    "changed_fields_contains": ["assessment_status"],
    "new_values_match": {
        "assessment_status": "completed"
    }
}

// Example: "Added a contact to an application" — INSERT on application_contacts
// (no extra conditions needed — entity_type + event_type are sufficient)
{}

// Example: "Used all 3 cost channels" — complex, handled by named check function
{
    "check_function": "check_achievement_cost_channels"
}

// Example: "Filled in hosting details" — UPDATE on deployment_profiles where hosting_model changed
{
    "changed_fields_contains": ["hosting_model"]
}
```

**Supported condition keys:**

| Key | Type | Meaning |
|-----|------|---------|
| `changed_fields_contains` | text[] | audit_logs.changed_fields must include ALL listed fields |
| `new_values_match` | jsonb | audit_logs.new_values must contain matching key-value pairs |
| `distinct_entities` | boolean | Count DISTINCT entity_id (not total events) |
| `check_function` | text | Named PostgreSQL function for complex logic |

### 3.4 Table: gamification_user_progress

Tracks each user's progress toward each achievement. One row per user per achievement.

```sql
-- =============================================================================
-- TABLE: gamification_user_progress
-- Purpose: Per-user progress toward each achievement
-- Scope: Namespace-scoped via achievement FK
-- =============================================================================

CREATE TABLE gamification_user_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES gamification_achievements(id) ON DELETE CASCADE,
    
    -- Progress
    current_count INT NOT NULL DEFAULT 0,        -- Events matched so far
    earned_at TIMESTAMPTZ,                        -- NULL = not yet earned
    notified_at TIMESTAMPTZ,                      -- NULL = toast not yet shown
    
    -- Metadata
    last_qualifying_event_at TIMESTAMPTZ,         -- Most recent matching audit_log entry
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    UNIQUE(user_id, achievement_id)
);

COMMENT ON TABLE gamification_user_progress IS 
    'Per-user achievement progress. current_count tracks qualifying events, '
    'earned_at marks completion (NULL = in progress). Row created lazily '
    'on first qualifying event, not on user creation.';

-- Index for the achievement engine's primary query pattern
CREATE INDEX idx_gup_user_namespace 
    ON gamification_user_progress(user_id, namespace_id);
CREATE INDEX idx_gup_unnotified
    ON gamification_user_progress(user_id) 
    WHERE earned_at IS NOT NULL AND notified_at IS NULL;
```

### 3.5 Table: gamification_user_stats

Denormalized rollup for cheap UI reads. Updated by the achievement engine, never written directly by the frontend.

```sql
-- =============================================================================
-- TABLE: gamification_user_stats
-- Purpose: Denormalized per-user summary — dashboard reads this, not progress table
-- Scope: One row per user per namespace
-- =============================================================================

CREATE TABLE gamification_user_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Rollup stats
    total_points INT NOT NULL DEFAULT 0,
    achievements_earned INT NOT NULL DEFAULT 0,
    achievements_total INT NOT NULL DEFAULT 0,     -- Total available (for progress %)
    
    -- Streaks
    current_streak_days INT NOT NULL DEFAULT 0,
    longest_streak_days INT NOT NULL DEFAULT 0,
    last_active_date DATE,                          -- Date (not timestamp) for streak calc
    
    -- Derived
    level INT NOT NULL DEFAULT 1,                   -- Computed from total_points
    completion_percent NUMERIC(5,2) DEFAULT 0.00,   -- achievements_earned / achievements_total
    
    -- Opt-out controls (see §8.6 Three-Level Opt-Out)
    gamification_opted_out BOOLEAN NOT NULL DEFAULT false,  -- Hides UI (toasts, widgets, wall)
    digest_opted_out BOOLEAN NOT NULL DEFAULT false,        -- Stops weekly digest + re-engagement emails
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Constraints
    UNIQUE(user_id, namespace_id)
);

COMMENT ON TABLE gamification_user_stats IS 
    'Denormalized achievement summary per user per namespace. Read by dashboard UI. '
    'Written only by check_achievements() and refresh_user_stats() RPCs. '
    'Includes opt-out controls: gamification_opted_out hides UI, digest_opted_out stops emails. '
    'Achievement engine runs regardless of opt-out (silent computation).';

CREATE INDEX idx_gus_namespace_points 
    ON gamification_user_stats(namespace_id, total_points DESC);
CREATE INDEX idx_gus_digest_eligible
    ON gamification_user_stats(namespace_id)
    WHERE digest_opted_out = false AND last_active_date IS NOT NULL;
```

### 3.6 Level Thresholds

Levels are computed from total_points using a simple lookup. No separate table needed — this is a pure function:

```sql
-- =============================================================================
-- FUNCTION: get_gamification_level
-- Purpose: Compute level from total points
-- =============================================================================

CREATE OR REPLACE FUNCTION get_gamification_level(p_points INT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE
        WHEN p_points >= 1000 THEN 10  -- APM Master
        WHEN p_points >= 750  THEN 9   -- Portfolio Strategist
        WHEN p_points >= 550  THEN 8   -- Integration Architect
        WHEN p_points >= 400  THEN 7   -- Cost Optimizer
        WHEN p_points >= 300  THEN 6   -- Data Steward
        WHEN p_points >= 200  THEN 5   -- Team Builder
        WHEN p_points >= 125  THEN 4   -- Assessment Pro
        WHEN p_points >= 75   THEN 3   -- Active Contributor
        WHEN p_points >= 30   THEN 2   -- Getting Started
        ELSE                       1   -- Newcomer
    END;
$$;

COMMENT ON FUNCTION get_gamification_level IS 
    'Pure function mapping total points to level (1-10). '
    'Level names: Newcomer, Getting Started, Active Contributor, Assessment Pro, '
    'Team Builder, Data Steward, Cost Optimizer, Integration Architect, '
    'Portfolio Strategist, APM Master.';
```

**Level Names (for UI):**

| Level | Name | Points | Tier Expectation |
|-------|------|--------|-----------------|
| 1 | Newcomer | 0 | Free |
| 2 | Getting Started | 30 | Free |
| 3 | Active Contributor | 75 | Free |
| 4 | Assessment Pro | 125 | Pro |
| 5 | Team Builder | 200 | Pro |
| 6 | Data Steward | 300 | Enterprise |
| 7 | Cost Optimizer | 400 | Enterprise |
| 8 | Integration Architect | 550 | Full |
| 9 | Portfolio Strategist | 750 | Full |
| 10 | APM Master | 1000 | Full |

---

## 4. Achievement Engine

### 4.1 Primary RPC: check_achievements()

Called from the frontend after key user actions (save application, complete assessment, etc.). Reads audit_logs, updates progress, awards achievements.

```sql
-- =============================================================================
-- FUNCTION: check_achievements
-- Purpose: Scan audit_logs for qualifying events, update user progress, award badges
-- Called: From frontend after save actions (debounced, non-blocking)
-- =============================================================================

CREATE OR REPLACE FUNCTION check_achievements(
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS JSONB  -- Returns newly earned achievements for toast display
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_namespace_id UUID;
    v_achievement RECORD;
    v_count INT;
    v_newly_earned JSONB := '[]'::jsonb;
    v_progress RECORD;
    v_tier TEXT;
BEGIN
    -- Get current namespace
    SELECT current_namespace_id INTO v_namespace_id
    FROM user_sessions WHERE user_id = p_user_id;
    
    IF v_namespace_id IS NULL THEN
        RETURN '[]'::jsonb;
    END IF;
    
    -- Get user's current tier
    SELECT n.tier INTO v_tier
    FROM namespaces n
    WHERE n.id = v_namespace_id;
    
    -- Loop through active achievements for this namespace
    FOR v_achievement IN
        SELECT * FROM gamification_achievements
        WHERE namespace_id = v_namespace_id
          AND is_active = true
    LOOP
        -- Skip if achievement requires a higher tier
        IF NOT tier_meets_minimum(v_tier, v_achievement.minimum_tier) THEN
            CONTINUE;
        END IF;
        
        -- Skip if already earned
        SELECT * INTO v_progress
        FROM gamification_user_progress
        WHERE user_id = p_user_id AND achievement_id = v_achievement.id;
        
        IF v_progress IS NOT NULL AND v_progress.earned_at IS NOT NULL THEN
            CONTINUE;
        END IF;
        
        -- Count qualifying events from audit_logs
        v_count := count_qualifying_events(
            p_user_id,
            v_namespace_id,
            v_achievement.trigger_entity_type,
            v_achievement.trigger_event_type,
            v_achievement.trigger_condition
        );
        
        -- Upsert progress
        INSERT INTO gamification_user_progress 
            (namespace_id, user_id, achievement_id, current_count, last_qualifying_event_at)
        VALUES 
            (v_namespace_id, p_user_id, v_achievement.id, v_count, now())
        ON CONFLICT (user_id, achievement_id) DO UPDATE
            SET current_count = v_count,
                last_qualifying_event_at = now(),
                updated_at = now();
        
        -- Check if newly earned
        IF v_count >= v_achievement.threshold THEN
            -- Award the achievement
            UPDATE gamification_user_progress
            SET earned_at = COALESCE(earned_at, now()),  -- Don't overwrite if re-check
                current_count = v_count,
                updated_at = now()
            WHERE user_id = p_user_id AND achievement_id = v_achievement.id
              AND earned_at IS NULL;  -- Only if not already earned
            
            IF FOUND THEN
                v_newly_earned := v_newly_earned || jsonb_build_object(
                    'achievement_id', v_achievement.id,
                    'code', v_achievement.code,
                    'name', v_achievement.name,
                    'description', v_achievement.description,
                    'icon', v_achievement.icon,
                    'badge_tier', v_achievement.badge_tier,
                    'points', v_achievement.points
                );
            END IF;
        END IF;
    END LOOP;
    
    -- Refresh stats rollup
    PERFORM refresh_user_stats(p_user_id, v_namespace_id);
    
    RETURN v_newly_earned;
END;
$$;

COMMENT ON FUNCTION check_achievements IS 
    'Main achievement engine RPC. Called from frontend after user actions. '
    'Returns JSONB array of newly earned achievements for toast display. '
    'SECURITY DEFINER to read audit_logs across RLS boundary.';
```

### 4.2 Helper: count_qualifying_events()

```sql
-- =============================================================================
-- FUNCTION: count_qualifying_events
-- Purpose: Count audit_log entries matching an achievement's trigger criteria
-- =============================================================================

CREATE OR REPLACE FUNCTION count_qualifying_events(
    p_user_id UUID,
    p_namespace_id UUID,
    p_entity_type TEXT,
    p_event_type TEXT,
    p_condition JSONB
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INT;
    v_sql TEXT;
    v_distinct BOOLEAN;
    v_check_fn TEXT;
BEGIN
    -- Check for named function override
    v_check_fn := p_condition ->> 'check_function';
    IF v_check_fn IS NOT NULL THEN
        EXECUTE format('SELECT %I($1, $2)', v_check_fn)
            INTO v_count
            USING p_user_id, p_namespace_id;
        RETURN COALESCE(v_count, 0);
    END IF;
    
    -- Determine if counting distinct entities or total events
    v_distinct := COALESCE((p_condition ->> 'distinct_entities')::boolean, false);
    
    -- Build dynamic query
    IF v_distinct THEN
        v_sql := 'SELECT COUNT(DISTINCT entity_id) FROM audit_logs WHERE user_id = $1 AND namespace_id = $2 AND entity_type = $3';
    ELSE
        v_sql := 'SELECT COUNT(*) FROM audit_logs WHERE user_id = $1 AND namespace_id = $2 AND entity_type = $3';
    END IF;
    
    -- Add event type filter (unless ANY)
    IF p_event_type != 'ANY' THEN
        v_sql := v_sql || format(' AND event_type = %L', p_event_type);
    END IF;
    
    -- Add changed_fields filter
    IF p_condition ? 'changed_fields_contains' THEN
        v_sql := v_sql || format(
            ' AND changed_fields @> %L::text[]',
            (SELECT array_agg(elem::text) FROM jsonb_array_elements_text(p_condition -> 'changed_fields_contains') elem)
        );
    END IF;
    
    -- Add new_values match filter
    IF p_condition ? 'new_values_match' THEN
        v_sql := v_sql || format(
            ' AND new_values @> %L::jsonb',
            p_condition -> 'new_values_match'
        );
    END IF;
    
    EXECUTE v_sql INTO v_count USING p_user_id, p_namespace_id, p_entity_type;
    RETURN COALESCE(v_count, 0);
END;
$$;
```

### 4.3 Helper: refresh_user_stats()

```sql
-- =============================================================================
-- FUNCTION: refresh_user_stats
-- Purpose: Recompute denormalized stats for a user in a namespace
-- =============================================================================

CREATE OR REPLACE FUNCTION refresh_user_stats(
    p_user_id UUID,
    p_namespace_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_earned INT;
    v_total INT;
    v_points INT;
    v_tier TEXT;
BEGIN
    -- Get namespace tier
    SELECT tier INTO v_tier FROM namespaces WHERE id = p_namespace_id;
    
    -- Count earned and total (only achievements available at current tier)
    SELECT 
        COUNT(*) FILTER (WHERE gup.earned_at IS NOT NULL),
        COUNT(*),
        COALESCE(SUM(ga.points) FILTER (WHERE gup.earned_at IS NOT NULL), 0)
    INTO v_earned, v_total, v_points
    FROM gamification_achievements ga
    LEFT JOIN gamification_user_progress gup 
        ON gup.achievement_id = ga.id AND gup.user_id = p_user_id
    WHERE ga.namespace_id = p_namespace_id
      AND ga.is_active = true
      AND tier_meets_minimum(v_tier, ga.minimum_tier);
    
    -- Upsert stats
    INSERT INTO gamification_user_stats (
        namespace_id, user_id,
        total_points, achievements_earned, achievements_total,
        level, completion_percent, updated_at
    ) VALUES (
        p_namespace_id, p_user_id,
        v_points, v_earned, v_total,
        get_gamification_level(v_points),
        CASE WHEN v_total > 0 THEN ROUND((v_earned::numeric / v_total) * 100, 2) ELSE 0 END,
        now()
    )
    ON CONFLICT (user_id, namespace_id) DO UPDATE SET
        total_points = EXCLUDED.total_points,
        achievements_earned = EXCLUDED.achievements_earned,
        achievements_total = EXCLUDED.achievements_total,
        level = EXCLUDED.level,
        completion_percent = EXCLUDED.completion_percent,
        updated_at = now();
END;
$$;
```

### 4.4 Helper: tier_meets_minimum()

```sql
-- =============================================================================
-- FUNCTION: tier_meets_minimum
-- Purpose: Check if a namespace tier meets the minimum required tier
-- =============================================================================

CREATE OR REPLACE FUNCTION tier_meets_minimum(
    p_current_tier TEXT,
    p_minimum_tier TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE p_current_tier
        WHEN 'full'       THEN 4
        WHEN 'enterprise' THEN 3
        WHEN 'pro'        THEN 2
        WHEN 'free'       THEN 1
        ELSE 0
    END >= CASE p_minimum_tier
        WHEN 'full'       THEN 4
        WHEN 'enterprise' THEN 3
        WHEN 'pro'        THEN 2
        WHEN 'free'       THEN 1
        ELSE 0
    END;
$$;
```

### 4.5 Streak Computation

Streaks are computed separately from the main achievement engine because they depend on calendar dates, not audit event counts. Called by the frontend on dashboard load.

```sql
-- =============================================================================
-- FUNCTION: update_streak
-- Purpose: Update login streak for current user
-- Called: On dashboard load (once per session)
-- =============================================================================

CREATE OR REPLACE FUNCTION update_streak(
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS JSONB  -- Returns {current_streak, longest_streak}
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_namespace_id UUID;
    v_stats RECORD;
    v_today DATE := CURRENT_DATE;
    v_new_streak INT;
BEGIN
    SELECT current_namespace_id INTO v_namespace_id
    FROM user_sessions WHERE user_id = p_user_id;
    
    IF v_namespace_id IS NULL THEN
        RETURN '{"current_streak": 0, "longest_streak": 0}'::jsonb;
    END IF;
    
    SELECT * INTO v_stats
    FROM gamification_user_stats
    WHERE user_id = p_user_id AND namespace_id = v_namespace_id;
    
    IF v_stats IS NULL THEN
        -- First time — create stats row
        INSERT INTO gamification_user_stats (namespace_id, user_id, current_streak_days, longest_streak_days, last_active_date)
        VALUES (v_namespace_id, p_user_id, 1, 1, v_today);
        RETURN '{"current_streak": 1, "longest_streak": 1}'::jsonb;
    END IF;
    
    -- Already active today — no change
    IF v_stats.last_active_date = v_today THEN
        RETURN jsonb_build_object(
            'current_streak', v_stats.current_streak_days,
            'longest_streak', v_stats.longest_streak_days
        );
    END IF;
    
    -- Calculate new streak
    IF v_stats.last_active_date = v_today - INTERVAL '1 day' THEN
        v_new_streak := v_stats.current_streak_days + 1;  -- Consecutive day
    ELSE
        v_new_streak := 1;  -- Streak broken
    END IF;
    
    UPDATE gamification_user_stats SET
        current_streak_days = v_new_streak,
        longest_streak_days = GREATEST(longest_streak_days, v_new_streak),
        last_active_date = v_today,
        updated_at = now()
    WHERE user_id = p_user_id AND namespace_id = v_namespace_id;
    
    RETURN jsonb_build_object(
        'current_streak', v_new_streak,
        'longest_streak', GREATEST(v_stats.longest_streak_days, v_new_streak)
    );
END;
$$;
```

---

## 5. Default Achievement Seed Data

Seeded into every new namespace via the namespace creation flow (same pattern as assessment_factors).

### 5.1 Onboarding Achievements (Free Tier)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `first_app` | First Steps | Create your first application | applications | INSERT | 1 | 10 | bronze |
| `first_assessment` | Rated & Ready | Complete your first assessment | deployment_profiles | UPDATE | 1 | 15 | bronze |
| `first_portfolio` | Portfolio Pioneer | Create your first portfolio | portfolios | INSERT | 1 | 10 | bronze |
| `first_invite` | Team Player | Invite your first team member | invitations | INSERT | 1 | 15 | bronze |
| `five_apps` | Building Momentum | Add 5 applications to your inventory | applications | INSERT | 5 | 20 | bronze |
| `first_dp_edit` | Profile Builder | Edit a deployment profile's hosting details | deployment_profiles | UPDATE | 1 | 10 | bronze |

**trigger_condition for `first_assessment`:**
```json
{"changed_fields_contains": ["assessment_status"], "new_values_match": {"assessment_status": "completed"}}
```

**trigger_condition for `first_dp_edit`:**
```json
{"changed_fields_contains": ["hosting_model"]}
```

### 5.2 Data Quality Achievements (Pro Tier)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `assess_10` | Assessment Ace | Complete 10 assessments | deployment_profiles | UPDATE | 10 | 30 | silver |
| `full_workspace` | Complete Coverage | Assess every DP in a workspace | deployment_profiles | UPDATE | 1 | 50 | silver |
| `owner_assigned_10` | Ownership Matters | Assign business owners to 10 applications | application_contacts | INSERT | 10 | 25 | silver |
| `all_portfolios_assigned` | Sorted & Stacked | Assign all DPs to at least one portfolio | portfolio_assignments | INSERT | 1 | 40 | silver |
| `hosting_complete` | Infrastructure Mapped | Fill in hosting details on 10 DPs | deployment_profiles | UPDATE | 10 | 25 | silver |

**Note:** `full_workspace` and `all_portfolios_assigned` use `check_function` conditions because they require cross-entity completeness checks, not simple event counts.

### 5.3 Collaboration Achievements (Enterprise Tier)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `multi_workspace` | Cross-Pollinator | Assess DPs in 3 different workspaces | deployment_profiles | UPDATE | 3 | 40 | gold |
| `invite_5` | Growing the Team | Invite 5 team members | invitations | INSERT | 5 | 30 | gold |
| `twenty_apps` | Serious Inventory | Reach 20 applications in your portfolio | applications | INSERT | 20 | 35 | gold |
| `portfolio_review` | Portfolio Review Champion | Complete assessments for an entire portfolio | deployment_profiles | UPDATE | 1 | 60 | gold |

### 5.4 Mastery Achievements (Full Tier)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `cost_channels` | Cost Connoisseur | Use all 3 cost channels | deployment_profiles | ANY | 1 | 75 | platinum |
| `it_service_created` | Service Architect | Create your first IT Service | it_services | INSERT | 1 | 50 | platinum |
| `integration_mapped` | Connected Thinking | Map your first integration | integrations | INSERT | 1 | 50 | platinum |
| `fifty_apps` | Enterprise Scale | Reach 50 applications | applications | INSERT | 50 | 100 | platinum |
| `full_time_quadrant` | TIME Master | Have applications in all 4 TIME quadrants | deployment_profiles | UPDATE | 1 | 75 | platinum |

### 5.5 Consistency Achievements (All Tiers)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `streak_3` | Getting Consistent | Log in 3 days in a row | — | — | 3 | 15 | bronze |
| `streak_7` | Dedicated | Log in 7 days in a row | — | — | 7 | 30 | silver |
| `streak_30` | Commitment | Log in 30 days in a row | — | — | 30 | 75 | gold |

**Note:** Streak achievements are checked by `update_streak()`, not `check_achievements()`. The streak function updates gamification_user_stats, and a separate check on streak values awards these achievements.

### 5.6 Data Quality Flag Achievements (Pro+ Tiers)

| Code | Name | Description | Entity | Event | Threshold | Points | Badge |
|------|------|-------------|--------|-------|-----------|--------|-------|
| `first_flag` | Eagle Eye | Raise your first data quality flag | flags | INSERT | 1 | 15 | bronze |
| `flag_5` | Data Watchdog | Raise 5 data quality flags | flags | INSERT | 5 | 30 | silver |
| `resolve_flag` | Quick Responder | Resolve your first assigned flag | flags | UPDATE | 1 | 15 | bronze |
| `resolve_10` | Problem Solver | Resolve 10 flags | flags | UPDATE | 10 | 40 | silver |
| `zero_open_flags` | Clean Slate | Resolve all open flags in a workspace | flags | UPDATE | 1 | 60 | gold |

**trigger_condition for `first_flag`:**
```json
{}
```

**trigger_condition for `resolve_flag`:**
```json
{"changed_fields_contains": ["status"], "new_values_match": {"status": "resolved"}}
```

**trigger_condition for `zero_open_flags`:**
```json
{"check_function": "check_achievement_zero_open_flags"}
```

**Note:** Flag achievements reward both reporting AND resolving — both behaviors are valuable for data governance. `zero_open_flags` uses a check function because it requires a workspace-wide completeness check.

---

## 6. RLS Policies

Following the new table checklist (operations/new-table-checklist.md):

```sql
-- =============================================================================
-- RLS: gamification_achievements
-- Pattern: Namespace-scoped read by all authenticated; write by namespace admins
-- =============================================================================

ALTER TABLE gamification_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view achievements in current namespace"
    ON gamification_achievements FOR SELECT
    USING (
        namespace_id = get_current_namespace_id()
        OR check_is_platform_admin()
    );

CREATE POLICY "Admins can insert achievements"
    ON gamification_achievements FOR INSERT
    WITH CHECK (
        namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
    );

CREATE POLICY "Admins can update achievements"
    ON gamification_achievements FOR UPDATE
    USING (
        namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
    )
    WITH CHECK (
        namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
    );

CREATE POLICY "Admins can delete achievements"
    ON gamification_achievements FOR DELETE
    USING (
        namespace_id = get_current_namespace_id()
        AND (check_is_platform_admin() OR check_is_namespace_admin_of_namespace(namespace_id))
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON gamification_achievements TO authenticated;

-- =============================================================================
-- RLS: gamification_user_progress
-- Pattern: Users see own progress; admins see all in namespace
-- =============================================================================

ALTER TABLE gamification_user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
    ON gamification_user_progress FOR SELECT
    USING (
        (user_id = auth.uid() AND namespace_id = get_current_namespace_id())
        OR check_is_platform_admin()
        OR (
            namespace_id = get_current_namespace_id()
            AND check_is_namespace_admin_of_namespace(namespace_id)
        )
    );

-- INSERT/UPDATE/DELETE handled by SECURITY DEFINER RPCs only
CREATE POLICY "System can manage progress"
    ON gamification_user_progress FOR ALL
    USING (check_is_platform_admin());

GRANT SELECT ON gamification_user_progress TO authenticated;
-- No INSERT/UPDATE/DELETE grants — managed by RPCs

-- =============================================================================
-- RLS: gamification_user_stats
-- Pattern: Users see own stats + namespace leaderboard; admins see all
-- =============================================================================

ALTER TABLE gamification_user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view stats in current namespace"
    ON gamification_user_stats FOR SELECT
    USING (
        namespace_id = get_current_namespace_id()
        OR check_is_platform_admin()
    );

-- INSERT/UPDATE handled by SECURITY DEFINER RPCs only
CREATE POLICY "System can manage stats"
    ON gamification_user_stats FOR ALL
    USING (check_is_platform_admin());

GRANT SELECT ON gamification_user_stats TO authenticated;
-- No INSERT/UPDATE/DELETE grants — managed by RPCs
```

---

## 7. Compliance

### 7.1 New Table Checklist Status

| Step | gamification_achievements | gamification_user_progress | gamification_user_stats | flags |
|------|--------------------------|---------------------------|------------------------|-------|
| Schema | ✅ UUID PK, FKs, CHECKs, timestamps | ✅ UUID PK, FKs, timestamps | ✅ UUID PK, FKs, timestamps | ✅ UUID PK, FKs, CHECKs, timestamps |
| GRANTs | ✅ CRUD to authenticated | ✅ SELECT to authenticated | ✅ SELECT to authenticated | ✅ CRUD to authenticated |
| RLS enabled | ✅ | ✅ | ✅ | ✅ |
| RLS policies | ✅ CRUD with namespace + admin scoping | ✅ SELECT own + admin; ALL via platform_admin | ✅ SELECT namespace; ALL via platform_admin | ✅ Namespace-scoped CRUD, reporter + assignee access |
| Platform admin bypass | ✅ check_is_platform_admin() | ✅ check_is_platform_admin() | ✅ check_is_platform_admin() | ✅ check_is_platform_admin() |
| Namespace scoping | ✅ namespace_id FK + RLS | ✅ namespace_id FK + RLS | ✅ namespace_id FK + RLS | ✅ namespace_id + workspace_id FK + RLS |
| updated_at trigger | ✅ | ✅ | ✅ | ✅ |
| Audit trigger | ✅ achievements (config changes are auditable) | ❌ Not needed (high-volume, non-sensitive) | ❌ Not needed (computed rollup) | ✅ Yes (data governance traceability) |

### 7.2 Triggers

```sql
-- updated_at triggers
CREATE TRIGGER update_gamification_achievements_updated_at
    BEFORE UPDATE ON gamification_achievements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gamification_user_progress_updated_at
    BEFORE UPDATE ON gamification_user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gamification_user_stats_updated_at
    BEFORE UPDATE ON gamification_user_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit trigger (config table only)
CREATE TRIGGER audit_gamification_achievements
    AFTER INSERT OR UPDATE OR DELETE ON gamification_achievements
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- Flags triggers
CREATE TRIGGER update_flags_updated_at
    BEFORE UPDATE ON flags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER audit_flags
    AFTER INSERT OR UPDATE OR DELETE ON flags
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
```

### 7.3 Schema Impact

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Tables | 72 | 76 | +4 (gamification_achievements, gamification_user_progress, gamification_user_stats, flags) |
| Table modifications | — | 1 | +1 column on namespaces (enable_achievement_digests) |
| RLS policies | ~290 | ~302 | +12 (8 gamification + 4 flags) |
| Audit triggers | 17 | 19 | +2 (achievements config + flags) |
| Functions | ~89 | ~98 | +9 (gamification engine x6, unsubscribe handler, generate_activity_feed, assign_flag_default) |

---

## 8. Frontend Integration

### 8.1 Call Points

The achievement engine should be called at these moments:

| User Action | What to Call | Where |
|-------------|-------------|-------|
| Dashboard loads | `update_streak()` | Dashboard component mount |
| Save application | `check_achievements()` | After successful save callback |
| Complete assessment | `check_achievements()` | After assessment modal close |
| Create portfolio | `check_achievements()` | After successful save callback |
| Send invitation | `check_achievements()` | After invitation sent |
| Save deployment profile | `check_achievements()` | After successful save callback |
| Create IT service | `check_achievements()` | After successful save callback |
| Create integration | `check_achievements()` | After successful save callback |

### 8.2 Toast Pattern

When `check_achievements()` returns newly earned achievements:

```typescript
// Conceptual — AG prompt will specify exact implementation
interface AchievementToast {
    code: string;
    name: string;
    description: string;
    icon: string;
    badge_tier: 'bronze' | 'silver' | 'gold' | 'platinum';
    points: number;
}

// On receiving newly_earned from RPC:
// Show a slide-in toast for 5 seconds with achievement name + points
// Queue multiple toasts if several achievements earned simultaneously
```

### 8.3 Dashboard Widget

A compact "Your Progress" card on the dashboard sidebar showing:

- Current level name and number (e.g., "Level 4 — Assessment Pro")
- Progress bar to next level
- Completion percentage (e.g., "12 of 28 achievements earned")
- Current streak (e.g., "🔥 5-day streak")
- Link to full achievement wall

### 8.4 Achievement Wall (Profile Page)

A grid of all achievements for the current namespace, grouped by category:

- Earned achievements shown in full color with earned date
- Unearned-but-available shown greyed out with progress indicator (e.g., "3/10")
- Tier-locked achievements shown with lock icon and tier badge (gamified upgrade teaser)

### 8.5 Namespace Leaderboard (Optional, Enterprise+)

A simple ranked list showing top users by total points within the namespace. Available to namespace admins. Uses gamification_user_stats directly — no additional queries needed.

### 8.6 Three-Level Opt-Out

Gamification is opt-in by default at all levels. Users and namespace admins can opt out independently.

**Level 1 — Namespace master switch:**

```sql
-- Schema change on existing namespaces table
ALTER TABLE namespaces 
    ADD COLUMN enable_achievement_digests BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN namespaces.enable_achievement_digests IS 
    'Master switch for all gamification emails in this namespace. '
    'When false, no digest or re-engagement emails are sent to any user. '
    'Gamification UI still works — this only controls email.';
```

Government customers can disable all gamification emails for their namespace in Org Settings. This does NOT disable the in-app gamification UI — only emails.

**Level 2 — User gamification UI opt-out:**

`gamification_user_stats.gamification_opted_out` (default: `false`)

When `true`, the frontend hides all gamification UI for this user: no toasts, no dashboard widget, no achievement wall, no level badge. The achievement engine continues computing silently — progress is always current.

User toggles this from their profile settings. If they opt back in later, all earned achievements appear immediately.

**Level 3 — User email digest opt-out:**

`gamification_user_stats.digest_opted_out` (default: `false`)

When `true`, no weekly digest or re-engagement emails are sent to this user. Independent of Level 2 — a user can opt out of UI but still receive emails, or vice versa.

User toggles this from profile settings or via unsubscribe link in email footer.

**Opt-out matrix:**

| Namespace digests | User gamification | User digest | Result |
|:-:|:-:|:-:|--------|
| ✅ on | ✅ on | ✅ on | Full experience — UI + weekly digest + re-engagement |
| ✅ on | ✅ on | ❌ off | In-app gamification only, no emails |
| ✅ on | ❌ off | ✅ on | No UI, but receives digest + re-engagement emails |
| ✅ on | ❌ off | ❌ off | Complete silence — but engine still computes silently |
| ❌ off | ✅ on | ✅ on | In-app gamification only, namespace blocked emails |
| ❌ off | ❌ off | ❌ off | Complete silence, engine still computes silently |

**Critical design decision — silent computation:** The achievement engine (`check_achievements()`) runs regardless of `gamification_opted_out`. Progress rows in `gamification_user_progress` are always up to date. This enables:

1. Instant opt-back-in — all earned achievements appear immediately
2. Accurate re-engagement emails — "You're 2 assessments away from Assessment Ace"
3. Namespace admin visibility — leaderboard and adoption metrics remain accurate
4. Retroactive awards — if a user completes actions while opted out, they still earn badges

### 8.7 Frontend Opt-Out Implementation

```typescript
// Conceptual — AG prompt will specify exact implementation
// Profile Settings → Notifications & Preferences section

interface GamificationPreferences {
    gamification_opted_out: boolean;  // "Show achievement badges and progress"
    digest_opted_out: boolean;        // "Receive weekly achievement digest email"
}

// Dashboard widget check:
// if (userStats.gamification_opted_out) return null;

// Toast check:
// if (userStats.gamification_opted_out) return; // don't show, but still compute

// check_achievements() is called regardless — frontend just suppresses display
```

---

## 9. Email Communications

### 9.1 Infrastructure

| Component | Technology | Details |
|-----------|------------|---------|
| Email provider | Resend | Transactional email API |
| Trigger | pg_cron (Supabase) | Weekly schedule for digest, daily for re-engagement checks |
| Execution | Supabase Edge Function | Queries eligible users, calls Resend API |
| Templates | Resend templates | Branded GetInSync email templates |
| Unsubscribe | One-click | Sets `digest_opted_out = true` via signed unsubscribe URL |

### 9.2 Weekly Achievement Digest

**Schedule:** Monday morning (8:00 AM recipient's timezone, or UTC if unknown)

**Eligible recipients:**

```sql
-- Users who are digest-eligible and had activity in the past 7 days
SELECT 
    gus.user_id,
    u.email,
    u.display_name,
    gus.total_points,
    gus.level,
    gus.current_streak_days,
    gus.completion_percent,
    n.name AS namespace_name
FROM gamification_user_stats gus
JOIN users u ON u.id = gus.user_id
JOIN namespaces n ON n.id = gus.namespace_id
WHERE n.enable_achievement_digests = true       -- namespace allows emails
  AND gus.digest_opted_out = false              -- user hasn't opted out
  AND gus.last_active_date >= CURRENT_DATE - INTERVAL '7 days')  -- active this week
```

**Digest content (per user):**

- Achievements earned this week (name, badge tier, points)
- Current streak status
- Level progress (e.g., "85 points away from Level 5 — Data Steward")
- Next closest unearned achievement with progress (e.g., "Assessment Ace: 7/10 complete")
- CTA: "Continue in GetInSync →"
- Unsubscribe link in footer

### 9.3 Re-engagement Email

**Schedule:** Daily check, but each user receives at most one re-engagement email per 30-day period.

**Eligible recipients:**

```sql
-- Users dormant 14+ days, with in-progress achievements, not recently emailed
SELECT 
    gus.user_id,
    u.email,
    u.display_name,
    gus.last_active_date,
    n.name AS namespace_name,
    -- Closest unearned achievement
    ga.name AS closest_achievement_name,
    ga.badge_tier AS closest_badge_tier,
    gup.current_count,
    ga.threshold,
    (ga.threshold - gup.current_count) AS remaining
FROM gamification_user_stats gus
JOIN users u ON u.id = gus.user_id
JOIN namespaces n ON n.id = gus.namespace_id
JOIN gamification_user_progress gup ON gup.user_id = gus.user_id
    AND gup.namespace_id = gus.namespace_id
JOIN gamification_achievements ga ON ga.id = gup.achievement_id
WHERE n.enable_achievement_digests = true       -- namespace allows emails
  AND gus.digest_opted_out = false              -- user hasn't opted out
  AND gus.last_active_date < CURRENT_DATE - INTERVAL '14 days'   -- dormant 14+ days
  AND gus.last_active_date > CURRENT_DATE - INTERVAL '90 days'   -- not abandoned (>90 days)
  AND gup.earned_at IS NULL                     -- not yet earned
  AND gup.current_count > 0                     -- they've started progress
  AND gus.last_reengagement_sent_at IS NULL 
      OR gus.last_reengagement_sent_at < CURRENT_DATE - INTERVAL '30 days'
ORDER BY (ga.threshold - gup.current_count) ASC  -- closest to finishing first
LIMIT 1;  -- one achievement per email — lead with the closest
```

**Re-engagement content:**

- Personalized hook: "You're [N] assessments away from earning [Achievement Name] ([Badge Tier])"
- Activity since they left: "Your team has added [X] new applications since [last_active_date]"
- CTA: "Pick up where you left off →"
- Secondary CTA: "View all achievements →"
- Unsubscribe link in footer

### 9.4 Required Schema Addition for Re-engagement Tracking

```sql
-- Add to gamification_user_stats to prevent email spam
ALTER TABLE gamification_user_stats
    ADD COLUMN last_reengagement_sent_at TIMESTAMPTZ;

COMMENT ON COLUMN gamification_user_stats.last_reengagement_sent_at IS
    'Timestamp of last re-engagement email sent. Used to enforce 30-day cooldown. '
    'NULL = never sent.';
```

### 9.5 Unsubscribe Flow

1. Email footer contains signed unsubscribe URL: `https://nextgen.getinsync.ca/unsubscribe?token={signed_token}`
2. Token contains: `user_id`, `namespace_id`, `type` (digest | reengagement | all), `expiry`
3. Landing page shows confirmation: "You've been unsubscribed from achievement digest emails"
4. Sets `gamification_user_stats.digest_opted_out = true`
5. No login required — signed token provides authentication
6. Landing page offers option to re-subscribe

### 9.6 Email Compliance

| Requirement | Implementation |
|-------------|---------------|
| CAN-SPAM / CASL | Unsubscribe link in every email, sender identification, no deceptive subject lines |
| PIPEDA | Canadian data residency — email content generated from ca-central-1 database |
| One-click unsubscribe | RFC 8058 List-Unsubscribe-Post header for email clients that support it |
| Opt-out processing | Honored within 24 hours (immediate in practice — database update) |
| Record keeping | `last_reengagement_sent_at` and `digest_opted_out` provide audit trail |

---

## 10. Data Quality Flags

### 10.1 Purpose

Data quality flags are the governance mechanism that turns GetInSync from a "fill in the form" tool into a living data governance platform. They solve the fundamental problem: the person who notices something wrong is almost never the person responsible for fixing it.

Flags are lightweight, contextual observations attached to any assessable entity — like comments in a Word document, but with assignment and resolution tracking. They are designed to feel like a team standup, not a system log.

### 10.2 Design Decisions

**Flags, not comments.** No threaded replies, no @mentions, no reactions. One row per flag, four lifecycle states. If people need to discuss a flag, they do it in Slack or Teams and come back to resolve it in GetInSync. This keeps it passing the 18-year-old test: "See something wrong? Click the flag icon, pick a category, type a sentence, hit submit."

**Assignment with smart defaults.** When someone flags an application, the default assignee is the business owner contact. When they flag a DP, it's the technical owner. Reporter can override, but the default should be smart. If no owner is assigned, that's itself a "missing info" flag — creating natural pressure to fill in owner information.

**No SLAs, no escalation.** That's GRC territory (same boundary as features/technology-health/risk-boundary.md). GetInSync tracks timestamps on each state transition, giving response time metrics without imposing process. A namespace admin can see "average time to resolve: 4.2 days" and draw their own conclusions.

**Silent lifecycle logging.** Every flag state change writes to audit_logs via the existing trigger. The activity feed, achievement engine, and re-engagement emails all pick it up automatically with zero new instrumentation.

### 10.3 Flag Categories

| Category | Code | Example | Icon |
|----------|------|---------|------|
| **Stale data** | `stale_data` | "This app was decommissioned last month" | clock |
| **Wrong owner** | `wrong_owner` | "Jane left the org, this needs a new owner" | user-x |
| **Planned change** | `planned_change` | "This is moving to Azure in Q3, assessment will change" | calendar |
| **Missing info** | `missing_info` | "No hosting details, can't assess properly" | alert-circle |
| **Correction** | `correction` | "This DP is listed as on-prem but it's actually SaaS" | edit |
| **General** | `general` | Free-text for anything that doesn't fit above | message-circle |

Categories serve two purposes: they make flag creation fast (tap category, type one sentence, assign, done) and they enable data quality reporting by category across the namespace.

### 10.4 Entity Scope

Flags attach to any assessable entity via polymorphic reference:

| Entity | Why Flags Matter |
|--------|-----------------|
| Application | Owner changes, lifecycle events, planned decommission |
| Deployment Profile | Infrastructure changes, wrong hosting details, DR gaps |
| Portfolio | Scope changes, apps that should/shouldn't be included |
| IT Service | Ownership changes, deprecation notices |
| Integration | Broken connections, API changes, vendor sunset |

### 10.5 Lifecycle

```
OPEN → ACKNOWLEDGED → RESOLVED
            ↓
         DISMISSED (with reason)
```

Four states, no branching complexity:

| State | Meaning | Who | Required |
|-------|---------|-----|----------|
| **open** | Flag raised, awaiting response | Reporter creates | summary (required) |
| **acknowledged** | Assignee confirms they've seen it | Assignee | — |
| **resolved** | Issue addressed | Assignee | resolution_note (required) |
| **dismissed** | Not actually a problem | Assignee or admin | resolution_note (required, must explain why) |

Timestamps captured on each transition: `created_at`, `acknowledged_at`, `resolved_at`. These enable response time metrics without imposing SLAs.

### 10.6 Table: flags

```sql
-- =============================================================================
-- TABLE: flags
-- Purpose: Data quality flags — contextual observations with assignment & resolution
-- Scope: Workspace-scoped, namespace-isolated
-- Pattern: Polymorphic entity reference (same as audit_logs)
-- =============================================================================

CREATE TABLE flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    namespace_id UUID NOT NULL REFERENCES namespaces(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    -- What entity is flagged (polymorphic reference)
    entity_type TEXT NOT NULL CHECK (entity_type IN (
        'applications', 'deployment_profiles', 'portfolios',
        'it_services', 'integrations'
    )),
    entity_id UUID NOT NULL,
    entity_name TEXT NOT NULL,            -- Denormalized for feed/email display
    
    -- Flag content
    category TEXT NOT NULL CHECK (category IN (
        'stale_data', 'wrong_owner', 'planned_change',
        'missing_info', 'correction', 'general'
    )),
    summary TEXT NOT NULL,                -- One sentence, required (max 500 chars)
    detail TEXT,                          -- Optional longer explanation
    
    -- People
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
    assignee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- NULL = unassigned
    
    -- Lifecycle
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
        'open', 'acknowledged', 'resolved', 'dismissed'
    )),
    resolution_note TEXT,                 -- Required on resolve/dismiss
    
    -- Timestamps (lifecycle tracking)
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    
    -- Response time (auto-computed on resolution for reporting)
    resolution_hours NUMERIC(10,2)        -- TRIGGER: resolved_at - created_at in hours
);

COMMENT ON TABLE flags IS 
    'Data quality flags — lightweight contextual observations attached to any assessable entity. '
    'Lifecycle: open → acknowledged → resolved/dismissed. Polymorphic entity reference via '
    'entity_type + entity_id (same pattern as audit_logs). Audit-triggered for full traceability. '
    'Feeds into activity feed, achievement engine, and re-engagement emails.';

-- Indexes for common query patterns
CREATE INDEX idx_flags_entity ON flags(entity_type, entity_id);
CREATE INDEX idx_flags_assignee_open ON flags(assignee_id) WHERE status IN ('open', 'acknowledged');
CREATE INDEX idx_flags_workspace_status ON flags(workspace_id, status);
CREATE INDEX idx_flags_namespace_category ON flags(namespace_id, category);
```

### 10.7 Auto-Assignment Function

Default assignee is derived from existing contact roles when the reporter doesn't specify one:

```sql
-- =============================================================================
-- FUNCTION: assign_flag_default
-- Purpose: Auto-assign flag to entity's business owner or technical owner
-- Called: BEFORE INSERT trigger on flags (when assignee_id is NULL)
-- =============================================================================

CREATE OR REPLACE FUNCTION assign_flag_default()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_owner_user_id UUID;
BEGIN
    -- Only auto-assign if no assignee specified
    IF NEW.assignee_id IS NOT NULL THEN
        RETURN NEW;
    END IF;
    
    -- Look up business owner contact for this entity
    -- Check application_contacts for role = 'business_owner'
    IF NEW.entity_type = 'applications' THEN
        SELECT c.user_id INTO v_owner_user_id
        FROM application_contacts ac
        JOIN contacts c ON c.id = ac.contact_id
        WHERE ac.application_id = NEW.entity_id
          AND ac.role = 'business_owner'
        LIMIT 1;
    ELSIF NEW.entity_type = 'deployment_profiles' THEN
        SELECT c.user_id INTO v_owner_user_id
        FROM deployment_profile_contacts dpc
        JOIN contacts c ON c.id = dpc.contact_id
        WHERE dpc.deployment_profile_id = NEW.entity_id
          AND dpc.role IN ('technical_owner', 'business_owner')
        LIMIT 1;
    ELSIF NEW.entity_type = 'it_services' THEN
        SELECT c.user_id INTO v_owner_user_id
        FROM it_service_contacts isc
        JOIN contacts c ON c.id = isc.contact_id
        WHERE isc.it_service_id = NEW.entity_id
          AND isc.role = 'service_owner'
        LIMIT 1;
    END IF;
    
    -- Fall back to NULL (unassigned) if no owner found
    -- Unassigned flags show up in namespace admin feed
    NEW.assignee_id := v_owner_user_id;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER flags_auto_assign
    BEFORE INSERT ON flags
    FOR EACH ROW EXECUTE FUNCTION assign_flag_default();

COMMENT ON FUNCTION assign_flag_default IS 
    'Auto-assigns flags to entity business/technical owner when reporter '
    'does not specify an assignee. Falls back to NULL (unassigned) if no '
    'owner contact is found — unassigned flags surface in namespace admin feed.';
```

### 10.8 Resolution Time Computation

```sql
-- =============================================================================
-- FUNCTION: compute_flag_resolution_hours
-- Purpose: Auto-compute resolution_hours when flag is resolved or dismissed
-- =============================================================================

CREATE OR REPLACE FUNCTION compute_flag_resolution_hours()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set acknowledged_at on first acknowledgement
    IF NEW.status = 'acknowledged' AND OLD.status = 'open' THEN
        NEW.acknowledged_at := COALESCE(NEW.acknowledged_at, now());
    END IF;
    
    -- Set resolved_at and compute resolution_hours on resolution/dismissal
    IF NEW.status IN ('resolved', 'dismissed') AND OLD.status IN ('open', 'acknowledged') THEN
        NEW.resolved_at := COALESCE(NEW.resolved_at, now());
        NEW.resolution_hours := EXTRACT(EPOCH FROM (NEW.resolved_at - NEW.created_at)) / 3600.0;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER flags_compute_resolution
    BEFORE UPDATE ON flags
    FOR EACH ROW EXECUTE FUNCTION compute_flag_resolution_hours();
```

### 10.9 RLS Policies

```sql
-- =============================================================================
-- RLS: flags
-- Pattern: Workspace-scoped. All workspace members can view and create.
-- Only reporter, assignee, workspace admins, and namespace admins can update.
-- =============================================================================

ALTER TABLE flags ENABLE ROW LEVEL SECURITY;

-- SELECT: Any user in the current namespace can view flags in their accessible workspaces
CREATE POLICY "Users can view flags in current namespace"
    ON flags FOR SELECT
    USING (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(namespace_id)
            OR EXISTS (
                SELECT 1 FROM workspace_users wu
                WHERE wu.workspace_id = flags.workspace_id
                  AND wu.user_id = auth.uid()
            )
        )
    );

-- INSERT: Any workspace member can raise a flag
CREATE POLICY "Workspace members can create flags"
    ON flags FOR INSERT
    WITH CHECK (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(namespace_id)
            OR EXISTS (
                SELECT 1 FROM workspace_users wu
                WHERE wu.workspace_id = flags.workspace_id
                  AND wu.user_id = auth.uid()
            )
        )
    );

-- UPDATE: Reporter, assignee, workspace admins, namespace admins
CREATE POLICY "Authorized users can update flags"
    ON flags FOR UPDATE
    USING (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(namespace_id)
            OR reporter_id = auth.uid()
            OR assignee_id = auth.uid()
        )
    )
    WITH CHECK (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(namespace_id)
            OR reporter_id = auth.uid()
            OR assignee_id = auth.uid()
        )
    );

-- DELETE: Namespace admins and platform admins only
CREATE POLICY "Admins can delete flags"
    ON flags FOR DELETE
    USING (
        namespace_id = get_current_namespace_id()
        AND (
            check_is_platform_admin()
            OR check_is_namespace_admin_of_namespace(namespace_id)
        )
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON flags TO authenticated;
```

### 10.10 Namespace Admin Reporting

Aggregate flag metrics provide a data quality health dashboard:

```sql
-- =============================================================================
-- VIEW: flag_summary_by_workspace
-- Purpose: Aggregate flag metrics per workspace for namespace admin reporting
-- =============================================================================

CREATE OR REPLACE VIEW flag_summary_by_workspace
WITH (security_invoker = true)
AS
SELECT
    f.namespace_id,
    f.workspace_id,
    w.name AS workspace_name,
    COUNT(*) FILTER (WHERE f.status = 'open') AS open_flags,
    COUNT(*) FILTER (WHERE f.status = 'acknowledged') AS acknowledged_flags,
    COUNT(*) FILTER (WHERE f.status = 'resolved') AS resolved_flags,
    COUNT(*) FILTER (WHERE f.status = 'dismissed') AS dismissed_flags,
    COUNT(*) AS total_flags,
    ROUND(AVG(f.resolution_hours) FILTER (WHERE f.resolved_at IS NOT NULL), 1) AS avg_resolution_hours,
    COUNT(*) FILTER (WHERE f.assignee_id IS NULL AND f.status = 'open') AS unassigned_open,
    -- Category breakdown
    COUNT(*) FILTER (WHERE f.category = 'stale_data' AND f.status IN ('open', 'acknowledged')) AS stale_data_active,
    COUNT(*) FILTER (WHERE f.category = 'wrong_owner' AND f.status IN ('open', 'acknowledged')) AS wrong_owner_active,
    COUNT(*) FILTER (WHERE f.category = 'planned_change' AND f.status IN ('open', 'acknowledged')) AS planned_change_active,
    COUNT(*) FILTER (WHERE f.category = 'missing_info' AND f.status IN ('open', 'acknowledged')) AS missing_info_active,
    COUNT(*) FILTER (WHERE f.category = 'correction' AND f.status IN ('open', 'acknowledged')) AS correction_active,
    COUNT(*) FILTER (WHERE f.category = 'general' AND f.status IN ('open', 'acknowledged')) AS general_active
FROM flags f
JOIN workspaces w ON w.id = f.workspace_id
GROUP BY f.namespace_id, f.workspace_id, w.name;

COMMENT ON VIEW flag_summary_by_workspace IS
    'Aggregate flag health metrics per workspace. Used by namespace admin '
    'dashboard and Delta for customer success reporting. security_invoker=true.';
```

**Key metrics for Delta and customer success:**

- Average resolution time trend (improving or declining?)
- Open flags by category (what types of data quality issues dominate?)
- Unassigned open flags (governance gaps — no owner to resolve)
- Flags per workspace (which teams have the most stale data?)
- Repeat flags on same entity (chronic problem areas)

### 10.11 Integration with Existing Systems

**Activity Feed:** Flag lifecycle events are the highest-priority feed items (see §11). Create, acknowledge, resolve, and dismiss all appear in the feed for relevant users.

**Achievement Engine:** Five new flag-related achievements (see §5.6) reward both reporting and resolving. The audit trigger on flags means `check_achievements()` picks up flag events automatically.

**Re-engagement Emails:** Open flags assigned to dormant users provide the strongest re-engagement hook: "You have 2 unresolved flags on applications you own. Stuart flagged Oracle EBS 3 days ago: 'Owner Jane retired last month.'" This is a genuine business reason to log in, not just a gamification nudge.

**Tier Alignment:**

| Tier | Flag Capability |
|------|----------------|
| Free | View flags on own workspace entities (read-only) |
| Pro | Create and resolve flags (full lifecycle) |
| Enterprise | Cross-workspace flag visibility, admin reporting |
| Full | Flag analytics, category trend reporting |

### 10.12 Out of Scope (v1)

Explicitly excluded to maintain simplicity:

- Threaded replies (edit the flag or create a new one)
- @mentions (use the feed for notification)
- File attachments (describe the issue in text)
- Priority levels (all flags are equal — org decides urgency)
- SLAs and escalation rules (GRC territory per ADR)
- Email notifications on individual flags (use the feed + digest instead)
- Approval workflows (acknowledge → resolve is sufficient)
- Flag templates (categories provide enough structure)

---

## 11. Activity Feed

### 11.1 Purpose

The activity feed completes the engagement triangle: achievements reward action, flags create action items, and the feed provides context for both. It answers "what happened while I was away?" in a format that feels like a team standup, not a system log.

### 11.2 Design Decisions

**Computed on demand, not materialized.** The feed depends on `last_active_date` which changes every session. Materializing means constantly recomputing for every user. Instead, `generate_activity_feed()` runs on dashboard load with client-side caching so it doesn't recompute on every tab switch.

**Aggregation is critical.** Raw audit_log entries are useless as feed content. "INSERT on applications" fifty times means nothing. The feed aggregates: "Sarah added 12 applications to Finance workspace this week." Events are grouped by actor + entity_type + time bucket.

**Time bucketing adapts to absence duration.** Away 2 days → group by day. Away 2 weeks → group by week. Away 1 month → monthly highlights. A user returning from vacation sees 5-8 meaningful summary cards, not 200 raw events.

**RLS-native.** Feed queries join through workspace_users, so users only see activity in workspaces they have access to. No separate permission model needed.

### 11.3 Feed Card Types

| Type | Priority | Example | Source |
|------|----------|---------|-------|
| **personal** | Highest | "3 of your applications were reassessed" | audit_logs where entity_id in user's owned apps/DPs |
| **flag_assigned** | Highest | "Stuart flagged Oracle EBS: 'Owner Jane retired'" | flags where assignee_id = current user |
| **team** | Medium | "Sarah completed 8 assessments in Finance" | audit_logs grouped by user + action |
| **flag_activity** | Medium | "5 flags were resolved in Finance this week" | flags aggregated by workspace |
| **milestone** | Medium | "85% assessment completion reached" | Computed from aggregate queries |
| **achievement_social** | Low | "Sarah earned Assessment Ace (Silver)" | gamification_user_progress.earned_at |
| **welcome_back** | One-time | "You've been away 5 days. Here's what happened" | Computed from last_active_date |

**"About you" items are pinned to the top** — changes to entities where the user is business owner or assignee appear first, visually distinct. This is the LinkedIn "someone viewed your profile" equivalent.

### 11.4 Feed Generation RPC

```sql
-- =============================================================================
-- FUNCTION: generate_activity_feed
-- Purpose: Generate personalized activity feed for current user
-- Called: On dashboard load (client-side cached, debounced)
-- Returns: JSONB array of feed cards, capped at 20 items
-- =============================================================================

CREATE OR REPLACE FUNCTION generate_activity_feed(
    p_user_id UUID DEFAULT auth.uid(),
    p_limit INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_namespace_id UUID;
    v_last_active DATE;
    v_since TIMESTAMPTZ;
    v_bucket TEXT;  -- 'day', 'week', 'month'
    v_feed JSONB := '[]'::jsonb;
    v_personal JSONB;
    v_flags JSONB;
    v_team JSONB;
    v_milestones JSONB;
    v_days_away INT;
BEGIN
    -- Get current context
    SELECT current_namespace_id INTO v_namespace_id
    FROM user_sessions WHERE user_id = p_user_id;
    
    IF v_namespace_id IS NULL THEN
        RETURN '[]'::jsonb;
    END IF;
    
    -- Get last active date
    SELECT last_active_date INTO v_last_active
    FROM gamification_user_stats
    WHERE user_id = p_user_id AND namespace_id = v_namespace_id;
    
    -- Default to 7 days ago if no prior activity
    v_last_active := COALESCE(v_last_active, CURRENT_DATE - INTERVAL '7 days');
    v_since := v_last_active::timestamptz;
    v_days_away := CURRENT_DATE - v_last_active;
    
    -- Cap at 90 days (don't scan entire audit history)
    IF v_since < now() - INTERVAL '90 days' THEN
        v_since := now() - INTERVAL '90 days';
    END IF;
    
    -- Determine time bucket based on absence duration
    v_bucket := CASE
        WHEN v_days_away <= 3  THEN 'day'
        WHEN v_days_away <= 21 THEN 'week'
        ELSE 'month'
    END;
    
    -- ── PRIORITY 1: Personal items (changes to entities you own) ──
    SELECT COALESCE(jsonb_agg(item), '[]'::jsonb) INTO v_personal
    FROM (
        SELECT jsonb_build_object(
            'type', 'personal',
            'icon', CASE al.entity_type
                WHEN 'applications' THEN 'app-window'
                WHEN 'deployment_profiles' THEN 'server'
                WHEN 'portfolios' THEN 'folder-kanban'
                ELSE 'file'
            END,
            'headline', format('%s was %s',
                al.entity_name,
                CASE al.event_type
                    WHEN 'UPDATE' THEN 'updated'
                    WHEN 'DELETE' THEN 'removed'
                    ELSE 'modified'
                END
            ),
            'detail', array_to_string(al.changed_fields, ', '),
            'actor', u.display_name,
            'timestamp', al.created_at,
            'entity_type', al.entity_type,
            'entity_id', al.entity_id
        ) AS item
        FROM audit_logs al
        LEFT JOIN users u ON u.id = al.user_id
        WHERE al.namespace_id = v_namespace_id
          AND al.created_at > v_since
          AND al.user_id != p_user_id  -- Not your own actions
          AND al.entity_type IN ('applications', 'deployment_profiles')
          -- Entity is owned by current user (via contact roles)
          AND EXISTS (
              SELECT 1 FROM application_contacts ac
              JOIN contacts c ON c.id = ac.contact_id
              WHERE ac.application_id = al.entity_id
                AND c.user_id = p_user_id
                AND ac.role = 'business_owner'
          )
        ORDER BY al.created_at DESC
        LIMIT 5
    ) sub;
    
    -- ── PRIORITY 2: Flags assigned to you ──
    SELECT COALESCE(jsonb_agg(item), '[]'::jsonb) INTO v_flags
    FROM (
        SELECT jsonb_build_object(
            'type', 'flag_assigned',
            'icon', CASE f.category
                WHEN 'stale_data' THEN 'clock'
                WHEN 'wrong_owner' THEN 'user-x'
                WHEN 'planned_change' THEN 'calendar'
                WHEN 'missing_info' THEN 'alert-circle'
                WHEN 'correction' THEN 'edit'
                ELSE 'message-circle'
            END,
            'headline', format('%s flagged %s', ru.display_name, f.entity_name),
            'detail', f.summary,
            'actor', ru.display_name,
            'timestamp', f.created_at,
            'entity_type', f.entity_type,
            'entity_id', f.entity_id,
            'flag_id', f.id,
            'category', f.category,
            'status', f.status
        ) AS item
        FROM flags f
        JOIN users ru ON ru.id = f.reporter_id
        WHERE f.assignee_id = p_user_id
          AND f.namespace_id = v_namespace_id
          AND f.status IN ('open', 'acknowledged')
        ORDER BY f.created_at DESC
        LIMIT 5
    ) sub;
    
    -- ── PRIORITY 3: Team activity (aggregated) ──
    SELECT COALESCE(jsonb_agg(item), '[]'::jsonb) INTO v_team
    FROM (
        SELECT jsonb_build_object(
            'type', 'team',
            'icon', CASE al.entity_type
                WHEN 'applications' THEN 'app-window'
                WHEN 'deployment_profiles' THEN 'server'
                WHEN 'flags' THEN 'flag'
                ELSE 'activity'
            END,
            'headline', format('%s %s %s %s',
                u.display_name,
                CASE al.event_type WHEN 'INSERT' THEN 'added' WHEN 'UPDATE' THEN 'updated' WHEN 'DELETE' THEN 'removed' END,
                COUNT(*),
                al.entity_type
            ),
            'actor', u.display_name,
            'timestamp', MAX(al.created_at),
            'count', COUNT(*)
        ) AS item
        FROM audit_logs al
        JOIN users u ON u.id = al.user_id
        WHERE al.namespace_id = v_namespace_id
          AND al.created_at > v_since
          AND al.user_id != p_user_id
          AND al.entity_type IN ('applications', 'deployment_profiles', 'portfolios', 'flags', 'it_services')
          -- Only workspaces user has access to
          AND (al.workspace_id IS NULL OR EXISTS (
              SELECT 1 FROM workspace_users wu
              WHERE wu.workspace_id = al.workspace_id
                AND wu.user_id = p_user_id
          ))
        GROUP BY u.display_name, al.entity_type, al.event_type,
                 -- Time bucket grouping
                 CASE v_bucket
                     WHEN 'day' THEN al.created_at::date::text
                     WHEN 'week' THEN date_trunc('week', al.created_at)::date::text
                     ELSE date_trunc('month', al.created_at)::date::text
                 END
        ORDER BY MAX(al.created_at) DESC
        LIMIT 10
    ) sub;
    
    -- ── Combine and sort by priority then timestamp ──
    v_feed := v_personal || v_flags || v_team;
    
    -- Sort combined feed: personal first, then flags, then team, each by timestamp desc
    SELECT COALESCE(jsonb_agg(item ORDER BY 
        CASE item->>'type'
            WHEN 'personal' THEN 1
            WHEN 'flag_assigned' THEN 2
            WHEN 'team' THEN 3
            WHEN 'milestone' THEN 4
            ELSE 5
        END,
        (item->>'timestamp')::timestamptz DESC
    ), '[]'::jsonb)
    INTO v_feed
    FROM jsonb_array_elements(v_feed) AS item
    LIMIT p_limit;
    
    RETURN v_feed;
END;
$$;

COMMENT ON FUNCTION generate_activity_feed IS 
    'Generates personalized activity feed for dashboard. Combines personal changes '
    '(entities you own), assigned flags, and team activity. Aggregates by actor + '
    'entity_type + time bucket. RLS-native via workspace_users join. Capped at 90 days '
    'lookback, 20 items returned. SECURITY DEFINER to read audit_logs.';
```

### 11.5 Feed UI Layout

On the dashboard, the feed occupies the right panel or a tabbed view:

**Top section — Gamification progress widget:**
- Current level, streak, next achievement (from gamification_user_stats)

**Below — Activity feed (scrolling):**
- "About you" cards (personal + flag_assigned) pinned at top with accent border
- Team activity cards
- Milestone cards
- Each card: icon | headline | one-line detail | timestamp | subtle "→" link

**Empty state (new user):**
- "Welcome! As your team starts working, you'll see activity here."
- Show onboarding achievements as suggested next steps instead

### 11.6 Feed Opt-Out

The activity feed respects the gamification opt-out at the UI level. If `gamification_opted_out = true`, the full feed panel is hidden. However, **flag assignments are always visible** regardless of gamification opt-out — assigned flags are governance items, not gamification. They appear in a separate "Your Open Flags" section that persists even when the feed is hidden.

---

## 12. Seed Function

Achievement definitions are seeded on namespace creation, mirroring the assessment_factors seed pattern:

```sql
-- =============================================================================
-- FUNCTION: seed_gamification_achievements
-- Purpose: Create default achievements for a new namespace
-- Called: From namespace creation flow (after seed_assessment_factors)
-- =============================================================================

CREATE OR REPLACE FUNCTION seed_gamification_achievements(
    p_namespace_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO gamification_achievements 
        (namespace_id, code, name, description, icon, category, badge_tier,
         trigger_entity_type, trigger_event_type, trigger_condition,
         threshold, points, minimum_tier, sort_order)
    VALUES
        -- Onboarding (Free)
        (p_namespace_id, 'first_app', 'First Steps', 'Create your first application', 'app-window', 'onboarding', 'bronze', 'applications', 'INSERT', '{}', 1, 10, 'free', 1),
        (p_namespace_id, 'first_assessment', 'Rated & Ready', 'Complete your first assessment', 'clipboard-check', 'onboarding', 'bronze', 'deployment_profiles', 'UPDATE', '{"changed_fields_contains": ["assessment_status"], "new_values_match": {"assessment_status": "completed"}}', 1, 15, 'free', 2),
        (p_namespace_id, 'first_portfolio', 'Portfolio Pioneer', 'Create your first portfolio', 'folder-kanban', 'onboarding', 'bronze', 'portfolios', 'INSERT', '{}', 1, 10, 'free', 3),
        (p_namespace_id, 'first_invite', 'Team Player', 'Invite your first team member', 'user-plus', 'onboarding', 'bronze', 'invitations', 'INSERT', '{}', 1, 15, 'free', 4),
        (p_namespace_id, 'five_apps', 'Building Momentum', 'Add 5 applications to your inventory', 'layers', 'onboarding', 'bronze', 'applications', 'INSERT', '{"distinct_entities": true}', 5, 20, 'free', 5),
        (p_namespace_id, 'first_dp_edit', 'Profile Builder', 'Edit a deployment profile hosting details', 'server', 'onboarding', 'bronze', 'deployment_profiles', 'UPDATE', '{"changed_fields_contains": ["hosting_model"]}', 1, 10, 'free', 6),
        
        -- Data Quality (Pro)
        (p_namespace_id, 'assess_10', 'Assessment Ace', 'Complete 10 assessments', 'bar-chart-3', 'data_quality', 'silver', 'deployment_profiles', 'UPDATE', '{"changed_fields_contains": ["assessment_status"], "new_values_match": {"assessment_status": "completed"}, "distinct_entities": true}', 10, 30, 'pro', 10),
        (p_namespace_id, 'full_workspace', 'Complete Coverage', 'Assess every DP in a workspace', 'check-circle', 'data_quality', 'silver', 'deployment_profiles', 'UPDATE', '{"check_function": "check_achievement_full_workspace"}', 1, 50, 'pro', 11),
        (p_namespace_id, 'hosting_complete', 'Infrastructure Mapped', 'Fill in hosting details on 10 DPs', 'cloud', 'data_quality', 'silver', 'deployment_profiles', 'UPDATE', '{"changed_fields_contains": ["hosting_model"], "distinct_entities": true}', 10, 25, 'pro', 12),
        
        -- Collaboration (Enterprise)
        (p_namespace_id, 'multi_workspace', 'Cross-Pollinator', 'Assess DPs in 3 different workspaces', 'git-branch', 'collaboration', 'gold', 'deployment_profiles', 'UPDATE', '{"check_function": "check_achievement_multi_workspace"}', 3, 40, 'enterprise', 20),
        (p_namespace_id, 'invite_5', 'Growing the Team', 'Invite 5 team members', 'users', 'collaboration', 'gold', 'invitations', 'INSERT', '{"distinct_entities": true}', 5, 30, 'enterprise', 21),
        (p_namespace_id, 'twenty_apps', 'Serious Inventory', 'Reach 20 applications', 'database', 'collaboration', 'gold', 'applications', 'INSERT', '{"distinct_entities": true}', 20, 35, 'enterprise', 22),
        
        -- Mastery (Full)
        (p_namespace_id, 'cost_channels', 'Cost Connoisseur', 'Use all 3 cost channels', 'dollar-sign', 'mastery', 'platinum', 'deployment_profiles', 'ANY', '{"check_function": "check_achievement_cost_channels"}', 1, 75, 'full', 30),
        (p_namespace_id, 'it_service_created', 'Service Architect', 'Create your first IT Service', 'server-cog', 'mastery', 'platinum', 'it_services', 'INSERT', '{}', 1, 50, 'full', 31),
        (p_namespace_id, 'integration_mapped', 'Connected Thinking', 'Map your first integration', 'link', 'mastery', 'platinum', 'integrations', 'INSERT', '{}', 1, 50, 'full', 32),
        (p_namespace_id, 'fifty_apps', 'Enterprise Scale', 'Reach 50 applications', 'building', 'mastery', 'platinum', 'applications', 'INSERT', '{"distinct_entities": true}', 50, 100, 'full', 33),
        
        -- Data Quality Flags (Pro+)
        (p_namespace_id, 'first_flag', 'Eagle Eye', 'Raise your first data quality flag', 'flag', 'data_quality', 'bronze', 'flags', 'INSERT', '{}', 1, 15, 'pro', 40),
        (p_namespace_id, 'flag_5', 'Data Watchdog', 'Raise 5 data quality flags', 'flag', 'data_quality', 'silver', 'flags', 'INSERT', '{"distinct_entities": true}', 5, 30, 'pro', 41),
        (p_namespace_id, 'resolve_flag', 'Quick Responder', 'Resolve your first assigned flag', 'check-circle', 'data_quality', 'bronze', 'flags', 'UPDATE', '{"changed_fields_contains": ["status"], "new_values_match": {"status": "resolved"}}', 1, 15, 'pro', 42),
        (p_namespace_id, 'resolve_10', 'Problem Solver', 'Resolve 10 flags', 'shield-check', 'data_quality', 'silver', 'flags', 'UPDATE', '{"changed_fields_contains": ["status"], "new_values_match": {"status": "resolved"}, "distinct_entities": true}', 10, 40, 'pro', 43),
        (p_namespace_id, 'zero_open_flags', 'Clean Slate', 'Resolve all open flags in a workspace', 'sparkles', 'data_quality', 'gold', 'flags', 'UPDATE', '{"check_function": "check_achievement_zero_open_flags"}', 1, 60, 'enterprise', 44);
        
    -- Streak achievements are tracked separately via update_streak()
    -- and awarded by a wrapper that checks gamification_user_stats.current_streak_days
END;
$$;
```

---

## 13. Implementation Phases

### Phase 1: Foundation (2-3 days) — Target: Demo-ready for Knowledge 2026

1. Deploy 4 tables + RLS + triggers (follow new table checklist): gamification_achievements, gamification_user_progress, gamification_user_stats, flags
2. Deploy core functions (get_gamification_level, tier_meets_minimum, count_qualifying_events, check_achievements, refresh_user_stats, update_streak, assign_flag_default, compute_flag_resolution_hours)
3. Add seed_gamification_achievements() call to namespace creation
4. Seed existing namespaces (City of Riverside, Gov of Alberta)
5. Build achievement toast component (AG prompt)
6. Add check_achievements() calls to save handlers
7. Build dashboard progress widget (AG prompt)

**Deliverable:** Users earn badges, see toasts, view progress on dashboard.

### Phase 2: Achievement Wall + Flags UI (2-3 days)

1. Build achievement wall page (profile or dedicated route)
2. Category grouping with tier-locked badges visible
3. Progress indicators on unearned achievements
4. Earned date display
5. Build flag creation UI — flag icon on application/DP/portfolio detail pages
6. Flag lifecycle UI — acknowledge/resolve/dismiss with resolution note
7. "Your Open Flags" panel (visible regardless of gamification opt-out)

**Deliverable:** Full achievement browsing + users can raise and resolve data quality flags.

### Phase 3: Activity Feed + Leaderboard (2-3 days)

1. Deploy generate_activity_feed() RPC
2. Deploy flag_summary_by_workspace view
3. Build activity feed panel on dashboard (scrolling, card-based)
4. Personal items pinned to top, team activity below
5. Flag assignments integrated into feed
6. Namespace leaderboard (Enterprise+ feature gate)
7. Streak display on dashboard
8. Level badge on user avatar/profile

**Deliverable:** Users see "what happened while you were away" on every dashboard load. Feed includes flag activity. Namespace admins see flag health metrics.

### Phase 4: Weekly Achievement Digest (1-2 days)

1. Add `enable_achievement_digests` column to namespaces table
2. Build Supabase Edge Function for digest email generation
3. Create Resend email template (branded, responsive)
4. Set up pg_cron weekly schedule (Monday 8:00 AM UTC)
5. Build digest-eligible user query (§9.2)
6. Add unsubscribe URL generation with signed tokens
7. Build unsubscribe landing page
8. Add digest/gamification opt-out toggles to profile settings UI

**Deliverable:** Active users receive weekly achievement summary emails. Namespace admins can disable for their org.

### Phase 5: Re-engagement Emails (1-2 days)

1. Add `last_reengagement_sent_at` column to gamification_user_stats
2. Build re-engagement eligible user query (§9.3)
3. Create re-engagement Resend template ("pick up where you left off")
4. Set up pg_cron daily schedule for dormancy check
5. Implement 30-day cooldown logic
6. Add team activity summary to email content (new apps since last visit)
7. Include open flag count in re-engagement emails ("You have 2 unresolved flags")

**Deliverable:** Dormant users receive personalized "you're X away from Y achievement" emails with open flag counts and 30-day cooldown.

### Phase 6: Flag Reporting + Admin Dashboard (1-2 days)

1. Namespace admin flag health dashboard (open/resolved/avg resolution time)
2. Flag category breakdown charts
3. Repeat flag detection (same entity flagged multiple times)
4. Unassigned flag alerts for namespace admins
5. Export flag data for customer success reporting (Delta)

**Deliverable:** Namespace admins see data quality health metrics. Delta can report "average resolution time improved from 8 to 3 days."

### Phase 7: Advanced Achievements + Custom Flags (Future)

1. Complex check functions (full_workspace, cost_channels, multi_workspace, zero_open_flags)
2. Custom achievement definitions (namespace admin UI)
3. Retroactive achievement computation for existing namespaces
4. Custom flag categories (namespace admin configurable)
5. Flag auto-creation rules (e.g., auto-flag apps with no owner after 30 days)

---

## 14. Demo Namespace Seeding

For City of Riverside demo, pre-earn some achievements and create sample flags to showcase both features:

```sql
-- After seeding gamification_achievements for Riverside:
-- Manually insert progress records with earned_at set
-- to show a realistic-looking achievement wall

-- Create sample flags to demonstrate data governance:
-- 1. Stale data flag on a decommissioned app (resolved)
-- 2. Wrong owner flag where someone left (acknowledged)  
-- 3. Planned change flag for cloud migration (open)
-- This shows the full lifecycle in one demo namespace
```

Specific demo data will be added to `schema/demo-namespace-template.sql` when gamification and flags ship.

---

## 15. Open Questions

| # | Question | Options | Recommendation |
|---|----------|---------|----------------|
| 1 | Should achievements persist if namespace downgrades tier? | Keep earned / revoke / hide | **Keep earned** — never take away something someone earned |
| 2 | Should check_achievements run on a cron schedule too? | Yes (belt + suspenders) / No (frontend-only) | **Yes** — add pg_cron job as Phase 2 insurance |
| 3 | Custom achievements for namespace admins? | Now / Later | **Later** — ship defaults first, iterate based on feedback |
| 4 | ~~Email digest of achievements?~~ | ~~Now / Later~~ | **✅ RESOLVED v1.1** — Resend integration designed. Weekly digest (Phase 4) + re-engagement (Phase 5). Opt-in by default, three-level opt-out. |
| 5 | Should leaderboard show real names or anonymized? | Real names / Initials | **Real names within namespace** — they're colleagues |
| 6 | Re-engagement dormancy threshold? | 7 / 14 / 21 / 30 days | **14 days** — long enough to not annoy, short enough to re-engage before they forget the platform |
| 7 | Re-engagement cooldown period? | 14 / 30 / 60 days | **30 days** — one email per month maximum for dormant users |
| 8 | Should namespace admins see individual opt-out status? | Yes / No | **No** — privacy. Admins see aggregate adoption metrics, not individual email preferences |
| 9 | Abandoned user threshold (stop emailing entirely)? | 60 / 90 / 180 days | **90 days** — if they haven't logged in for 3 months, stop emailing |
| 10 | Should flags support reassignment? | Reporter can reassign / Only admins / No reassignment | **Reporter + admins can reassign** — reporter knows context best, admin handles escalation |
| 11 | Flag notification to assignee? | In-app only / Email per flag / Batch in digest | **In-app via feed + batch in weekly digest** — no per-flag emails (too noisy) |
| 12 | Auto-flag stale data? | Auto-create flags for apps with no activity in 90 days / Manual only | **Later (Phase 7)** — get manual flagging right first, then automate |
| 13 | Should namespace admins control flag categories? | Fixed categories / Admin-configurable | **Fixed for v1** — 6 categories cover 95% of cases. Custom categories in Phase 7 |
| 14 | Activity feed: show other users' achievements? | Yes (social proof) / No (privacy) | **Yes, within namespace** — "Sarah earned Assessment Ace" creates healthy motivation |
| 15 | Should the feed show deletions? | Yes / Only to admins / No | **Only to entity owners + admins** — "Your application Oracle EBS was removed" is important context |

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| v1.2 | 2026-02-14 | Data Quality Flags architecture (§10): flags table with polymorphic entity reference, 6 categories, 4-state lifecycle (open→acknowledged→resolved/dismissed), auto-assignment from contact roles, resolution time tracking, flag_summary_by_workspace reporting view. Activity Feed architecture (§11): generate_activity_feed() RPC with time-bucketed aggregation, personal/flag/team/milestone card types, RLS-native workspace scoping. 5 new flag-related achievements (§5.6). Feed opt-out respects gamification toggle but flag assignments always visible. Implementation phases reorganized: 7 phases (was 6). Added Open Questions #10-15. Schema impact: +1 table (flags), +2 audit triggers, +2 functions, +4 RLS policies, +1 view. |
| v1.1 | 2026-02-14 | Three-level opt-out architecture (namespace → user gamification → user digest). Silent computation design decision. Email communications section: weekly digest via Resend (Phase 4), re-engagement emails with 30-day cooldown (Phase 5). Added gamification_opted_out, digest_opted_out, last_reengagement_sent_at to user_stats. Added enable_achievement_digests to namespaces. Unsubscribe flow with signed tokens. CASL/CAN-SPAM compliance. Resolved Open Question #4. Added Open Questions #6-9. |
| v1.0 | 2026-02-14 | Initial architecture. 3 tables, 6 functions, 16 default achievements across 4 tiers. Audit-log-driven event sourcing. Tier-aligned achievement visibility. Phase 1 targets Knowledge 2026 demo readiness. |

---

*Document: features/gamification/architecture.md*  
*SOC2 Controls: CC6.6 (flags audit trigger for data governance traceability)*  
*February 2026*
