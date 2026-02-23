# GetInSync APM Chat - Multi-Cloud Architecture
**Version:** 3.0  
**Date:** January 2026  
**Based on:** NextGen Schema (2026-01-25)

---

## Executive Summary

This document defines an AI-powered APM chat feature with a **provider-agnostic architecture** that supports:

| Tier | AI Provider | Target Customer |
|------|-------------|-----------------|
| **Essentials** | Supabase (pgvector + Edge Functions) | SMB, startups |
| **Plus** | Supabase (enhanced) | Mid-market |
| **Enterprise** | Customer's Azure or AWS | Government, regulated industries |

The architecture uses a **Provider Abstraction Layer** so the React frontend and core business logic remain unchanged regardless of where the AI/RAG infrastructure runs.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GetInSync Frontend (React/Antigravity)               │
│                              <ApmChatPanel />                               │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ POST /api/chat
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                         GetInSync Chat Gateway                              │
│                    (Supabase Edge Function or API Route)                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Provider Abstraction Layer                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐  │   │
│  │  │  Supabase   │  │    Azure    │  │     AWS     │  │   Custom   │  │   │
│  │  │  Provider   │  │  Provider   │  │  Provider   │  │  Provider  │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬──────┘  │   │
│  └─────────┼────────────────┼────────────────┼───────────────┼─────────┘   │
└────────────┼────────────────┼────────────────┼───────────────┼─────────────┘
             │                │                │               │
             ▼                ▼                ▼               ▼
┌────────────────────┐ ┌─────────────────┐ ┌──────────────────┐ ┌────────────┐
│ Supabase           │ │ Azure           │ │ AWS              │ │ Customer   │
│ ├─ pgvector        │ │ ├─ AI Search    │ │ ├─ OpenSearch    │ │ Custom     │
│ ├─ Edge Functions  │ │ ├─ OpenAI       │ │ ├─ Bedrock       │ │ Endpoint   │
│ └─ Claude API      │ │ └─ Blob Storage │ │ └─ S3            │ │            │
└────────────────────┘ └─────────────────┘ └──────────────────┘ └────────────┘
             ▲                ▲                ▲
             │                │                │
             └────────────────┴────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Data Sync Layer  │
                    │  (Event-driven)   │
                    └─────────┬─────────┘
                              │
              ┌───────────────▼───────────────┐
              │   GetInSync Core (Supabase)   │
              │   Source of Truth for APM     │
              │   ├─ applications             │
              │   ├─ deployment_profiles      │
              │   ├─ portfolio_assignments    │
              │   ├─ software_products        │
              │   ├─ it_services              │
              │   └─ namespace_settings       │
              └───────────────────────────────┘
```

---

## 1. Provider Abstraction Layer

### 1.1 Provider Interface

All AI providers implement this TypeScript interface:

```typescript
// lib/ai-providers/types.ts

export interface SearchResult {
  entityType: 'application' | 'deployment_profile' | 'software_product' | 'it_service' | 'technology_product';
  entityId: string;
  workspaceId: string;
  content: string;
  metadata: Record<string, any>;
  similarity: number;
}

export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ChatRequest {
  query: string;
  namespaceId: string;
  workspaceId?: string;
  conversationHistory?: ChatMessage[];
  options?: {
    maxResults?: number;
    entityTypes?: string[];
    streamResponse?: boolean;
  };
}

export interface ChatResponse {
  content: string;
  sources: SearchResult[];
  usage?: {
    promptTokens: number;
    completionTokens: number;
  };
}

export interface EmbeddingRequest {
  entityType: string;
  entityId: string;
  namespaceId: string;
  workspaceId: string;
  content: string;
  metadata: Record<string, any>;
}

export interface ApmAiProvider {
  // Provider identification
  readonly name: string;
  readonly version: string;
  
  // Core operations
  search(query: string, namespaceId: string, options?: SearchOptions): Promise<SearchResult[]>;
  chat(request: ChatRequest): Promise<ChatResponse>;
  chatStream(request: ChatRequest): AsyncGenerator<string>;
  
  // Embedding management
  upsertEmbedding(request: EmbeddingRequest): Promise<void>;
  deleteEmbedding(entityType: string, entityId: string, namespaceId: string): Promise<void>;
  
  // Health & diagnostics
  healthCheck(): Promise<{ healthy: boolean; latencyMs: number }>;
}

export interface SearchOptions {
  workspaceId?: string;
  entityTypes?: string[];
  maxResults?: number;
  minSimilarity?: number;
  includeMetadataFilter?: Record<string, any>;
}
```

### 1.2 Provider Factory

```typescript
// lib/ai-providers/factory.ts

import { ApmAiProvider } from './types';
import { SupabaseProvider } from './supabase-provider';
import { AzureProvider } from './azure-provider';
import { AwsProvider } from './aws-provider';

export type ProviderType = 'supabase' | 'azure' | 'aws' | 'custom';

export interface ProviderConfig {
  type: ProviderType;
  
  // Supabase config
  supabaseUrl?: string;
  supabaseKey?: string;
  
  // Azure config
  azureSearchEndpoint?: string;
  azureSearchKey?: string;
  azureOpenAiEndpoint?: string;
  azureOpenAiKey?: string;
  azureOpenAiDeployment?: string;
  
  // AWS config
  awsRegion?: string;
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  opensearchEndpoint?: string;
  bedrockModelId?: string;
  
  // Custom endpoint
  customEndpoint?: string;
  customApiKey?: string;
}

export function createProvider(config: ProviderConfig): ApmAiProvider {
  switch (config.type) {
    case 'supabase':
      return new SupabaseProvider(config);
    case 'azure':
      return new AzureProvider(config);
    case 'aws':
      return new AwsProvider(config);
    case 'custom':
      return new CustomEndpointProvider(config);
    default:
      throw new Error(`Unknown provider type: ${config.type}`);
  }
}

// Get provider for a specific namespace (tenant)
export async function getProviderForNamespace(
  supabase: SupabaseClient,
  namespaceId: string
): Promise<ApmAiProvider> {
  // Fetch namespace AI settings
  const { data: settings } = await supabase
    .from('namespace_settings')
    .select('ai_provider_config')
    .eq('namespace_id', namespaceId)
    .single();
  
  if (!settings?.ai_provider_config) {
    // Default to Supabase provider
    return createProvider({
      type: 'supabase',
      supabaseUrl: Deno.env.get('SUPABASE_URL'),
      supabaseKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
    });
  }
  
  return createProvider(settings.ai_provider_config);
}
```

---

## 2. Supabase Provider (Default)

Enhanced with hybrid search and reranking.

### 2.1 Database Schema Additions

```sql
-- Enable extensions
create extension if not exists vector;
create extension if not exists pg_trgm;  -- For fuzzy text search

-- Main embeddings table with FTS support
create table apm_embeddings (
  id uuid default gen_random_uuid() primary key,
  namespace_id uuid not null references namespaces(id) on delete cascade,
  workspace_id uuid references workspaces(id) on delete cascade,
  
  entity_type text not null,
  entity_id uuid not null,
  
  -- Embedding data
  content text not null,
  embedding vector(1536),
  
  -- Full-text search
  content_tsv tsvector generated always as (to_tsvector('english', content)) stored,
  
  -- Metadata for filtering
  metadata jsonb default '{}',
  
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  unique(namespace_id, entity_type, entity_id)
);

-- Indexes
create index idx_apm_embeddings_vector 
  on apm_embeddings using ivfflat (embedding vector_cosine_ops) with (lists = 100);
