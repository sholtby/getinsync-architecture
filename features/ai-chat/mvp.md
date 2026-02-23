# GetInSync APM Chat - MVP Implementation
**Version:** 1.0 (Ship Fast Edition)  
**Date:** January 2026  
**Goal:** Working AI chat in 1-2 weeks, multi-cloud later

---

## What We're Building

A chat interface where users ask questions about their APM data in plain English:

```
User: "Which apps should we migrate?"
AI: "Based on your TIME assessments, 12 applications are marked for migration..."

User: "Generate a SWOT for Finance workspace"
AI: "## SWOT Analysis for Finance
     **Strengths:** 3 apps marked for Investment..."
```

---

## Architecture (Simplified)

```
┌─────────────────────────────────────────────────┐
│  React Frontend                                 │
│  └── <ApmChatPanel />                          │
└─────────────────┬───────────────────────────────┘
                  │ POST /functions/v1/apm-chat
┌─────────────────▼───────────────────────────────┐
│  Supabase Edge Function                         │
│  1. Embed query (OpenAI)                        │
│  2. Hybrid search (pgvector + FTS)              │
│  3. Build prompt + call Claude                  │
│  4. Stream response                             │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│  Supabase PostgreSQL                            │
│  ├── apm_embeddings (vectors + full-text)       │
│  └── Your existing APM tables                   │
└─────────────────────────────────────────────────┘
```

---

## Step 1: Database Setup (15 minutes)

Run this SQL in Supabase SQL Editor:

```sql
-- ============================================
-- GETINSYNC APM CHAT - DATABASE SETUP
-- ============================================

-- 1. Enable required extensions
create extension if not exists vector;
create extension if not exists pg_trgm;

-- 2. Create embeddings table
create table if not exists apm_embeddings (
  id uuid default gen_random_uuid() primary key,
  namespace_id uuid not null references namespaces(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  
  -- What entity this embedding represents
  entity_type text not null,  -- 'application', 'deployment_profile', 'software_product', 'it_service'
  entity_id uuid not null,
  
  -- The actual content and embedding
  content text not null,
  embedding vector(1536),  -- OpenAI text-embedding-3-small dimension
  
  -- Full-text search support
  content_tsv tsvector generated always as (to_tsvector('english', content)) stored,
  
  -- Extra metadata for filtering
  metadata jsonb default '{}',
  
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  -- One embedding per entity
  unique(namespace_id, entity_type, entity_id)
);

-- 3. Create indexes
create index if not exists idx_apm_embeddings_vector 
  on apm_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 100);

create index if not exists idx_apm_embeddings_fts 
  on apm_embeddings using gin(content_tsv);

create index if not exists idx_apm_embeddings_namespace 
  on apm_embeddings(namespace_id);

create index if not exists idx_apm_embeddings_workspace 
  on apm_embeddings(workspace_id);

create index if not exists idx_apm_embeddings_type 
  on apm_embeddings(entity_type);

-- 4. Enable RLS
alter table apm_embeddings enable row level security;

create policy "Namespace isolation" on apm_embeddings
  for all using (namespace_id = (auth.jwt()->>'namespace_id')::uuid);

-- 5. Create hybrid search function (vector + keyword with RRF)
create or replace function search_apm(
  p_query text,
  p_query_embedding vector(1536),
  p_namespace_id uuid,
  p_workspace_id uuid default null,
  p_limit int default 10
)
returns table (
  entity_type text,
  entity_id uuid,
  workspace_id uuid,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
security definer
as $$
begin
  return query
  with
  -- Vector similarity search
  vector_matches as (
    select
      e.entity_type,
      e.entity_id,
      e.workspace_id,
      e.content,
      e.metadata,
      1 - (e.embedding <=> p_query_embedding) as vec_score,
      row_number() over (order by e.embedding <=> p_query_embedding) as vec_rank
    from apm_embeddings e
    where e.namespace_id = p_namespace_id
      and (p_workspace_id is null or e.workspace_id = p_workspace_id)
    order by e.embedding <=> p_query_embedding
    limit p_limit * 3
  ),
  
  -- Full-text search
  text_matches as (
    select
      e.entity_type,
      e.entity_id,
      e.workspace_id,
      e.content,
      e.metadata,
      ts_rank_cd(e.content_tsv, websearch_to_tsquery('english', p_query)) as text_score,
      row_number() over (
        order by ts_rank_cd(e.content_tsv, websearch_to_tsquery('english', p_query)) desc
      ) as text_rank
    from apm_embeddings e
    where e.namespace_id = p_namespace_id
      and (p_workspace_id is null or e.workspace_id = p_workspace_id)
      and e.content_tsv @@ websearch_to_tsquery('english', p_query)
    limit p_limit * 3
  ),
  
  -- Combine with Reciprocal Rank Fusion
  combined as (
    select
      coalesce(v.entity_type, t.entity_type) as entity_type,
      coalesce(v.entity_id, t.entity_id) as entity_id,
      coalesce(v.workspace_id, t.workspace_id) as workspace_id,
      coalesce(v.content, t.content) as content,
      coalesce(v.metadata, t.metadata) as metadata,
      -- RRF score: 1/(k+rank) for each result set, k=60 is standard
      coalesce(1.0 / (60 + v.vec_rank), 0) + 
      coalesce(1.0 / (60 + t.text_rank), 0) as rrf_score,
      v.vec_score
    from vector_matches v
    full outer join text_matches t 
      on v.entity_id = t.entity_id and v.entity_type = t.entity_type
  )
  
  select
    c.entity_type,
    c.entity_id,
    c.workspace_id,
    c.content,
    c.metadata,
    coalesce(c.vec_score, c.rrf_score)::float as similarity
  from combined c
  order by c.rrf_score desc
  limit p_limit;
end;
$$;

-- 6. Simple chat usage tracking
create table if not exists apm_chat_usage (
  id uuid default gen_random_uuid() primary key,
  namespace_id uuid not null references namespaces(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  query text not null,
  tokens_used integer,
  created_at timestamptz default now()
);

create index if not exists idx_chat_usage_namespace 
  on apm_chat_usage(namespace_id, created_at);

alter table apm_chat_usage enable row level security;

create policy "Namespace isolation" on apm_chat_usage
  for all using (namespace_id = (auth.jwt()->>'namespace_id')::uuid);
```