create index idx_apm_embeddings_fts 
  on apm_embeddings using gin(content_tsv);
create index idx_apm_embeddings_trgm 
  on apm_embeddings using gin(content gin_trgm_ops);
create index idx_apm_embeddings_namespace 
  on apm_embeddings(namespace_id);
create index idx_apm_embeddings_workspace 
  on apm_embeddings(workspace_id);
create index idx_apm_embeddings_metadata 
  on apm_embeddings using gin(metadata);

-- RLS
alter table apm_embeddings enable row level security;

create policy "Namespace isolation" on apm_embeddings
  for all using (namespace_id = (auth.jwt()->>'namespace_id')::uuid);


-- Namespace AI settings table
create table namespace_ai_settings (
  id uuid default gen_random_uuid() primary key,
  namespace_id uuid not null references namespaces(id) on delete cascade unique,
  
  -- Provider configuration
  provider_type text not null default 'supabase',
  provider_config jsonb default '{}',
  
  -- Feature flags
  chat_enabled boolean default true,
  swot_enabled boolean default true,
  impact_analysis_enabled boolean default true,
  
  -- Usage limits
  monthly_chat_limit integer default 1000,
  current_month_usage integer default 0,
  
  -- Audit
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table namespace_ai_settings enable row level security;

create policy "Namespace admins only" on namespace_ai_settings
  for all using (
    namespace_id = (auth.jwt()->>'namespace_id')::uuid
    and (auth.jwt()->>'role')::text in ('admin', 'owner')
  );
```

### 2.2 Hybrid Search Function (BM25 + Vector + RRF)

```sql
-- Reciprocal Rank Fusion for combining search results
create or replace function hybrid_search_apm(
  p_query text,
  p_query_embedding vector(1536),
  p_namespace_id uuid,
  p_workspace_id uuid default null,
  p_entity_types text[] default null,
  p_limit int default 20,
  p_vector_weight float default 0.5,  -- Weight for vector vs keyword results
  p_rrf_k int default 60  -- RRF constant (typically 60)
)
returns table (
  entity_type text,
  entity_id uuid,
  workspace_id uuid,
  content text,
  metadata jsonb,
  vector_rank int,
  keyword_rank int,
  rrf_score float,
  vector_similarity float
)
language plpgsql
security definer
as $$
begin
  return query
  with
  -- Vector search results
  vector_results as (
    select
      e.entity_type,
      e.entity_id,
      e.workspace_id,
      e.content,
      e.metadata,
      1 - (e.embedding <=> p_query_embedding) as similarity,
      row_number() over (order by e.embedding <=> p_query_embedding) as rank
    from apm_embeddings e
    where e.namespace_id = p_namespace_id
      and (p_workspace_id is null or e.workspace_id = p_workspace_id)
      and (p_entity_types is null or e.entity_type = any(p_entity_types))
    order by e.embedding <=> p_query_embedding
    limit p_limit * 2
  ),
  
  -- Keyword search results (BM25-style via ts_rank)
  keyword_results as (
    select
      e.entity_type,
      e.entity_id,
      e.workspace_id,
      e.content,
      e.metadata,
      ts_rank_cd(e.content_tsv, websearch_to_tsquery('english', p_query)) as ts_score,
      row_number() over (
        order by ts_rank_cd(e.content_tsv, websearch_to_tsquery('english', p_query)) desc
      ) as rank
    from apm_embeddings e
    where e.namespace_id = p_namespace_id
      and (p_workspace_id is null or e.workspace_id = p_workspace_id)
      and (p_entity_types is null or e.entity_type = any(p_entity_types))
      and e.content_tsv @@ websearch_to_tsquery('english', p_query)
    order by ts_score desc
    limit p_limit * 2
  ),
  
  -- Combine with RRF
  combined as (
    select
      coalesce(v.entity_type, k.entity_type) as entity_type,
      coalesce(v.entity_id, k.entity_id) as entity_id,
      coalesce(v.workspace_id, k.workspace_id) as workspace_id,
      coalesce(v.content, k.content) as content,
      coalesce(v.metadata, k.metadata) as metadata,
      v.rank as vector_rank,
      k.rank as keyword_rank,
      v.similarity as vector_similarity,
      -- RRF score calculation
      (
        coalesce(p_vector_weight / (p_rrf_k + v.rank), 0) +
        coalesce((1 - p_vector_weight) / (p_rrf_k + k.rank), 0)
      ) as rrf_score
    from vector_results v
    full outer join keyword_results k
      on v.entity_id = k.entity_id and v.entity_type = k.entity_type
  )
  
  select
    c.entity_type,
    c.entity_id,
    c.workspace_id,
    c.content,
    c.metadata,
    c.vector_rank::int,
    c.keyword_rank::int,
    c.rrf_score,
    c.vector_similarity::float
  from combined c
  order by c.rrf_score desc
  limit p_limit;
end;
$$;
```

### 2.3 Supabase Provider Implementation

```typescript
// lib/ai-providers/supabase-provider.ts

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import Anthropic from '@anthropic-ai/sdk';
import {
  ApmAiProvider,
  ChatRequest,
  ChatResponse,
  SearchResult,
  SearchOptions,
  EmbeddingRequest,
} from './types';
import { buildSystemPrompt, classifyQuery, generateWorkspaceSwot } from './utils';

const OPENAI_EMBEDDING_MODEL = 'text-embedding-3-small';
const COHERE_RERANK_MODEL = 'rerank-english-v3.0';

export class SupabaseProvider implements ApmAiProvider {
  readonly name = 'supabase';
  readonly version = '2.0';
  
  private supabase: SupabaseClient;
  private anthropic: Anthropic;
  private openaiKey: string;
  private cohereKey: string | null;
  
  constructor(config: ProviderConfig) {
    this.supabase = createClient(config.supabaseUrl!, config.supabaseKey!);
    this.anthropic = new Anthropic({ apiKey: config.anthropicKey });
    this.openaiKey = config.openaiKey!;
    this.cohereKey = config.cohereKey || null;
  }
  
  async search(
    query: string,
    namespaceId: string,
    options: SearchOptions = {}
  ): Promise<SearchResult[]> {
    // 1. Generate query embedding
    const queryEmbedding = await this.generateEmbedding(query);
    
    // 2. Hybrid search (vector + keyword with RRF)
    const { data: results, error } = await this.supabase.rpc('hybrid_search_apm', {
      p_query: query,
      p_query_embedding: queryEmbedding,
      p_namespace_id: namespaceId,
      p_workspace_id: options.workspaceId || null,
      p_entity_types: options.entityTypes || null,
      p_limit: (options.maxResults || 10) * 2, // Fetch extra for reranking
    });
    
    if (error) throw error;
    if (!results || results.length === 0) return [];
    
    // 3. Rerank with Cohere (if available)
    if (this.cohereKey && results.length > 1) {
      return this.rerankResults(query, results, options.maxResults || 10);
    }
    
    // Return top results without reranking
    return results.slice(0, options.maxResults || 10).map(this.mapToSearchResult);
  }
  
  private async rerankResults(
    query: string,
    results: any[],
    topK: number
  ): Promise<SearchResult[]> {
    const response = await fetch('https://api.cohere.ai/v1/rerank', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.cohereKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: COHERE_RERANK_MODEL,
        query: query,
        documents: results.map(r => r.content),
        top_n: topK,
        return_documents: false,
      }),
    });
    
    const { results: reranked } = await response.json();
    
    return reranked.map((r: any) => this.mapToSearchResult(results[r.index]));
  }
  
  async chat(request: ChatRequest): Promise<ChatResponse> {
    const { query, namespaceId, workspaceId, conversationHistory, options } = request;
    
    // 1. Classify query intent
    const intent = classifyQuery(query);
    
    // 2. Get context based on intent
    let contextText = '';
    let sources: SearchResult[] = [];
    
    if (intent.type === 'swot' && intent.workspaceName) {
      // SWOT analysis - fetch structured data
      const swotData = await generateWorkspaceSwot(
        this.supabase,
        namespaceId,
        intent.workspaceName
      );
      contextText = this.formatSwotContext(swotData);
    } else {
      // Standard retrieval
      sources = await this.search(query, namespaceId, {
        workspaceId,
        maxResults: options?.maxResults || 10,
        entityTypes: options?.entityTypes,
      });
      contextText = this.formatSearchContext(sources);
    }
    
    // 3. Build prompt and call Claude
    const systemPrompt = buildSystemPrompt(contextText);
    
    const response = await this.anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemPrompt,
      messages: [
        ...(conversationHistory || []),
        { role: 'user', content: query },
      ],
    });
    
    return {
      content: response.content[0].type === 'text' ? response.content[0].text : '',
      sources,
      usage: {
        promptTokens: response.usage.input_tokens,
        completionTokens: response.usage.output_tokens,
      },
    };
  }
  
  async *chatStream(request: ChatRequest): AsyncGenerator<string> {
    const { query, namespaceId, workspaceId, conversationHistory, options } = request;
    
    // Get context
    const sources = await this.search(query, namespaceId, {
      workspaceId,
      maxResults: options?.maxResults || 10,
    });
    const contextText = this.formatSearchContext(sources);
    const systemPrompt = buildSystemPrompt(contextText);
    
    // Stream response
    const stream = await this.anthropic.messages.stream({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemPrompt,
      messages: [
        ...(conversationHistory || []),
        { role: 'user', content: query },
      ],
    });
    
    for await (const event of stream) {
      if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
        yield event.delta.text;
      }
    }
  }
  
  async upsertEmbedding(request: EmbeddingRequest): Promise<void> {
    const embedding = await this.generateEmbedding(request.content);
    
    await this.supabase.from('apm_embeddings').upsert({
      namespace_id: request.namespaceId,
      workspace_id: request.workspaceId,
      entity_type: request.entityType,
      entity_id: request.entityId,
      content: request.content,
      embedding,
      metadata: request.metadata,
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'namespace_id,entity_type,entity_id',
    });
  }
  
  async deleteEmbedding(
    entityType: string,
    entityId: string,
    namespaceId: string
  ): Promise<void> {
    await this.supabase
      .from('apm_embeddings')
      .delete()
      .eq('namespace_id', namespaceId)
      .eq('entity_type', entityType)
      .eq('entity_id', entityId);
  }
  
  async healthCheck(): Promise<{ healthy: boolean; latencyMs: number }> {
    const start = Date.now();
    try {
      await this.supabase.from('apm_embeddings').select('id').limit(1);
      return { healthy: true, latencyMs: Date.now() - start };
    } catch {
      return { healthy: false, latencyMs: Date.now() - start };
    }
  }
  
  // Helper methods
  private async generateEmbedding(text: string): Promise<number[]> {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.openaiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: OPENAI_EMBEDDING_MODEL,
        input: text,
      }),
    });
    
    const { data } = await response.json();
    return data[0].embedding;
  }
  
  private mapToSearchResult(row: any): SearchResult {
    return {
      entityType: row.entity_type,
      entityId: row.entity_id,
      workspaceId: row.workspace_id,
      content: row.content,
      metadata: row.metadata,
      similarity: row.vector_similarity || row.rrf_score,
    };
  }
  
  private formatSearchContext(results: SearchResult[]): string {
    return results
      .map(r => `[${r.entityType.toUpperCase()}]\n${r.content}`)
      .join('\n\n---\n\n');
  }
  
  private formatSwotContext(swot: any): string {
    return `
SWOT ANALYSIS DATA

STATISTICS:
- Total Applications: ${swot.stats.totalApps}
- Assessed Applications: ${swot.stats.assessedApps}
- Total Annual Cost: $${swot.stats.totalCost.toLocaleString()}
- Total Tech Debt: $${swot.stats.techDebtTotal.toLocaleString()}

STRENGTHS:
${swot.strengths.map((s: string) => `• ${s}`).join('\n')}

WEAKNESSES:
${swot.weaknesses.map((w: string) => `• ${w}`).join('\n')}

OPPORTUNITIES:
${swot.opportunities.map((o: string) => `• ${o}`).join('\n')}

THREATS:
${swot.threats.map((t: string) => `• ${t}`).join('\n')}
    `.trim();
  }
}
```

---

## 3. Azure Provider (Enterprise)

For customers requiring Azure compliance (FedRAMP, government clouds).

### 3.1 Azure Resources Required

| Resource | Purpose | SKU Recommendation |
|----------|---------|-------------------|
| **Azure AI Search** | Vector + hybrid search | Standard S1+ |
| **Azure OpenAI** | Embeddings + chat | GPT-4, text-embedding-ada-002 |
| **Azure Blob Storage** | Document storage (optional) | Standard LRS |

### 3.2 Azure Provider Implementation

```typescript
// lib/ai-providers/azure-provider.ts

import { SearchClient, AzureKeyCredential } from '@azure/search-documents';
import { OpenAIClient } from '@azure/openai';
import {
  ApmAiProvider,
  ChatRequest,
  ChatResponse,
  SearchResult,
  SearchOptions,
  EmbeddingRequest,
} from './types';

export class AzureProvider implements ApmAiProvider {
  readonly name = 'azure';
  readonly version = '1.0';
  
  private searchClient: SearchClient<any>;
  private openaiClient: OpenAIClient;
  private embeddingDeployment: string;
  private chatDeployment: string;
  
  constructor(config: ProviderConfig) {
    this.searchClient = new SearchClient(
      config.azureSearchEndpoint!,
      'apm-embeddings', // Index name
      new AzureKeyCredential(config.azureSearchKey!)
    );
    
    this.openaiClient = new OpenAIClient(
      config.azureOpenAiEndpoint!,
      new AzureKeyCredential(config.azureOpenAiKey!)
    );
    
    this.embeddingDeployment = config.azureEmbeddingDeployment || 'text-embedding-ada-002';
    this.chatDeployment = config.azureChatDeployment || 'gpt-4';
  }
  
  async search(
    query: string,
    namespaceId: string,
    options: SearchOptions = {}
  ): Promise<SearchResult[]> {
    // Generate query embedding
    const embeddingResponse = await this.openaiClient.getEmbeddings(
      this.embeddingDeployment,
      [query]
    );
    const queryVector = embeddingResponse.data[0].embedding;
    
    // Hybrid search with Azure AI Search
    const searchResults = await this.searchClient.search(query, {
      filter: this.buildFilter(namespaceId, options),
      select: ['entity_type', 'entity_id', 'workspace_id', 'content', 'metadata'],
      top: options.maxResults || 10,
      
      // Vector search configuration
      vectorSearchOptions: {
        queries: [{
          kind: 'vector',
          vector: queryVector,
          kNearestNeighborsCount: 50,
          fields: ['embedding'],
        }],
      },
      
      // Semantic ranking (reranking)
      queryType: 'semantic',
      semanticSearchOptions: {
        configurationName: 'apm-semantic-config',
        captions: { captionType: 'extractive' },
      },
    });
    
    const results: SearchResult[] = [];
    for await (const result of searchResults.results) {
      results.push({
        entityType: result.document.entity_type,
        entityId: result.document.entity_id,
        workspaceId: result.document.workspace_id,
        content: result.document.content,
        metadata: result.document.metadata,
        similarity: result.score || 0,
      });
    }
    
    return results;
  }
  