---

## Step 2: Edge Function - Embed Entity (10 minutes)

Create `supabase/functions/embed-entity/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { entity_type, entity_id, namespace_id, action } = await req.json();

  // Handle deletes
  if (action === "delete") {
    await supabase
      .from("apm_embeddings")
      .delete()
      .eq("namespace_id", namespace_id)
      .eq("entity_type", entity_type)
      .eq("entity_id", entity_id);
    
    return Response.json({ success: true, action: "deleted" });
  }

  // Build content based on entity type
  const { content, metadata, workspaceId } = await buildContent(
    supabase,
    entity_type,
    entity_id
  );

  // Generate embedding
  const embeddingRes = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "text-embedding-3-small",
      input: content,
    }),
  });

  const { data } = await embeddingRes.json();
  const embedding = data[0].embedding;

  // Upsert embedding
  await supabase.from("apm_embeddings").upsert(
    {
      namespace_id,
      workspace_id: workspaceId,
      entity_type,
      entity_id,
      content,
      embedding,
      metadata,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "namespace_id,entity_type,entity_id" }
  );

  return Response.json({ success: true, action: "upserted" });
});

// ============================================
// CONTENT BUILDERS
// ============================================

async function buildContent(
  supabase: any,
  entityType: string,
  entityId: string
): Promise<{ content: string; metadata: Record<string, any>; workspaceId: string }> {
  
  switch (entityType) {
    case "application":
      return buildApplicationContent(supabase, entityId);
    case "deployment_profile":
      return buildDeploymentProfileContent(supabase, entityId);
    case "software_product":
      return buildSoftwareProductContent(supabase, entityId);
    case "it_service":
      return buildItServiceContent(supabase, entityId);
    default:
      throw new Error(`Unknown entity type: ${entityType}`);
  }
}

async function buildApplicationContent(supabase: any, appId: string) {
  const { data: app } = await supabase
    .from("applications")
    .select(`
      *,
      workspace:workspaces(id, name, namespace_id),
      deployment_profiles(
        name, environment, hosting_type, cloud_provider,
        assessment_status, estimated_tech_debt
      ),
      portfolio_assignments(
        time_quadrant, paid_quadrant, business_score, technical_score,
        criticality_score, tech_risk_score,
        portfolio:portfolios(name)
      ),
      application_contacts(
        role_type, is_primary,
        contact:contacts(display_name)
      )
    `)
    .eq("id", appId)
    .single();

  if (!app) throw new Error(`Application ${appId} not found`);

  const dp = app.deployment_profiles?.[0];
  const pa = app.portfolio_assignments?.[0];
  const owner = app.application_contacts?.find(
    (c: any) => c.role_type === "business_owner" && c.is_primary
  );

  const content = `