  async chat(request: ChatRequest): Promise<ChatResponse> {
    const sources = await this.search(request.query, request.namespaceId, {
      workspaceId: request.workspaceId,
      maxResults: 10,
    });
    
    const contextText = sources
      .map(s => `[${s.entityType.toUpperCase()}]\n${s.content}`)
      .join('\n\n---\n\n');
    
    const systemPrompt = this.buildSystemPrompt(contextText);
    
    const response = await this.openaiClient.getChatCompletions(
      this.chatDeployment,
      [
        { role: 'system', content: systemPrompt },
        ...(request.conversationHistory || []).map(m => ({
          role: m.role as 'user' | 'assistant',
          content: m.content,
        })),
        { role: 'user', content: request.query },
      ],
      { maxTokens: 2048 }
    );
    
    return {
      content: response.choices[0]?.message?.content || '',
      sources,
      usage: {
        promptTokens: response.usage?.promptTokens || 0,
        completionTokens: response.usage?.completionTokens || 0,
      },
    };
  }
  
  async *chatStream(request: ChatRequest): AsyncGenerator<string> {
    const sources = await this.search(request.query, request.namespaceId, {
      workspaceId: request.workspaceId,
    });
    
    const contextText = sources
      .map(s => `[${s.entityType.toUpperCase()}]\n${s.content}`)
      .join('\n\n---\n\n');
    
    const events = await this.openaiClient.streamChatCompletions(
      this.chatDeployment,
      [
        { role: 'system', content: this.buildSystemPrompt(contextText) },
        ...(request.conversationHistory || []),
        { role: 'user', content: request.query },
      ],
      { maxTokens: 2048 }
    );
    
    for await (const event of events) {
      const delta = event.choices[0]?.delta?.content;
      if (delta) yield delta;
    }
  }
  
  async upsertEmbedding(request: EmbeddingRequest): Promise<void> {
    const embeddingResponse = await this.openaiClient.getEmbeddings(
      this.embeddingDeployment,
      [request.content]
    );
    
    await this.searchClient.uploadDocuments([{
      id: `${request.entityType}-${request.entityId}`,
      namespace_id: request.namespaceId,
      workspace_id: request.workspaceId,
      entity_type: request.entityType,
      entity_id: request.entityId,
      content: request.content,
      embedding: embeddingResponse.data[0].embedding,
      metadata: request.metadata,
      updated_at: new Date().toISOString(),
    }]);
  }
  
  async deleteEmbedding(
    entityType: string,
    entityId: string,
    namespaceId: string
  ): Promise<void> {
    await this.searchClient.deleteDocuments([
      { id: `${entityType}-${entityId}` }
    ]);
  }
  
  async healthCheck(): Promise<{ healthy: boolean; latencyMs: number }> {
    const start = Date.now();
    try {
      await this.searchClient.getDocumentsCount();
      return { healthy: true, latencyMs: Date.now() - start };
    } catch {
      return { healthy: false, latencyMs: Date.now() - start };
    }
  }
  
  private buildFilter(namespaceId: string, options: SearchOptions): string {
    const filters = [`namespace_id eq '${namespaceId}'`];
    
    if (options.workspaceId) {
      filters.push(`workspace_id eq '${options.workspaceId}'`);
    }
    
    if (options.entityTypes?.length) {
      const typeFilter = options.entityTypes
        .map(t => `entity_type eq '${t}'`)
        .join(' or ');
      filters.push(`(${typeFilter})`);
    }
    
    return filters.join(' and ');
  }
  
  private buildSystemPrompt(context: string): string {
    return `You are an APM assistant helping users understand their application portfolio.

<context>
${context}
</context>

Guidelines:
- Be concise and actionable
- Reference specific applications by name
- Explain TIME/PAID classifications when relevant
- Acknowledge missing data`;
  }
}


// Azure AI Search Index Definition (deploy via Azure CLI or Portal)
export const AZURE_INDEX_DEFINITION = {
  name: 'apm-embeddings',
  fields: [
    { name: 'id', type: 'Edm.String', key: true },
    { name: 'namespace_id', type: 'Edm.String', filterable: true },
    { name: 'workspace_id', type: 'Edm.String', filterable: true },
    { name: 'entity_type', type: 'Edm.String', filterable: true, facetable: true },
    { name: 'entity_id', type: 'Edm.String' },
    { name: 'content', type: 'Edm.String', searchable: true, analyzerName: 'en.microsoft' },
    { name: 'embedding', type: 'Collection(Edm.Single)', dimensions: 1536, vectorSearchProfile: 'apm-vector-profile' },
    { name: 'metadata', type: 'Edm.ComplexType', fields: [
      { name: 'time_quadrant', type: 'Edm.String', filterable: true },
      { name: 'lifecycle_status', type: 'Edm.String', filterable: true },
      { name: 'has_tech_debt', type: 'Edm.Boolean', filterable: true },
    ]},
    { name: 'updated_at', type: 'Edm.DateTimeOffset', sortable: true },
  ],
  vectorSearch: {
    profiles: [{ name: 'apm-vector-profile', algorithm: 'apm-hnsw-algorithm' }],
    algorithms: [{ name: 'apm-hnsw-algorithm', kind: 'hnsw', parameters: { m: 4, efConstruction: 400 } }],
  },
  semantic: {
    configurations: [{
      name: 'apm-semantic-config',
      prioritizedFields: {
        contentFields: [{ fieldName: 'content' }],
      },
    }],
  },
};
```

---

## 4. AWS Provider (Enterprise)

For customers on AWS or requiring specific AWS compliance.

### 4.1 AWS Resources Required

| Resource | Purpose | Recommendation |
|----------|---------|----------------|
| **OpenSearch Serverless** | Vector + hybrid search | Development or Production collection |
| **Amazon Bedrock** | Embeddings + chat | Claude 3 Sonnet or Haiku |
| **S3** | Document storage (optional) | Standard |

### 4.2 AWS Provider Implementation

```typescript
// lib/ai-providers/aws-provider.ts

import {
  BedrockRuntimeClient,
  InvokeModelCommand,
  InvokeModelWithResponseStreamCommand,
} from '@aws-sdk/client-bedrock-runtime';
import { Client as OpenSearchClient } from '@opensearch-project/opensearch';
import {
  ApmAiProvider,
  ChatRequest,
  ChatResponse,
  SearchResult,
  SearchOptions,
  EmbeddingRequest,
} from './types';

export class AwsProvider implements ApmAiProvider {
  readonly name = 'aws';
  readonly version = '1.0';
  
  private bedrock: BedrockRuntimeClient;
  private opensearch: OpenSearchClient;
  private embeddingModelId: string;
  private chatModelId: string;
  private indexName = 'apm-embeddings';
  
  constructor(config: ProviderConfig) {
    this.bedrock = new BedrockRuntimeClient({
      region: config.awsRegion,
      credentials: {
        accessKeyId: config.awsAccessKeyId!,
        secretAccessKey: config.awsSecretAccessKey!,
      },
    });
    
    this.opensearch = new OpenSearchClient({
      node: config.opensearchEndpoint,
      auth: {
        username: config.opensearchUsername!,
        password: config.opensearchPassword!,
      },
    });
    
    this.embeddingModelId = config.embeddingModelId || 'amazon.titan-embed-text-v2:0';
    this.chatModelId = config.bedrockModelId || 'anthropic.claude-3-sonnet-20240229-v1:0';
  }
  
  async search(
    query: string,
    namespaceId: string,
    options: SearchOptions = {}
  ): Promise<SearchResult[]> {
    // Generate query embedding via Bedrock
    const queryEmbedding = await this.generateEmbedding(query);
    
    // Build OpenSearch query (hybrid: knn + text)
    const searchBody = {
      size: options.maxResults || 10,
      query: {
        bool: {
          must: [
            { term: { namespace_id: namespaceId } },
          ],
          should: [
            // Vector search (kNN)
            {
              knn: {
                embedding: {
                  vector: queryEmbedding,
                  k: 50,
                },
              },
            },
            // Text search (BM25)
            {
              match: {
                content: {
                  query: query,
                  boost: 0.3,
                },
              },
            },
          ],
          filter: this.buildFilters(options),
        },
      },
    };
    
    const response = await this.opensearch.search({
      index: this.indexName,
      body: searchBody,
    });
    
    return response.body.hits.hits.map((hit: any) => ({
      entityType: hit._source.entity_type,
      entityId: hit._source.entity_id,
      workspaceId: hit._source.workspace_id,
      content: hit._source.content,
      metadata: hit._source.metadata,
      similarity: hit._score,
    }));
  }
  
  async chat(request: ChatRequest): Promise<ChatResponse> {
    const sources = await this.search(request.query, request.namespaceId, {
      workspaceId: request.workspaceId,
    });
    
    const contextText = sources
      .map(s => `[${s.entityType.toUpperCase()}]\n${s.content}`)
      .join('\n\n---\n\n');
    
    // Build Claude messages format for Bedrock
    const payload = {
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 2048,
      system: this.buildSystemPrompt(contextText),
      messages: [
        ...(request.conversationHistory || []),
        { role: 'user', content: request.query },
      ],
    };
    
    const command = new InvokeModelCommand({
      modelId: this.chatModelId,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(payload),
    });
    
    const response = await this.bedrock.send(command);
    const result = JSON.parse(new TextDecoder().decode(response.body));
    
    return {
      content: result.content[0]?.text || '',
      sources,
      usage: {
        promptTokens: result.usage?.input_tokens || 0,
        completionTokens: result.usage?.output_tokens || 0,
      },
    };
  }
  
  async *chatStream(request: ChatRequest): AsyncGenerator<string> {
    const sources = await this.search(request.query, request.namespaceId, {
      workspaceId: request.workspaceId,
    });
    
    const contextText = sources
      .map(s => `[${s.entityType.toUpperCase()}]\n${s.content}`)
      .join('\n\n---\n\n');
    
    const payload = {
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: 2048,
      system: this.buildSystemPrompt(contextText),
      messages: [
        ...(request.conversationHistory || []),
        { role: 'user', content: request.query },
      ],
    };
    
    const command = new InvokeModelWithResponseStreamCommand({
      modelId: this.chatModelId,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(payload),
    });
    
    const response = await this.bedrock.send(command);
    
    if (response.body) {
      for await (const chunk of response.body) {
        if (chunk.chunk?.bytes) {
          const parsed = JSON.parse(new TextDecoder().decode(chunk.chunk.bytes));
          if (parsed.type === 'content_block_delta') {
            yield parsed.delta?.text || '';
          }
        }
      }
    }
  }
  
  async upsertEmbedding(request: EmbeddingRequest): Promise<void> {
    const embedding = await this.generateEmbedding(request.content);
    
    await this.opensearch.index({
      index: this.indexName,
      id: `${request.entityType}-${request.entityId}`,
      body: {
        namespace_id: request.namespaceId,
        workspace_id: request.workspaceId,
        entity_type: request.entityType,
        entity_id: request.entityId,
        content: request.content,
        embedding,
        metadata: request.metadata,
        updated_at: new Date().toISOString(),
      },
      refresh: true,
    });
  }
  
  async deleteEmbedding(
    entityType: string,
    entityId: string,
    namespaceId: string
  ): Promise<void> {
    await this.opensearch.delete({
      index: this.indexName,
      id: `${entityType}-${entityId}`,
    });
  }
  
  async healthCheck(): Promise<{ healthy: boolean; latencyMs: number }> {
    const start = Date.now();
    try {
      await this.opensearch.cluster.health();
      return { healthy: true, latencyMs: Date.now() - start };
    } catch {
      return { healthy: false, latencyMs: Date.now() - start };
    }
  }
  
  private async generateEmbedding(text: string): Promise<number[]> {
    const command = new InvokeModelCommand({
      modelId: this.embeddingModelId,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({ inputText: text }),
    });
    
    const response = await this.bedrock.send(command);
    const result = JSON.parse(new TextDecoder().decode(response.body));
    return result.embedding;
  }
  
  private buildFilters(options: SearchOptions): any[] {
    const filters: any[] = [];
    
    if (options.workspaceId) {
      filters.push({ term: { workspace_id: options.workspaceId } });
    }
    
    if (options.entityTypes?.length) {
      filters.push({ terms: { entity_type: options.entityTypes } });
    }
    
    return filters;
  }
  
  private buildSystemPrompt(context: string): string {
    return `You are an APM assistant helping users understand their application portfolio.

<context>
${context}
</context>

Guidelines:
- Be concise and actionable
- Reference specific applications by name
- Explain TIME/PAID classifications when relevant`;
  }
}


// OpenSearch Index Mapping (deploy via AWS Console or CLI)
export const OPENSEARCH_INDEX_MAPPING = {
  settings: {
    index: {
      knn: true,
      'knn.algo_param.ef_search': 100,
    },
  },
  mappings: {
    properties: {
      namespace_id: { type: 'keyword' },
      workspace_id: { type: 'keyword' },
      entity_type: { type: 'keyword' },
      entity_id: { type: 'keyword' },
      content: { type: 'text', analyzer: 'english' },
      embedding: {
        type: 'knn_vector',
        dimension: 1536,
        method: {
          name: 'hnsw',
          space_type: 'cosinesimil',
          engine: 'nmslib',
          parameters: { ef_construction: 128, m: 24 },
        },
      },
      metadata: { type: 'object', enabled: true },
      updated_at: { type: 'date' },
    },
  },
};
```

---

## 5. Data Synchronization Layer

Keeps embeddings in sync regardless of provider.

### 5.1 Sync Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   GetInSync Core (Supabase)                     │
│  ┌───────────┐  ┌────────────┐  ┌───────────┐  ┌─────────────┐ │
│  │applications│  │deployment_ │  │software_  │  │it_services  │ │
│  │           │  │profiles    │  │products   │  │             │ │
│  └─────┬─────┘  └─────┬──────┘  └─────┬─────┘  └──────┬──────┘ │
│        │              │               │               │         │
│        └──────────────┴───────────────┴───────────────┘         │
│                              │                                   │
│                     ┌────────▼────────┐                         │
│                     │  DB Triggers    │                         │
│                     │  pg_notify()    │                         │
│                     └────────┬────────┘                         │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                      ┌────────▼────────┐
                      │  Sync Worker    │
                      │  (Edge Function │
                      │   or External)  │
                      └────────┬────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       ┌────────────┐  ┌────────────┐  ┌────────────┐
       │  Supabase  │  │   Azure    │  │    AWS     │
       │  pgvector  │  │  AI Search │  │ OpenSearch │
       └────────────┘  └────────────┘  └────────────┘
```