APPLICATION: ${app.name}
App ID: ${app.app_id}
Workspace: ${app.workspace?.name}
Description: ${app.description || "No description"}

LIFECYCLE & ASSESSMENT:
- Lifecycle Status: ${app.lifecycle_status || "Not set"}
- TIME Quadrant: ${pa?.time_quadrant || "Not assessed"}
- PAID Quadrant: ${pa?.paid_quadrant || "Not assessed"}
- Portfolio: ${pa?.portfolio?.name || "Default"}
- Business Score: ${pa?.business_score ?? "N/A"}
- Technical Score: ${pa?.technical_score ?? "N/A"}
- Criticality: ${pa?.criticality_score ?? "N/A"}

FINANCIALS:
- Annual Cost: $${(app.annual_cost || 0).toLocaleString()}
- Budget: $${(app.budget_amount || 0).toLocaleString()}
- Tech Debt: $${(dp?.estimated_tech_debt || 0).toLocaleString()}

DEPLOYMENT:
- Environment: ${dp?.environment || "N/A"}
- Hosting: ${dp?.hosting_type || "N/A"}
- Cloud: ${dp?.cloud_provider || "N/A"}
- Assessment Status: ${dp?.assessment_status || "N/A"}

OWNERSHIP:
- Business Owner: ${owner?.contact?.display_name || app.owner || "Not assigned"}
- Support: ${app.primary_support || "Not assigned"}
  `.trim();

  return {
    content,
    metadata: {
      time_quadrant: pa?.time_quadrant,
      lifecycle_status: app.lifecycle_status,
      has_tech_debt: (dp?.estimated_tech_debt || 0) > 0,
      annual_cost: app.annual_cost,
    },
    workspaceId: app.workspace?.id,
  };
}

async function buildDeploymentProfileContent(supabase: any, dpId: string) {
  const { data: dp } = await supabase
    .from("deployment_profiles")
    .select(`
      *,
      application:applications(name, app_id),
      workspace:workspaces(id, name, namespace_id),
      software:deployment_profile_software_products(
        deployed_version, annual_cost,
        software_product:software_products(name, lifecycle_state)
      ),
      tech:deployment_profile_technology_products(
        technology_product:technology_products(name)
      )
    `)
    .eq("id", dpId)
    .single();

  if (!dp) throw new Error(`Deployment Profile ${dpId} not found`);

  const softwareList = dp.software
    ?.map((s: any) => `  - ${s.software_product?.name} v${s.deployed_version || "?"}`)
    .join("\n") || "  None";

  const techList = dp.tech
    ?.map((t: any) => `  - ${t.technology_product?.name}`)
    .join("\n") || "  None";

  const content = `
DEPLOYMENT PROFILE: ${dp.name}
Application: ${dp.application?.name || "Standalone"} (ID: ${dp.application?.app_id || "N/A"})
Workspace: ${dp.workspace?.name}
Type: ${dp.dp_type}

INFRASTRUCTURE:
- Environment: ${dp.environment}
- Hosting: ${dp.hosting_type || "N/A"}
- Cloud Provider: ${dp.cloud_provider || "N/A"}
- Region: ${dp.region || "N/A"}
- DR Status: ${dp.dr_status || "N/A"}

ASSESSMENT:
- Status: ${dp.assessment_status}
- Tech Debt: $${(dp.estimated_tech_debt || 0).toLocaleString()}
- Remediation Effort: ${dp.remediation_effort || "Not estimated"}

SOFTWARE:
${softwareList}

TECHNOLOGY:
${techList}
  `.trim();

  return {
    content,
    metadata: {
      dp_type: dp.dp_type,
      environment: dp.environment,
      assessment_status: dp.assessment_status,
      has_tech_debt: (dp.estimated_tech_debt || 0) > 0,
    },
    workspaceId: dp.workspace?.id,
  };
}

async function buildSoftwareProductContent(supabase: any, productId: string) {
  const { data: product } = await supabase
    .from("software_products")
    .select(`
      *,
      owner_workspace:workspaces(id, name, namespace_id),
      manufacturer:organizations!manufacturer_org_id(name),
      deployments:deployment_profile_software_products(
        deployed_version, annual_cost, contract_end_date,
        deployment_profile:deployment_profiles(
          name,
          application:applications(name)
        )
      )
    `)
    .eq("id", productId)
    .single();

  if (!product) throw new Error(`Software Product ${productId} not found`);

  const deploymentList = product.deployments
    ?.map((d: any) => {
      const appName = d.deployment_profile?.application?.name || "Infrastructure";
      return `  - ${appName}: v${d.deployed_version || "?"}, $${(d.annual_cost || 0).toLocaleString()}/yr`;
    })
    .join("\n") || "  Not deployed";

  const totalCost = product.deployments?.reduce(
    (sum: number, d: any) => sum + (d.annual_cost || 0),
    0
  ) || 0;

  const content = `
SOFTWARE PRODUCT: ${product.name}
Owner: ${product.owner_workspace?.name}
Manufacturer: ${product.manufacturer?.name || "Unknown"}
Lifecycle: ${product.lifecycle_state}

DESCRIPTION:
${product.description || "No description"}

COST:
- Catalog Price: $${(product.annual_cost || 0).toLocaleString()}/yr
- Total Deployed: $${totalCost.toLocaleString()}/yr
- Deployments: ${product.deployments?.length || 0}

DEPLOYED TO:
${deploymentList}
  `.trim();

  return {
    content,
    metadata: {
      lifecycle_state: product.lifecycle_state,
      total_cost: totalCost,
      deployment_count: product.deployments?.length || 0,
    },
    workspaceId: product.owner_workspace?.id,
  };
}

async function buildItServiceContent(supabase: any, serviceId: string) {
  const { data: service } = await supabase
    .from("it_services")
    .select(`
      *,
      owner_workspace:workspaces(id, name, namespace_id),
      service_type:service_types(name, category:service_type_categories(name)),
      consumers:deployment_profile_it_services(
        deployment_profile:deployment_profiles(
          name,
          application:applications(name)
        )
      )
    `)
    .eq("id", serviceId)
    .single();

  if (!service) throw new Error(`IT Service ${serviceId} not found`);

  const consumerList = service.consumers
    ?.map((c: any) => {
      const appName = c.deployment_profile?.application?.name || "Infrastructure";
      return `  - ${appName}`;
    })
    .join("\n") || "  No consumers";

  const content = `
IT SERVICE: ${service.name}
Owner: ${service.owner_workspace?.name || "Central"}
Category: ${service.service_type?.category?.name || "Uncategorized"}
Type: ${service.service_type?.name || "Unknown"}

DESCRIPTION:
${service.description || "No description"}

DETAILS:
- Lifecycle: ${service.lifecycle_state || "Active"}
- Cost Model: ${service.cost_model || "N/A"}
- Annual Cost: $${(service.annual_cost || 0).toLocaleString()}

CONSUMED BY:
${consumerList}
  `.trim();

  return {
    content,
    metadata: {
      lifecycle_state: service.lifecycle_state,
      cost_model: service.cost_model,
      consumer_count: service.consumers?.length || 0,
    },
    workspaceId: service.owner_workspace?.id,
  };
}
```

---

## Step 3: Edge Function - Chat API (15 minutes)

Create `supabase/functions/apm-chat/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  // Auth
  const authHeader = req.headers.get("Authorization")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const namespaceId = user.user_metadata.namespace_id;
  const { query, workspace_id, conversation_history = [] } = await req.json();

  // 1. Generate query embedding
  const embeddingRes = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "text-embedding-3-small",
      input: query,
    }),
  });

  const { data: embData } = await embeddingRes.json();
  const queryEmbedding = embData[0].embedding;

  // 2. Hybrid search
  const { data: searchResults } = await supabase.rpc("search_apm", {
    p_query: query,
    p_query_embedding: queryEmbedding,
    p_namespace_id: namespaceId,
    p_workspace_id: workspace_id || null,
    p_limit: 10,
  });

  // 3. Build context
  const context = searchResults
    ?.map((r: any) => `[${r.entity_type.toUpperCase()}]\n${r.content}`)
    .join("\n\n---\n\n") || "No relevant data found.";

  // 4. Build system prompt
  const systemPrompt = `You are an APM (Application Portfolio Management) assistant for GetInSync.