### 5.2 Sync Worker Implementation

```typescript
// supabase/functions/sync-embeddings/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getProviderForNamespace } from "../_shared/provider-factory.ts";
import {
  buildApplicationContent,
  buildDeploymentProfileContent,
  buildSoftwareProductContent,
  buildItServiceContent,
} from "../_shared/embedding-builders.ts";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const { entity_type, entity_id, namespace_id, action } = await req.json();
  
  // Get the provider for this namespace
  const provider = await getProviderForNamespace(supabase, namespace_id);
  
  if (action === 'delete') {
    await provider.deleteEmbedding(entity_type, entity_id, namespace_id);
    return new Response(JSON.stringify({ success: true, action: 'deleted' }));
  }
  
  // Build content based on entity type
  let content: string;
  let metadata: Record<string, any>;
  let workspaceId: string;
  
  switch (entity_type) {
    case 'application': {
      const result = await buildApplicationContent(supabase, entity_id);
      content = result.content;
      metadata = result.metadata;
      workspaceId = result.workspaceId;
      break;
    }
    case 'deployment_profile': {
      const result = await buildDeploymentProfileContent(supabase, entity_id);
      content = result.content;
      metadata = result.metadata;
      workspaceId = result.workspaceId;
      break;
    }
    case 'software_product': {
      const result = await buildSoftwareProductContent(supabase, entity_id);
      content = result.content;
      metadata = result.metadata;
      workspaceId = result.workspaceId;
      break;
    }
    case 'it_service': {
      const result = await buildItServiceContent(supabase, entity_id);
      content = result.content;
      metadata = result.metadata;
      workspaceId = result.workspaceId;
      break;
    }
    default:
      return new Response(
        JSON.stringify({ error: `Unknown entity type: ${entity_type}` }),
        { status: 400 }
      );
  }
  
  // Upsert to the provider
  await provider.upsertEmbedding({
    entityType: entity_type,
    entityId: entity_id,
    namespaceId: namespace_id,
    workspaceId,
    content,
    metadata,
  });
  
  return new Response(JSON.stringify({ success: true, action: 'upserted' }));
});
```

### 5.3 Database Triggers for Auto-Sync

```sql
-- Trigger function that calls sync worker
create or replace function trigger_embedding_sync()
returns trigger as $$
declare
  v_namespace_id uuid;
  v_action text;
begin
  -- Determine namespace_id based on table
  case TG_TABLE_NAME
    when 'applications' then
      v_namespace_id := (select namespace_id from workspaces where id = coalesce(NEW.workspace_id, OLD.workspace_id));
    when 'deployment_profiles' then
      v_namespace_id := (select namespace_id from workspaces where id = coalesce(NEW.workspace_id, OLD.workspace_id));
    when 'software_products' then
      v_namespace_id := coalesce(NEW.namespace_id, OLD.namespace_id);
    when 'it_services' then
      v_namespace_id := coalesce(NEW.namespace_id, OLD.namespace_id);
    else
      return coalesce(NEW, OLD);
  end case;
  
  -- Determine action
  if TG_OP = 'DELETE' then
    v_action := 'delete';
  else
    v_action := 'upsert';
  end if;
  
  -- Queue async sync via pg_net (Supabase HTTP extension)
  perform net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/sync-embeddings',
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

-- Create triggers for each entity type
create trigger sync_applications
  after insert or update or delete on applications
  for each row execute function trigger_embedding_sync('application');

create trigger sync_deployment_profiles
  after insert or update or delete on deployment_profiles
  for each row execute function trigger_embedding_sync('deployment_profile');

create trigger sync_software_products
  after insert or update or delete on software_products
  for each row execute function trigger_embedding_sync('software_product');

create trigger sync_it_services
  after insert or update or delete on it_services
  for each row execute function trigger_embedding_sync('it_service');

-- Also sync when portfolio_assignments change (affects app context)
create trigger sync_portfolio_assignments
  after insert or update or delete on portfolio_assignments
  for each row execute function trigger_embedding_sync('application');
```

---

## 6. Chat Gateway (Unified API)

Single endpoint that routes to the appropriate provider.

```typescript
// supabase/functions/apm-chat/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getProviderForNamespace } from "../_shared/provider-factory.ts";

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      },
    });
  }
  
  // Auth
  const authHeader = req.headers.get('Authorization')!;
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  );
  
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const namespaceId = user.user_metadata.namespace_id;
  
  // Check usage limits
  const { data: settings } = await supabase
    .from('namespace_ai_settings')
    .select('chat_enabled, monthly_chat_limit, current_month_usage')
    .eq('namespace_id', namespaceId)
    .single();
  
  if (!settings?.chat_enabled) {
    return new Response(JSON.stringify({ error: 'AI chat is disabled for this namespace' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  
  if (settings.current_month_usage >= settings.monthly_chat_limit) {
    return new Response(JSON.stringify({ error: 'Monthly chat limit reached' }), {
      status: 429,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  
  // Parse request
  const { query, workspace_id, conversation_history, stream } = await req.json();
  
  // Get provider for this namespace
  const provider = await getProviderForNamespace(supabase, namespaceId);
  
  // Increment usage
  await supabase.rpc('increment_chat_usage', { p_namespace_id: namespaceId });
  
  // Handle streaming vs non-streaming
  if (stream) {
    const encoder = new TextEncoder();
    const readable = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of provider.chatStream({
            query,
            namespaceId,
            workspaceId: workspace_id,
            conversationHistory: conversation_history,
          })) {
            controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text: chunk })}\n\n`));
          }
          controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        } catch (error) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: error.message })}\n\n`));
        } finally {
          controller.close();
        }
      },
    });
    
    return new Response(readable, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
  
  // Non-streaming response
  const response = await provider.chat({
    query,
    namespaceId,
    workspaceId: workspace_id,
    conversationHistory: conversation_history,
  });
  
  return new Response(JSON.stringify(response), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
});
```

---

## 7. React Client Component

Works identically regardless of backend provider.