You help users understand their application portfolio, technologies, assessments, and technical debt.

<terminology>
- TIME Quadrants: Tolerate (maintain minimally), Invest (strategic), Migrate (modernize), Eliminate (retire)
- PAID Quadrants: Protect, Advance, Innovate, Divest
- B-Scores (B01-B10): Business assessment factors
- T-Scores (T01-T15): Technical assessment factors
- Deployment Profile: WHERE an app runs (environment, hosting, tech stack)
- Workspace: Organizational unit (ministry, department, team)
</terminology>

<context>
${context}
</context>

<guidelines>
- Be concise and actionable
- Reference specific applications, technologies, or services by name
- If data is missing, acknowledge it
- For SWOT requests, structure as Strengths/Weaknesses/Opportunities/Threats
- Suggest follow-up questions when helpful
- Don't make up data - only use what's in the context
</guidelines>`;

  // 5. Stream response
  const stream = await anthropic.messages.stream({
    model: "claude-sonnet-4-20250514",
    max_tokens: 2048,
    system: systemPrompt,
    messages: [
      ...conversation_history.slice(-10),
      { role: "user", content: query },
    ],
  });

  // 6. Log usage
  supabase.from("apm_chat_usage").insert({
    namespace_id: namespaceId,
    user_id: user.id,
    query,
  });

  const encoder = new TextEncoder();
  const readable = new ReadableStream({
    async start(controller) {
      for await (const event of stream) {
        if (
          event.type === "content_block_delta" &&
          event.delta.type === "text_delta"
        ) {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ text: event.delta.text })}\n\n`)
          );
        }
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });

  return new Response(readable, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Access-Control-Allow-Origin": "*",
    },
  });
});
```

---

## Step 4: Database Triggers (5 minutes)

Run in SQL Editor:

```sql
-- ============================================
-- AUTO-SYNC TRIGGERS
-- ============================================

-- Trigger function to queue embedding updates
create or replace function trigger_embedding_update()
returns trigger as $$
declare
  v_namespace_id uuid;
  v_action text := 'upsert';
begin
  -- Get namespace_id
  if TG_TABLE_NAME = 'applications' then
    select namespace_id into v_namespace_id 
    from workspaces 
    where id = coalesce(NEW.workspace_id, OLD.workspace_id);
  elsif TG_TABLE_NAME = 'deployment_profiles' then
    select namespace_id into v_namespace_id 
    from workspaces 
    where id = coalesce(NEW.workspace_id, OLD.workspace_id);
  elsif TG_TABLE_NAME in ('software_products', 'it_services') then
    v_namespace_id := coalesce(NEW.namespace_id, OLD.namespace_id);
  end if;

  if TG_OP = 'DELETE' then
    v_action := 'delete';
  end if;

  -- Call edge function via pg_net
  perform net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/embed-entity',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.service_role_key')
    ),
    body := jsonb_build_object(
      'entity_type', TG_ARGV[0],
      'entity_id', coalesce(NEW.id, OLD.id),
      'namespace_id', v_namespace_id,
      'action', v_action
    )
  );

  return coalesce(NEW, OLD);
end;
$$ language plpgsql security definer;

-- Create triggers
drop trigger if exists embed_applications on applications;
create trigger embed_applications
  after insert or update or delete on applications
  for each row execute function trigger_embedding_update('application');

drop trigger if exists embed_deployment_profiles on deployment_profiles;
create trigger embed_deployment_profiles
  after insert or update or delete on deployment_profiles
  for each row execute function trigger_embedding_update('deployment_profile');

drop trigger if exists embed_software_products on software_products;
create trigger embed_software_products
  after insert or update or delete on software_products
  for each row execute function trigger_embedding_update('software_product');

drop trigger if exists embed_it_services on it_services;
create trigger embed_it_services
  after insert or update or delete on it_services
  for each row execute function trigger_embedding_update('it_service');

-- Also re-embed apps when their portfolio assignments change
drop trigger if exists embed_portfolio_assignments on portfolio_assignments;
create trigger embed_portfolio_assignments
  after insert or update on portfolio_assignments
  for each row execute function trigger_embedding_update('application');
```

---

## Step 5: React Component (15 minutes)

Create `components/ApmChatPanel.tsx`:

```tsx
import { useState, useRef, useEffect } from "react";
import { supabase } from "../lib/supabase";

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
}

interface Props {
  workspaceId?: string;
  className?: string;
}

export function ApmChatPanel({ workspaceId, className = "" }: Props) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const sendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage = input.trim();
    const userMsgId = crypto.randomUUID();

    setInput("");
    setMessages((prev) => [...prev, { id: userMsgId, role: "user", content: userMessage }]);
    setIsLoading(true);

    try {
      const { data: { session } } = await supabase.auth.getSession();

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/apm-chat`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${session?.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            query: userMessage,
            workspace_id: workspaceId,
            conversation_history: messages.slice(-10).map((m) => ({
              role: m.role,
              content: m.content,
            })),
          }),
        }
      );

      if (!response.ok) throw new Error("Chat request failed");

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      let assistantMessage = "";
      const assistantMsgId = crypto.randomUUID();

      setMessages((prev) => [...prev, { id: assistantMsgId, role: "assistant", content: "" }]);

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        for (const line of chunk.split("\n")) {
          if (line.startsWith("data: ") && line !== "data: [DONE]") {
            try {
              const { text } = JSON.parse(line.slice(6));
              if (text) {
                assistantMessage += text;
                setMessages((prev) =>
                  prev.map((m) =>
                    m.id === assistantMsgId ? { ...m, content: assistantMessage } : m
                  )
                );
              }
            } catch {
              // Skip malformed lines
            }
          }
        }
      }
    } catch (error) {
      setMessages((prev) => [
        ...prev,
        {
          id: crypto.randomUUID(),
          role: "assistant",
          content: "Sorry, something went wrong. Please try again.",
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const suggestions = [
    "Which applications are marked for migration?",
    "Show me high-priority tech debt items",
    "What technologies are approaching end-of-life?",
    "Generate a SWOT for this workspace",
  ];

  return (
    <div className={`flex flex-col h-[600px] bg-white rounded-lg border shadow-sm ${className}`}>
      {/* Header */}
      <div className="px-4 py-3 border-b bg-gray-50 rounded-t-lg flex justify-between items-center">
        <div>
          <h3 className="font-semibold text-gray-800">APM Assistant</h3>
          <p className="text-sm text-gray-500">Ask questions about your portfolio</p>
        </div>
        <button
          onClick={() => setMessages([])}
          className="text-sm text-gray-500 hover:text-gray-700"
        >
          Clear
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-400 mt-8">
            <p className="mb-4">Try asking:</p>
            <div className="space-y-2 max-w-sm mx-auto">
              {suggestions.map((s, i) => (
                <button
                  key={i}
                  onClick={() => setInput(s)}
                  className="block w-full text-left px-3 py-2 text-sm bg-gray-50 
                           hover:bg-blue-50 hover:text-blue-700 rounded-lg"
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}

        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={`max-w-[80%] px-4 py-2 rounded-2xl ${
                msg.role === "user"
                  ? "bg-blue-600 text-white rounded-br-sm"
                  : "bg-gray-100 text-gray-800 rounded-bl-sm"
              }`}
            >
              <p className="whitespace-pre-wrap text-sm">{msg.content}</p>
            </div>
          </div>
        ))}

        {isLoading && messages[messages.length - 1]?.role === "user" && (
          <div className="flex justify-start">
            <div className="bg-gray-100 px-4 py-2 rounded-2xl rounded-bl-sm">
              <div className="flex space-x-1">
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:0.1s]" />
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce [animation-delay:0.2s]" />
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-4 border-t">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && sendMessage()}
            placeholder="Ask about applications, tech debt, assessments..."
            className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={isLoading}
          />
          <button
            onClick={sendMessage}
            disabled={isLoading || !input.trim()}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 
                     disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## Step 6: Backfill Existing Data (One-time)

Create a script to embed all existing entities:

```typescript
// scripts/backfill-embeddings.ts
// Run with: npx ts-node scripts/backfill-embeddings.ts

import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const FUNCTION_URL = `${process.env.SUPABASE_URL}/functions/v1/embed-entity`;

async function backfill() {
  console.log("Starting backfill...");

  // Get all namespaces
  const { data: namespaces } = await supabase.from("namespaces").select("id");

  for (const ns of namespaces || []) {
    console.log(`\nProcessing namespace: ${ns.id}`);

    // Applications
    const { data: apps } = await supabase
      .from("applications")
      .select("id, workspace:workspaces(namespace_id)")
      .eq("workspace.namespace_id", ns.id);

    for (const app of apps || []) {
      await fetch(FUNCTION_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          entity_type: "application",
          entity_id: app.id,
          namespace_id: ns.id,
        }),
      });
      console.log(`  ✓ Application: ${app.id}`);
    }

    // Deployment Profiles
    const { data: dps } = await supabase
      .from("deployment_profiles")
      .select("id, workspace:workspaces(namespace_id)")
      .eq("workspace.namespace_id", ns.id);

    for (const dp of dps || []) {
      await fetch(FUNCTION_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          entity_type: "deployment_profile",
          entity_id: dp.id,
          namespace_id: ns.id,
        }),
      });
      console.log(`  ✓ Deployment Profile: ${dp.id}`);
    }

    // Software Products
    const { data: products } = await supabase
      .from("software_products")
      .select("id")
      .eq("namespace_id", ns.id);

    for (const product of products || []) {
      await fetch(FUNCTION_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          entity_type: "software_product",
          entity_id: product.id,
          namespace_id: ns.id,
        }),
      });
      console.log(`  ✓ Software Product: ${product.id}`);
    }

    // IT Services
    const { data: services } = await supabase
      .from("it_services")
      .select("id")
      .eq("namespace_id", ns.id);

    for (const service of services || []) {
      await fetch(FUNCTION_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          entity_type: "it_service",
          entity_id: service.id,
          namespace_id: ns.id,
        }),
      });
      console.log(`  ✓ IT Service: ${service.id}`);
    }
  }

  console.log("\n✅ Backfill complete!");
}