```tsx
// components/ApmChatPanel.tsx

import { useState, useRef, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  sources?: SearchResult[];
}

interface SearchResult {
  entityType: string;
  entityId: string;
  content: string;
  similarity: number;
}

interface ApmChatPanelProps {
  workspaceId?: string;
  className?: string;
}

export function ApmChatPanel({ workspaceId, className }: ApmChatPanelProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showSources, setShowSources] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, []);

  useEffect(scrollToBottom, [messages, scrollToBottom]);

  // Auto-resize textarea
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = `${inputRef.current.scrollHeight}px`;
    }
  }, [input]);

  const sendMessage = async () => {
    if (!input.trim() || isLoading) return;

    const userMessage = input.trim();
    const userMessageId = crypto.randomUUID();
    
    setInput('');
    setMessages(prev => [...prev, { 
      id: userMessageId, 
      role: 'user', 
      content: userMessage 
    }]);
    setIsLoading(true);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/apm-chat`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session?.access_token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            query: userMessage,
            workspace_id: workspaceId,
            conversation_history: messages.slice(-10).map(m => ({
              role: m.role,
              content: m.content,
            })),
            stream: true,
          }),
        }
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Chat request failed');
      }

      // Handle streaming response
      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      let assistantMessage = '';
      const assistantMessageId = crypto.randomUUID();

      setMessages(prev => [...prev, { 
        id: assistantMessageId, 
        role: 'assistant', 
        content: '' 
      }]);

      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ') && line !== 'data: [DONE]') {
            try {
              const data = JSON.parse(line.slice(6));
              if (data.text) {
                assistantMessage += data.text;
                setMessages(prev => 
                  prev.map(m => 
                    m.id === assistantMessageId 
                      ? { ...m, content: assistantMessage }
                      : m
                  )
                );
              }
              if (data.error) {
                throw new Error(data.error);
              }
            } catch (e) {
              // Skip malformed JSON
            }
          }
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'An error occurred';
      setMessages(prev => [
        ...prev,
        { 
          id: crypto.randomUUID(), 
          role: 'assistant', 
          content: `Sorry, I encountered an error: ${errorMessage}. Please try again.` 
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const suggestedQueries = [
    "Which applications are marked for migration?",
    "Show me high-priority tech debt items",
    "Generate a SWOT for this workspace",
    "What technologies are approaching end-of-life?",
    "Compare application costs vs budgets",
  ];

  return (
    <div className={`flex flex-col h-full bg-white rounded-lg shadow-sm border ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b bg-gray-50 rounded-t-lg">
        <div>
          <h3 className="font-semibold text-gray-800 flex items-center gap-2">
            <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
            </svg>
            APM Assistant
          </h3>
          <p className="text-sm text-gray-500">Ask questions about your application portfolio</p>
        </div>
        <button
          onClick={() => setMessages([])}
          className="text-sm text-gray-500 hover:text-gray-700"
        >
          Clear chat
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-400 mt-8">
            <div className="mb-6">
              <svg className="w-12 h-12 mx-auto text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5}
                  d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
              </svg>
            </div>
            <p className="mb-4 font-medium">Try asking:</p>
            <div className="space-y-2 max-w-md mx-auto">
              {suggestedQueries.map((suggestion, i) => (
                <button
                  key={i}
                  onClick={() => setInput(suggestion)}
                  className="block w-full text-left px-4 py-2 text-sm bg-gray-50 
                           hover:bg-blue-50 hover:text-blue-700 rounded-lg transition-colors
                           border border-transparent hover:border-blue-200"
                >
                  {suggestion}
                </button>
              ))}
            </div>
          </div>
        )}

        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[85%] px-4 py-3 rounded-2xl ${
                msg.role === 'user'
                  ? 'bg-blue-600 text-white rounded-br-md'
                  : 'bg-gray-100 text-gray-800 rounded-bl-md'
              }`}
            >
              <p className="whitespace-pre-wrap text-sm leading-relaxed">{msg.content}</p>
              
              {/* Sources toggle */}
              {msg.role === 'assistant' && msg.sources && msg.sources.length > 0 && (
                <div className="mt-2 pt-2 border-t border-gray-200">
                  <button
                    onClick={() => setShowSources(!showSources)}
                    className="text-xs text-gray-500 hover:text-gray-700"
                  >
                    {showSources ? 'Hide' : 'Show'} {msg.sources.length} sources
                  </button>
                  {showSources && (
                    <div className="mt-2 space-y-1">
                      {msg.sources.map((source, i) => (
                        <div key={i} className="text-xs text-gray-500">
                          • {source.entityType}: {source.content.slice(0, 50)}...
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}

        {isLoading && messages[messages.length - 1]?.role === 'user' && (
          <div className="flex justify-start">
            <div className="bg-gray-100 px-4 py-3 rounded-2xl rounded-bl-md">
              <div className="flex space-x-1.5">
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" 
                     style={{ animationDelay: '0ms' }} />
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" 
                     style={{ animationDelay: '150ms' }} />
                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" 
                     style={{ animationDelay: '300ms' }} />
              </div>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="p-4 border-t bg-gray-50 rounded-b-lg">
        <div className="flex items-end gap-2">
          <textarea
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask about applications, technologies, tech debt, assessments..."
            className="flex-1 px-4 py-2.5 border rounded-xl focus:outline-none 
                     focus:ring-2 focus:ring-blue-500 focus:border-transparent
                     resize-none min-h-[44px] max-h-32 text-sm"
            disabled={isLoading}
            rows={1}
          />
          <button
            onClick={sendMessage}
            disabled={isLoading || !input.trim()}
            className="px-4 py-2.5 bg-blue-600 text-white rounded-xl 
                     hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed
                     transition-colors flex items-center gap-2"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
            </svg>
            Send
          </button>
        </div>
        <p className="mt-2 text-xs text-gray-400 text-center">
          AI responses are generated based on your APM data. Always verify important decisions.
        </p>
      </div>
    </div>
  );
}
```

---

## 8. Admin Configuration UI

Allows enterprise customers to configure their own AI backend.

```tsx
// components/admin/AiProviderSettings.tsx

import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';

type ProviderType = 'supabase' | 'azure' | 'aws';

interface ProviderConfig {
  type: ProviderType;
  // Azure
  azureSearchEndpoint?: string;
  azureSearchKey?: string;
  azureOpenAiEndpoint?: string;
  azureOpenAiKey?: string;
  // AWS
  awsRegion?: string;
  awsAccessKeyId?: string;
  awsSecretAccessKey?: string;
  opensearchEndpoint?: string;
}

export function AiProviderSettings() {
  const [config, setConfig] = useState<ProviderConfig>({ type: 'supabase' });
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    const { data } = await supabase
      .from('namespace_ai_settings')
      .select('provider_type, provider_config')
      .single();
    
    if (data) {
      setConfig({
        type: data.provider_type as ProviderType,
        ...data.provider_config,
      });
    }
  };

  const saveConfig = async () => {
    setSaving(true);
    try {
      const { type, ...providerConfig } = config;
      
      await supabase.from('namespace_ai_settings').upsert({
        provider_type: type,
        provider_config: providerConfig,
        updated_at: new Date().toISOString(),
      });
      
      setTestResult({ success: true, message: 'Configuration saved successfully' });
    } catch (error) {
      setTestResult({ success: false, message: 'Failed to save configuration' });
    } finally {
      setSaving(false);
    }
  };

  const testConnection = async () => {
    setTesting(true);
    setTestResult(null);
    
    try {
      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/test-ai-provider`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(config),
        }
      );
      
      const result = await response.json();
      setTestResult({
        success: result.healthy,
        message: result.healthy 
          ? `Connection successful (${result.latencyMs}ms latency)`
          : 'Connection failed',
      });
    } catch {
      setTestResult({ success: false, message: 'Connection test failed' });
    } finally {
      setTesting(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      <h2 className="text-xl font-semibold mb-6">AI Provider Configuration</h2>
      
      {/* Provider Selection */}
      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          AI Backend Provider
        </label>
        <div className="grid grid-cols-3 gap-3">
          {[
            { value: 'supabase', label: 'Supabase (Default)', desc: 'Included in your plan' },
            { value: 'azure', label: 'Azure AI', desc: 'Bring your own Azure' },
            { value: 'aws', label: 'AWS', desc: 'Bring your own AWS' },
          ].map((option) => (
            <button
              key={option.value}
              onClick={() => setConfig({ ...config, type: option.value as ProviderType })}
              className={`p-4 border rounded-lg text-left transition-colors ${
                config.type === option.value
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="font-medium">{option.label}</div>
              <div className="text-xs text-gray-500">{option.desc}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Azure Configuration */}
      {config.type === 'azure' && (
        <div className="space-y-4 p-4 bg-gray-50 rounded-lg mb-6">
          <h3 className="font-medium">Azure Configuration</h3>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">Azure AI Search Endpoint</label>
            <input
              type="text"
              value={config.azureSearchEndpoint || ''}
              onChange={(e) => setConfig({ ...config, azureSearchEndpoint: e.target.value })}
              placeholder="https://your-search.search.windows.net"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">Azure AI Search Key</label>
            <input
              type="password"
              value={config.azureSearchKey || ''}
              onChange={(e) => setConfig({ ...config, azureSearchKey: e.target.value })}
              placeholder="••••••••"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">Azure OpenAI Endpoint</label>
            <input
              type="text"
              value={config.azureOpenAiEndpoint || ''}
              onChange={(e) => setConfig({ ...config, azureOpenAiEndpoint: e.target.value })}
              placeholder="https://your-openai.openai.azure.com"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">Azure OpenAI Key</label>
            <input
              type="password"
              value={config.azureOpenAiKey || ''}
              onChange={(e) => setConfig({ ...config, azureOpenAiKey: e.target.value })}
              placeholder="••••••••"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>
      )}

      {/* AWS Configuration */}
      {config.type === 'aws' && (
        <div className="space-y-4 p-4 bg-gray-50 rounded-lg mb-6">
          <h3 className="font-medium">AWS Configuration</h3>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">AWS Region</label>
            <select
              value={config.awsRegion || ''}
              onChange={(e) => setConfig({ ...config, awsRegion: e.target.value })}
              className="w-full px-3 py-2 border rounded-lg"
            >
              <option value="">Select region</option>
              <option value="us-east-1">US East (N. Virginia)</option>
              <option value="us-west-2">US West (Oregon)</option>
              <option value="ca-central-1">Canada (Central)</option>
              <option value="eu-west-1">EU (Ireland)</option>
              <option value="eu-central-1">EU (Frankfurt)</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">OpenSearch Endpoint</label>
            <input
              type="text"
              value={config.opensearchEndpoint || ''}
              onChange={(e) => setConfig({ ...config, opensearchEndpoint: e.target.value })}
              placeholder="https://your-domain.region.aoss.amazonaws.com"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">AWS Access Key ID</label>
            <input
              type="text"
              value={config.awsAccessKeyId || ''}
              onChange={(e) => setConfig({ ...config, awsAccessKeyId: e.target.value })}
              placeholder="AKIA..."
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          
          <div>
            <label className="block text-sm text-gray-600 mb-1">AWS Secret Access Key</label>
            <input
              type="password"
              value={config.awsSecretAccessKey || ''}
              onChange={(e) => setConfig({ ...config, awsSecretAccessKey: e.target.value })}
              placeholder="••••••••"
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>
      )}

      {/* Test Result */}
      {testResult && (
        <div className={`mb-6 p-4 rounded-lg ${
          testResult.success ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
        }`}>
          {testResult.message}
        </div>
      )}

      {/* Actions */}
      <div className="flex gap-3">
        <button
          onClick={testConnection}
          disabled={testing || config.type === 'supabase'}
          className="px-4 py-2 border rounded-lg hover:bg-gray-50 disabled:opacity-50"
        >
          {testing ? 'Testing...' : 'Test Connection'}
        </button>
        
        <button
          onClick={saveConfig}
          disabled={saving}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save Configuration'}
        </button>
      </div>
      
      {config.type !== 'supabase' && (
        <p className="mt-4 text-sm text-gray-500">
          Note: After saving, existing embeddings will need to be re-synced to your new provider.
          This may take several minutes depending on your data volume.
        </p>
      )}
    </div>
  );
}
```

---

## 9. Pricing Tier Integration

### Feature Matrix

| Feature | Essentials ($15K) | Plus ($30K) | Enterprise ($62.5K) |
|---------|-------------------|-------------|---------------------|
| AI Chat | ✅ 100 queries/mo | ✅ 1,000 queries/mo | ✅ Unlimited |
| SWOT Analysis | ❌ | ✅ | ✅ |
| Impact Analysis | ❌ | ✅ | ✅ |
| AI Provider | Supabase | Supabase | **BYO Azure/AWS** |
| Data Residency | Supabase CA | Supabase CA | **Customer controlled** |
| SLA | — | 99.5% | **99.9%** |

### Enforcement Logic

```typescript
// lib/ai-providers/feature-flags.ts

export interface AiFeatureFlags {
  chatEnabled: boolean;
  swotEnabled: boolean;
  impactAnalysisEnabled: boolean;
  monthlyQueryLimit: number;
  customProviderAllowed: boolean;
}

export function getFeatureFlagsForTier(tier: 'essentials' | 'plus' | 'enterprise'): AiFeatureFlags {
  switch (tier) {
    case 'essentials':
      return {
        chatEnabled: true,
        swotEnabled: false,
        impactAnalysisEnabled: false,
        monthlyQueryLimit: 100,
        customProviderAllowed: false,
      };
    case 'plus':
      return {
        chatEnabled: true,
        swotEnabled: true,
        impactAnalysisEnabled: true,
        monthlyQueryLimit: 1000,
        customProviderAllowed: false,
      };
    case 'enterprise':
      return {
        chatEnabled: true,
        swotEnabled: true,
        impactAnalysisEnabled: true,
        monthlyQueryLimit: Infinity,
        customProviderAllowed: true,
      };
  }
}
```

---

## 10. Deployment Checklist

### Essentials/Plus Tier (Supabase)
- [ ] Enable pgvector extension
- [ ] Create `apm_embeddings` table
- [ ] Create `namespace_ai_settings` table
- [ ] Deploy `hybrid_search_apm` function
- [ ] Deploy Edge Functions (sync-embeddings, apm-chat)
- [ ] Create database triggers
- [ ] Backfill embeddings for existing data
- [ ] Configure API keys (OpenAI, Anthropic, Cohere)

### Enterprise Tier (Azure)
- [ ] Provision Azure AI Search (Standard S1+)
- [ ] Create search index with schema
- [ ] Provision Azure OpenAI
- [ ] Deploy embedding + chat models
- [ ] Configure semantic ranking
- [ ] Set up network security (VNet, private endpoints)
- [ ] Configure customer's credentials in GetInSync
- [ ] Initial data sync from Supabase

### Enterprise Tier (AWS)
- [ ] Provision OpenSearch Serverless collection
- [ ] Create index with kNN mapping
- [ ] Enable Amazon Bedrock models
- [ ] Configure IAM roles and policies
- [ ] Set up VPC endpoints (optional)
- [ ] Configure customer's credentials in GetInSync
- [ ] Initial data sync from Supabase

---

## 11. Cost Estimates

### Supabase (Essentials/Plus)
| Component | Monthly Cost |
|-----------|--------------|
| OpenAI Embeddings | ~$5 |
| Claude API (via Anthropic) | ~$30-60 |
| Cohere Rerank | ~$10 |
| Supabase Pro (shared) | ~$5 allocated |
| **Total** | **~$50-80/namespace** |

### Azure (Enterprise)
| Component | Monthly Cost |
|-----------|--------------|
| Azure AI Search S1 | ~$250 |
| Azure OpenAI | ~$50-100 |
| Blob Storage | ~$5 |
| **Total** | **~$300-400/namespace** |

### AWS (Enterprise)
| Component | Monthly Cost |
|-----------|--------------|
| OpenSearch Serverless | ~$200-300 |
| Bedrock (Claude) | ~$50-100 |
| S3 | ~$5 |
| **Total** | **~$250-400/namespace** |

---

*Implementation guide for GetInSync APM Chat with Multi-Cloud Support*
*Version 3.0 — January 2026*