backfill().catch(console.error);
```

---

## Step 7: Environment Variables

Add to Supabase Dashboard → Edge Functions → Secrets:

```
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

Add to your app settings:

```
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

---

## Step 8: Deploy Edge Functions

```bash
# Deploy embed function
supabase functions deploy embed-entity --no-verify-jwt

# Deploy chat function  
supabase functions deploy apm-chat
```

---

## Step 9: Test It!

1. Run the backfill script to embed existing data
2. Add `<ApmChatPanel />` to your app
3. Ask: "Which applications are marked for migration?"

---

## What's Included

✅ **Hybrid search** (vector + keyword with RRF)  
✅ **Streaming responses** (real-time typing effect)  
✅ **Auto-sync** (triggers update embeddings on data changes)  
✅ **Multi-tenant** (namespace-scoped, RLS enforced)  
✅ **Conversation history** (context-aware follow-ups)  
✅ **Usage tracking** (for billing/limits later)

## What's NOT Included (Add Later)

- ❌ Reranking (Cohere) — adds ~10-30% accuracy, ~$10/mo
- ❌ SWOT structured analysis — needs dedicated function
- ❌ Multi-cloud providers — see v3 architecture
- ❌ Usage limits/billing — add when you monetize
- ❌ Evaluation framework — add when you need to iterate

---

## Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| OpenAI Embeddings (5K entities) | ~$2 |
| Claude Sonnet (500 chats) | ~$15-30 |
| Supabase (existing plan) | $0 incremental |
| **Total** | **~$20-35/mo** |

---

## Checklist

- [ ] Run database setup SQL
- [ ] Create `embed-entity` Edge Function
- [ ] Create `apm-chat` Edge Function
- [ ] Run trigger setup SQL
- [ ] Add environment secrets
- [ ] Deploy Edge Functions
- [ ] Run backfill script
- [ ] Add `<ApmChatPanel />` to UI
- [ ] Test with real queries
- [ ] Ship it! 🚀

---

*MVP Implementation — January 2026*
*Time to implement: ~2-4 hours*
*Time to production: ~1-2 weeks with testing*
