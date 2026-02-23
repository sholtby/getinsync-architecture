--
-- PostgreSQL database dump
--

\restrict yIjvezCuWFH4JHwC5XzYhqCHLCmI1IOugzEnaZugLTPnf28Xe0kfCe13q5Fzayt

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'GetInSync NextGen - Complete schema installed';


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA supabase_migrations;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: accept_invitation(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_invitation(p_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_invitation RECORD;
  v_user_id UUID;
  v_result jsonb;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_invitation
  FROM invitations
  WHERE token = p_token
    AND status = 'pending'
    AND expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or expired invitation';
  END IF;

  -- STEP 1: Update users with namespace_id AND namespace_role
  UPDATE users
  SET namespace_id = v_invitation.namespace_id,
      namespace_role = v_invitation.namespace_role,
      name = COALESCE(name, v_invitation.name)
  WHERE id = v_user_id;

  -- STEP 2: Add user to namespace_users
  INSERT INTO namespace_users (user_id, namespace_id, role)
  VALUES (v_user_id, v_invitation.namespace_id, v_invitation.namespace_role)
  ON CONFLICT (user_id, namespace_id) DO UPDATE
    SET role = v_invitation.namespace_role;

  -- STEP 3: Add to workspace_users from invitation_workspaces
  INSERT INTO workspace_users (user_id, workspace_id, role)
  SELECT v_user_id, iw.workspace_id, iw.role
  FROM invitation_workspaces iw
  WHERE iw.invitation_id = v_invitation.id
  ON CONFLICT (workspace_id, user_id) DO NOTHING;

  -- STEP 4: Fallback — if no workspaces assigned, add default workspace as viewer
  IF NOT EXISTS (
    SELECT 1 FROM workspace_users wu
    JOIN workspaces w ON w.id = wu.workspace_id
    WHERE wu.user_id = v_user_id
      AND w.namespace_id = v_invitation.namespace_id
  ) THEN
    INSERT INTO workspace_users (user_id, workspace_id, role)
    SELECT v_user_id, w.id, 'viewer'
    FROM workspaces w
    WHERE w.namespace_id = v_invitation.namespace_id AND w.is_default = true
    LIMIT 1
    ON CONFLICT (workspace_id, user_id) DO NOTHING;
  END IF;

  -- STEP 5: Mark invitation as accepted
  UPDATE invitations
  SET status = 'accepted'
  WHERE id = v_invitation.id;

  v_result := jsonb_build_object(
    'success', true,
    'namespace_id', v_invitation.namespace_id,
    'workspace_count', (
      SELECT count(*) FROM workspace_users wu
      JOIN workspaces w ON w.id = wu.workspace_id
      WHERE wu.user_id = v_user_id
        AND w.namespace_id = v_invitation.namespace_id
    )
  );

  RETURN v_result;
END;
$$;


--
-- Name: add_creator_to_workspace_users(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_creator_to_workspace_users() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    ns_admin RECORD;
    creator_namespace_id UUID;
BEGIN
    -- Get creator's namespace
    SELECT namespace_id INTO creator_namespace_id
    FROM users WHERE id = auth.uid();

    -- Only add creator if they belong to this namespace (skip platform admins managing other namespaces)
    IF creator_namespace_id = NEW.namespace_id THEN
        INSERT INTO workspace_users (workspace_id, user_id, role)
        VALUES (NEW.id, auth.uid(), 'admin')
        ON CONFLICT (workspace_id, user_id) DO NOTHING;
    END IF;

    -- Add all namespace admins as workspace admins
    FOR ns_admin IN 
        SELECT id FROM users 
        WHERE namespace_id = NEW.namespace_id 
        AND namespace_role = 'admin'
        AND id != auth.uid()
    LOOP
        INSERT INTO workspace_users (workspace_id, user_id, role)
        VALUES (NEW.id, ns_admin.id, 'admin')
        ON CONFLICT (workspace_id, user_id) DO UPDATE SET role = 'admin';
    END LOOP;

    RETURN NEW;
END;
$$;


--
-- Name: add_user_to_workspace(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_user_to_workspace(p_workspace_id uuid, p_user_id uuid, p_role text DEFAULT 'viewer'::text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_ws_namespace_id UUID;
  v_user_namespace_id UUID;
BEGIN
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can add users to workspaces';
  END IF;

  IF p_role NOT IN ('admin', 'editor', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role: %. Must be admin, editor, or viewer', p_role;
  END IF;

  SELECT namespace_id INTO v_ws_namespace_id FROM workspaces WHERE id = p_workspace_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Workspace not found: %', p_workspace_id; END IF;

  SELECT namespace_id INTO v_user_namespace_id FROM users WHERE id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'User not found: %', p_user_id; END IF;

  IF v_ws_namespace_id != v_user_namespace_id THEN
    RAISE EXCEPTION 'User does not belong to this namespace';
  END IF;

  IF EXISTS (SELECT 1 FROM workspace_users WHERE workspace_id = p_workspace_id AND user_id = p_user_id) THEN
    RAISE EXCEPTION 'User is already a member of this workspace';
  END IF;

  INSERT INTO workspace_users (workspace_id, user_id, role) VALUES (p_workspace_id, p_user_id, p_role);

  RETURN json_build_object('added', true, 'workspace_id', p_workspace_id, 'user_id', p_user_id, 'role', p_role);
END;
$$;


--
-- Name: add_workspace_to_namespace(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_workspace_to_namespace(p_namespace_id uuid, p_workspace_name text, p_workspace_slug text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_workspace_id UUID;
  v_admin RECORD;
BEGIN
  -- Platform admin check
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can add workspaces';
  END IF;

  -- Validate namespace exists
  IF NOT EXISTS (SELECT 1 FROM namespaces WHERE id = p_namespace_id) THEN
    RAISE EXCEPTION 'Namespace not found: %', p_namespace_id;
  END IF;

  -- Check slug uniqueness within namespace
  IF EXISTS (
    SELECT 1 FROM workspaces 
    WHERE namespace_id = p_namespace_id AND slug = p_workspace_slug
  ) THEN
    RAISE EXCEPTION 'Workspace slug "%" already exists in this namespace', p_workspace_slug;
  END IF;

  -- Create workspace
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (p_namespace_id, p_workspace_name, p_workspace_slug, false)
  RETURNING id INTO v_workspace_id;

  -- Auto-add all namespace admins to new workspace
  FOR v_admin IN
    SELECT id FROM users
    WHERE namespace_id = p_namespace_id AND namespace_role = 'admin'
  LOOP
    INSERT INTO workspace_users (workspace_id, user_id, role)
    VALUES (v_workspace_id, v_admin.id, 'admin')
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN json_build_object(
    'workspace_id', v_workspace_id,
    'name', p_workspace_name,
    'slug', p_workspace_slug,
    'namespace_id', p_namespace_id
  );
END;
$$;


--
-- Name: audit_log_cleanup(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_log_cleanup(p_retention_days integer DEFAULT 365) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_deleted integer;
BEGIN
    IF NOT check_is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: platform admin required';
    END IF;

    IF p_retention_days < 365 THEN
        RAISE EXCEPTION 'Minimum retention period is 365 days (SOC2 requirement)';
    END IF;

    DELETE FROM public.audit_logs
    WHERE created_at < now() - (p_retention_days || ' days')::interval;
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    
    -- Log the cleanup action itself
    INSERT INTO public.audit_logs (
        user_id, event_category, event_type, entity_type,
        entity_name, new_values, outcome
    ) VALUES (
        auth.uid(), 'admin', 'DELETE', 'audit_logs',
        'Retention cleanup', 
        jsonb_build_object('retention_days', p_retention_days, 'rows_deleted', v_deleted),
        'success'
    );
    
    RETURN v_deleted;
END;
$$;


--
-- Name: FUNCTION audit_log_cleanup(p_retention_days integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.audit_log_cleanup(p_retention_days integer) IS 'Deletes audit logs older than retention period. Minimum 365 days (SOC2). Platform admin only.';


--
-- Name: audit_log_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_log_trigger() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_id UUID;
  v_namespace_id UUID;
  v_workspace_id UUID;
  v_entity_name TEXT;
  v_old_values JSONB;
  v_new_values JSONB;
  v_changed_fields TEXT[];
  v_event_category TEXT;
  v_key TEXT;
BEGIN
  v_user_id := auth.uid();

  v_event_category := CASE TG_TABLE_NAME
    WHEN 'users' THEN 'access_control'
    WHEN 'invitations' THEN 'access_control'
    WHEN 'namespace_users' THEN 'access_control'
    WHEN 'workspace_users' THEN 'access_control'
    ELSE 'data_change'
  END;

  IF TG_OP = 'DELETE' THEN
    v_old_values := to_jsonb(OLD);
    v_new_values := NULL;
  ELSIF TG_OP = 'INSERT' THEN
    v_old_values := NULL;
    v_new_values := to_jsonb(NEW);
  ELSIF TG_OP = 'UPDATE' THEN
    v_old_values := to_jsonb(OLD);
    v_new_values := to_jsonb(NEW);
    FOR v_key IN SELECT jsonb_object_keys(v_new_values)
    LOOP
      IF v_old_values->v_key IS DISTINCT FROM v_new_values->v_key THEN
        IF v_key NOT IN ('updated_at') THEN
          v_changed_fields := array_append(v_changed_fields, v_key);
        END IF;
      END IF;
    END LOOP;
    IF v_changed_fields IS NULL OR array_length(v_changed_fields, 1) IS NULL THEN
      RETURN NEW;
    END IF;
  END IF;

  v_namespace_id := CASE
    WHEN TG_OP = 'DELETE' THEN v_old_values->>'namespace_id'
    ELSE v_new_values->>'namespace_id'
  END;

  v_workspace_id := CASE
    WHEN TG_OP = 'DELETE' THEN v_old_values->>'workspace_id'
    ELSE v_new_values->>'workspace_id'
  END;

  v_entity_name := CASE TG_TABLE_NAME
    WHEN 'applications' THEN COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'name' ELSE v_new_values->>'name' END, 'Unknown')
    WHEN 'deployment_profiles' THEN COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'name' ELSE v_new_values->>'name' END, 'Unknown')
    WHEN 'portfolios' THEN COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'name' ELSE v_new_values->>'name' END, 'Unknown')
    WHEN 'invitations' THEN COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'email' ELSE v_new_values->>'email' END, 'Unknown')
    WHEN 'users' THEN COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'email' ELSE v_new_values->>'email' END, 'Unknown')
    ELSE COALESCE(
      CASE WHEN TG_OP = 'DELETE' THEN v_old_values->>'id' ELSE v_new_values->>'id' END, 'Unknown')
  END;

  INSERT INTO audit_logs (
    namespace_id, workspace_id, user_id,
    event_category, event_type, entity_type,
    entity_id, entity_name,
    old_values, new_values, changed_fields
  ) VALUES (
    v_namespace_id::UUID,
    v_workspace_id::UUID,
    v_user_id,
    v_event_category,
    TG_OP,
    TG_TABLE_NAME,
    CASE WHEN TG_OP = 'DELETE' THEN (v_old_values->>'id')::UUID 
         ELSE (v_new_values->>'id')::UUID END,
    v_entity_name,
    v_old_values,
    v_new_values,
    v_changed_fields
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;


--
-- Name: FUNCTION audit_log_trigger(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.audit_log_trigger() IS 'Generic audit logging trigger. SECURITY DEFINER bypasses RLS for INSERT. Handles tables with id PK (standard) and user_id PK (user_sessions). Captures old/new values, changed fields, user context.';


--
-- Name: auto_calculate_deployment_profile_tech_scores(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.auto_calculate_deployment_profile_tech_scores() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
-- Calculate tech_risk
NEW.tech_risk := calculate_tech_risk(
NEW.t02, NEW.t03, NEW.t04, NEW.t05, NEW.t11
);

-- Calculate tech_health (now using t12, t13, t14 instead of t13, t14, t15)
NEW.tech_health := calculate_tech_health(
NEW.t01, NEW.t02, NEW.t03, NEW.t04, NEW.t05,
NEW.t06, NEW.t07, NEW.t08, NEW.t09, NEW.t10,
NEW.t11, NEW.t12, NEW.t13, NEW.t14
);

RETURN NEW;
END;
$$;


--
-- Name: calculate_tech_health(numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_tech_health(p_t01 numeric, p_t02 numeric, p_t03 numeric, p_t04 numeric, p_t05 numeric, p_t06 numeric, p_t07 numeric, p_t08 numeric, p_t09 numeric, p_t10 numeric, p_t11 numeric, p_t12 numeric, p_t13 numeric, p_t14 numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public'
    AS $$
DECLARE
v_weighted_sum numeric := 0;
v_total_weight numeric := 0;
v_raw_score numeric;
BEGIN
-- Apply weights for each factor (matching scoring.ts TECH_WEIGHTS)
IF p_t01 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t01 * 0.10);
v_total_weight := v_total_weight + 0.10;
END IF;

IF p_t02 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t02 * 0.10);
v_total_weight := v_total_weight + 0.10;
END IF;

IF p_t03 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t03 * 0.05);
v_total_weight := v_total_weight + 0.05;
END IF;

IF p_t04 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t04 * 0.10);
v_total_weight := v_total_weight + 0.10;
END IF;

IF p_t05 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t05 * 0.08);
v_total_weight := v_total_weight + 0.08;
END IF;

IF p_t06 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t06 * 0.08);
v_total_weight := v_total_weight + 0.08;
END IF;

IF p_t07 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t07 * 0.08);
v_total_weight := v_total_weight + 0.08;
END IF;

IF p_t08 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t08 * 0.06);
v_total_weight := v_total_weight + 0.06;
END IF;

IF p_t09 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t09 * 0.05);
v_total_weight := v_total_weight + 0.05;
END IF;

IF p_t10 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t10 * 0.05);
v_total_weight := v_total_weight + 0.05;
END IF;

IF p_t11 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t11 * 0.05);
v_total_weight := v_total_weight + 0.05;
END IF;

-- T12: Modern UX Support (4%)
IF p_t12 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t12 * 0.04);
v_total_weight := v_total_weight + 0.04;
END IF;

-- T13: Integration Count (7%)
IF p_t13 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t13 * 0.07);
v_total_weight := v_total_weight + 0.07;
END IF;

-- T14: Data Accessibility (9%)
IF p_t14 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + (p_t14 * 0.09);
v_total_weight := v_total_weight + 0.09;
END IF;

-- Return null if no factors available
IF v_total_weight = 0 THEN
RETURN NULL;
END IF;

-- Calculate raw score (1-5 scale)
v_raw_score := v_weighted_sum / v_total_weight;

-- Normalize to 0-100 scale
RETURN ROUND(((v_raw_score - 1) / 4) * 100, 2);
END;
$$;


--
-- Name: calculate_tech_risk(numeric, numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_tech_risk(p_t02 numeric, p_t03 numeric, p_t04 numeric, p_t05 numeric, p_t11 numeric) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO 'public'
    AS $$
DECLARE
v_weighted_sum numeric := 0;
v_total_weight numeric := 0;
v_raw_score numeric;
BEGIN
-- t04_security_controls: 0.25
IF p_t04 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + ((6 - p_t04) * 0.25);
v_total_weight := v_total_weight + 0.25;
END IF;

-- t02_vendor_support: 0.20
IF p_t02 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + ((6 - p_t02) * 0.20);
v_total_weight := v_total_weight + 0.20;
END IF;

-- t05_resilience_recovery: 0.20
IF p_t05 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + ((6 - p_t05) * 0.20);
v_total_weight := v_total_weight + 0.20;
END IF;

-- t11_data_sensitivity_controls: 0.20
IF p_t11 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + ((6 - p_t11) * 0.20);
v_total_weight := v_total_weight + 0.20;
END IF;

-- t03_dev_platform: 0.15
IF p_t03 IS NOT NULL THEN
v_weighted_sum := v_weighted_sum + ((6 - p_t03) * 0.15);
v_total_weight := v_total_weight + 0.15;
END IF;

-- Return null if no factors available
IF v_total_weight = 0 THEN
RETURN NULL;
END IF;

-- Calculate raw score (1-5 scale)
v_raw_score := v_weighted_sum / v_total_weight;

-- Normalize to 0-100 scale: ((raw - 1) / 4) * 100
RETURN ROUND(((v_raw_score - 1) / 4) * 100, 2);
END;
$$;


--
-- Name: can_manage_workspace_budget(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.can_manage_workspace_budget(_workspace_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM workspace_users wu
    JOIN workspaces w ON w.id = wu.workspace_id
    WHERE wu.workspace_id = _workspace_id
    AND wu.user_id = auth.uid()
    AND wu.role = 'admin'
  );
END;
$$;


--
-- Name: check_is_namespace_admin(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_is_namespace_admin(_workspace_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM users u
    JOIN workspaces w ON w.namespace_id = u.namespace_id
    WHERE w.id = _workspace_id
    AND u.id = auth.uid()
    AND u.namespace_role = 'admin'
  );
END;
$$;


--
-- Name: check_is_namespace_admin_of_namespace(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_is_namespace_admin_of_namespace(_namespace_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Check if user is admin in their home namespace AND it matches
  IF EXISTS (
    SELECT 1
    FROM users
    WHERE id = auth.uid()
    AND namespace_id = _namespace_id
    AND namespace_role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- OR check if user has access via namespace_users
  -- (assume all namespace_users entries are admins for now)
  RETURN EXISTS (
    SELECT 1
    FROM namespace_users nu
    JOIN users u ON u.id = nu.user_id
    WHERE nu.user_id = auth.uid()
    AND nu.namespace_id = _namespace_id
    AND u.namespace_role = 'admin'  -- User is admin in their home namespace
  );
END;
$$;


--
-- Name: check_is_platform_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_is_platform_admin() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM platform_admins
    WHERE user_id = auth.uid()
    AND is_active = true
  );
END;
$$;


--
-- Name: check_is_workspace_member(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_is_workspace_member(_workspace_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM workspace_users
    WHERE workspace_id = _workspace_id
    AND user_id = auth.uid()
  );
END;
$$;


--
-- Name: check_portfolio_assignment_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_portfolio_assignment_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  dp_namespace_id UUID;
  portfolio_namespace_id UUID;
BEGIN
  -- Get namespace of the deployment profile (via application → workspace)
  SELECT w.namespace_id INTO dp_namespace_id
  FROM deployment_profiles dp
  JOIN applications a ON a.id = dp.application_id
  JOIN workspaces w ON w.id = a.workspace_id
  WHERE dp.id = NEW.deployment_profile_id;

  -- Get namespace of the portfolio (via workspace)
  SELECT w.namespace_id INTO portfolio_namespace_id
  FROM portfolios p
  JOIN workspaces w ON w.id = p.workspace_id
  WHERE p.id = NEW.portfolio_id;

  -- Check they match
  IF dp_namespace_id != portfolio_namespace_id THEN
    RAISE EXCEPTION 'Cannot assign deployment profile to portfolio in different namespace. DP namespace: %, Portfolio namespace: %', 
      dp_namespace_id, portfolio_namespace_id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: check_workspace_user_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_workspace_user_namespace() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Platform admins can manage workspace membership across namespaces
  IF check_is_platform_admin() THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM users u
    JOIN workspaces w ON w.namespace_id = u.namespace_id
    WHERE u.id = NEW.user_id 
    AND w.id = NEW.workspace_id
  ) THEN
    RAISE EXCEPTION 'User cannot be added to workspace in different namespace';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: compute_lifecycle_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.compute_lifecycle_status() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.current_status := CASE
    WHEN NEW.end_of_life_date IS NOT NULL AND NEW.end_of_life_date < CURRENT_DATE THEN 'end_of_support'
    WHEN NEW.extended_support_end IS NOT NULL AND NEW.extended_support_end < CURRENT_DATE THEN 'end_of_support'
    WHEN NEW.mainstream_support_end IS NOT NULL AND NEW.mainstream_support_end < CURRENT_DATE THEN 'extended'
    WHEN NEW.ga_date IS NOT NULL AND NEW.ga_date <= CURRENT_DATE THEN 'mainstream'
    WHEN NEW.ga_date IS NOT NULL AND NEW.ga_date > CURRENT_DATE THEN 'preview'
    ELSE 'incomplete_data'
  END;
  RETURN NEW;
END;
$$;


--
-- Name: copy_assessment_factors_to_new_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.copy_assessment_factors_to_new_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
  v_factor_record RECORD;
  v_new_factor_id uuid;
  v_option_record RECORD;
BEGIN
  -- Only copy if template namespace exists and has factors
  IF NOT EXISTS (
    SELECT 1 FROM assessment_factors WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no factors, skipping copy';
    RETURN NEW;
  END IF;

  -- Copy all factors from template namespace
  FOR v_factor_record IN
    SELECT * FROM assessment_factors
    WHERE namespace_id = v_template_namespace_id
    ORDER BY sort_order
  LOOP
    -- Insert new factor for the new namespace
    INSERT INTO assessment_factors (
      namespace_id,
      factor_code,
      factor_type,
      question,
      description,
      weight,
      contributes_to_criticality,
      contributes_to_tech_risk,
      sort_order,
      is_active,
      criticality_weight,
      tech_risk_weight,
      applicability_rules,
      label,
      survey_order,
      domain
    ) VALUES (
      NEW.id,
      v_factor_record.factor_code,
      v_factor_record.factor_type,
      v_factor_record.question,
      v_factor_record.description,
      v_factor_record.weight,
      v_factor_record.contributes_to_criticality,
      v_factor_record.contributes_to_tech_risk,
      v_factor_record.sort_order,
      v_factor_record.is_active,
      v_factor_record.criticality_weight,
      v_factor_record.tech_risk_weight,
      v_factor_record.applicability_rules,
      v_factor_record.label,
      v_factor_record.survey_order,
      v_factor_record.domain
    )
    RETURNING id INTO v_new_factor_id;

    -- Copy all options for this factor
    FOR v_option_record IN
      SELECT score, label, description
      FROM assessment_factor_options
      WHERE factor_id = v_factor_record.id
      ORDER BY score
    LOOP
      INSERT INTO assessment_factor_options (
        factor_id,
        score,
        label,
        description
      ) VALUES (
        v_new_factor_id,
        v_option_record.score,
        v_option_record.label,
        v_option_record.description
      );
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Copied % factors to new namespace %', 
    (SELECT COUNT(*) FROM assessment_factors WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: copy_assessment_thresholds_to_new_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.copy_assessment_thresholds_to_new_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Only copy if template namespace exists and has thresholds
  IF NOT EXISTS (
    SELECT 1 FROM assessment_thresholds WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no thresholds, skipping copy';
    RETURN NEW;
  END IF;

  -- Copy all thresholds from template namespace
  INSERT INTO assessment_thresholds (
    namespace_id,
    threshold_type,
    threshold_name,
    threshold_value
  )
  SELECT
    NEW.id,
    threshold_type,
    threshold_name,
    threshold_value
  FROM assessment_thresholds
  WHERE namespace_id = v_template_namespace_id;

  RAISE NOTICE 'Copied % thresholds to new namespace %', 
    (SELECT COUNT(*) FROM assessment_thresholds WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: copy_service_types_to_new_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.copy_service_types_to_new_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Only copy if template namespace exists and has categories
  IF NOT EXISTS (
    SELECT 1 FROM service_type_categories WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no service type categories, skipping copy';
    RETURN NEW;
  END IF;

  -- Step 1: Copy categories from template
  INSERT INTO service_type_categories (
    namespace_id,
    code,
    name,
    description,
    display_order,
    is_active
  )
  SELECT
    NEW.id,
    code,
    name,
    description,
    display_order,
    is_active
  FROM service_type_categories
  WHERE namespace_id = v_template_namespace_id;

  -- Step 2: Copy service types, linking to new namespace's categories
  INSERT INTO service_types (
    namespace_id,
    category_id,
    code,
    name,
    description,
    display_order,
    is_active
  )
  SELECT
    NEW.id,
    new_cat.id,
    t.code,
    t.name,
    t.description,
    t.display_order,
    t.is_active
  FROM service_types t
  JOIN service_type_categories old_cat ON old_cat.id = t.category_id
  JOIN service_type_categories new_cat ON new_cat.namespace_id = NEW.id AND new_cat.code = old_cat.code
  WHERE t.namespace_id = v_template_namespace_id;

  RAISE NOTICE 'Copied % categories and % service types to new namespace %', 
    (SELECT COUNT(*) FROM service_type_categories WHERE namespace_id = NEW.id),
    (SELECT COUNT(*) FROM service_types WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: copy_software_product_categories_to_new_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.copy_software_product_categories_to_new_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Only copy if template namespace exists and has categories
  IF NOT EXISTS (
    SELECT 1 FROM software_product_categories WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no software product categories, skipping copy';
    RETURN NEW;
  END IF;

  -- Copy all categories from template namespace
  INSERT INTO software_product_categories (
    namespace_id,
    code,
    name,
    description,
    display_order,
    is_active
  )
  SELECT
    NEW.id,
    code,
    name,
    description,
    display_order,
    is_active
  FROM software_product_categories
  WHERE namespace_id = v_template_namespace_id
  ORDER BY display_order;

  RAISE NOTICE 'Copied % software product categories to new namespace %', 
    (SELECT COUNT(*) FROM software_product_categories WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: copy_technology_categories_to_new_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.copy_technology_categories_to_new_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Only copy if template namespace exists and has categories
  IF NOT EXISTS (
    SELECT 1 FROM technology_product_categories WHERE namespace_id = v_template_namespace_id
  ) THEN
    RAISE NOTICE 'Template namespace has no technology categories, skipping copy';
    RETURN NEW;
  END IF;

  -- Copy all categories from template namespace
  INSERT INTO technology_product_categories (
    namespace_id,
    name,
    description,
    display_order,
    is_active
  )
  SELECT
    NEW.id,
    name,
    description,
    display_order,
    is_active
  FROM technology_product_categories
  WHERE namespace_id = v_template_namespace_id
  ORDER BY display_order;

  RAISE NOTICE 'Copied % technology categories to new namespace %', 
    (SELECT COUNT(*) FROM technology_product_categories WHERE namespace_id = NEW.id),
    NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: create_default_deployment_profile(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_default_deployment_profile() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.deployment_profiles (
    application_id,
    workspace_id,
    name,
    is_primary,
    tech_assessment_status
  )
  VALUES (
    NEW.id,
    NEW.workspace_id,
    NEW.name || ' — Region-PROD',
    true,
    'not_started'
  );
  RETURN NEW;
END;
$$;


--
-- Name: create_default_portfolio_for_workspace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_default_portfolio_for_workspace() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Only create default portfolio if one doesn't already exist
  IF NOT EXISTS (
    SELECT 1 FROM portfolios
    WHERE workspace_id = NEW.id
    AND is_default = true
  ) THEN
    INSERT INTO portfolios (name, workspace_id, is_default)
    VALUES ('Core', NEW.id, true);
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: create_workspace_as_super_admin(uuid, text, text, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_workspace_as_super_admin(p_namespace_id uuid, p_name text, p_slug text, p_admin_user_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_workspace_id uuid;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can call this function';
  END IF;

  -- Disable auto-add trigger
  EXECUTE 'ALTER TABLE workspaces DISABLE TRIGGER add_workspace_creator_trigger';
  
  -- Create workspace
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (p_namespace_id, p_name, p_slug, true)
  RETURNING id INTO v_workspace_id;
  
  -- Add admin to workspace
  INSERT INTO workspace_users (workspace_id, user_id, role)
  VALUES (v_workspace_id, p_admin_user_id, 'admin');
  
  -- Re-enable trigger
  EXECUTE 'ALTER TABLE workspaces ENABLE TRIGGER add_workspace_creator_trigger';
  
  RETURN v_workspace_id;
END;
$$;


--
-- Name: generate_soc2_evidence(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_soc2_evidence() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_result jsonb;
BEGIN
    -- Platform admin check: skip if called from SQL Editor (no auth context)
    IF auth.uid() IS NOT NULL AND NOT check_is_platform_admin() THEN
        RAISE EXCEPTION 'Access denied: platform admin required';
    END IF;

    SELECT jsonb_build_object(
        'report_generated_at', now(),
        'report_type', 'SOC2 Type II Evidence Summary',
        'platform_version', 'GetInSync NextGen',
        
        'cc6_1_logical_access', jsonb_build_object(
            'total_tables', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'),
            'tables_with_rls', (SELECT count(DISTINCT tablename) FROM pg_policies WHERE schemaname = 'public'),
            'total_rls_policies', (SELECT count(*) FROM pg_policies WHERE schemaname = 'public'),
            'total_users', (SELECT count(*) FROM public.users),
            'users_by_namespace_role', (
                SELECT COALESCE(jsonb_object_agg(COALESCE(namespace_role, 'null'), cnt), '{}'::jsonb)
                FROM (SELECT namespace_role, count(*) as cnt FROM public.users GROUP BY namespace_role) r
            ),
            'platform_admins', (SELECT count(*) FROM public.platform_admins),
            'total_namespaces', (SELECT count(*) FROM public.namespaces),
            'namespaces_by_tier', (
                SELECT COALESCE(jsonb_object_agg(tier, cnt), '{}'::jsonb)
                FROM (SELECT tier, count(*) as cnt FROM public.namespaces GROUP BY tier) t
            ),
            'namespaces_by_status', (
                SELECT COALESCE(jsonb_object_agg(COALESCE(status, 'null'), cnt), '{}'::jsonb)
                FROM (SELECT status, count(*) as cnt FROM public.namespaces GROUP BY status) s
            )
        ),

        'cc6_2_encryption', jsonb_build_object(
            'database_region', 'ca-central-1',
            'encryption_at_rest', 'AES-256 (Supabase managed)',
            'encryption_in_transit', 'TLS 1.2+ (enforced)',
            'namespaces_by_region', (
                SELECT COALESCE(jsonb_object_agg(region, cnt), '{}'::jsonb)
                FROM (SELECT region, count(*) as cnt FROM public.namespaces GROUP BY region) r
            )
        ),

        'cc6_6_audit_logging', jsonb_build_object(
            'audit_logging_enabled', true,
            'audit_logging_start_date', (SELECT min(created_at) FROM public.audit_logs),
            'total_audit_entries', (SELECT count(*) FROM public.audit_logs),
            'entries_last_30_days', (SELECT count(*) FROM public.audit_logs WHERE created_at > now() - interval '30 days'),
            'entries_by_category', (
                SELECT COALESCE(jsonb_object_agg(event_category, cnt), '{}'::jsonb)
                FROM (SELECT event_category, count(*) as cnt FROM public.audit_logs GROUP BY event_category) c
            ),
            'entries_by_event_type', (
                SELECT COALESCE(jsonb_object_agg(event_type, cnt), '{}'::jsonb)
                FROM (SELECT event_type, count(*) as cnt FROM public.audit_logs GROUP BY event_type) e
            ),
            'audited_tables', (
                SELECT COALESCE(jsonb_agg(DISTINCT entity_type), '[]'::jsonb)
                FROM public.audit_logs
            ),
            'auth_audit_entries', (SELECT count(*) FROM auth.audit_log_entries),
            'auth_audit_start_date', (SELECT min(created_at) FROM auth.audit_log_entries)
        ),

        'c1_1_tenant_isolation', jsonb_build_object(
            'multi_tenant_model', 'Namespace-scoped with RLS',
            'isolation_method', 'PostgreSQL Row Level Security',
            'namespace_switching_method', 'user_sessions.current_namespace_id',
            'orphaned_records_check', jsonb_build_object(
                'orphaned_workspace_users', (
                    SELECT count(*) FROM public.workspace_users wu
                    WHERE NOT EXISTS (SELECT 1 FROM public.workspaces w WHERE w.id = wu.workspace_id)
                ),
                'orphaned_portfolio_assignments', (
                    SELECT count(*) FROM public.portfolio_assignments pa
                    WHERE NOT EXISTS (SELECT 1 FROM public.portfolios p WHERE p.id = pa.portfolio_id)
                ),
                'users_without_namespace', (
                    SELECT count(*) FROM public.users u WHERE u.namespace_id IS NULL
                )
            )
        ),

        'a1_2_backup_recovery', jsonb_build_object(
            'backup_method', 'Supabase automated daily + manual pg_dump',
            'last_manual_backup', '2026-02-08',
            'schema_table_count', (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'),
            'schema_view_count', (SELECT count(*) FROM information_schema.views WHERE table_schema = 'public'),
            'schema_function_count', (SELECT count(*) FROM information_schema.routines WHERE routine_schema = 'public')
        ),

        'access_review', jsonb_build_object(
            'workspace_admins', (SELECT count(DISTINCT user_id) FROM public.workspace_users WHERE role = 'admin'),
            'namespace_admins', (SELECT count(*) FROM public.users WHERE namespace_role = 'admin'),
            'platform_admin_count', (SELECT count(*) FROM public.platform_admins),
            'recent_access_control_events_30d', (
                SELECT count(*) FROM public.audit_logs
                WHERE event_category = 'access_control'
                AND created_at > now() - interval '30 days'
            ),
            'recent_namespace_switches_30d', (
                SELECT count(*) FROM public.audit_logs
                WHERE entity_type = 'user_sessions'
                AND created_at > now() - interval '30 days'
            )
        )
    ) INTO v_result;
    
    RETURN v_result;
END;
$$;


--
-- Name: FUNCTION generate_soc2_evidence(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.generate_soc2_evidence() IS 'Generates SOC2 Type II evidence report as JSON. Platform admin only. Run monthly and archive results.';


--
-- Name: get_current_namespace_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_current_namespace_id() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT current_namespace_id 
  FROM user_sessions 
  WHERE user_id = auth.uid();
$$;


--
-- Name: get_invitation_details(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_invitation_details(p_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'invitation_id', i.id,
    'email', i.email,
    'name', i.name,
    'namespace_name', n.name,
    'namespace_id', i.namespace_id,
    'namespace_role', i.namespace_role,
    'invited_by', u.name,
    'expires_at', i.expires_at,
    'status', i.status,
    'workspaces', COALESCE(
      (SELECT jsonb_agg(jsonb_build_object(
        'workspace_name', w.name,
        'role', iw.role
      ))
      FROM invitation_workspaces iw
      JOIN workspaces w ON w.id = iw.workspace_id
      WHERE iw.invitation_id = i.id),
      '[]'::jsonb
    )
  ) INTO v_result
  FROM invitations i
  JOIN namespaces n ON n.id = i.namespace_id
  LEFT JOIN users u ON u.id = i.invited_by
  WHERE i.token = p_token
    AND i.status = 'pending'
    AND i.expires_at > now();

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;


--
-- Name: get_user_namespace_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_namespace_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT namespace_id 
  FROM namespace_users 
  WHERE user_id = auth.uid();
$$;


--
-- Name: get_user_namespaces(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_namespaces() RETURNS TABLE(namespace_id uuid, namespace_name text, namespace_slug text, user_role text, is_current boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  -- Check if user is platform admin
  SELECT 
    n.id as namespace_id,
    n.name as namespace_name,
    n.slug as namespace_slug,
    COALESCE(nu.role, 'platform_admin') as user_role,
    (n.id = get_current_namespace_id()) as is_current
  FROM namespaces n
  LEFT JOIN namespace_users nu ON nu.namespace_id = n.id AND nu.user_id = auth.uid()
  WHERE 
    -- Platform admins see all namespaces
    check_is_platform_admin()
    OR 
    -- Regular users see only their namespaces
    nu.user_id = auth.uid()
  ORDER BY n.name;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_has_invitation BOOLEAN;
  v_namespace_id UUID;
  v_workspace_id UUID;
  v_org_name TEXT;
  v_org_slug TEXT;
BEGIN
  -- Check if this email has a pending invitation
  SELECT EXISTS(
    SELECT 1 FROM invitations 
    WHERE email = NEW.email 
      AND status = 'pending' 
      AND expires_at > now()
  ) INTO v_has_invitation;

  IF v_has_invitation THEN
    -- INVITATION SIGNUP: Create minimal user record
    -- accept_invitation() will set namespace_id, namespace_role, workspace_users
    INSERT INTO public.users (id, email, name, namespace_role, created_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      'viewer',
      NEW.created_at
    )
    ON CONFLICT (id) DO NOTHING;
  ELSE
    -- SELF-SIGNUP: Create full namespace + workspace + user as admin
    v_org_name := INITCAP(SPLIT_PART(SPLIT_PART(NEW.email, '@', 2), '.', 1));
    v_org_slug := LOWER(REPLACE(v_org_name, ' ', '-')) || '-' || SUBSTRING(NEW.id::TEXT, 1, 8);

    -- Create namespace
    INSERT INTO namespaces (name, slug, tier)
    VALUES (v_org_name, v_org_slug, 'trial')
    RETURNING id INTO v_namespace_id;

    -- Create default workspace (bypass the add_workspace_creator trigger)
    INSERT INTO workspaces (namespace_id, name, slug, is_default)
    VALUES (v_namespace_id, 'General', 'general', TRUE)
    RETURNING id INTO v_workspace_id;

    -- Create user as namespace admin
    INSERT INTO public.users (id, email, name, namespace_id, namespace_role, created_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      v_namespace_id,
      'admin',
      NEW.created_at
    )
    ON CONFLICT (id) DO NOTHING;

    -- Add user to default workspace as admin
    INSERT INTO workspace_users (workspace_id, user_id, role)
    VALUES (v_workspace_id, NEW.id, 'admin')
    ON CONFLICT (workspace_id, user_id) DO NOTHING;

    -- Add to namespace_users
    INSERT INTO namespace_users (user_id, namespace_id, role)
    VALUES (NEW.id, v_namespace_id, 'admin')
    ON CONFLICT (user_id, namespace_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: initialize_app_budgets(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.initialize_app_budgets(p_workspace_id uuid) RETURNS TABLE(updated_count integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_count integer;
BEGIN
  -- Update all apps in workspace with budget_amount = 0
  UPDATE applications a
  SET 
    budget_amount = COALESCE(
      (SELECT total_run_rate 
       FROM vw_application_run_rate 
       WHERE application_id = a.id),
      0
    ),
    updated_at = now()
  WHERE a.workspace_id = p_workspace_id
  AND a.budget_amount = 0;
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_count;
END;
$$;


--
-- Name: FUNCTION initialize_app_budgets(p_workspace_id uuid); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.initialize_app_budgets(p_workspace_id uuid) IS 'Initializes app budgets to their current run rate for apps with budget_amount = 0';


--
-- Name: initialize_it_service_budgets(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.initialize_it_service_budgets(p_workspace_id uuid, p_fiscal_year integer DEFAULT 2025) RETURNS TABLE(it_service_id uuid, it_service_name text, current_run_rate numeric, new_budget numeric, status text)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  WITH service_run_rates AS (
    SELECT 
      its.id,
      its.name,
      COALESCE(
        (SELECT SUM(
          CASE
            WHEN dpis.allocation_basis = 'fixed' THEN dpis.allocation_value
            WHEN dpis.allocation_basis = 'percent' AND dpis.allocation_value > 100 THEN dpis.allocation_value
            WHEN dpis.allocation_basis = 'percent' THEN its.annual_cost * dpis.allocation_value / 100
            ELSE dpis.allocation_value
          END
        )
        FROM deployment_profile_it_services dpis
        WHERE dpis.it_service_id = its.id),
        0
      ) as run_rate
    FROM it_services its
    WHERE its.owner_workspace_id = p_workspace_id
      AND its.budget_amount IS NULL  -- Only initialize services without budgets
  ),
  updates AS (
    UPDATE it_services its
    SET 
      budget_amount = ROUND(srr.run_rate * 1.10, 2),
      budget_fiscal_year = p_fiscal_year
    FROM service_run_rates srr
    WHERE its.id = srr.id
    RETURNING its.id, its.name, srr.run_rate, its.budget_amount
  )
  SELECT 
    u.id,
    u.name,
    u.run_rate,
    u.budget_amount,
    CASE 
      WHEN u.run_rate = 0 THEN 'no_costs'
      ELSE 'initialized'
    END::text
  FROM updates u;
END;
$$;


--
-- Name: FUNCTION initialize_it_service_budgets(p_workspace_id uuid, p_fiscal_year integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.initialize_it_service_budgets(p_workspace_id uuid, p_fiscal_year integer) IS 'Initialize IT Service budgets to 110% of current run rate';


--
-- Name: is_platform_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_platform_admin() RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM platform_admins
    WHERE user_id = auth.uid() AND is_active = true
  );
END;
$$;


--
-- Name: prevent_assignment_to_parent_portfolio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_assignment_to_parent_portfolio() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Check if target portfolio has any children
  IF EXISTS (
    SELECT 1 FROM portfolios 
    WHERE parent_portfolio_id = NEW.portfolio_id
  ) THEN
    RAISE EXCEPTION 
      'Cannot assign applications to a portfolio that has child portfolios. Assign to a leaf portfolio instead. Portfolio ID: %', 
      NEW.portfolio_id
      USING HINT = 'Remove child portfolios first, or assign to a different portfolio.';
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: prevent_children_on_assigned_portfolio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_children_on_assigned_portfolio() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Only check if setting a parent (not NULL)
  IF NEW.parent_portfolio_id IS NOT NULL THEN
    -- Check if proposed parent has any assignments
    IF EXISTS (
      SELECT 1 FROM portfolio_assignments 
      WHERE portfolio_id = NEW.parent_portfolio_id
    ) THEN
      RAISE EXCEPTION 
        'Cannot add child portfolios to a portfolio that has application assignments. Remove assignments first, or choose a different parent. Parent Portfolio ID: %', 
        NEW.parent_portfolio_id
        USING HINT = 'Query portfolio_assignments to see what is assigned to this portfolio.';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;


--
-- Name: prevent_children_on_default_portfolio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_children_on_default_portfolio() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.parent_portfolio_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM portfolios
      WHERE id = NEW.parent_portfolio_id
      AND is_default = true
    ) THEN
      RAISE EXCEPTION
        'Cannot nest portfolios under a default portfolio. Default portfolios must remain leaf portfolios to accept application assignments. Portfolio ID: %',
        NEW.parent_portfolio_id
        USING HINT = 'Choose a non-default portfolio as the parent, or remove the default flag first.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: prevent_default_on_parent_portfolio(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_default_on_parent_portfolio() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  IF NEW.is_default = true THEN
    IF EXISTS (
      SELECT 1 FROM portfolios
      WHERE parent_portfolio_id = NEW.id
    ) THEN
      RAISE EXCEPTION
        'Cannot make a parent portfolio the default. Portfolio "%" has child portfolios. Remove or reparent children first.',
        NEW.name
        USING HINT = 'The default portfolio must be a leaf portfolio to accept automatic application assignments.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: prevent_parent_portfolio_deletion(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.prevent_parent_portfolio_deletion() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Check if portfolio has children
  IF EXISTS (
    SELECT 1 FROM portfolios WHERE parent_portfolio_id = OLD.id
  ) THEN
    RAISE EXCEPTION 
      'Cannot delete portfolio "%" because it has child portfolios. Delete or move children first.', 
      OLD.name
      USING HINT = 'Use UPDATE to set parent_portfolio_id = NULL on children, or DELETE children first.';
  END IF;
  
  RETURN OLD;
END;
$$;


--
-- Name: provision_namespace(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.provision_namespace(p_org_name text, p_slug text, p_tier text, p_admin_email text, p_admin_name text, p_workspace_name text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_namespace_id uuid;
  v_workspace_id uuid;
  v_invite_token uuid;
  v_expires_at timestamptz;
  v_result jsonb;
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can provision namespaces';
  END IF;

  -- Validate tier (UPDATED TO NEW TIERS)
  IF p_tier NOT IN ('trial', 'essentials', 'plus', 'enterprise') THEN
    RAISE EXCEPTION 'Invalid tier: %. Must be trial, essentials, plus, or enterprise', p_tier;
  END IF;

  -- Step 1: Create namespace (triggers will auto-seed templates)
  INSERT INTO namespaces (name, slug, tier)
  VALUES (p_org_name, p_slug, p_tier)
  RETURNING id INTO v_namespace_id;
  
  -- Step 2: Create workspace with trigger disabled
  EXECUTE 'ALTER TABLE workspaces DISABLE TRIGGER add_workspace_creator_trigger';
  
  INSERT INTO workspaces (namespace_id, name, slug, is_default)
  VALUES (
    v_namespace_id,
    p_workspace_name,
    lower(regexp_replace(p_workspace_name, '[^a-z0-9]+', '-', 'g')),
    true
  )
  RETURNING id INTO v_workspace_id;
  
  EXECUTE 'ALTER TABLE workspaces ENABLE TRIGGER add_workspace_creator_trigger';
  
  -- Step 3: Create invitation
  v_invite_token := gen_random_uuid();
  v_expires_at := now() + interval '7 days';
  
  INSERT INTO invitations (
    namespace_id, email, name, namespace_role, invited_by, token, expires_at, status
  ) VALUES (
    v_namespace_id, p_admin_email, p_admin_name, 'admin',
    auth.uid(), v_invite_token::text, v_expires_at, 'pending'
  );
  
  INSERT INTO invitation_workspaces (invitation_id, workspace_id, role)
  SELECT 
    (SELECT id FROM invitations WHERE token = v_invite_token::text),
    v_workspace_id,
    'admin';
  
  v_result := jsonb_build_object(
    'namespace_id', v_namespace_id,
    'namespace_name', p_org_name,
    'slug', p_slug,
    'tier', p_tier,
    'workspace_id', v_workspace_id,
    'invite_token', v_invite_token,
    'invite_link', format('https://nextgen.getinsync.ca/signup?token=%s', v_invite_token)
  );
  
  RETURN v_result;
END;
$$;


--
-- Name: remove_user_from_workspace(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_user_from_workspace(p_workspace_id uuid, p_user_id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_role TEXT;
BEGIN
  -- Platform admin check
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can remove users from workspaces';
  END IF;

  -- Check membership exists
  SELECT role INTO v_role
  FROM workspace_users
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User is not a member of this workspace';
  END IF;

  -- Remove from workspace
  DELETE FROM workspace_users
  WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  RETURN json_build_object(
    'removed', true,
    'workspace_id', p_workspace_id,
    'user_id', p_user_id,
    'previous_role', v_role
  );
END;
$$;


--
-- Name: search_audit_logs(uuid, uuid, text, uuid, text, timestamp with time zone, timestamp with time zone, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_audit_logs(p_namespace_id uuid DEFAULT NULL::uuid, p_user_id uuid DEFAULT NULL::uuid, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_event_category text DEFAULT NULL::text, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 100, p_offset integer DEFAULT 0) RETURNS TABLE(id uuid, namespace_id uuid, workspace_id uuid, user_id uuid, event_category text, event_type text, entity_type text, entity_id uuid, entity_name text, changed_fields text[], outcome text, created_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    -- Always scope to current namespace — no exceptions
    -- Cross-namespace view is a separate future RPC
    p_namespace_id := get_current_namespace_id();

    RETURN QUERY
    SELECT 
        al.id, al.namespace_id, al.workspace_id, al.user_id,
        al.event_category, al.event_type,
        al.entity_type, al.entity_id, al.entity_name,
        al.changed_fields, al.outcome, al.created_at
    FROM public.audit_logs al
    WHERE al.namespace_id = p_namespace_id
      AND (p_user_id IS NULL OR al.user_id = p_user_id)
      AND (p_entity_type IS NULL OR al.entity_type = p_entity_type)
      AND (p_entity_id IS NULL OR al.entity_id = p_entity_id)
      AND (p_event_category IS NULL OR al.event_category = p_event_category)
      AND (p_from_date IS NULL OR al.created_at >= p_from_date)
      AND (p_to_date IS NULL OR al.created_at <= p_to_date)
    ORDER BY al.created_at DESC
    LIMIT LEAST(p_limit, 1000)
    OFFSET p_offset;
END;
$$;


--
-- Name: FUNCTION search_audit_logs(p_namespace_id uuid, p_user_id uuid, p_entity_type text, p_entity_id uuid, p_event_category text, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_limit integer, p_offset integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.search_audit_logs(p_namespace_id uuid, p_user_id uuid, p_entity_type text, p_entity_id uuid, p_event_category text, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_limit integer, p_offset integer) IS 'Search audit logs with filters. Non-platform-admins scoped to current namespace. Returns summary (no old/new values for performance).';


--
-- Name: seed_alert_preferences_for_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seed_alert_preferences_for_namespace() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO alert_preferences (
    namespace_id,
    show_over_budget,
    show_no_budget,
    no_budget_severity,
    show_eliminate_apps,
    eliminate_severity,
    visible_to_all
  ) VALUES (
    NEW.id,
    true,
    true,
    'info',
    true,
    'warning',
    true
  );
  RETURN NEW;
END;
$$;


--
-- Name: seed_default_assessment_factors(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seed_default_assessment_factors() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  -- Insert Business Factors (B1-B10)
  INSERT INTO assessment_factors (namespace_id, factor_code, factor_type, description, weight, sort_order, contributes_to_business_fit, contributes_to_criticality, label, survey_order, domain)
  VALUES
    (NEW.id, 'B1', 'business', 'Strategic Contribution to Organizational Goals', 15, 1, true, true, 'Strategic Contribution to Organizational Goals', 1, 'Strategic Alignment'),
    (NEW.id, 'B2', 'business', 'Regional Growth Support', 15, 2, true, true, 'Strategic Contribution to Growth', 2, 'Strategic Alignment'),
    (NEW.id, 'B3', 'business', 'Public Confidence Impact', 5, 3, true, true, 'Public Confidence Impact', 3, 'Strategic Alignment'),
    (NEW.id, 'B4', 'business', 'Scope of Use', 15, 4, true, true, 'Scope of Use', 4, 'Business Impact'),
    (NEW.id, 'B5', 'business', 'Business Process Criticality', 15, 5, true, true, 'Business Process Criticality', 5, 'Business Impact'),
    (NEW.id, 'B6', 'business', 'Business Interruption Tolerance', 0, 6, false, true, 'Business Interruption Tolerance', 6, 'Business Impact'),
    (NEW.id, 'B7', 'business', 'Essential Service Impact', 0, 7, false, true, 'Safety Impact', 7, 'Business Impact'),
    (NEW.id, 'B8', 'business', 'Current Needs Fulfillment', 10, 8, true, false, 'Current Needs Fulfillment', 8, 'Business Fit'),
    (NEW.id, 'B9', 'business', 'Future Needs Adaptability', 10, 9, true, false, 'Future Needs Adaptability', 9, 'Business Fit'),
    (NEW.id, 'B10', 'business', 'User Satisfaction', 15, 10, true, false, 'User Satisfaction', 10, 'Business Fit'),

  -- Insert Technical Factors (T01-T14)
    (NEW.id, 'T01', 'technical', 'Platform / Product Footprint', 10, 1, false, false, 'Platform / Product Footprint', 1, 'Platform Architecture & Hosting'),
    (NEW.id, 'T02', 'technical', 'Vendor and Support Availability', 10, 2, false, false, 'Vendor and Support Availability', 11, 'Resilience & Operations'),
    (NEW.id, 'T03', 'technical', 'Application Development Platform', 5, 3, false, false, 'Application Development Platform', 2, 'Platform Architecture & Hosting'),
    (NEW.id, 'T04', 'technical', 'Security Controls', 10, 4, false, false, 'Security Controls', 6, 'Security Posture'),
    (NEW.id, 'T05', 'technical', 'Resilience & Recovery', 8, 5, false, false, 'Resilience & Recovery', 9, 'Resilience & Operations'),
    (NEW.id, 'T06', 'technical', 'Observability & Manageability', 8, 6, false, false, 'Observability & Manageability', 10, 'Resilience & Operations'),
    (NEW.id, 'T07', 'technical', 'Integration Capabilities', 8, 7, false, false, 'Integration Capabilities', 12, 'Integration Capabilities'),
    (NEW.id, 'T08', 'technical', 'Identity Assurance', 6, 8, false, false, 'Identity Assurance', 8, 'Security Posture'),
    (NEW.id, 'T09', 'technical', 'Platform Portability', 5, 9, false, false, 'Platform Portability', 3, 'Platform Architecture & Hosting'),
    (NEW.id, 'T10', 'technical', 'Configurability & Extensibility', 5, 10, false, false, 'Configurability & Extensibility', 4, 'Extensibility & Delivery'),
    (NEW.id, 'T11', 'technical', 'Security Controls for Data Sensitivity', 5, 11, false, false, 'Security Controls for Data Sensitivity', 7, 'Security Posture'),
    (NEW.id, 'T12', 'technical', 'Support for Modern UX', 4, 12, false, false, 'Support for Modern UX', 5, 'Extensibility & Delivery'),
    (NEW.id, 'T13', 'technical', 'Integrations', 7, 13, false, false, 'Integrations', 13, 'Integration Capabilities'),
    (NEW.id, 'T14', 'technical', 'Data Accessibility', 9, 14, false, false, 'Data Accessibility', 14, 'Reporting');

  RETURN NEW;
END;
$$;


--
-- Name: seed_namespace_templates(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seed_namespace_templates(p_namespace_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_template_namespace_id uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- Verify caller is platform admin
  IF NOT is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform admins can call this function';
  END IF;

  -- Copy assessment factors (with correct column names)
  INSERT INTO assessment_factors (
    namespace_id, factor_type, factor_code, sort_order, question, 
    description, weight, contributes_to_criticality, contributes_to_tech_risk,
    is_active, criticality_weight, tech_risk_weight, label, domain, survey_order,
    applicability_rules
  )
  SELECT 
    p_namespace_id, factor_type, factor_code, sort_order, question,
    description, weight, contributes_to_criticality, contributes_to_tech_risk,
    is_active, criticality_weight, tech_risk_weight, label, domain, survey_order,
    applicability_rules
  FROM assessment_factors
  WHERE namespace_id = v_template_namespace_id;
  
  -- Copy assessment thresholds
  INSERT INTO assessment_thresholds (
    namespace_id, metric_type, threshold_type, 
    threshold_value, description
  )
  SELECT 
    p_namespace_id, metric_type, threshold_type,
    threshold_value, description
  FROM assessment_thresholds
  WHERE namespace_id = v_template_namespace_id;
  
  -- Service types, software categories, tech categories seed automatically via triggers
  
  -- Create organization_settings
  INSERT INTO organization_settings (namespace_id, name, max_project_budget)
  VALUES (p_namespace_id, (SELECT name FROM namespaces WHERE id = p_namespace_id), 1000000);
  
END;
$$;


--
-- Name: seed_organization_settings_for_namespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seed_organization_settings_for_namespace() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO organization_settings (namespace_id, name, max_project_budget)
  VALUES (NEW.id, NEW.name, 1000000);
  
  RETURN NEW;
END;
$$;


--
-- Name: seed_service_type_taxonomy(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seed_service_type_taxonomy(p_namespace_id uuid) RETURNS void
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
    -- Copy categories from template
    INSERT INTO service_type_categories (namespace_id, code, name, description, display_order, is_active)
    SELECT 
        p_namespace_id,
        code,
        name,
        description,
        display_order,
        is_active
    FROM service_type_categories
    WHERE namespace_id = '00000000-0000-0000-0000-000000000001'
    ON CONFLICT (namespace_id, code) DO NOTHING;

    -- Copy types from template, linking to new namespace's categories
    INSERT INTO service_types (namespace_id, category_id, code, name, description, display_order, is_active)
    SELECT 
        p_namespace_id,
        new_cat.id,
        t.code,
        t.name,
        t.description,
        t.display_order,
        t.is_active
    FROM service_types t
    JOIN service_type_categories old_cat ON old_cat.id = t.category_id
    JOIN service_type_categories new_cat ON new_cat.namespace_id = p_namespace_id AND new_cat.code = old_cat.code
    WHERE t.namespace_id = '00000000-0000-0000-0000-000000000001'
    ON CONFLICT (namespace_id, code) DO NOTHING;
END;
$$;


--
-- Name: set_current_namespace(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_current_namespace(p_namespace_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_user_id UUID;
  v_is_platform_admin BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  
  -- Check if user is platform admin
  v_is_platform_admin := check_is_platform_admin();
  
  -- Verify user belongs to namespace OR is platform admin
  IF NOT v_is_platform_admin AND NOT EXISTS (
    SELECT 1 FROM namespace_users 
    WHERE user_id = v_user_id 
      AND namespace_id = p_namespace_id
  ) THEN
    RAISE EXCEPTION 'User does not belong to namespace %', p_namespace_id;
  END IF;
  
  -- Upsert current namespace
  INSERT INTO user_sessions (user_id, current_namespace_id, updated_at)
  VALUES (v_user_id, p_namespace_id, NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    current_namespace_id = p_namespace_id,
    updated_at = NOW();
END;
$$;


--
-- Name: sync_namespace_admin_to_workspaces(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_namespace_admin_to_workspaces() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    ws RECORD;
BEGIN
    -- Only act if user is (now) a namespace admin
    IF NEW.namespace_role = 'admin' THEN
        -- If this is an UPDATE and they were already admin, do nothing
        IF TG_OP = 'UPDATE' AND OLD.namespace_role = 'admin' THEN
            RETURN NEW;
        END IF;
        
        -- Add user as admin to all workspaces in their namespace
        FOR ws IN SELECT id FROM workspaces WHERE namespace_id = NEW.namespace_id LOOP
            INSERT INTO workspace_users (workspace_id, user_id, role)
            VALUES (ws.id, NEW.id, 'admin')
            ON CONFLICT (workspace_id, user_id) DO UPDATE SET role = 'admin';
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: update_namespace_tier(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_namespace_tier(p_namespace_id uuid, p_new_tier text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_old_tier TEXT;
BEGIN
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can change namespace tiers';
  END IF;

  IF p_new_tier NOT IN ('trial', 'essentials', 'plus', 'enterprise') THEN
    RAISE EXCEPTION 'Invalid tier: %. Must be trial, essentials, plus, or enterprise', p_new_tier;
  END IF;

  SELECT tier INTO v_old_tier
  FROM namespaces WHERE id = p_namespace_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Namespace not found: %', p_namespace_id;
  END IF;

  IF v_old_tier = p_new_tier THEN
    RETURN json_build_object('changed', false, 'tier', v_old_tier);
  END IF;

  UPDATE namespaces
  SET tier = p_new_tier, updated_at = now()
  WHERE id = p_namespace_id;

  RETURN json_build_object(
    'changed', true,
    'old_tier', v_old_tier,
    'new_tier', p_new_tier,
    'namespace_id', p_namespace_id
  );
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: update_user_namespace_role(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_user_namespace_role(p_user_id uuid, p_new_role text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_namespace_id UUID;
  v_old_role TEXT;
  v_admin_count INTEGER;
BEGIN
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can change namespace roles';
  END IF;

  IF p_new_role NOT IN ('admin', 'editor', 'steward', 'viewer', 'restricted') THEN
    RAISE EXCEPTION 'Invalid role: %. Must be admin, editor, steward, viewer, or restricted', p_new_role;
  END IF;

  SELECT namespace_id, namespace_role INTO v_namespace_id, v_old_role
  FROM users WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found: %', p_user_id;
  END IF;

  IF v_old_role = p_new_role THEN
    RETURN json_build_object('changed', false, 'role', v_old_role);
  END IF;

  IF v_old_role = 'admin' AND p_new_role != 'admin' THEN
    SELECT COUNT(*) INTO v_admin_count
    FROM users WHERE namespace_id = v_namespace_id AND namespace_role = 'admin';
    IF v_admin_count <= 1 THEN
      RAISE EXCEPTION 'Cannot demote the last namespace admin';
    END IF;
  END IF;

  UPDATE users SET namespace_role = p_new_role, updated_at = now() WHERE id = p_user_id;

  RETURN json_build_object('changed', true, 'old_role', v_old_role, 'new_role', p_new_role, 'user_id', p_user_id);
END;
$$;


--
-- Name: update_workspace_user_role(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_workspace_user_role(p_workspace_id uuid, p_user_id uuid, p_new_role text) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_old_role TEXT;
BEGIN
  IF NOT check_is_platform_admin() THEN
    RAISE EXCEPTION 'Only platform administrators can change workspace roles';
  END IF;

  IF p_new_role NOT IN ('admin', 'editor', 'viewer') THEN
    RAISE EXCEPTION 'Invalid role: %. Must be admin, editor, or viewer', p_new_role;
  END IF;

  SELECT role INTO v_old_role FROM workspace_users WHERE workspace_id = p_workspace_id AND user_id = p_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'User is not a member of this workspace'; END IF;

  IF v_old_role = p_new_role THEN
    RETURN json_build_object('changed', false, 'role', v_old_role);
  END IF;

  UPDATE workspace_users SET role = p_new_role, updated_at = now() WHERE workspace_id = p_workspace_id AND user_id = p_user_id;

  RETURN json_build_object('changed', true, 'old_role', v_old_role, 'new_role', p_new_role, 'workspace_id', p_workspace_id, 'user_id', p_user_id);
END;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_
        -- Filter by action early - only get subscriptions interested in this action
        -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
        and (subs.action_filter = '*' or subs.action_filter = action::text);

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: delete_leaf_prefixes(text[], text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.delete_leaf_prefixes(bucket_ids text[], names text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_rows_deleted integer;
BEGIN
    LOOP
        WITH candidates AS (
            SELECT DISTINCT
                t.bucket_id,
                unnest(storage.get_prefixes(t.name)) AS name
            FROM unnest(bucket_ids, names) AS t(bucket_id, name)
        ),
        uniq AS (
             SELECT
                 bucket_id,
                 name,
                 storage.get_level(name) AS level
             FROM candidates
             WHERE name <> ''
             GROUP BY bucket_id, name
        ),
        leaf AS (
             SELECT
                 p.bucket_id,
                 p.name,
                 p.level
             FROM storage.prefixes AS p
                  JOIN uniq AS u
                       ON u.bucket_id = p.bucket_id
                           AND u.name = p.name
                           AND u.level = p.level
             WHERE NOT EXISTS (
                 SELECT 1
                 FROM storage.objects AS o
                 WHERE o.bucket_id = p.bucket_id
                   AND o.level = p.level + 1
                   AND o.name COLLATE "C" LIKE p.name || '/%'
             )
             AND NOT EXISTS (
                 SELECT 1
                 FROM storage.prefixes AS c
                 WHERE c.bucket_id = p.bucket_id
                   AND c.level = p.level + 1
                   AND c.name COLLATE "C" LIKE p.name || '/%'
             )
        )
        DELETE
        FROM storage.prefixes AS p
            USING leaf AS l
        WHERE p.bucket_id = l.bucket_id
          AND p.name = l.name
          AND p.level = l.level;

        GET DIAGNOSTICS v_rows_deleted = ROW_COUNT;
        EXIT WHEN v_rows_deleted = 0;
    END LOOP;
END;
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    SELECT _parts[array_length(_parts,1)] INTO _filename;
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_level(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_level(name text) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT array_length(string_to_array("name", '/'), 1);
$$;


--
-- Name: get_prefix(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefix(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
SELECT
    CASE WHEN strpos("name", '/') > 0 THEN
             regexp_replace("name", '[\/]{1}[^\/]+\/?$', '')
         ELSE
             ''
        END;
$_$;


--
-- Name: get_prefixes(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_prefixes(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
DECLARE
    parts text[];
    prefixes text[];
    prefix text;
BEGIN
    -- Split the name into parts by '/'
    parts := string_to_array("name", '/');
    prefixes := '{}';

    -- Construct the prefixes, stopping one level below the last part
    FOR i IN 1..array_length(parts, 1) - 1 LOOP
            prefix := array_to_string(parts[1:i], '/');
            prefixes := array_append(prefixes, prefix);
    END LOOP;

    RETURN prefixes;
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_legacy_v1(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_legacy_v1(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
    v_order_by text;
    v_sort_order text;
begin
    case
        when sortcolumn = 'name' then
            v_order_by = 'name';
        when sortcolumn = 'updated_at' then
            v_order_by = 'updated_at';
        when sortcolumn = 'created_at' then
            v_order_by = 'created_at';
        when sortcolumn = 'last_accessed_at' then
            v_order_by = 'last_accessed_at';
        else
            v_order_by = 'name';
        end case;

    case
        when sortorder = 'asc' then
            v_sort_order = 'asc';
        when sortorder = 'desc' then
            v_sort_order = 'desc';
        else
            v_sort_order = 'asc';
        end case;

    v_order_by = v_order_by || ' ' || v_sort_order;

    return query execute
        'with folders as (
           select path_tokens[$1] as folder
           from storage.objects
             where objects.name ilike $2 || $3 || ''%''
               and bucket_id = $4
               and array_length(objects.path_tokens, 1) <> $1
           group by folder
           order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: alert_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid,
    workspace_id uuid,
    show_over_budget boolean DEFAULT true NOT NULL,
    show_no_budget boolean DEFAULT true NOT NULL,
    no_budget_severity text DEFAULT 'info'::text NOT NULL,
    show_eliminate_apps boolean DEFAULT true NOT NULL,
    eliminate_severity text DEFAULT 'warning'::text NOT NULL,
    visible_to_all boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    updated_by uuid,
    CONSTRAINT alert_preferences_eliminate_severity_check CHECK ((eliminate_severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text]))),
    CONSTRAINT alert_preferences_no_budget_severity_check CHECK ((no_budget_severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text]))),
    CONSTRAINT alert_preferences_scope_check CHECK ((((namespace_id IS NOT NULL) AND (workspace_id IS NULL)) OR ((namespace_id IS NULL) AND (workspace_id IS NOT NULL))))
);


--
-- Name: TABLE alert_preferences; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.alert_preferences IS 'Configurable alert preferences for budget health dashboard.';


--
-- Name: app_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.app_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_compliance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_compliance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    framework text NOT NULL,
    applicability text NOT NULL,
    compliance_status text,
    last_audit_date date,
    next_audit_date date,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT application_compliance_applicability_check CHECK ((applicability = ANY (ARRAY['required'::text, 'optional'::text, 'not_applicable'::text]))),
    CONSTRAINT application_compliance_compliance_status_check CHECK ((compliance_status = ANY (ARRAY['compliant'::text, 'non_compliant'::text, 'in_progress'::text, 'not_assessed'::text])))
);


--
-- Name: application_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    role_type text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT application_contacts_role_check CHECK ((role_type = ANY (ARRAY['business_owner'::text, 'technical_owner'::text, 'steward'::text, 'sponsor'::text, 'sme'::text, 'support'::text, 'vendor_rep'::text, 'other'::text])))
);


--
-- Name: application_data_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_data_assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    classification text,
    contains_pii boolean DEFAULT false,
    contains_phi boolean DEFAULT false,
    contains_financial boolean DEFAULT false,
    retention_years integer,
    data_steward_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT application_data_assets_classification_check CHECK ((classification = ANY (ARRAY['public'::text, 'internal'::text, 'confidential'::text, 'restricted'::text])))
);


--
-- Name: application_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    name text NOT NULL,
    document_type text,
    storage_type text NOT NULL,
    file_path text,
    external_url text,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT application_documents_document_type_check CHECK ((document_type = ANY (ARRAY['architecture'::text, 'data_flow'::text, 'sla'::text, 'contract'::text, 'runbook'::text, 'security'::text, 'other'::text]))),
    CONSTRAINT application_documents_storage_type_check CHECK ((storage_type = ANY (ARRAY['uploaded'::text, 'link'::text])))
);


--
-- Name: application_integrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_integrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_application_id uuid NOT NULL,
    target_application_id uuid,
    external_system_name text,
    direction text NOT NULL,
    integration_type text,
    frequency text,
    criticality text,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    name text,
    external_organization_id uuid,
    data_format text,
    sensitivity text DEFAULT 'low'::text,
    data_classification text DEFAULT 'internal'::text,
    status text DEFAULT 'active'::text,
    sla_description text,
    notes text,
    updated_at timestamp with time zone DEFAULT now(),
    data_tags text[] DEFAULT '{}'::text[],
    CONSTRAINT application_integrations_criticality_check CHECK ((criticality = ANY (ARRAY['critical'::text, 'important'::text, 'nice_to_have'::text]))),
    CONSTRAINT application_integrations_data_classification_check CHECK ((data_classification = ANY (ARRAY['public'::text, 'internal'::text, 'confidential'::text, 'restricted'::text]))),
    CONSTRAINT application_integrations_data_format_check CHECK (((data_format IS NULL) OR (data_format = ANY (ARRAY['json'::text, 'xml'::text, 'csv'::text, 'xlsx'::text, 'fixed_width'::text, 'binary'::text, 'hl7'::text, 'edi'::text, 'other'::text])))),
    CONSTRAINT application_integrations_direction_check CHECK ((direction = ANY (ARRAY['upstream'::text, 'downstream'::text, 'bidirectional'::text]))),
    CONSTRAINT application_integrations_frequency_check CHECK ((frequency = ANY (ARRAY['real_time'::text, 'batch_daily'::text, 'batch_weekly'::text, 'batch_monthly'::text, 'on_demand'::text]))),
    CONSTRAINT application_integrations_integration_type_check CHECK ((integration_type = ANY (ARRAY['api'::text, 'file'::text, 'database'::text, 'sso'::text, 'manual'::text, 'event'::text, 'other'::text]))),
    CONSTRAINT application_integrations_sensitivity_check CHECK ((sensitivity = ANY (ARRAY['low'::text, 'moderate'::text, 'high'::text, 'confidential'::text]))),
    CONSTRAINT application_integrations_status_check CHECK ((status = ANY (ARRAY['planned'::text, 'active'::text, 'deprecated'::text, 'retired'::text])))
);


--
-- Name: application_roadmap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_roadmap (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    event_type text NOT NULL,
    title text NOT NULL,
    description text,
    target_date date,
    status text DEFAULT 'planned'::text,
    replacement_app_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT application_roadmap_event_type_check CHECK ((event_type = ANY (ARRAY['upgrade'::text, 'migration'::text, 'decommission'::text, 'major_release'::text, 'security_patch'::text, 'audit'::text, 'review'::text, 'other'::text]))),
    CONSTRAINT application_roadmap_status_check CHECK ((status = ANY (ARRAY['planned'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text, 'deferred'::text])))
);


--
-- Name: application_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    it_service_id uuid NOT NULL,
    usage_notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_id integer DEFAULT nextval('public.app_id_seq'::regclass) NOT NULL,
    workspace_id uuid NOT NULL,
    owner_workspace_id uuid,
    name text NOT NULL,
    description text DEFAULT ''::text,
    owner text DEFAULT ''::text,
    primary_support text DEFAULT ''::text,
    annual_cost numeric DEFAULT 0,
    portfolio_name text DEFAULT 'Default Portfolio'::text,
    remediation_effort character varying,
    lifecycle_status text DEFAULT 'Mainstream'::text,
    is_internal_only boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    expert_contacts text,
    secondary_support text,
    operational_status text DEFAULT 'operational'::text,
    lifecycle_stage_status text DEFAULT 'active'::text,
    short_description text,
    budget_amount numeric(12,2) DEFAULT 0,
    budget_locked boolean DEFAULT false,
    budget_notes text,
    management_classification text DEFAULT 'apm'::text,
    csdm_stage text,
    branch text,
    CONSTRAINT applications_lifecycle_status_check CHECK ((lifecycle_status = ANY (ARRAY['Mainstream'::text, 'Extended'::text, 'End of Support'::text]))),
    CONSTRAINT applications_remediation_effort_check CHECK (((remediation_effort)::text = ANY ((ARRAY['XS'::character varying, 'S'::character varying, 'M'::character varying, 'L'::character varying, 'XL'::character varying, '2XL'::character varying])::text[]))),
    CONSTRAINT chk_app_csdm_stage CHECK (((csdm_stage IS NULL) OR (csdm_stage = ANY (ARRAY['stage_0'::text, 'stage_1'::text, 'stage_2'::text, 'stage_3'::text, 'stage_4'::text])))),
    CONSTRAINT chk_app_mgmt_classification CHECK ((management_classification = ANY (ARRAY['apm'::text, 'alm'::text, 'other'::text]))),
    CONSTRAINT chk_app_operational_status CHECK ((operational_status = ANY (ARRAY['operational'::text, 'pipeline'::text, 'retired'::text])))
);


--
-- Name: COLUMN applications.operational_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.operational_status IS 'CSDM: Running/Planned/Retired';


--
-- Name: COLUMN applications.lifecycle_stage_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.lifecycle_stage_status IS 'CSDM: Active/Planned/Retired';


--
-- Name: COLUMN applications.short_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.short_description IS 'Brief description (160 char recommended)';


--
-- Name: COLUMN applications.budget_amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.budget_amount IS 'Budget allocated to this application from the workspace pool.';


--
-- Name: COLUMN applications.budget_locked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.budget_locked IS 'If true, budget cannot be reallocated without admin override.';


--
-- Name: COLUMN applications.budget_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.budget_notes IS 'Notes about this application budget.';


--
-- Name: COLUMN applications.management_classification; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.management_classification IS 'APM (portfolio management), ALM (lifecycle management), or other. Default: apm.';


--
-- Name: COLUMN applications.csdm_stage; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.csdm_stage IS 'ServiceNow CSDM maturity stage (0-4). Nullable if org does not track CSDM.';


--
-- Name: COLUMN applications.branch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.applications.branch IS 'Organizational branch or division. Free text for grouping in reports.';


--
-- Name: assessment_factor_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_factor_options (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    factor_id uuid NOT NULL,
    score integer NOT NULL,
    label text NOT NULL,
    description text,
    CONSTRAINT assessment_factor_options_score_check CHECK (((score >= 1) AND (score <= 5)))
);


--
-- Name: assessment_factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_factors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    factor_type text NOT NULL,
    factor_code text NOT NULL,
    sort_order integer NOT NULL,
    question text NOT NULL,
    description text,
    weight numeric DEFAULT 10.0,
    contributes_to_criticality boolean DEFAULT false,
    contributes_to_tech_risk boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    applicability_rules jsonb DEFAULT '{}'::jsonb,
    criticality_weight numeric DEFAULT 0,
    tech_risk_weight numeric DEFAULT 0,
    label text,
    domain text,
    survey_order integer,
    CONSTRAINT assessment_factors_factor_type_check CHECK ((factor_type = ANY (ARRAY['business'::text, 'technical'::text])))
);


--
-- Name: assessment_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    portfolio_assignment_id uuid NOT NULL,
    version integer NOT NULL,
    assessed_at timestamp with time zone DEFAULT now(),
    assessed_by uuid,
    business_fit numeric,
    tech_health numeric,
    criticality numeric,
    tech_risk numeric,
    time_quadrant text,
    paid_action text,
    snapshot_data jsonb,
    notes text
);


--
-- Name: assessment_thresholds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessment_thresholds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    threshold_type text NOT NULL,
    threshold_name text NOT NULL,
    threshold_value numeric DEFAULT 50.0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT assessment_thresholds_threshold_type_check CHECK ((threshold_type = ANY (ARRAY['time_quadrant'::text, 'paid_quadrant'::text])))
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid,
    workspace_id uuid,
    user_id uuid,
    event_category text NOT NULL,
    event_type text NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid,
    entity_name text,
    old_values jsonb,
    new_values jsonb,
    changed_fields text[],
    ip_address inet,
    user_agent text,
    outcome text DEFAULT 'success'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE audit_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.audit_logs IS 'SOC2 application-level audit trail. Append-only. Started 2026-02-08.';


--
-- Name: COLUMN audit_logs.old_values; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.audit_logs.old_values IS 'Previous row state as JSONB. NULL for INSERTs.';


--
-- Name: COLUMN audit_logs.new_values; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.audit_logs.new_values IS 'New row state as JSONB. NULL for DELETEs.';


--
-- Name: COLUMN audit_logs.changed_fields; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.audit_logs.changed_fields IS 'Array of column names that changed. UPDATEs only.';


--
-- Name: budget_transfers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_transfers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    fiscal_year integer NOT NULL,
    from_application_id uuid,
    to_application_id uuid,
    amount numeric(12,2) NOT NULL,
    reason text NOT NULL,
    transferred_by uuid NOT NULL,
    transferred_at timestamp with time zone DEFAULT now() NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    from_it_service_id uuid,
    to_it_service_id uuid,
    CONSTRAINT budget_transfers_valid_from CHECK ((((from_application_id IS NOT NULL) AND (from_it_service_id IS NULL)) OR ((from_application_id IS NULL) AND (from_it_service_id IS NOT NULL)) OR ((from_application_id IS NULL) AND (from_it_service_id IS NULL)))),
    CONSTRAINT budget_transfers_valid_to CHECK ((((to_application_id IS NOT NULL) AND (to_it_service_id IS NULL)) OR ((to_application_id IS NULL) AND (to_it_service_id IS NOT NULL)) OR ((to_application_id IS NULL) AND (to_it_service_id IS NULL))))
);


--
-- Name: TABLE budget_transfers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.budget_transfers IS 'Audit trail for budget reallocations between applications.';


--
-- Name: COLUMN budget_transfers.from_it_service_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.budget_transfers.from_it_service_id IS 'Source IT Service for budget transfer. NULL if transferring from application or unallocated reserve.';


--
-- Name: COLUMN budget_transfers.to_it_service_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.budget_transfers.to_it_service_id IS 'Destination IT Service for budget transfer. NULL if transferring to application or unallocated reserve.';


--
-- Name: business_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    b1_strategic_goals integer,
    b2_regional_growth integer,
    b3_public_confidence integer,
    b4_scope_of_use integer,
    b5_business_process integer,
    b6_interruption_tolerance integer,
    b7_essential_service integer,
    b8_current_needs integer,
    b9_future_needs integer,
    b10_user_satisfaction integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT business_assessments_b10_user_satisfaction_check CHECK (((b10_user_satisfaction >= 1) AND (b10_user_satisfaction <= 5))),
    CONSTRAINT business_assessments_b1_strategic_goals_check CHECK (((b1_strategic_goals >= 1) AND (b1_strategic_goals <= 5))),
    CONSTRAINT business_assessments_b2_regional_growth_check CHECK (((b2_regional_growth >= 1) AND (b2_regional_growth <= 5))),
    CONSTRAINT business_assessments_b3_public_confidence_check CHECK (((b3_public_confidence >= 1) AND (b3_public_confidence <= 5))),
    CONSTRAINT business_assessments_b4_scope_of_use_check CHECK (((b4_scope_of_use >= 1) AND (b4_scope_of_use <= 5))),
    CONSTRAINT business_assessments_b5_business_process_check CHECK (((b5_business_process >= 1) AND (b5_business_process <= 5))),
    CONSTRAINT business_assessments_b6_interruption_tolerance_check CHECK (((b6_interruption_tolerance >= 1) AND (b6_interruption_tolerance <= 5))),
    CONSTRAINT business_assessments_b7_essential_service_check CHECK (((b7_essential_service >= 1) AND (b7_essential_service <= 5))),
    CONSTRAINT business_assessments_b8_current_needs_check CHECK (((b8_current_needs >= 1) AND (b8_current_needs <= 5))),
    CONSTRAINT business_assessments_b9_future_needs_check CHECK (((b9_future_needs >= 1) AND (b9_future_needs <= 5)))
);


--
-- Name: cloud_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cloud_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: contact_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contact_organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    contact_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    role_at_org text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    primary_workspace_id uuid,
    individual_id uuid,
    display_name text NOT NULL,
    job_title text,
    department text,
    email text,
    phone text,
    workspace_role text DEFAULT 'read_only'::text NOT NULL,
    contact_category text DEFAULT 'internal'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    namespace_id uuid NOT NULL,
    CONSTRAINT contacts_category_check CHECK ((contact_category = ANY (ARRAY['internal'::text, 'external'::text, 'vendor_rep'::text]))),
    CONSTRAINT contacts_workspace_role_check CHECK ((workspace_role = ANY (ARRAY['admin'::text, 'editor'::text, 'steward'::text, 'read_only'::text, 'restricted'::text])))
);


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.countries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    flag_emoji text,
    region_type text DEFAULT 'country'::text NOT NULL,
    has_gdpr boolean DEFAULT false,
    has_pipeda boolean DEFAULT false,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: criticality_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.criticality_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: custom_field_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_definitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    entity_type text NOT NULL,
    field_name text NOT NULL,
    field_label text NOT NULL,
    field_type text NOT NULL,
    options jsonb,
    is_required boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT custom_field_definitions_entity_type_check CHECK ((entity_type = ANY (ARRAY['application'::text, 'portfolio'::text, 'it_service'::text, 'software_product'::text]))),
    CONSTRAINT custom_field_definitions_field_type_check CHECK ((field_type = ANY (ARRAY['text'::text, 'number'::text, 'date'::text, 'dropdown'::text, 'multi_select'::text, 'checkbox'::text, 'url'::text])))
);


--
-- Name: custom_field_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_values (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    field_definition_id uuid NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid NOT NULL,
    value jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: data_centers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_centers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    location text NOT NULL,
    country_code text NOT NULL,
    type text NOT NULL,
    is_active boolean DEFAULT true,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT data_centers_country_code_check CHECK ((length(country_code) = 2)),
    CONSTRAINT data_centers_type_check CHECK ((type = ANY (ARRAY['primary'::text, 'dr'::text, 'colocation'::text, 'edge'::text])))
);


--
-- Name: TABLE data_centers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.data_centers IS 'Organization-specific data centers for on-prem deployments';


--
-- Name: COLUMN data_centers.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.data_centers.code IS 'Short code for display/reporting (e.g., RGN-DC1)';


--
-- Name: COLUMN data_centers.location; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.data_centers.location IS 'Human-readable location (e.g., Regina, Saskatchewan, Canada)';


--
-- Name: COLUMN data_centers.country_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.data_centers.country_code IS 'ISO 3166-1 alpha-2 for data residency compliance';


--
-- Name: COLUMN data_centers.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.data_centers.type IS 'Data center type: primary, dr (disaster recovery), colocation, edge';


--
-- Name: data_classification_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_classification_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: data_format_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_format_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: data_tag_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_tag_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_system boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: deployment_profile_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_profile_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deployment_profile_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    role_type text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT dp_contacts_role_check CHECK ((role_type = ANY (ARRAY['operational_owner'::text, 'technical_sme'::text, 'support'::text, 'vendor_rep'::text, 'other'::text])))
);


--
-- Name: deployment_profile_it_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_profile_it_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deployment_profile_id uuid NOT NULL,
    it_service_id uuid NOT NULL,
    relationship_type text DEFAULT 'depends_on'::text NOT NULL,
    allocation_basis text,
    allocation_value numeric(12,2),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT dpis_relationship_check CHECK ((relationship_type = ANY (ARRAY['depends_on'::text, 'built_on'::text])))
);


--
-- Name: deployment_profile_software_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_profile_software_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deployment_profile_id uuid NOT NULL,
    software_product_id uuid NOT NULL,
    deployed_version text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    vendor_org_id uuid,
    annual_cost numeric(12,2),
    quantity integer,
    allocation_percent numeric(5,2),
    allocation_basis text,
    contract_reference text,
    contract_start_date date,
    contract_end_date date,
    renewal_notice_days integer DEFAULT 90,
    cost_confidence text DEFAULT 'estimated'::text,
    CONSTRAINT chk_dpsp_cost_confidence CHECK ((cost_confidence = ANY (ARRAY['estimated'::text, 'verified'::text])))
);


--
-- Name: COLUMN deployment_profile_software_products.vendor_org_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_software_products.vendor_org_id IS 'Who you buy from (reseller/vendor), not who makes it (manufacturer)';


--
-- Name: COLUMN deployment_profile_software_products.annual_cost; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_software_products.annual_cost IS 'Cost override - what you actually pay (overrides catalog price)';


--
-- Name: COLUMN deployment_profile_software_products.contract_end_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_software_products.contract_end_date IS 'For renewal tracking';


--
-- Name: COLUMN deployment_profile_software_products.cost_confidence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_software_products.cost_confidence IS 'estimated or verified';


--
-- Name: deployment_profile_technology_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_profile_technology_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deployment_profile_id uuid NOT NULL,
    technology_product_id uuid NOT NULL,
    deployed_version text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    edition text,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN deployment_profile_technology_products.edition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_technology_products.edition IS 'Specific edition deployed (e.g., Standard, Enterprise, Datacenter). Supplements deployed_version.';


--
-- Name: COLUMN deployment_profile_technology_products.updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profile_technology_products.updated_at IS 'When this technology tag was last modified.';


--
-- Name: deployment_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid,
    workspace_id uuid NOT NULL,
    name text NOT NULL,
    is_primary boolean DEFAULT false,
    hosting_type text,
    cloud_provider text,
    region text DEFAULT 'CA'::text,
    dr_status text,
    t01 integer,
    t02 integer,
    t03 integer,
    t04 integer,
    t05 integer,
    t06 integer,
    t07 integer,
    t08 integer,
    t09 integer,
    t10 integer,
    t11 integer,
    t12 integer,
    t13 integer,
    t14 integer,
    t15 integer,
    tech_health numeric(5,2),
    tech_risk numeric(5,2),
    paid_action text,
    remediation_effort text,
    tech_assessment_status text DEFAULT 'not_started'::text,
    assessment_notes text,
    assessed_at timestamp with time zone,
    assessed_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    annual_tech_cost numeric DEFAULT 0,
    annual_licensing_cost numeric DEFAULT 0,
    estimated_tech_debt numeric DEFAULT 0,
    environment text DEFAULT 'PROD'::text NOT NULL,
    score_overrides jsonb DEFAULT '{}'::jsonb,
    dp_type text DEFAULT 'application'::text NOT NULL,
    annual_cost numeric(12,2) DEFAULT 0,
    operational_status text DEFAULT 'operational'::text,
    version text,
    tech_debt_description text,
    vendor_org_id uuid,
    cost_recurrence text DEFAULT 'recurring'::text,
    data_center_id uuid,
    server_name text,
    CONSTRAINT chk_dp_cost_recurrence CHECK ((cost_recurrence = ANY (ARRAY['recurring'::text, 'one_time'::text]))),
    CONSTRAINT chk_dp_operational_status CHECK ((operational_status = ANY (ARRAY['operational'::text, 'non-operational'::text]))),
    CONSTRAINT deployment_profiles_assessment_status_check CHECK ((tech_assessment_status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'complete'::text]))),
    CONSTRAINT deployment_profiles_cloud_provider_check CHECK (((cloud_provider IS NULL) OR (cloud_provider = ''::text) OR (cloud_provider = ANY (ARRAY['aws'::text, 'azure'::text, 'gcp'::text, 'oracle'::text, 'ibm'::text, 'other'::text])))),
    CONSTRAINT deployment_profiles_dp_type_check CHECK ((dp_type = ANY (ARRAY['application'::text, 'platform_tenant'::text, 'infrastructure'::text, 'cost_bundle'::text]))),
    CONSTRAINT deployment_profiles_paid_action_check CHECK (((paid_action IS NULL) OR (paid_action = ANY (ARRAY['plan'::text, 'address'::text, 'ignore'::text, 'delay'::text, 'improve'::text, 'divest'::text, 'Plan'::text, 'Address'::text, 'Ignore'::text, 'Delay'::text])))),
    CONSTRAINT deployment_profiles_remediation_effort_check CHECK (((remediation_effort IS NULL) OR (remediation_effort = ANY (ARRAY['xs'::text, 's'::text, 'm'::text, 'l'::text, 'xl'::text, '2xl'::text, 'XS'::text, 'S'::text, 'M'::text, 'L'::text, 'XL'::text, '2XL'::text])))),
    CONSTRAINT deployment_profiles_t01_check CHECK (((t01 >= 1) AND (t01 <= 5))),
    CONSTRAINT deployment_profiles_t02_check CHECK (((t02 >= 1) AND (t02 <= 5))),
    CONSTRAINT deployment_profiles_t03_check CHECK (((t03 >= 1) AND (t03 <= 5))),
    CONSTRAINT deployment_profiles_t04_check CHECK (((t04 >= 1) AND (t04 <= 5))),
    CONSTRAINT deployment_profiles_t05_check CHECK (((t05 >= 1) AND (t05 <= 5))),
    CONSTRAINT deployment_profiles_t06_check CHECK (((t06 >= 1) AND (t06 <= 5))),
    CONSTRAINT deployment_profiles_t07_check CHECK (((t07 >= 1) AND (t07 <= 5))),
    CONSTRAINT deployment_profiles_t08_check CHECK (((t08 >= 1) AND (t08 <= 5))),
    CONSTRAINT deployment_profiles_t09_check CHECK (((t09 >= 1) AND (t09 <= 5))),
    CONSTRAINT deployment_profiles_t10_check CHECK (((t10 >= 1) AND (t10 <= 5))),
    CONSTRAINT deployment_profiles_t11_check CHECK (((t11 >= 1) AND (t11 <= 5))),
    CONSTRAINT deployment_profiles_t12_check CHECK (((t12 >= 1) AND (t12 <= 5))),
    CONSTRAINT deployment_profiles_t13_check CHECK (((t13 >= 1) AND (t13 <= 5))),
    CONSTRAINT deployment_profiles_t14_check CHECK (((t14 >= 1) AND (t14 <= 5))),
    CONSTRAINT deployment_profiles_t15_check CHECK (((t15 >= 1) AND (t15 <= 5))),
    CONSTRAINT valid_hosting_type CHECK ((hosting_type = ANY (ARRAY['SaaS'::text, 'Third-Party-Hosted'::text, 'Cloud'::text, 'On-Prem'::text, 'Hybrid'::text, 'Desktop'::text])))
);


--
-- Name: COLUMN deployment_profiles.operational_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.operational_status IS 'CSDM: Running/Not Running';


--
-- Name: COLUMN deployment_profiles.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.version IS 'Version identifier (e.g., v2.4.1)';


--
-- Name: COLUMN deployment_profiles.tech_debt_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.tech_debt_description IS 'Technical debt notes';


--
-- Name: COLUMN deployment_profiles.vendor_org_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.vendor_org_id IS 'Vendor for cost bundles (support contracts, misc costs)';


--
-- Name: COLUMN deployment_profiles.cost_recurrence; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.cost_recurrence IS 'recurring = include in run rate, one_time = exclude from run rate';


--
-- Name: COLUMN deployment_profiles.data_center_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.data_center_id IS 'For on-prem/hybrid: links to namespace data center. For cloud/SaaS: use region field.';


--
-- Name: COLUMN deployment_profiles.server_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.deployment_profiles.server_name IS 'Optional server reference label for grouping. NOT a CMDB CI — per Infrastructure Boundary Rubric.';


--
-- Name: dr_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dr_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: environments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.environments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: findings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.findings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    workspace_id uuid,
    assessment_domain text NOT NULL,
    impact text DEFAULT 'medium'::text NOT NULL,
    title text NOT NULL,
    rationale text NOT NULL,
    as_of_date date DEFAULT CURRENT_DATE NOT NULL,
    source_type text DEFAULT 'manual'::text NOT NULL,
    source_reference_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT findings_domain_check CHECK ((assessment_domain = ANY (ARRAY['icoms'::text, 'bpa'::text, 'ti'::text, 'dqa'::text, 'cr'::text, 'other'::text]))),
    CONSTRAINT findings_impact_check CHECK ((impact = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text]))),
    CONSTRAINT findings_source_type_check CHECK ((source_type = ANY (ARRAY['manual'::text, 'computed'::text, 'imported'::text])))
);


--
-- Name: hosting_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hosting_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: ideas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ideas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    workspace_id uuid,
    title text NOT NULL,
    description text,
    assessment_domain text,
    submitted_by_contact_id uuid,
    status text DEFAULT 'submitted'::text NOT NULL,
    review_notes text,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    promoted_to_initiative_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT ideas_domain_check CHECK (((assessment_domain IS NULL) OR (assessment_domain = ANY (ARRAY['icoms'::text, 'bpa'::text, 'ti'::text, 'dqa'::text, 'cr'::text, 'other'::text])))),
    CONSTRAINT ideas_status_check CHECK ((status = ANY (ARRAY['submitted'::text, 'under_review'::text, 'approved'::text, 'declined'::text, 'deferred'::text])))
);


--
-- Name: individuals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.individuals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    display_name text NOT NULL,
    primary_email text,
    external_identity_key text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: initiative_dependencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiative_dependencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_initiative_id uuid NOT NULL,
    target_initiative_id uuid NOT NULL,
    dependency_type text DEFAULT 'requires'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT initiative_deps_no_self CHECK ((source_initiative_id <> target_initiative_id)),
    CONSTRAINT initiative_deps_type_check CHECK ((dependency_type = ANY (ARRAY['requires'::text, 'enables'::text, 'blocks'::text, 'related_to'::text])))
);


--
-- Name: initiative_deployment_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiative_deployment_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    initiative_id uuid NOT NULL,
    deployment_profile_id uuid NOT NULL,
    relationship_type text DEFAULT 'impacted'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT initiative_dps_type_check CHECK ((relationship_type = ANY (ARRAY['impacted'::text, 'replaced'::text, 'modernized'::text, 'retired'::text, 'dependent'::text])))
);


--
-- Name: initiative_it_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiative_it_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    initiative_id uuid NOT NULL,
    it_service_id uuid NOT NULL,
    relationship_type text DEFAULT 'impacted'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT initiative_services_type_check CHECK ((relationship_type = ANY (ARRAY['impacted'::text, 'replaced'::text, 'enhanced'::text, 'dependent'::text])))
);


--
-- Name: initiatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiatives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    workspace_id uuid,
    assessment_domain text NOT NULL,
    strategic_theme text NOT NULL,
    priority text DEFAULT 'medium'::text NOT NULL,
    title text NOT NULL,
    description text,
    time_horizon text DEFAULT 'q2'::text NOT NULL,
    target_start_date date,
    target_end_date date,
    actual_start_date date,
    actual_end_date date,
    status text DEFAULT 'identified'::text NOT NULL,
    status_notes text,
    owner_contact_id uuid,
    one_time_cost_low numeric,
    one_time_cost_high numeric,
    recurring_cost_low numeric,
    recurring_cost_high numeric,
    cost_frequency text DEFAULT 'annual'::text,
    estimated_run_rate_change numeric,
    run_rate_change_rationale text,
    expected_benefit text,
    benefit_type text,
    source_finding_id uuid,
    created_from_assessment boolean DEFAULT true,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    source_idea_id uuid,
    CONSTRAINT initiatives_benefit_check CHECK (((benefit_type IS NULL) OR (benefit_type = ANY (ARRAY['cost_savings'::text, 'risk_reduction'::text, 'growth_enablement'::text, 'efficiency'::text, 'compliance'::text, 'other'::text])))),
    CONSTRAINT initiatives_domain_check CHECK ((assessment_domain = ANY (ARRAY['icoms'::text, 'bpa'::text, 'ti'::text, 'dqa'::text, 'cr'::text, 'other'::text]))),
    CONSTRAINT initiatives_frequency_check CHECK (((cost_frequency IS NULL) OR (cost_frequency = ANY (ARRAY['monthly'::text, 'quarterly'::text, 'annual'::text])))),
    CONSTRAINT initiatives_horizon_check CHECK ((time_horizon = ANY (ARRAY['q1'::text, 'q2'::text, 'q3'::text, 'q4'::text, 'beyond'::text]))),
    CONSTRAINT initiatives_priority_check CHECK ((priority = ANY (ARRAY['critical'::text, 'high'::text, 'medium'::text, 'low'::text]))),
    CONSTRAINT initiatives_status_check CHECK ((status = ANY (ARRAY['identified'::text, 'planned'::text, 'in_progress'::text, 'completed'::text, 'deferred'::text, 'cancelled'::text]))),
    CONSTRAINT initiatives_theme_check CHECK ((strategic_theme = ANY (ARRAY['optimize'::text, 'growth'::text, 'risk'::text])))
);


--
-- Name: COLUMN initiatives.source_idea_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.initiatives.source_idea_id IS 'FK to the Idea that was promoted to create this initiative. An initiative can have source_finding_id, source_idea_id, both, or neither.';


--
-- Name: integration_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    integration_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    role_type text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT integration_contacts_role_check CHECK ((role_type = ANY (ARRAY['integration_owner'::text, 'technical_sme'::text, 'data_steward'::text, 'vendor_contact'::text, 'support_contact'::text, 'other'::text])))
);


--
-- Name: integration_direction_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_direction_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: integration_frequency_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_frequency_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: integration_method_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_method_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: integration_status_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_status_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: invitation_workspaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitation_workspaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invitation_id uuid NOT NULL,
    workspace_id uuid NOT NULL,
    role text DEFAULT 'editor'::text NOT NULL,
    CONSTRAINT invitation_workspaces_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'editor'::text, 'viewer'::text])))
);


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    email text NOT NULL,
    namespace_role text DEFAULT 'viewer'::text NOT NULL,
    invited_by uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    token text DEFAULT encode(extensions.gen_random_bytes(32), 'hex'::text) NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval),
    name text,
    CONSTRAINT invitations_namespace_role_check CHECK ((namespace_role = ANY (ARRAY['admin'::text, 'editor'::text, 'steward'::text, 'viewer'::text, 'restricted'::text]))),
    CONSTRAINT invitations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'expired'::text])))
);


--
-- Name: it_service_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.it_service_providers (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    it_service_id uuid NOT NULL,
    deployment_profile_id uuid NOT NULL,
    is_primary boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    namespace_id uuid NOT NULL
);


--
-- Name: it_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.it_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    owner_workspace_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    annual_cost numeric DEFAULT 0,
    cost_model text,
    is_internal_only boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    lifecycle_state text DEFAULT 'active'::text,
    service_type_id uuid,
    vendor_org_id uuid,
    budget_amount numeric(12,2) DEFAULT 0,
    budget_locked boolean DEFAULT false,
    budget_notes text,
    budget_fiscal_year integer DEFAULT 2025,
    CONSTRAINT it_services_cost_model_check CHECK ((cost_model = ANY (ARRAY['fixed'::text, 'per_user'::text, 'per_instance'::text, 'consumption'::text, 'tiered'::text])))
);


--
-- Name: COLUMN it_services.vendor_org_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.it_services.vendor_org_id IS 'Service provider organization';


--
-- Name: COLUMN it_services.budget_amount; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.it_services.budget_amount IS 'Annual budget allocated for this IT Service';


--
-- Name: COLUMN it_services.budget_locked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.it_services.budget_locked IS 'If true, budget cannot be reallocated without admin override.';


--
-- Name: COLUMN it_services.budget_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.it_services.budget_notes IS 'Notes about this IT Service budget (capacity planning, growth assumptions, etc.).';


--
-- Name: COLUMN it_services.budget_fiscal_year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.it_services.budget_fiscal_year IS 'Fiscal year for the budget';


--
-- Name: lifecycle_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lifecycle_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: namespace_role_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_role_options (
    role text NOT NULL,
    display_name text NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true
);


--
-- Name: namespace_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT namespace_users_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'editor'::text, 'steward'::text, 'viewer'::text, 'restricted'::text])))
);


--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    tier text DEFAULT 'trial'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    status text DEFAULT 'active'::text NOT NULL,
    region character varying(10) DEFAULT 'ca'::character varying NOT NULL,
    CONSTRAINT namespaces_region_check CHECK (((region)::text = ANY ((ARRAY['ca'::character varying, 'us'::character varying, 'eu'::character varying])::text[]))),
    CONSTRAINT namespaces_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text]))),
    CONSTRAINT namespaces_tier_check CHECK ((tier = ANY (ARRAY['trial'::text, 'essentials'::text, 'plus'::text, 'enterprise'::text])))
);


--
-- Name: COLUMN namespaces.tier; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.namespaces.tier IS 'Subscription tier: trial, essentials, plus, enterprise';


--
-- Name: COLUMN namespaces.region; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.namespaces.region IS 'Data residency region: ca (Canada), us (United States), eu (European Union)';


--
-- Name: notification_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    trigger_type text NOT NULL,
    conditions jsonb DEFAULT '{}'::jsonb,
    channels jsonb DEFAULT '["in_app"]'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notification_rules_trigger_type_check CHECK ((trigger_type = ANY (ARRAY['assessment_due'::text, 'license_expiry'::text, 'end_of_support'::text, 'compliance_due'::text, 'custom'::text])))
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    link text,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: operational_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.operational_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    scope text NOT NULL,
    description text,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT operational_statuses_scope_check CHECK ((scope = ANY (ARRAY['application'::text, 'deployment_profile'::text])))
);


--
-- Name: organization_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text DEFAULT ''::text,
    max_project_budget integer DEFAULT 1000000,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    owner_workspace_id uuid,
    name text NOT NULL,
    legal_name text,
    website text,
    primary_email text,
    primary_phone text,
    address_line1 text,
    address_line2 text,
    address_city text,
    address_region text,
    address_postal text,
    address_country text,
    is_shared boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_vendor boolean DEFAULT false NOT NULL,
    is_manufacturer boolean DEFAULT false NOT NULL,
    is_partner boolean DEFAULT false NOT NULL,
    is_government boolean DEFAULT false NOT NULL,
    is_internal boolean DEFAULT false NOT NULL,
    is_msp boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    primary_workspace_id uuid
);


--
-- Name: platform_admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_admins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    email text NOT NULL,
    name text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid
);


--
-- Name: portfolio_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portfolio_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    portfolio_id uuid NOT NULL,
    application_id uuid NOT NULL,
    deployment_profile_id uuid,
    remediation_effort text,
    business_assessment_status text DEFAULT 'Not Started'::text,
    b1 integer,
    b2 integer,
    b3 integer,
    b4 integer,
    b5 integer,
    b6 integer,
    b7 integer,
    b8 integer,
    b9 integer,
    b10 integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    business_fit numeric,
    criticality numeric,
    time_quadrant text,
    relationship_type text DEFAULT 'publisher'::text,
    cost_allocation_percent numeric(5,2) DEFAULT NULL::numeric,
    cost_allocation_basis text,
    cost_allocation_notes text,
    CONSTRAINT portfolio_assignments_assessment_status_check CHECK (((business_assessment_status IS NULL) OR (business_assessment_status = ANY (ARRAY['not_started'::text, 'in_progress'::text, 'complete'::text, 'Not Started'::text, 'In Progress'::text, 'Complete'::text])))),
    CONSTRAINT portfolio_assignments_b10_user_satisfaction_check CHECK (((b10 >= 1) AND (b10 <= 5))),
    CONSTRAINT portfolio_assignments_b1_strategic_goals_check CHECK (((b1 >= 1) AND (b1 <= 5))),
    CONSTRAINT portfolio_assignments_b2_regional_growth_check CHECK (((b2 >= 1) AND (b2 <= 5))),
    CONSTRAINT portfolio_assignments_b3_public_confidence_check CHECK (((b3 >= 1) AND (b3 <= 5))),
    CONSTRAINT portfolio_assignments_b4_scope_of_use_check CHECK (((b4 >= 1) AND (b4 <= 5))),
    CONSTRAINT portfolio_assignments_b5_business_process_check CHECK (((b5 >= 1) AND (b5 <= 5))),
    CONSTRAINT portfolio_assignments_b6_interruption_tolerance_check CHECK (((b6 >= 1) AND (b6 <= 5))),
    CONSTRAINT portfolio_assignments_b7_essential_service_check CHECK (((b7 >= 1) AND (b7 <= 5))),
    CONSTRAINT portfolio_assignments_b8_current_needs_check CHECK (((b8 >= 1) AND (b8 <= 5))),
    CONSTRAINT portfolio_assignments_b9_future_needs_check CHECK (((b9 >= 1) AND (b9 <= 5))),
    CONSTRAINT portfolio_assignments_relationship_type_check CHECK ((relationship_type = ANY (ARRAY['publisher'::text, 'consumer'::text]))),
    CONSTRAINT portfolio_assignments_remediation_effort_check CHECK ((remediation_effort = ANY (ARRAY['XS'::text, 'S'::text, 'M'::text, 'L'::text, 'XL'::text, '2XL'::text])))
);


--
-- Name: portfolio_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portfolio_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    setting_key text NOT NULL,
    setting_value jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: portfolios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.portfolios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    parent_portfolio_id uuid
);


--
-- Name: COLUMN portfolios.parent_portfolio_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.portfolios.parent_portfolio_id IS 'Links to parent portfolio. NULL = root portfolio. Max depth: 3 levels.';


--
-- Name: program_initiatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.program_initiatives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    program_id uuid NOT NULL,
    initiative_id uuid NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    workspace_id uuid,
    title text NOT NULL,
    description text,
    strategic_theme text,
    business_driver text,
    budget_amount numeric,
    budget_fiscal_year text,
    target_start_date date,
    target_end_date date,
    status text DEFAULT 'active'::text NOT NULL,
    owner_contact_id uuid,
    sponsor_contact_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT programs_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'completed'::text, 'cancelled'::text]))),
    CONSTRAINT programs_theme_check CHECK (((strategic_theme IS NULL) OR (strategic_theme = ANY (ARRAY['optimize'::text, 'growth'::text, 'risk'::text]))))
);


--
-- Name: remediation_efforts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.remediation_efforts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    hours_min integer,
    hours_max integer,
    display_order integer,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: sensitivity_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sensitivity_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    is_system boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: service_type_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_type_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: service_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    category_id uuid
);


--
-- Name: software_product_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.software_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: software_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.software_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    owner_workspace_id uuid NOT NULL,
    name text NOT NULL,
    version text,
    license_type text,
    is_internal_only boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    manufacturer_org_id uuid,
    product_family_name text,
    category text,
    is_deprecated boolean DEFAULT false NOT NULL,
    annual_cost numeric(12,2) DEFAULT 0,
    category_id uuid,
    CONSTRAINT software_products_category_check CHECK (((category IS NULL) OR (category = ANY (ARRAY['suite'::text, 'saas'::text, 'platform'::text, 'plugin'::text, 'managed_service'::text, 'other'::text])))),
    CONSTRAINT software_products_license_type_check CHECK ((license_type = ANY (ARRAY['perpetual'::text, 'subscription'::text, 'open_source'::text, 'freemium'::text, 'enterprise'::text, 'other'::text])))
);


--
-- Name: standard_regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.standard_regions (
    code text NOT NULL,
    name text NOT NULL,
    provider text,
    country_code text NOT NULL,
    sort_order integer DEFAULT 999,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT standard_regions_provider_check CHECK ((provider = ANY (ARRAY['aws'::text, 'azure'::text, 'gcp'::text, 'oracle'::text, 'generic'::text])))
);


--
-- Name: TABLE standard_regions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.standard_regions IS 'Reference data for cloud provider regions';


--
-- Name: COLUMN standard_regions.provider; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.standard_regions.provider IS 'Cloud provider or "generic" for vendor-agnostic';


--
-- Name: COLUMN standard_regions.country_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.standard_regions.country_code IS 'ISO 3166-1 alpha-2 for compliance';


--
-- Name: technical_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technical_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    application_id uuid NOT NULL,
    t01_platform_footprint integer,
    t02_vendor_support integer,
    t03_dev_platform integer,
    t04_security_controls integer,
    t05_resilience_recovery integer,
    t06_observability integer,
    t07_integration_capabilities integer,
    t08_identity_assurance integer,
    t09_platform_portability integer,
    t10_configurability integer,
    t11_data_sensitivity_controls integer,
    t13_modern_ux integer,
    t14_integrations_count integer,
    t15_data_accessibility integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT technical_assessments_t01_platform_footprint_check CHECK (((t01_platform_footprint >= 1) AND (t01_platform_footprint <= 5))),
    CONSTRAINT technical_assessments_t02_vendor_support_check CHECK (((t02_vendor_support >= 1) AND (t02_vendor_support <= 5))),
    CONSTRAINT technical_assessments_t03_dev_platform_check CHECK (((t03_dev_platform >= 1) AND (t03_dev_platform <= 5))),
    CONSTRAINT technical_assessments_t04_security_controls_check CHECK (((t04_security_controls >= 1) AND (t04_security_controls <= 5))),
    CONSTRAINT technical_assessments_t05_resilience_recovery_check CHECK (((t05_resilience_recovery >= 1) AND (t05_resilience_recovery <= 5))),
    CONSTRAINT technical_assessments_t06_observability_check CHECK (((t06_observability >= 1) AND (t06_observability <= 5))),
    CONSTRAINT technical_assessments_t07_integration_capabilities_check CHECK (((t07_integration_capabilities >= 1) AND (t07_integration_capabilities <= 5))),
    CONSTRAINT technical_assessments_t08_identity_assurance_check CHECK (((t08_identity_assurance >= 1) AND (t08_identity_assurance <= 5))),
    CONSTRAINT technical_assessments_t09_platform_portability_check CHECK (((t09_platform_portability >= 1) AND (t09_platform_portability <= 5))),
    CONSTRAINT technical_assessments_t10_configurability_check CHECK (((t10_configurability >= 1) AND (t10_configurability <= 5))),
    CONSTRAINT technical_assessments_t11_data_sensitivity_controls_check CHECK (((t11_data_sensitivity_controls >= 1) AND (t11_data_sensitivity_controls <= 5))),
    CONSTRAINT technical_assessments_t13_modern_ux_check CHECK (((t13_modern_ux >= 1) AND (t13_modern_ux <= 5))),
    CONSTRAINT technical_assessments_t14_integrations_count_check CHECK (((t14_integrations_count >= 1) AND (t14_integrations_count <= 5))),
    CONSTRAINT technical_assessments_t15_data_accessibility_check CHECK (((t15_data_accessibility >= 1) AND (t15_data_accessibility <= 5)))
);


--
-- Name: technology_lifecycle_reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technology_lifecycle_reference (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_name text NOT NULL,
    product_name text NOT NULL,
    product_family text,
    version text NOT NULL,
    edition text,
    ga_date date,
    mainstream_support_end date,
    extended_support_end date,
    end_of_life_date date,
    maintenance_type text,
    confidence_level text DEFAULT 'medium'::text,
    source_url text,
    last_verified_at timestamp with time zone,
    verification_notes text,
    is_manually_overridden boolean DEFAULT false,
    override_reason text,
    overridden_by uuid,
    overridden_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    current_status text DEFAULT 'unknown'::text,
    CONSTRAINT technology_lifecycle_reference_confidence_level_check CHECK ((confidence_level = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text, 'unverified'::text]))),
    CONSTRAINT technology_lifecycle_reference_current_status_check CHECK ((current_status = ANY (ARRAY['mainstream'::text, 'extended'::text, 'end_of_support'::text, 'preview'::text, 'business_vendor_managed'::text, 'incomplete_data'::text]))),
    CONSTRAINT technology_lifecycle_reference_maintenance_type_check CHECK (((maintenance_type IS NULL) OR (maintenance_type = ANY (ARRAY['mandatory'::text, 'regular_high'::text, 'regular_low'::text, 'none'::text]))))
);


--
-- Name: technology_product_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technology_product_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: technology_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technology_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    manufacturer_id uuid,
    category_id uuid,
    version text,
    description text,
    is_internal_only boolean DEFAULT false,
    is_deprecated boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    license_type text,
    product_family text,
    lifecycle_reference_id uuid
);


--
-- Name: COLUMN technology_products.lifecycle_reference_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.technology_products.lifecycle_reference_id IS 'FK to technology_lifecycle_reference. Links catalog product to vendor lifecycle dates. SET NULL on delete.';


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    user_id uuid NOT NULL,
    current_namespace_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    namespace_id uuid,
    email text NOT NULL,
    name text,
    namespace_role text DEFAULT 'viewer'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_super_admin boolean DEFAULT false,
    individual_id uuid,
    CONSTRAINT users_namespace_role_check CHECK ((namespace_role = ANY (ARRAY['admin'::text, 'editor'::text, 'steward'::text, 'viewer'::text, 'restricted'::text])))
);


--
-- Name: vendor_lifecycle_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendor_lifecycle_sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vendor_name text NOT NULL,
    vendor_aliases text[],
    lifecycle_url text,
    lifecycle_url_pattern text,
    extraction_strategy text DEFAULT 'general'::text,
    last_crawl_at timestamp with time zone,
    crawl_frequency_days integer DEFAULT 30,
    is_active boolean DEFAULT true,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT vendor_lifecycle_sources_extraction_strategy_check CHECK ((extraction_strategy = ANY (ARRAY['general'::text, 'microsoft'::text, 'oracle'::text, 'vmware'::text, 'redhat'::text, 'adobe'::text, 'sap'::text, 'cisco'::text, 'ibm'::text, 'salesforce'::text, 'aws'::text, 'google'::text])))
);


--
-- Name: workspaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    budget_fiscal_year integer,
    budget_notes text,
    description text
);


--
-- Name: COLUMN workspaces.budget_fiscal_year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.workspaces.budget_fiscal_year IS 'Fiscal year for the budget (e.g., 2026). NULL if no budget set.';


--
-- Name: COLUMN workspaces.budget_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.workspaces.budget_notes IS 'Notes about the budget (assumptions, constraints, etc.).';


--
-- Name: vw_application_infrastructure_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_application_infrastructure_report WITH (security_invoker='true') AS
 SELECT a.id AS application_id,
    a.name AS application_name,
    a.operational_status AS app_operational_status,
    a.management_classification,
    a.csdm_stage,
    a.branch,
    dp.id AS deployment_profile_id,
    dp.name AS deployment_profile_name,
    dp.is_primary,
    dp.hosting_type,
    dp.cloud_provider,
    dp.environment,
    dp.server_name,
    dp.tech_health,
    dp.tech_risk,
    dp.tech_assessment_status,
    dp.operational_status AS dp_operational_status,
    w.id AS workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    os_tag.technology_name AS os_name,
    os_tag.deployed_version AS os_version,
    os_tag.deployed_edition AS os_edition,
    os_tag.lifecycle_status AS os_lifecycle_status,
    os_tag.days_to_eol AS os_days_to_eol,
    db_tag.technology_name AS db_name,
    db_tag.deployed_version AS db_version,
    db_tag.deployed_edition AS db_edition,
    db_tag.lifecycle_status AS db_lifecycle_status,
    db_tag.days_to_eol AS db_days_to_eol,
    web_tag.technology_name AS web_name,
    web_tag.deployed_version AS web_version,
    web_tag.deployed_edition AS web_edition,
    web_tag.lifecycle_status AS web_lifecycle_status,
    web_tag.days_to_eol AS web_days_to_eol,
    (EXISTS ( SELECT 1
           FROM public.portfolio_assignments pa
          WHERE ((pa.application_id = a.id) AND (pa.criticality IS NOT NULL) AND (pa.criticality >= (50)::numeric)))) AS is_crown_jewel,
        CASE
            WHEN ((dp.hosting_type = ANY (ARRAY['SaaS'::text, 'Managed'::text])) AND (NOT (EXISTS ( SELECT 1
               FROM public.deployment_profile_technology_products dptp2
              WHERE (dptp2.deployment_profile_id = dp.id))))) THEN 'business_vendor_managed'::text
            WHEN (EXISTS ( SELECT 1
               FROM ((public.deployment_profile_technology_products dptp2
                 JOIN public.technology_products tp2 ON ((tp2.id = dptp2.technology_product_id)))
                 JOIN public.technology_lifecycle_reference tlr2 ON ((tlr2.id = tp2.lifecycle_reference_id)))
              WHERE ((dptp2.deployment_profile_id = dp.id) AND (((tlr2.end_of_life_date IS NOT NULL) AND (tlr2.end_of_life_date < CURRENT_DATE)) OR ((tlr2.extended_support_end IS NOT NULL) AND (tlr2.extended_support_end < CURRENT_DATE)))))) THEN 'end_of_support'::text
            WHEN (EXISTS ( SELECT 1
               FROM ((public.deployment_profile_technology_products dptp2
                 JOIN public.technology_products tp2 ON ((tp2.id = dptp2.technology_product_id)))
                 JOIN public.technology_lifecycle_reference tlr2 ON ((tlr2.id = tp2.lifecycle_reference_id)))
              WHERE ((dptp2.deployment_profile_id = dp.id) AND (tlr2.mainstream_support_end IS NOT NULL) AND (tlr2.mainstream_support_end < CURRENT_DATE)))) THEN 'extended'::text
            WHEN (EXISTS ( SELECT 1
               FROM public.deployment_profile_technology_products dptp2
              WHERE (dptp2.deployment_profile_id = dp.id))) THEN 'mainstream'::text
            ELSE 'incomplete_data'::text
        END AS worst_lifecycle_status
   FROM (((((public.deployment_profiles dp
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     LEFT JOIN LATERAL ( SELECT tp.name AS technology_name,
            COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
            dptp.edition AS deployed_edition,
                CASE
                    WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
                    WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
                    ELSE NULL::text
                END AS lifecycle_status,
                CASE
                    WHEN (tlr.end_of_life_date IS NOT NULL) THEN (tlr.end_of_life_date - CURRENT_DATE)
                    ELSE NULL::integer
                END AS days_to_eol
           FROM (((public.deployment_profile_technology_products dptp
             JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
             JOIN public.technology_product_categories tpc ON ((tpc.id = tp.category_id)))
             LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)))
          WHERE ((dptp.deployment_profile_id = dp.id) AND (tpc.name = 'Operating System'::text))
         LIMIT 1) os_tag ON (true))
     LEFT JOIN LATERAL ( SELECT tp.name AS technology_name,
            COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
            dptp.edition AS deployed_edition,
                CASE
                    WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
                    WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
                    ELSE NULL::text
                END AS lifecycle_status,
                CASE
                    WHEN (tlr.end_of_life_date IS NOT NULL) THEN (tlr.end_of_life_date - CURRENT_DATE)
                    ELSE NULL::integer
                END AS days_to_eol
           FROM (((public.deployment_profile_technology_products dptp
             JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
             JOIN public.technology_product_categories tpc ON ((tpc.id = tp.category_id)))
             LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)))
          WHERE ((dptp.deployment_profile_id = dp.id) AND (tpc.name = 'Database'::text))
         LIMIT 1) db_tag ON (true))
     LEFT JOIN LATERAL ( SELECT tp.name AS technology_name,
            COALESCE(dptp.deployed_version, tp.version) AS deployed_version,
            dptp.edition AS deployed_edition,
                CASE
                    WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
                    WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
                    WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
                    WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
                    ELSE NULL::text
                END AS lifecycle_status,
                CASE
                    WHEN (tlr.end_of_life_date IS NOT NULL) THEN (tlr.end_of_life_date - CURRENT_DATE)
                    ELSE NULL::integer
                END AS days_to_eol
           FROM (((public.deployment_profile_technology_products dptp
             JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
             JOIN public.technology_product_categories tpc ON ((tpc.id = tp.category_id)))
             LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)))
          WHERE ((dptp.deployment_profile_id = dp.id) AND (tpc.name = 'Web Server'::text))
         LIMIT 1) web_tag ON (true));


--
-- Name: vw_application_integration_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_application_integration_summary WITH (security_invoker='true') AS
 SELECT a.id AS application_id,
    a.name AS application_name,
    w.id AS workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    count(ai.id) AS total_integrations,
    count(ai.id) FILTER (WHERE (ai.target_application_id IS NOT NULL)) AS internal_count,
    count(ai.id) FILTER (WHERE (ai.target_application_id IS NULL)) AS external_count,
    count(ai.id) FILTER (WHERE (ai.status = 'active'::text)) AS active_count,
    count(ai.id) FILTER (WHERE (ai.status = 'planned'::text)) AS planned_count,
    count(ai.id) FILTER (WHERE (ai.status = 'deprecated'::text)) AS deprecated_count,
    count(ai.id) FILTER (WHERE (ai.sensitivity = ANY (ARRAY['high'::text, 'confidential'::text]))) AS high_sensitivity_count,
    count(ai.id) FILTER (WHERE (ai.criticality = 'critical'::text)) AS critical_count
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.application_integrations ai ON (((ai.source_application_id = a.id) OR (ai.target_application_id = a.id))))
  GROUP BY a.id, a.name, w.id, w.name, w.namespace_id;


--
-- Name: vw_deployment_profile_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_deployment_profile_costs WITH (security_invoker='true') AS
 SELECT dp.id AS deployment_profile_id,
    dp.name AS deployment_profile_name,
    dp.application_id,
    a.name AS application_name,
    dp.workspace_id,
    a.operational_status,
    COALESCE(sw.software_cost, (0)::numeric) AS software_cost,
    COALESCE(its.service_cost, (0)::numeric) AS service_cost,
        CASE
            WHEN (dp.is_primary = true) THEN COALESCE(cb.bundle_cost, (0)::numeric)
            ELSE (0)::numeric
        END AS bundle_cost,
    ((COALESCE(sw.software_cost, (0)::numeric) + COALESCE(its.service_cost, (0)::numeric)) +
        CASE
            WHEN (dp.is_primary = true) THEN COALESCE(cb.bundle_cost, (0)::numeric)
            ELSE (0)::numeric
        END) AS total_cost
   FROM ((((public.deployment_profiles dp
     JOIN public.applications a ON ((a.id = dp.application_id)))
     LEFT JOIN ( SELECT dpsp.deployment_profile_id,
            sum(COALESCE(dpsp.annual_cost, sp.annual_cost, (0)::numeric)) AS software_cost
           FROM (public.deployment_profile_software_products dpsp
             JOIN public.software_products sp ON ((sp.id = dpsp.software_product_id)))
          GROUP BY dpsp.deployment_profile_id) sw ON ((sw.deployment_profile_id = dp.id)))
     LEFT JOIN ( SELECT dpis.deployment_profile_id,
            sum(
                CASE
                    WHEN (dpis.allocation_basis = 'fixed'::text) THEN COALESCE(dpis.allocation_value, (0)::numeric)
                    WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN COALESCE(dpis.allocation_value, (0)::numeric)
                    WHEN (dpis.allocation_basis = 'percent'::text) THEN COALESCE(((its_1.annual_cost * dpis.allocation_value) / (100)::numeric), (0)::numeric)
                    ELSE COALESCE(dpis.allocation_value, (0)::numeric)
                END) AS service_cost
           FROM (public.deployment_profile_it_services dpis
             JOIN public.it_services its_1 ON ((its_1.id = dpis.it_service_id)))
          GROUP BY dpis.deployment_profile_id) its ON ((its.deployment_profile_id = dp.id)))
     LEFT JOIN ( SELECT cb_1.application_id,
            sum(COALESCE(cb_1.annual_cost, (0)::numeric)) AS bundle_cost
           FROM public.deployment_profiles cb_1
          WHERE ((cb_1.dp_type = 'cost_bundle'::text) AND (cb_1.cost_recurrence = 'recurring'::text))
          GROUP BY cb_1.application_id) cb ON ((cb.application_id = dp.application_id)))
  WHERE (dp.dp_type = 'application'::text);


--
-- Name: vw_application_run_rate; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_application_run_rate WITH (security_invoker='true') AS
 SELECT a.id AS application_id,
    a.name AS application_name,
    a.workspace_id,
    w.namespace_id,
    a.operational_status,
    sum(COALESCE(dpc.software_cost, (0)::numeric)) AS software_cost,
    sum(COALESCE(dpc.service_cost, (0)::numeric)) AS service_cost,
    sum(COALESCE(dpc.bundle_cost, (0)::numeric)) AS bundle_cost,
    sum(COALESCE(dpc.total_cost, (0)::numeric)) AS total_run_rate
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.vw_deployment_profile_costs dpc ON ((dpc.application_id = a.id)))
  WHERE (a.operational_status = 'operational'::text)
  GROUP BY a.id, a.name, a.workspace_id, w.namespace_id, a.operational_status;


--
-- Name: vw_budget_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_budget_status WITH (security_invoker='true') AS
 SELECT a.id AS application_id,
    a.name AS application_name,
    a.workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    a.operational_status,
    COALESCE(a.budget_amount, (0)::numeric) AS budget,
    a.budget_locked,
    a.budget_notes,
    COALESCE(rr.total_run_rate, (0)::numeric) AS committed,
    (COALESCE(a.budget_amount, (0)::numeric) - COALESCE(rr.total_run_rate, (0)::numeric)) AS remaining,
        CASE
            WHEN ((a.budget_amount IS NULL) OR (a.budget_amount = (0)::numeric)) THEN 'no_budget'::text
            WHEN ((rr.total_run_rate IS NULL) OR (rr.total_run_rate = (0)::numeric)) THEN 'no_costs'::text
            WHEN (rr.total_run_rate <= (a.budget_amount * 0.8)) THEN 'healthy'::text
            WHEN (rr.total_run_rate <= a.budget_amount) THEN 'tight'::text
            WHEN (rr.total_run_rate <= (a.budget_amount * 1.1)) THEN 'over_10'::text
            ELSE 'over_critical'::text
        END AS budget_status,
        CASE
            WHEN ((a.budget_amount IS NULL) OR (a.budget_amount = (0)::numeric)) THEN NULL::numeric
            ELSE round(((COALESCE(rr.total_run_rate, (0)::numeric) / a.budget_amount) * (100)::numeric), 1)
        END AS percent_used
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.vw_application_run_rate rr ON ((rr.application_id = a.id)))
  WHERE (a.operational_status = 'operational'::text);


--
-- Name: vw_budget_alerts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_budget_alerts WITH (security_invoker='true') AS
 SELECT workspace_id,
    workspace_name,
    namespace_id,
    application_id,
    application_name,
    budget,
    committed,
    remaining,
    budget_status,
    percent_used,
        CASE
            WHEN (budget_status = ANY (ARRAY['over_10'::text, 'over_critical'::text])) THEN 'over_budget'::text
            WHEN ((budget_status = 'tight'::text) AND (remaining < (5000)::numeric)) THEN 'nearly_exhausted'::text
            WHEN ((budget_status = 'no_budget'::text) AND (committed > (10000)::numeric)) THEN 'significant_unbudgeted'::text
            ELSE NULL::text
        END AS alert_type,
        CASE
            WHEN (budget_status = 'over_critical'::text) THEN 1
            WHEN (budget_status = 'over_10'::text) THEN 2
            WHEN ((budget_status = 'tight'::text) AND (remaining < (5000)::numeric)) THEN 3
            WHEN ((budget_status = 'no_budget'::text) AND (committed > (10000)::numeric)) THEN 4
            ELSE 5
        END AS alert_priority
   FROM public.vw_budget_status
  WHERE ((budget_status = ANY (ARRAY['over_10'::text, 'over_critical'::text, 'tight'::text, 'no_budget'::text])) AND ((budget_status = ANY (ARRAY['over_10'::text, 'over_critical'::text])) OR ((budget_status = 'tight'::text) AND (remaining < (5000)::numeric)) OR ((budget_status = 'no_budget'::text) AND (committed > (10000)::numeric))))
  ORDER BY
        CASE
            WHEN (budget_status = 'over_critical'::text) THEN 1
            WHEN (budget_status = 'over_10'::text) THEN 2
            WHEN ((budget_status = 'tight'::text) AND (remaining < (5000)::numeric)) THEN 3
            WHEN ((budget_status = 'no_budget'::text) AND (committed > (10000)::numeric)) THEN 4
            ELSE 5
        END, remaining;


--
-- Name: vw_budget_transfer_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_budget_transfer_history WITH (security_invoker='true') AS
 SELECT bt.id,
    bt.workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    bt.fiscal_year,
    bt.from_application_id,
    from_app.name AS from_application_name,
        CASE
            WHEN (bt.from_application_id IS NULL) THEN 'Unallocated Reserve'::text
            ELSE from_app.name
        END AS from_display,
    bt.to_application_id,
    to_app.name AS to_application_name,
        CASE
            WHEN (bt.to_application_id IS NULL) THEN 'Unallocated Reserve'::text
            ELSE to_app.name
        END AS to_display,
    bt.amount,
    bt.reason,
    bt.transferred_by,
    u.email AS transferred_by_email,
    bt.transferred_at,
    bt.approved_by,
    bt.approved_at
   FROM ((((public.budget_transfers bt
     JOIN public.workspaces w ON ((w.id = bt.workspace_id)))
     LEFT JOIN public.applications from_app ON ((from_app.id = bt.from_application_id)))
     LEFT JOIN public.applications to_app ON ((to_app.id = bt.to_application_id)))
     LEFT JOIN public.users u ON ((u.id = bt.transferred_by)))
  ORDER BY bt.transferred_at DESC;


--
-- Name: vw_finding_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_finding_summary WITH (security_invoker='true') AS
 SELECT namespace_id,
    assessment_domain,
        CASE assessment_domain
            WHEN 'icoms'::text THEN 'IT Operating Model & Spend'::text
            WHEN 'bpa'::text THEN 'Business Process & Applications'::text
            WHEN 'ti'::text THEN 'Technology Infrastructure'::text
            WHEN 'dqa'::text THEN 'Data Quality & Analytics'::text
            WHEN 'cr'::text THEN 'Cybersecurity Risk'::text
            WHEN 'other'::text THEN 'Other'::text
            ELSE NULL::text
        END AS domain_name,
        CASE
            WHEN bool_or((impact = 'high'::text)) THEN 'high'::text
            WHEN bool_or((impact = 'medium'::text)) THEN 'medium'::text
            ELSE 'low'::text
        END AS domain_impact,
    count(*) AS finding_count,
    count(*) FILTER (WHERE (impact = 'high'::text)) AS high_count,
    count(*) FILTER (WHERE (impact = 'medium'::text)) AS medium_count,
    count(*) FILTER (WHERE (impact = 'low'::text)) AS low_count,
    count(*) FILTER (WHERE (source_type = 'computed'::text)) AS computed_count,
    count(*) FILTER (WHERE (source_type = 'manual'::text)) AS manual_count,
    max(as_of_date) AS latest_finding_date
   FROM public.findings f
  GROUP BY namespace_id, assessment_domain;


--
-- Name: vw_idea_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_idea_summary WITH (security_invoker='true') AS
 SELECT i.namespace_id,
    i.workspace_id,
    w.name AS workspace_name,
    i.id AS idea_id,
    i.title,
    i.description,
    i.assessment_domain,
        CASE i.assessment_domain
            WHEN 'icoms'::text THEN 'IT Operating Model & Spend'::text
            WHEN 'bpa'::text THEN 'Business Process & Applications'::text
            WHEN 'ti'::text THEN 'Technology Infrastructure'::text
            WHEN 'dqa'::text THEN 'Data Quality & Analytics'::text
            WHEN 'cr'::text THEN 'Cybersecurity Risk'::text
            WHEN 'other'::text THEN 'Other'::text
            ELSE NULL::text
        END AS domain_name,
    i.status,
    i.review_notes,
    i.reviewed_at,
    c.display_name AS submitted_by_name,
    i.promoted_to_initiative_id,
    init.title AS promoted_initiative_title,
    i.created_at
   FROM (((public.ideas i
     LEFT JOIN public.workspaces w ON ((w.id = i.workspace_id)))
     LEFT JOIN public.contacts c ON ((c.id = i.submitted_by_contact_id)))
     LEFT JOIN public.initiatives init ON ((init.id = i.promoted_to_initiative_id)));


--
-- Name: vw_initiative_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_initiative_summary WITH (security_invoker='true') AS
 SELECT i.namespace_id,
    i.workspace_id,
    w.name AS workspace_name,
    i.id AS initiative_id,
    i.title,
    i.assessment_domain,
        CASE i.assessment_domain
            WHEN 'icoms'::text THEN 'IT Operating Model & Spend'::text
            WHEN 'bpa'::text THEN 'Business Process & Applications'::text
            WHEN 'ti'::text THEN 'Technology Infrastructure'::text
            WHEN 'dqa'::text THEN 'Data Quality & Analytics'::text
            WHEN 'cr'::text THEN 'Cybersecurity Risk'::text
            WHEN 'other'::text THEN 'Other'::text
            ELSE NULL::text
        END AS domain_name,
    i.strategic_theme,
    i.priority,
    i.time_horizon,
    i.status,
    i.owner_contact_id,
    c.display_name AS owner_name,
    round(((COALESCE(i.one_time_cost_low, (0)::numeric) + COALESCE(i.one_time_cost_high, (0)::numeric)) / (2)::numeric)) AS one_time_cost_mid,
    round(((COALESCE(i.recurring_cost_low, (0)::numeric) + COALESCE(i.recurring_cost_high, (0)::numeric)) / (2)::numeric)) AS recurring_cost_mid,
    i.one_time_cost_low,
    i.one_time_cost_high,
    i.recurring_cost_low,
    i.recurring_cost_high,
    COALESCE(i.estimated_run_rate_change, (0)::numeric) AS run_rate_change,
    i.run_rate_change_rationale,
    i.source_finding_id,
    f.title AS source_finding_title,
    i.expected_benefit,
    i.benefit_type,
    ( SELECT count(*) AS count
           FROM public.initiative_deployment_profiles idp
          WHERE (idp.initiative_id = i.id)) AS linked_dp_count,
    ( SELECT count(*) AS count
           FROM public.initiative_it_services iis
          WHERE (iis.initiative_id = i.id)) AS linked_service_count,
    i.target_start_date,
    i.target_end_date,
    i.created_at
   FROM (((public.initiatives i
     LEFT JOIN public.workspaces w ON ((w.id = i.workspace_id)))
     LEFT JOIN public.contacts c ON ((c.id = i.owner_contact_id)))
     LEFT JOIN public.findings f ON ((f.id = i.source_finding_id)));


--
-- Name: vw_integration_contacts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_integration_contacts WITH (security_invoker='true') AS
 SELECT ic.id AS integration_contact_id,
    ic.integration_id,
    ai.name AS integration_name,
    ai.source_application_id,
    sa.name AS source_application_name,
    sw.namespace_id,
    ic.contact_id,
    c.display_name AS contact_name,
    c.email AS contact_email,
    c.job_title AS contact_job_title,
    ic.role_type,
    ic.is_primary,
    ic.notes,
    ic.created_at
   FROM ((((public.integration_contacts ic
     JOIN public.application_integrations ai ON ((ai.id = ic.integration_id)))
     JOIN public.applications sa ON ((sa.id = ai.source_application_id)))
     JOIN public.workspaces sw ON ((sw.id = sa.workspace_id)))
     JOIN public.contacts c ON ((c.id = ic.contact_id)));


--
-- Name: vw_integration_detail; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_integration_detail WITH (security_invoker='true') AS
 SELECT ai.id,
    ai.name AS integration_name,
    ai.source_application_id,
    sa.name AS source_application_name,
    sw.id AS source_workspace_id,
    sw.name AS source_workspace_name,
    sw.namespace_id,
    ai.target_application_id,
    ta.name AS target_application_name,
    tw.name AS target_workspace_name,
    ai.external_system_name,
    ai.external_organization_id,
    eo.name AS external_organization_name,
        CASE
            WHEN (ai.target_application_id IS NOT NULL) THEN 'internal'::text
            ELSE 'external'::text
        END AS integration_category,
    ai.direction,
    ai.integration_type,
    ai.data_format,
    ai.frequency,
    ai.criticality,
    ai.sensitivity,
    ai.data_classification,
    ai.status,
    ai.description,
    ai.sla_description,
    ai.notes,
    ai.created_at,
    ai.updated_at,
    ( SELECT count(*) AS count
           FROM public.integration_contacts ic
          WHERE (ic.integration_id = ai.id)) AS contact_count,
    ( SELECT c.display_name
           FROM (public.integration_contacts ic
             JOIN public.contacts c ON ((c.id = ic.contact_id)))
          WHERE ((ic.integration_id = ai.id) AND (ic.is_primary = true))
         LIMIT 1) AS primary_contact_name
   FROM (((((public.application_integrations ai
     JOIN public.applications sa ON ((sa.id = ai.source_application_id)))
     JOIN public.workspaces sw ON ((sw.id = sa.workspace_id)))
     LEFT JOIN public.applications ta ON ((ta.id = ai.target_application_id)))
     LEFT JOIN public.workspaces tw ON ((tw.id = ta.workspace_id)))
     LEFT JOIN public.organizations eo ON ((eo.id = ai.external_organization_id)));


--
-- Name: vw_it_service_budget_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_it_service_budget_status WITH (security_invoker='true') AS
 SELECT its.id AS it_service_id,
    its.name AS it_service_name,
    its.owner_workspace_id AS workspace_id,
    w.namespace_id,
    its.budget_amount AS budget,
    its.budget_fiscal_year,
    COALESCE(( SELECT sum(
                CASE
                    WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                    WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                    WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its.annual_cost * dpis.allocation_value) / (100)::numeric)
                    ELSE dpis.allocation_value
                END) AS sum
           FROM public.deployment_profile_it_services dpis
          WHERE (dpis.it_service_id = its.id)), (0)::numeric) AS committed,
    (its.budget_amount - COALESCE(( SELECT sum(
                CASE
                    WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                    WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                    WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its.annual_cost * dpis.allocation_value) / (100)::numeric)
                    ELSE dpis.allocation_value
                END) AS sum
           FROM public.deployment_profile_it_services dpis
          WHERE (dpis.it_service_id = its.id)), (0)::numeric)) AS remaining,
        CASE
            WHEN (its.budget_amount IS NULL) THEN 'no_budget'::text
            WHEN ((its.budget_amount - COALESCE(( SELECT sum(
                    CASE
                        WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                        WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                        WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its.annual_cost * dpis.allocation_value) / (100)::numeric)
                        ELSE dpis.allocation_value
                    END) AS sum
               FROM public.deployment_profile_it_services dpis
              WHERE (dpis.it_service_id = its.id)), (0)::numeric)) < (0)::numeric) THEN 'over_critical'::text
            WHEN (((its.budget_amount - COALESCE(( SELECT sum(
                    CASE
                        WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                        WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                        WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its.annual_cost * dpis.allocation_value) / (100)::numeric)
                        ELSE dpis.allocation_value
                    END) AS sum
               FROM public.deployment_profile_it_services dpis
              WHERE (dpis.it_service_id = its.id)), (0)::numeric)) / NULLIF(its.budget_amount, (0)::numeric)) < 0.10) THEN 'over_10'::text
            WHEN (((its.budget_amount - COALESCE(( SELECT sum(
                    CASE
                        WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                        WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                        WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its.annual_cost * dpis.allocation_value) / (100)::numeric)
                        ELSE dpis.allocation_value
                    END) AS sum
               FROM public.deployment_profile_it_services dpis
              WHERE (dpis.it_service_id = its.id)), (0)::numeric)) / NULLIF(its.budget_amount, (0)::numeric)) < 0.25) THEN 'under_25'::text
            ELSE 'healthy'::text
        END AS budget_status
   FROM (public.it_services its
     JOIN public.workspaces w ON ((w.id = its.owner_workspace_id)));


--
-- Name: VIEW vw_it_service_budget_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_it_service_budget_status IS 'Budget health status for IT Services';


--
-- Name: vw_namespace_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_namespace_summary WITH (security_invoker='true') AS
 SELECT n.id,
    n.name,
    n.slug,
    n.tier,
    n.region,
    n.status,
    n.created_at,
    n.updated_at,
    os.name AS org_display_name,
    COALESCE(ws.workspace_count, (0)::bigint) AS workspace_count,
    COALESCE(us.user_count, (0)::bigint) AS user_count,
    COALESCE(ap.app_count, (0)::bigint) AS app_count,
    COALESCE(dp.dp_count, (0)::bigint) AS dp_count,
    COALESCE(inv.pending_count, (0)::bigint) AS pending_invitation_count,
    COALESCE(inv.expired_count, (0)::bigint) AS expired_invitation_count,
        CASE
            WHEN (n.status = 'inactive'::text) THEN 'inactive'::text
            WHEN (COALESCE(us.user_count, (0)::bigint) > 0) THEN 'active'::text
            WHEN (COALESCE(inv.pending_count, (0)::bigint) > 0) THEN 'invited'::text
            WHEN (COALESCE(inv.expired_count, (0)::bigint) > 0) THEN 'expired'::text
            ELSE 'new'::text
        END AS health_status
   FROM ((((((public.namespaces n
     LEFT JOIN public.organization_settings os ON ((os.namespace_id = n.id)))
     LEFT JOIN ( SELECT workspaces.namespace_id,
            count(*) AS workspace_count
           FROM public.workspaces
          GROUP BY workspaces.namespace_id) ws ON ((ws.namespace_id = n.id)))
     LEFT JOIN ( SELECT users.namespace_id,
            count(*) AS user_count
           FROM public.users
          GROUP BY users.namespace_id) us ON ((us.namespace_id = n.id)))
     LEFT JOIN ( SELECT w.namespace_id,
            count(*) AS app_count
           FROM (public.applications a
             JOIN public.workspaces w ON ((w.id = a.workspace_id)))
          GROUP BY w.namespace_id) ap ON ((ap.namespace_id = n.id)))
     LEFT JOIN ( SELECT w.namespace_id,
            count(*) AS dp_count
           FROM (public.deployment_profiles d
             JOIN public.workspaces w ON ((w.id = d.workspace_id)))
          GROUP BY w.namespace_id) dp ON ((dp.namespace_id = n.id)))
     LEFT JOIN ( SELECT invitations.namespace_id,
            count(*) FILTER (WHERE ((invitations.status = 'pending'::text) AND (invitations.expires_at > now()))) AS pending_count,
            count(*) FILTER (WHERE ((invitations.status = 'pending'::text) AND (invitations.expires_at <= now()))) AS expired_count
           FROM public.invitations
          GROUP BY invitations.namespace_id) inv ON ((inv.namespace_id = n.id)));


--
-- Name: workspace_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text DEFAULT 'editor'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT workspace_users_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'editor'::text, 'viewer'::text])))
);


--
-- Name: vw_namespace_user_detail; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_namespace_user_detail WITH (security_invoker='true') AS
 SELECT id,
    namespace_id,
    email,
    name,
    namespace_role,
    is_super_admin,
    created_at,
    COALESCE(( SELECT json_agg(json_build_object('workspace_id', w.id, 'workspace_name', w.name, 'role', wu.role) ORDER BY w.name) AS json_agg
           FROM (public.workspace_users wu
             JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
          WHERE ((wu.user_id = u.id) AND (w.namespace_id = u.namespace_id))), '[]'::json) AS workspace_assignments
   FROM public.users u;


--
-- Name: vw_namespace_workspace_detail; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_namespace_workspace_detail WITH (security_invoker='true') AS
 SELECT w.id,
    w.namespace_id,
    w.name,
    w.slug,
    w.is_default,
    w.created_at,
    COALESCE(wu.user_count, (0)::bigint) AS user_count,
    COALESCE(ap.app_count, (0)::bigint) AS app_count,
    COALESCE(pf.portfolio_count, (0)::bigint) AS portfolio_count
   FROM (((public.workspaces w
     LEFT JOIN ( SELECT workspace_users.workspace_id,
            count(*) AS user_count
           FROM public.workspace_users
          GROUP BY workspace_users.workspace_id) wu ON ((wu.workspace_id = w.id)))
     LEFT JOIN ( SELECT applications.workspace_id,
            count(*) AS app_count
           FROM public.applications
          GROUP BY applications.workspace_id) ap ON ((ap.workspace_id = w.id)))
     LEFT JOIN ( SELECT portfolios.workspace_id,
            count(*) AS portfolio_count
           FROM public.portfolios
          GROUP BY portfolios.workspace_id) pf ON ((pf.workspace_id = w.id)));


--
-- Name: vw_portfolio_costs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_portfolio_costs WITH (security_invoker='true') AS
 SELECT p.id AS portfolio_id,
    p.name AS portfolio_name,
    p.parent_portfolio_id,
    p.workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
        CASE
            WHEN (EXISTS ( SELECT 1
               FROM public.portfolios c
              WHERE (c.parent_portfolio_id = p.id))) THEN 'parent'::text
            ELSE 'leaf'::text
        END AS portfolio_type,
    count(DISTINCT pa.deployment_profile_id) AS dp_count,
    count(DISTINCT dp.application_id) AS app_count,
    COALESCE(sum((COALESCE(dpc.software_cost, (0)::numeric) * COALESCE((pa.cost_allocation_percent / 100.0), 1.0))), (0)::numeric) AS software_cost,
    COALESCE(sum((COALESCE(dpc.service_cost, (0)::numeric) * COALESCE((pa.cost_allocation_percent / 100.0), 1.0))), (0)::numeric) AS service_cost,
    COALESCE(sum((COALESCE(dpc.bundle_cost, (0)::numeric) * COALESCE((pa.cost_allocation_percent / 100.0), 1.0))), (0)::numeric) AS bundle_cost,
    COALESCE(sum((COALESCE(dpc.total_cost, (0)::numeric) * COALESCE((pa.cost_allocation_percent / 100.0), 1.0))), (0)::numeric) AS total_cost
   FROM ((((public.portfolios p
     LEFT JOIN public.workspaces w ON ((w.id = p.workspace_id)))
     LEFT JOIN public.portfolio_assignments pa ON ((pa.portfolio_id = p.id)))
     LEFT JOIN public.deployment_profiles dp ON ((dp.id = pa.deployment_profile_id)))
     LEFT JOIN public.vw_deployment_profile_costs dpc ON ((dpc.deployment_profile_id = dp.id)))
  GROUP BY p.id, p.name, p.parent_portfolio_id, p.workspace_id, w.name, w.namespace_id;


--
-- Name: VIEW vw_portfolio_costs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_portfolio_costs IS 'Portfolio costs at leaf level. Parent portfolios show 0 direct costs. Use vw_portfolio_costs_rollup for hierarchical aggregation.';


--
-- Name: vw_portfolio_costs_rollup; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_portfolio_costs_rollup WITH (security_invoker='true') AS
 WITH RECURSIVE portfolio_tree AS (
         SELECT portfolios.id AS portfolio_id,
            portfolios.parent_portfolio_id,
            0 AS depth,
            ARRAY[portfolios.id] AS path
           FROM public.portfolios
          WHERE (portfolios.parent_portfolio_id IS NULL)
        UNION ALL
         SELECT p_1.id,
            p_1.parent_portfolio_id,
            (pt_1.depth + 1),
            (pt_1.path || p_1.id)
           FROM (public.portfolios p_1
             JOIN portfolio_tree pt_1 ON ((p_1.parent_portfolio_id = pt_1.portfolio_id)))
          WHERE (pt_1.depth < 10)
        ), leaf_costs AS (
         SELECT vw_portfolio_costs.portfolio_id,
            vw_portfolio_costs.software_cost,
            vw_portfolio_costs.service_cost,
            vw_portfolio_costs.bundle_cost,
            vw_portfolio_costs.total_cost,
            vw_portfolio_costs.dp_count,
            vw_portfolio_costs.app_count
           FROM public.vw_portfolio_costs
        ), descendants AS (
         SELECT pt1.portfolio_id,
            pt2.portfolio_id AS descendant_id
           FROM (portfolio_tree pt1
             CROSS JOIN portfolio_tree pt2)
          WHERE (pt1.portfolio_id = ANY (pt2.path))
        )
 SELECT pt.portfolio_id,
    p.name AS portfolio_name,
    p.parent_portfolio_id,
    p.workspace_id,
    pt.depth,
    COALESCE(lc.software_cost, (0)::numeric) AS direct_software_cost,
    COALESCE(lc.service_cost, (0)::numeric) AS direct_service_cost,
    COALESCE(lc.bundle_cost, (0)::numeric) AS direct_bundle_cost,
    COALESCE(lc.total_cost, (0)::numeric) AS direct_total_cost,
    COALESCE(sum(lc_desc.software_cost), (0)::numeric) AS rollup_software_cost,
    COALESCE(sum(lc_desc.service_cost), (0)::numeric) AS rollup_service_cost,
    COALESCE(sum(lc_desc.bundle_cost), (0)::numeric) AS rollup_bundle_cost,
    COALESCE(sum(lc_desc.total_cost), (0)::numeric) AS rollup_total_cost,
    COALESCE(lc.dp_count, (0)::bigint) AS direct_dp_count,
    COALESCE(lc.app_count, (0)::bigint) AS direct_app_count,
    COALESCE(sum(lc_desc.dp_count), (0)::numeric) AS rollup_dp_count,
    COALESCE(sum(lc_desc.app_count), (0)::numeric) AS rollup_app_count,
        CASE
            WHEN (pt.depth = 0) THEN true
            ELSE false
        END AS is_leaf,
        CASE
            WHEN (p.parent_portfolio_id IS NULL) THEN true
            ELSE false
        END AS is_root
   FROM ((((portfolio_tree pt
     JOIN public.portfolios p ON ((p.id = pt.portfolio_id)))
     LEFT JOIN leaf_costs lc ON ((lc.portfolio_id = pt.portfolio_id)))
     LEFT JOIN descendants d ON ((d.portfolio_id = pt.portfolio_id)))
     LEFT JOIN leaf_costs lc_desc ON ((lc_desc.portfolio_id = d.descendant_id)))
  GROUP BY pt.portfolio_id, p.name, p.parent_portfolio_id, p.workspace_id, pt.depth, lc.software_cost, lc.service_cost, lc.bundle_cost, lc.total_cost, lc.dp_count, lc.app_count;


--
-- Name: VIEW vw_portfolio_costs_rollup; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_portfolio_costs_rollup IS 'Recursive portfolio cost aggregation. direct_* fields show costs directly assigned. rollup_* fields include all descendants.';


--
-- Name: vw_program_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_program_summary WITH (security_invoker='true') AS
 SELECT p.namespace_id,
    p.workspace_id,
    w.name AS workspace_name,
    p.id AS program_id,
    p.title,
    p.description,
    p.strategic_theme,
    p.business_driver,
    p.status,
    p.budget_amount,
    p.budget_fiscal_year,
    p.target_start_date,
    p.target_end_date,
    owner_c.display_name AS owner_name,
    sponsor_c.display_name AS sponsor_name,
    ( SELECT count(*) AS count
           FROM public.program_initiatives pi
          WHERE (pi.program_id = p.id)) AS initiative_count,
    ( SELECT count(*) AS count
           FROM (public.program_initiatives pi
             JOIN public.initiatives i ON ((i.id = pi.initiative_id)))
          WHERE ((pi.program_id = p.id) AND (i.status = 'completed'::text))) AS completed_count,
    ( SELECT count(*) AS count
           FROM (public.program_initiatives pi
             JOIN public.initiatives i ON ((i.id = pi.initiative_id)))
          WHERE ((pi.program_id = p.id) AND (i.status = 'in_progress'::text))) AS active_count,
    ( SELECT COALESCE(sum(round(((COALESCE(i.one_time_cost_low, (0)::numeric) + COALESCE(i.one_time_cost_high, (0)::numeric)) / (2)::numeric))), (0)::numeric) AS "coalesce"
           FROM (public.program_initiatives pi
             JOIN public.initiatives i ON ((i.id = pi.initiative_id)))
          WHERE ((pi.program_id = p.id) AND (i.status <> 'cancelled'::text))) AS total_initiative_cost_mid,
    ( SELECT COALESCE(sum(COALESCE(i.estimated_run_rate_change, (0)::numeric)), (0)::numeric) AS "coalesce"
           FROM (public.program_initiatives pi
             JOIN public.initiatives i ON ((i.id = pi.initiative_id)))
          WHERE ((pi.program_id = p.id) AND (i.status <> 'cancelled'::text))) AS total_run_rate_change,
    p.created_at
   FROM (((public.programs p
     LEFT JOIN public.workspaces w ON ((w.id = p.workspace_id)))
     LEFT JOIN public.contacts owner_c ON ((owner_c.id = p.owner_contact_id)))
     LEFT JOIN public.contacts sponsor_c ON ((sponsor_c.id = p.sponsor_contact_id)));


--
-- Name: vw_run_rate_by_vendor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_run_rate_by_vendor WITH (security_invoker='true') AS
 SELECT w.namespace_id,
    COALESCE(dpsp.vendor_org_id, sp.manufacturer_org_id) AS vendor_org_id,
    o.name AS vendor_name,
    'Software'::text AS cost_channel,
    sum(COALESCE(sp.annual_cost, (0)::numeric)) AS total_cost
   FROM (((((public.deployment_profile_software_products dpsp
     JOIN public.software_products sp ON ((sp.id = dpsp.software_product_id)))
     JOIN public.deployment_profiles dp ON ((dp.id = dpsp.deployment_profile_id)))
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.organizations o ON ((o.id = COALESCE(dpsp.vendor_org_id, sp.manufacturer_org_id))))
  WHERE ((a.operational_status = 'operational'::text) AND (dp.dp_type = 'application'::text))
  GROUP BY w.namespace_id, COALESCE(dpsp.vendor_org_id, sp.manufacturer_org_id), o.name
UNION ALL
 SELECT w.namespace_id,
    its.vendor_org_id,
    o.name AS vendor_name,
    'IT Service'::text AS cost_channel,
    sum(COALESCE(dpis.allocation_value, (0)::numeric)) AS total_cost
   FROM (((((public.deployment_profile_it_services dpis
     JOIN public.it_services its ON ((its.id = dpis.it_service_id)))
     JOIN public.deployment_profiles dp ON ((dp.id = dpis.deployment_profile_id)))
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.organizations o ON ((o.id = its.vendor_org_id)))
  WHERE ((a.operational_status = 'operational'::text) AND (dp.dp_type = 'application'::text))
  GROUP BY w.namespace_id, its.vendor_org_id, o.name
UNION ALL
 SELECT w.namespace_id,
    dp.vendor_org_id,
    o.name AS vendor_name,
    'Cost Bundle'::text AS cost_channel,
    sum(COALESCE(dp.annual_cost, (0)::numeric)) AS total_cost
   FROM (((public.deployment_profiles dp
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.organizations o ON ((o.id = dp.vendor_org_id)))
  WHERE ((a.operational_status = 'operational'::text) AND (dp.dp_type = 'cost_bundle'::text) AND (dp.cost_recurrence = 'recurring'::text))
  GROUP BY w.namespace_id, dp.vendor_org_id, o.name;


--
-- Name: vw_server_technology_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_server_technology_report WITH (security_invoker='true') AS
 SELECT dp.server_name,
    dp.workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    count(DISTINCT dp.id) AS deployment_count,
    count(DISTINCT dp.application_id) AS application_count,
    mode() WITHIN GROUP (ORDER BY os_tp.name) AS primary_os,
    mode() WITHIN GROUP (ORDER BY os_dptp.deployed_version) AS primary_os_version,
        CASE
            WHEN bool_or(((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE))) THEN 'end_of_support'::text
            WHEN bool_or(((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE))) THEN 'end_of_support'::text
            WHEN bool_or(((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE))) THEN 'extended'::text
            WHEN bool_or((tlr.id IS NOT NULL)) THEN 'mainstream'::text
            ELSE 'incomplete_data'::text
        END AS worst_lifecycle_status,
    count(DISTINCT dptp.id) FILTER (WHERE (((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) OR ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)))) AS end_of_support_tech_count,
    min(tlr.end_of_life_date) FILTER (WHERE (tlr.end_of_life_date >= CURRENT_DATE)) AS next_eol_date
   FROM (((((((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     LEFT JOIN public.deployment_profile_technology_products dptp ON ((dptp.deployment_profile_id = dp.id)))
     LEFT JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
     LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)))
     LEFT JOIN public.deployment_profile_technology_products os_dptp ON ((os_dptp.deployment_profile_id = dp.id)))
     LEFT JOIN public.technology_products os_tp ON ((os_tp.id = os_dptp.technology_product_id)))
     LEFT JOIN public.technology_product_categories os_tpc ON (((os_tpc.id = os_tp.category_id) AND (os_tpc.name = 'Operating System'::text))))
  WHERE (dp.server_name IS NOT NULL)
  GROUP BY dp.server_name, dp.workspace_id, w.name, w.namespace_id;


--
-- Name: vw_service_type_picker; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_service_type_picker WITH (security_invoker='true') AS
 SELECT st.id AS type_id,
    st.namespace_id,
    stc.id AS category_id,
    stc.code AS category_code,
    stc.name AS category_name,
    stc.display_order AS category_sort,
    st.code AS type_code,
    st.name AS type_name,
    st.description AS type_description,
    st.display_order AS type_sort,
        CASE
            WHEN (stc.code = st.code) THEN stc.name
            ELSE ((stc.name || ' > '::text) || st.name)
        END AS display_name,
    st.is_active
   FROM (public.service_types st
     JOIN public.service_type_categories stc ON ((stc.id = st.category_id)))
  WHERE ((st.is_active = true) AND (stc.is_active = true))
  ORDER BY stc.display_order, st.display_order;


--
-- Name: vw_software_contract_expiry; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_software_contract_expiry WITH (security_invoker='true') AS
 SELECT dpsp.id AS junction_id,
    dpsp.deployment_profile_id,
    dp.name AS deployment_profile_name,
    dp.application_id,
    a.name AS application_name,
    sp.id AS software_product_id,
    sp.name AS software_product_name,
    w.namespace_id,
    dpsp.vendor_org_id,
    o.name AS vendor_name,
    dpsp.contract_reference,
    dpsp.contract_start_date,
    dpsp.contract_end_date,
    dpsp.renewal_notice_days,
        CASE
            WHEN (dpsp.contract_end_date IS NULL) THEN 'No Contract'::text
            WHEN (dpsp.contract_end_date < CURRENT_DATE) THEN 'Expired'::text
            WHEN (dpsp.contract_end_date <= (CURRENT_DATE + '30 days'::interval)) THEN 'Expiring 30 Days'::text
            WHEN (dpsp.contract_end_date <= (CURRENT_DATE + '90 days'::interval)) THEN 'Expiring 90 Days'::text
            WHEN (dpsp.contract_end_date <= (CURRENT_DATE + '180 days'::interval)) THEN 'Expiring 180 Days'::text
            ELSE 'Active'::text
        END AS contract_status,
    (dpsp.contract_end_date - CURRENT_DATE) AS days_until_expiry
   FROM (((((public.deployment_profile_software_products dpsp
     JOIN public.software_products sp ON ((sp.id = dpsp.software_product_id)))
     JOIN public.deployment_profiles dp ON ((dp.id = dpsp.deployment_profile_id)))
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     LEFT JOIN public.organizations o ON ((o.id = dpsp.vendor_org_id)))
  WHERE (dp.dp_type = 'application'::text);


--
-- Name: vw_technology_health_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_technology_health_summary WITH (security_invoker='true') AS
 SELECT w.namespace_id,
    tpc.name AS category_name,
        CASE
            WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
            WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
            ELSE 'incomplete_data'::text
        END AS lifecycle_status,
    count(DISTINCT dptp.id) AS tag_count,
    count(DISTINCT dp.id) AS deployment_count,
    count(DISTINCT dp.application_id) AS application_count,
    (count(DISTINCT dptp.id) FILTER (WHERE ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE))) + count(DISTINCT dptp.id) FILTER (WHERE ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE) AND ((tlr.end_of_life_date IS NULL) OR (tlr.end_of_life_date >= CURRENT_DATE))))) AS end_of_support_tag_count,
    count(DISTINCT dptp.id) FILTER (WHERE ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date >= CURRENT_DATE) AND (tlr.end_of_life_date < (CURRENT_DATE + '1 year'::interval)))) AS eol_within_12mo_count,
    count(DISTINCT dptp.id) FILTER (WHERE ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end >= CURRENT_DATE) AND (tlr.extended_support_end < (CURRENT_DATE + '1 year'::interval)))) AS ext_end_within_12mo_count
   FROM (((((public.deployment_profile_technology_products dptp
     JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
     JOIN public.deployment_profiles dp ON ((dp.id = dptp.deployment_profile_id)))
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     LEFT JOIN public.technology_product_categories tpc ON ((tpc.id = tp.category_id)))
     LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)))
  GROUP BY w.namespace_id, tpc.name,
        CASE
            WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
            WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
            ELSE 'incomplete_data'::text
        END;


--
-- Name: vw_technology_tag_lifecycle_risk; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_technology_tag_lifecycle_risk WITH (security_invoker='true') AS
 SELECT dptp.id AS tag_id,
    dptp.deployment_profile_id,
    dptp.technology_product_id,
    dptp.deployed_version,
    dptp.edition AS deployed_edition,
    dptp.notes AS tag_notes,
    tp.name AS technology_name,
    tp.version AS catalog_version,
    tp.product_family,
    tp.manufacturer_id,
    tpc.name AS category_name,
    dp.name AS deployment_profile_name,
    dp.application_id,
    dp.workspace_id,
    dp.hosting_type,
    dp.environment,
    dp.server_name,
    dp.operational_status AS dp_operational_status,
    a.name AS application_name,
    a.operational_status AS app_operational_status,
    w.namespace_id,
    w.name AS workspace_name,
    tlr.id AS lifecycle_reference_id,
    tlr.vendor_name,
    tlr.ga_date,
    tlr.mainstream_support_end,
    tlr.extended_support_end,
    tlr.end_of_life_date,
    tlr.confidence_level,
    tlr.is_manually_overridden,
        CASE
            WHEN ((tlr.end_of_life_date IS NOT NULL) AND (tlr.end_of_life_date < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.extended_support_end IS NOT NULL) AND (tlr.extended_support_end < CURRENT_DATE)) THEN 'end_of_support'::text
            WHEN ((tlr.mainstream_support_end IS NOT NULL) AND (tlr.mainstream_support_end < CURRENT_DATE)) THEN 'extended'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date <= CURRENT_DATE)) THEN 'mainstream'::text
            WHEN ((tlr.ga_date IS NOT NULL) AND (tlr.ga_date > CURRENT_DATE)) THEN 'preview'::text
            WHEN (tlr.id IS NOT NULL) THEN 'incomplete_data'::text
            ELSE NULL::text
        END AS lifecycle_status,
        CASE
            WHEN (tlr.end_of_life_date IS NOT NULL) THEN (tlr.end_of_life_date - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_to_eol,
        CASE
            WHEN (tlr.extended_support_end IS NOT NULL) THEN (tlr.extended_support_end - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_to_extended_end,
        CASE
            WHEN (tlr.mainstream_support_end IS NOT NULL) THEN (tlr.mainstream_support_end - CURRENT_DATE)
            ELSE NULL::integer
        END AS days_to_mainstream_end,
    ( SELECT max(pa.criticality) AS max
           FROM public.portfolio_assignments pa
          WHERE (pa.application_id = a.id)) AS max_criticality
   FROM ((((((public.deployment_profile_technology_products dptp
     JOIN public.technology_products tp ON ((tp.id = dptp.technology_product_id)))
     JOIN public.deployment_profiles dp ON ((dp.id = dptp.deployment_profile_id)))
     JOIN public.applications a ON ((a.id = dp.application_id)))
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     LEFT JOIN public.technology_product_categories tpc ON ((tpc.id = tp.category_id)))
     LEFT JOIN public.technology_lifecycle_reference tlr ON ((tlr.id = tp.lifecycle_reference_id)));


--
-- Name: workspace_budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_budgets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid NOT NULL,
    fiscal_year integer NOT NULL,
    budget_amount numeric(12,2) NOT NULL,
    actual_run_rate numeric(12,2),
    budget_notes text,
    is_current boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE workspace_budgets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.workspace_budgets IS 'Year-over-year budget tracking per workspace';


--
-- Name: COLUMN workspace_budgets.actual_run_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.workspace_budgets.actual_run_rate IS 'Snapshot of run rate at fiscal year end';


--
-- Name: COLUMN workspace_budgets.is_current; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.workspace_budgets.is_current IS 'True for the active budget year';


--
-- Name: vw_workspace_budget_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_workspace_budget_history WITH (security_invoker='true') AS
 SELECT wb.id,
    wb.workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    wb.fiscal_year,
    wb.budget_amount,
    wb.actual_run_rate,
    wb.budget_notes,
    wb.is_current,
        CASE
            WHEN (wb.actual_run_rate IS NOT NULL) THEN (wb.budget_amount - wb.actual_run_rate)
            ELSE NULL::numeric
        END AS variance,
        CASE
            WHEN ((wb.actual_run_rate IS NOT NULL) AND (wb.budget_amount > (0)::numeric)) THEN round((((wb.budget_amount - wb.actual_run_rate) / wb.budget_amount) * (100)::numeric), 1)
            ELSE NULL::numeric
        END AS variance_percent,
    lag(wb.budget_amount) OVER (PARTITION BY wb.workspace_id ORDER BY wb.fiscal_year) AS prior_year_budget,
    lag(wb.actual_run_rate) OVER (PARTITION BY wb.workspace_id ORDER BY wb.fiscal_year) AS prior_year_actual,
    (wb.budget_amount - lag(wb.budget_amount) OVER (PARTITION BY wb.workspace_id ORDER BY wb.fiscal_year)) AS budget_yoy_change
   FROM (public.workspace_budgets wb
     JOIN public.workspaces w ON ((w.id = wb.workspace_id)))
  ORDER BY wb.workspace_id, wb.fiscal_year DESC;


--
-- Name: vw_workspace_budget_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_workspace_budget_summary WITH (security_invoker='true') AS
 SELECT w.id AS workspace_id,
    w.name AS workspace_name,
    w.namespace_id,
    wb.budget_amount AS workspace_budget,
    wb.fiscal_year AS budget_fiscal_year,
    COALESCE(sum(a.budget_amount), (0)::numeric) AS app_budget_allocated,
    COALESCE(sum(( SELECT vpc.total_cost
           FROM public.vw_deployment_profile_costs vpc
          WHERE ((vpc.application_id = a.id) AND (vpc.deployment_profile_id = ( SELECT deployment_profiles.id
                   FROM public.deployment_profiles
                  WHERE ((deployment_profiles.application_id = a.id) AND (deployment_profiles.is_primary = true))
                 LIMIT 1))))), (0)::numeric) AS app_run_rate,
    COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM public.it_services its
          WHERE (its.owner_workspace_id = w.id)), (0)::numeric) AS service_budget_allocated,
    COALESCE(( SELECT sum(( SELECT sum(
                        CASE
                            WHEN (dpis.allocation_basis = 'fixed'::text) THEN dpis.allocation_value
                            WHEN ((dpis.allocation_basis = 'percent'::text) AND (dpis.allocation_value > (100)::numeric)) THEN dpis.allocation_value
                            WHEN (dpis.allocation_basis = 'percent'::text) THEN ((its2.annual_cost * dpis.allocation_value) / (100)::numeric)
                            ELSE dpis.allocation_value
                        END) AS sum
                   FROM public.deployment_profile_it_services dpis
                  WHERE (dpis.it_service_id = its2.id))) AS sum
           FROM public.it_services its2
          WHERE (its2.owner_workspace_id = w.id)), (0)::numeric) AS service_run_rate,
    (COALESCE(sum(a.budget_amount), (0)::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM public.it_services its
          WHERE (its.owner_workspace_id = w.id)), (0)::numeric)) AS total_allocated,
    (COALESCE(wb.budget_amount, (0)::numeric) - (COALESCE(sum(a.budget_amount), (0)::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
           FROM public.it_services its
          WHERE (its.owner_workspace_id = w.id)), (0)::numeric))) AS unallocated,
        CASE
            WHEN (wb.budget_amount IS NULL) THEN 'no_budget'::text
            WHEN ((COALESCE(wb.budget_amount, (0)::numeric) - (COALESCE(sum(a.budget_amount), (0)::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
               FROM public.it_services its
              WHERE (its.owner_workspace_id = w.id)), (0)::numeric))) < (0)::numeric) THEN 'over_allocated'::text
            WHEN (((COALESCE(wb.budget_amount, (0)::numeric) - (COALESCE(sum(a.budget_amount), (0)::numeric) + COALESCE(( SELECT sum(its.budget_amount) AS sum
               FROM public.it_services its
              WHERE (its.owner_workspace_id = w.id)), (0)::numeric))) / NULLIF(wb.budget_amount, (0)::numeric)) < 0.10) THEN 'under_10'::text
            ELSE 'healthy'::text
        END AS workspace_status
   FROM ((public.workspaces w
     LEFT JOIN public.workspace_budgets wb ON (((wb.workspace_id = w.id) AND (wb.is_current = true))))
     LEFT JOIN public.applications a ON ((a.workspace_id = w.id)))
  GROUP BY w.id, w.name, w.namespace_id, wb.budget_amount, wb.fiscal_year;


--
-- Name: VIEW vw_workspace_budget_summary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.vw_workspace_budget_summary IS 'Workspace-level budget summary including both applications and IT services';


--
-- Name: workflow_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_definitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    workflow_type text NOT NULL,
    steps jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT workflow_definitions_workflow_type_check CHECK ((workflow_type = ANY (ARRAY['assessment_approval'::text, 'change_request'::text, 'decommission'::text, 'custom'::text])))
);


--
-- Name: workflow_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_instances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_definition_id uuid NOT NULL,
    entity_type text NOT NULL,
    entity_id uuid NOT NULL,
    current_step integer DEFAULT 0,
    status text DEFAULT 'pending'::text,
    started_by uuid,
    started_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    CONSTRAINT workflow_instances_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'approved'::text, 'rejected'::text, 'cancelled'::text])))
);


--
-- Name: workspace_group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_group_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_group_id uuid NOT NULL,
    workspace_id uuid NOT NULL,
    can_publish boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    can_subscribe boolean DEFAULT true,
    added_by uuid,
    joined_at timestamp with time zone DEFAULT now()
);


--
-- Name: workspace_group_publications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_group_publications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_group_id uuid NOT NULL,
    deployment_profile_id uuid NOT NULL,
    published_by uuid,
    published_at timestamp with time zone DEFAULT now()
);


--
-- Name: workspace_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    namespace_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: workspace_role_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_role_options (
    role text NOT NULL,
    display_name text NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true
);


--
-- Name: workspace_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspace_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workspace_id uuid,
    name text DEFAULT ''::text,
    max_project_budget integer DEFAULT 1000000,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: -
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: alert_preferences alert_preferences_namespace_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_namespace_unique UNIQUE (namespace_id);


--
-- Name: alert_preferences alert_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_pkey PRIMARY KEY (id);


--
-- Name: alert_preferences alert_preferences_workspace_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_workspace_unique UNIQUE (workspace_id);


--
-- Name: application_compliance application_compliance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_compliance
    ADD CONSTRAINT application_compliance_pkey PRIMARY KEY (id);


--
-- Name: application_contacts application_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_contacts
    ADD CONSTRAINT application_contacts_pkey PRIMARY KEY (id);


--
-- Name: application_contacts application_contacts_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_contacts
    ADD CONSTRAINT application_contacts_unique UNIQUE (application_id, contact_id, role_type);


--
-- Name: application_data_assets application_data_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_data_assets
    ADD CONSTRAINT application_data_assets_pkey PRIMARY KEY (id);


--
-- Name: application_documents application_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_documents
    ADD CONSTRAINT application_documents_pkey PRIMARY KEY (id);


--
-- Name: application_integrations application_integrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_integrations
    ADD CONSTRAINT application_integrations_pkey PRIMARY KEY (id);


--
-- Name: application_roadmap application_roadmap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_roadmap
    ADD CONSTRAINT application_roadmap_pkey PRIMARY KEY (id);


--
-- Name: application_services application_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_services
    ADD CONSTRAINT application_services_pkey PRIMARY KEY (id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: assessment_factor_options assessment_factor_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_factor_options
    ADD CONSTRAINT assessment_factor_options_pkey PRIMARY KEY (id);


--
-- Name: assessment_factors assessment_factors_namespace_id_factor_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_factors
    ADD CONSTRAINT assessment_factors_namespace_id_factor_code_key UNIQUE (namespace_id, factor_code);


--
-- Name: assessment_factors assessment_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_factors
    ADD CONSTRAINT assessment_factors_pkey PRIMARY KEY (id);


--
-- Name: assessment_history assessment_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_history
    ADD CONSTRAINT assessment_history_pkey PRIMARY KEY (id);


--
-- Name: assessment_thresholds assessment_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_thresholds
    ADD CONSTRAINT assessment_thresholds_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: budget_transfers budget_transfers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_pkey PRIMARY KEY (id);


--
-- Name: business_assessments business_assessments_application_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_assessments
    ADD CONSTRAINT business_assessments_application_id_key UNIQUE (application_id);


--
-- Name: business_assessments business_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_assessments
    ADD CONSTRAINT business_assessments_pkey PRIMARY KEY (id);


--
-- Name: cloud_providers cloud_providers_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cloud_providers
    ADD CONSTRAINT cloud_providers_code_key UNIQUE (code);


--
-- Name: cloud_providers cloud_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cloud_providers
    ADD CONSTRAINT cloud_providers_pkey PRIMARY KEY (id);


--
-- Name: contact_organizations contact_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_organizations
    ADD CONSTRAINT contact_organizations_pkey PRIMARY KEY (id);


--
-- Name: contact_organizations contact_organizations_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_organizations
    ADD CONSTRAINT contact_organizations_unique UNIQUE (contact_id, organization_id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: countries countries_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_code_key UNIQUE (code);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: criticality_types criticality_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criticality_types
    ADD CONSTRAINT criticality_types_code_key UNIQUE (code);


--
-- Name: criticality_types criticality_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.criticality_types
    ADD CONSTRAINT criticality_types_pkey PRIMARY KEY (id);


--
-- Name: custom_field_definitions custom_field_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_definitions
    ADD CONSTRAINT custom_field_definitions_pkey PRIMARY KEY (id);


--
-- Name: custom_field_values custom_field_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_pkey PRIMARY KEY (id);


--
-- Name: data_centers data_centers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_centers
    ADD CONSTRAINT data_centers_pkey PRIMARY KEY (id);


--
-- Name: data_centers data_centers_unique_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_centers
    ADD CONSTRAINT data_centers_unique_code UNIQUE (namespace_id, code);


--
-- Name: data_classification_types data_classification_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_classification_types
    ADD CONSTRAINT data_classification_types_code_key UNIQUE (code);


--
-- Name: data_classification_types data_classification_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_classification_types
    ADD CONSTRAINT data_classification_types_pkey PRIMARY KEY (id);


--
-- Name: data_format_types data_format_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_format_types
    ADD CONSTRAINT data_format_types_code_key UNIQUE (code);


--
-- Name: data_format_types data_format_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_format_types
    ADD CONSTRAINT data_format_types_pkey PRIMARY KEY (id);


--
-- Name: data_tag_types data_tag_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_tag_types
    ADD CONSTRAINT data_tag_types_code_key UNIQUE (code);


--
-- Name: data_tag_types data_tag_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_tag_types
    ADD CONSTRAINT data_tag_types_pkey PRIMARY KEY (id);


--
-- Name: deployment_profile_contacts deployment_profile_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_contacts
    ADD CONSTRAINT deployment_profile_contacts_pkey PRIMARY KEY (id);


--
-- Name: deployment_profile_it_services deployment_profile_it_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_it_services
    ADD CONSTRAINT deployment_profile_it_services_pkey PRIMARY KEY (id);


--
-- Name: deployment_profile_it_services deployment_profile_it_services_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_it_services
    ADD CONSTRAINT deployment_profile_it_services_unique UNIQUE (deployment_profile_id, it_service_id);


--
-- Name: deployment_profile_software_products deployment_profile_software_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_software_products
    ADD CONSTRAINT deployment_profile_software_products_pkey PRIMARY KEY (id);


--
-- Name: deployment_profile_technology_products deployment_profile_technology_deployment_profile_id_technol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_technology_products
    ADD CONSTRAINT deployment_profile_technology_deployment_profile_id_technol_key UNIQUE (deployment_profile_id, technology_product_id);


--
-- Name: deployment_profile_technology_products deployment_profile_technology_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_technology_products
    ADD CONSTRAINT deployment_profile_technology_products_pkey PRIMARY KEY (id);


--
-- Name: deployment_profiles deployment_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_pkey PRIMARY KEY (id);


--
-- Name: deployment_profile_contacts dp_contacts_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_contacts
    ADD CONSTRAINT dp_contacts_unique UNIQUE (deployment_profile_id, contact_id, role_type);


--
-- Name: deployment_profile_software_products dpsp_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_software_products
    ADD CONSTRAINT dpsp_unique UNIQUE (deployment_profile_id, software_product_id);


--
-- Name: dr_statuses dr_statuses_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dr_statuses
    ADD CONSTRAINT dr_statuses_code_key UNIQUE (code);


--
-- Name: dr_statuses dr_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dr_statuses
    ADD CONSTRAINT dr_statuses_pkey PRIMARY KEY (id);


--
-- Name: environments environments_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_code_key UNIQUE (code);


--
-- Name: environments environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);


--
-- Name: findings findings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_pkey PRIMARY KEY (id);


--
-- Name: hosting_types hosting_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hosting_types
    ADD CONSTRAINT hosting_types_code_key UNIQUE (code);


--
-- Name: hosting_types hosting_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hosting_types
    ADD CONSTRAINT hosting_types_pkey PRIMARY KEY (id);


--
-- Name: ideas ideas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_pkey PRIMARY KEY (id);


--
-- Name: individuals individuals_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individuals
    ADD CONSTRAINT individuals_email_unique UNIQUE (primary_email);


--
-- Name: individuals individuals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.individuals
    ADD CONSTRAINT individuals_pkey PRIMARY KEY (id);


--
-- Name: initiative_dependencies initiative_dependencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_dependencies
    ADD CONSTRAINT initiative_dependencies_pkey PRIMARY KEY (id);


--
-- Name: initiative_deployment_profiles initiative_deployment_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_deployment_profiles
    ADD CONSTRAINT initiative_deployment_profiles_pkey PRIMARY KEY (id);


--
-- Name: initiative_dependencies initiative_deps_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_dependencies
    ADD CONSTRAINT initiative_deps_unique UNIQUE (source_initiative_id, target_initiative_id);


--
-- Name: initiative_deployment_profiles initiative_dps_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_deployment_profiles
    ADD CONSTRAINT initiative_dps_unique UNIQUE (initiative_id, deployment_profile_id);


--
-- Name: initiative_it_services initiative_it_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_it_services
    ADD CONSTRAINT initiative_it_services_pkey PRIMARY KEY (id);


--
-- Name: initiative_it_services initiative_services_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_it_services
    ADD CONSTRAINT initiative_services_unique UNIQUE (initiative_id, it_service_id);


--
-- Name: initiatives initiatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_pkey PRIMARY KEY (id);


--
-- Name: integration_contacts integration_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_contacts
    ADD CONSTRAINT integration_contacts_pkey PRIMARY KEY (id);


--
-- Name: integration_contacts integration_contacts_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_contacts
    ADD CONSTRAINT integration_contacts_unique UNIQUE (integration_id, contact_id, role_type);


--
-- Name: integration_direction_types integration_direction_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_direction_types
    ADD CONSTRAINT integration_direction_types_code_key UNIQUE (code);


--
-- Name: integration_direction_types integration_direction_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_direction_types
    ADD CONSTRAINT integration_direction_types_pkey PRIMARY KEY (id);


--
-- Name: integration_frequency_types integration_frequency_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_frequency_types
    ADD CONSTRAINT integration_frequency_types_code_key UNIQUE (code);


--
-- Name: integration_frequency_types integration_frequency_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_frequency_types
    ADD CONSTRAINT integration_frequency_types_pkey PRIMARY KEY (id);


--
-- Name: integration_method_types integration_method_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_method_types
    ADD CONSTRAINT integration_method_types_code_key UNIQUE (code);


--
-- Name: integration_method_types integration_method_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_method_types
    ADD CONSTRAINT integration_method_types_pkey PRIMARY KEY (id);


--
-- Name: integration_status_types integration_status_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_status_types
    ADD CONSTRAINT integration_status_types_code_key UNIQUE (code);


--
-- Name: integration_status_types integration_status_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_status_types
    ADD CONSTRAINT integration_status_types_pkey PRIMARY KEY (id);


--
-- Name: invitation_workspaces invitation_workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation_workspaces
    ADD CONSTRAINT invitation_workspaces_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: it_service_providers it_service_providers_it_service_id_deployment_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_service_providers
    ADD CONSTRAINT it_service_providers_it_service_id_deployment_profile_id_key UNIQUE (it_service_id, deployment_profile_id);


--
-- Name: it_service_providers it_service_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_service_providers
    ADD CONSTRAINT it_service_providers_pkey PRIMARY KEY (id);


--
-- Name: it_services it_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_services
    ADD CONSTRAINT it_services_pkey PRIMARY KEY (id);


--
-- Name: lifecycle_statuses lifecycle_statuses_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifecycle_statuses
    ADD CONSTRAINT lifecycle_statuses_code_key UNIQUE (code);


--
-- Name: lifecycle_statuses lifecycle_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lifecycle_statuses
    ADD CONSTRAINT lifecycle_statuses_pkey PRIMARY KEY (id);


--
-- Name: namespace_role_options namespace_role_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_role_options
    ADD CONSTRAINT namespace_role_options_pkey PRIMARY KEY (role);


--
-- Name: namespace_users namespace_users_namespace_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_users
    ADD CONSTRAINT namespace_users_namespace_id_user_id_key UNIQUE (namespace_id, user_id);


--
-- Name: namespace_users namespace_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_users
    ADD CONSTRAINT namespace_users_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: namespaces namespaces_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_slug_key UNIQUE (slug);


--
-- Name: notification_rules notification_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_rules
    ADD CONSTRAINT notification_rules_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: operational_statuses operational_statuses_code_scope_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operational_statuses
    ADD CONSTRAINT operational_statuses_code_scope_key UNIQUE (code, scope);


--
-- Name: operational_statuses operational_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.operational_statuses
    ADD CONSTRAINT operational_statuses_pkey PRIMARY KEY (id);


--
-- Name: organization_settings organization_settings_namespace_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_namespace_id_key UNIQUE (namespace_id);


--
-- Name: organization_settings organization_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_namespace_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_namespace_id_name_key UNIQUE (namespace_id, name);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: platform_admins platform_admins_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_admins
    ADD CONSTRAINT platform_admins_email_key UNIQUE (email);


--
-- Name: platform_admins platform_admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_admins
    ADD CONSTRAINT platform_admins_pkey PRIMARY KEY (id);


--
-- Name: portfolio_assignments portfolio_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_assignments
    ADD CONSTRAINT portfolio_assignments_pkey PRIMARY KEY (id);


--
-- Name: portfolio_assignments portfolio_assignments_portfolio_id_deployment_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_assignments
    ADD CONSTRAINT portfolio_assignments_portfolio_id_deployment_profile_id_key UNIQUE (portfolio_id, deployment_profile_id);


--
-- Name: portfolio_settings portfolio_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_settings
    ADD CONSTRAINT portfolio_settings_pkey PRIMARY KEY (id);


--
-- Name: portfolio_settings portfolio_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_settings
    ADD CONSTRAINT portfolio_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: portfolios portfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (id);


--
-- Name: portfolios portfolios_workspace_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_workspace_id_name_key UNIQUE (workspace_id, name);


--
-- Name: program_initiatives program_initiatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_initiatives
    ADD CONSTRAINT program_initiatives_pkey PRIMARY KEY (id);


--
-- Name: program_initiatives program_initiatives_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_initiatives
    ADD CONSTRAINT program_initiatives_unique UNIQUE (program_id, initiative_id);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (id);


--
-- Name: remediation_efforts remediation_efforts_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remediation_efforts
    ADD CONSTRAINT remediation_efforts_code_key UNIQUE (code);


--
-- Name: remediation_efforts remediation_efforts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.remediation_efforts
    ADD CONSTRAINT remediation_efforts_pkey PRIMARY KEY (id);


--
-- Name: sensitivity_types sensitivity_types_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensitivity_types
    ADD CONSTRAINT sensitivity_types_code_key UNIQUE (code);


--
-- Name: sensitivity_types sensitivity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sensitivity_types
    ADD CONSTRAINT sensitivity_types_pkey PRIMARY KEY (id);


--
-- Name: service_type_categories service_type_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_type_categories
    ADD CONSTRAINT service_type_categories_pkey PRIMARY KEY (id);


--
-- Name: service_type_categories service_type_categories_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_type_categories
    ADD CONSTRAINT service_type_categories_unique UNIQUE (namespace_id, code);


--
-- Name: service_types service_types_namespace_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_types
    ADD CONSTRAINT service_types_namespace_id_code_key UNIQUE (namespace_id, code);


--
-- Name: service_types service_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_types
    ADD CONSTRAINT service_types_pkey PRIMARY KEY (id);


--
-- Name: software_product_categories software_product_categories_namespace_id_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_product_categories
    ADD CONSTRAINT software_product_categories_namespace_id_code_key UNIQUE (namespace_id, code);


--
-- Name: software_product_categories software_product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_product_categories
    ADD CONSTRAINT software_product_categories_pkey PRIMARY KEY (id);


--
-- Name: software_products software_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_products
    ADD CONSTRAINT software_products_pkey PRIMARY KEY (id);


--
-- Name: standard_regions standard_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.standard_regions
    ADD CONSTRAINT standard_regions_pkey PRIMARY KEY (code);


--
-- Name: technical_assessments technical_assessments_application_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_assessments
    ADD CONSTRAINT technical_assessments_application_id_key UNIQUE (application_id);


--
-- Name: technical_assessments technical_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_assessments
    ADD CONSTRAINT technical_assessments_pkey PRIMARY KEY (id);


--
-- Name: technology_lifecycle_reference technology_lifecycle_reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_lifecycle_reference
    ADD CONSTRAINT technology_lifecycle_reference_pkey PRIMARY KEY (id);


--
-- Name: technology_product_categories technology_product_categories_namespace_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_product_categories
    ADD CONSTRAINT technology_product_categories_namespace_id_name_key UNIQUE (namespace_id, name);


--
-- Name: technology_product_categories technology_product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_product_categories
    ADD CONSTRAINT technology_product_categories_pkey PRIMARY KEY (id);


--
-- Name: technology_products technology_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_products
    ADD CONSTRAINT technology_products_pkey PRIMARY KEY (id);


--
-- Name: technology_lifecycle_reference tlr_unique_product; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_lifecycle_reference
    ADD CONSTRAINT tlr_unique_product UNIQUE (vendor_name, product_name, version, edition);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vendor_lifecycle_sources vendor_lifecycle_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_lifecycle_sources
    ADD CONSTRAINT vendor_lifecycle_sources_pkey PRIMARY KEY (id);


--
-- Name: vendor_lifecycle_sources vendor_lifecycle_sources_vendor_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendor_lifecycle_sources
    ADD CONSTRAINT vendor_lifecycle_sources_vendor_name_key UNIQUE (vendor_name);


--
-- Name: workflow_definitions workflow_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_definitions
    ADD CONSTRAINT workflow_definitions_pkey PRIMARY KEY (id);


--
-- Name: workflow_instances workflow_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_instances
    ADD CONSTRAINT workflow_instances_pkey PRIMARY KEY (id);


--
-- Name: workspace_budgets workspace_budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_budgets
    ADD CONSTRAINT workspace_budgets_pkey PRIMARY KEY (id);


--
-- Name: workspace_budgets workspace_budgets_workspace_id_fiscal_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_budgets
    ADD CONSTRAINT workspace_budgets_workspace_id_fiscal_year_key UNIQUE (workspace_id, fiscal_year);


--
-- Name: workspace_group_members workspace_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_members
    ADD CONSTRAINT workspace_group_members_pkey PRIMARY KEY (id);


--
-- Name: workspace_group_publications workspace_group_publications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_publications
    ADD CONSTRAINT workspace_group_publications_pkey PRIMARY KEY (id);


--
-- Name: workspace_group_publications workspace_group_publications_workspace_group_id_deployment__key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_publications
    ADD CONSTRAINT workspace_group_publications_workspace_group_id_deployment__key UNIQUE (workspace_group_id, deployment_profile_id);


--
-- Name: workspace_groups workspace_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_groups
    ADD CONSTRAINT workspace_groups_pkey PRIMARY KEY (id);


--
-- Name: workspace_role_options workspace_role_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_role_options
    ADD CONSTRAINT workspace_role_options_pkey PRIMARY KEY (role);


--
-- Name: workspace_settings workspace_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_settings
    ADD CONSTRAINT workspace_settings_pkey PRIMARY KEY (id);


--
-- Name: workspace_settings workspace_settings_workspace_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_settings
    ADD CONSTRAINT workspace_settings_workspace_id_key UNIQUE (workspace_id);


--
-- Name: workspace_users workspace_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users
    ADD CONSTRAINT workspace_users_pkey PRIMARY KEY (id);


--
-- Name: workspace_users workspace_users_workspace_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users
    ADD CONSTRAINT workspace_users_workspace_id_user_id_key UNIQUE (workspace_id, user_id);


--
-- Name: workspaces workspaces_namespace_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_namespace_id_slug_key UNIQUE (namespace_id, slug);


--
-- Name: workspaces workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: idx_alert_preferences_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_preferences_namespace ON public.alert_preferences USING btree (namespace_id) WHERE (namespace_id IS NOT NULL);


--
-- Name: idx_alert_preferences_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_preferences_workspace ON public.alert_preferences USING btree (workspace_id) WHERE (workspace_id IS NOT NULL);


--
-- Name: idx_app_contacts_app; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_contacts_app ON public.application_contacts USING btree (application_id);


--
-- Name: idx_app_contacts_contact; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_contacts_contact ON public.application_contacts USING btree (contact_id);


--
-- Name: idx_app_contacts_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_contacts_role ON public.application_contacts USING btree (role_type);


--
-- Name: idx_application_compliance_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_compliance_application ON public.application_compliance USING btree (application_id);


--
-- Name: idx_application_data_assets_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_data_assets_application ON public.application_data_assets USING btree (application_id);


--
-- Name: idx_application_documents_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_documents_application ON public.application_documents USING btree (application_id);


--
-- Name: idx_application_integrations_external_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_integrations_external_org ON public.application_integrations USING btree (external_organization_id);


--
-- Name: idx_application_integrations_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_integrations_source ON public.application_integrations USING btree (source_application_id);


--
-- Name: idx_application_integrations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_integrations_status ON public.application_integrations USING btree (status);


--
-- Name: idx_application_integrations_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_integrations_target ON public.application_integrations USING btree (target_application_id);


--
-- Name: idx_application_roadmap_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_roadmap_application ON public.application_roadmap USING btree (application_id);


--
-- Name: idx_application_services_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_application_services_application ON public.application_services USING btree (application_id);


--
-- Name: idx_applications_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_applications_name ON public.applications USING btree (name);


--
-- Name: idx_applications_owner_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_applications_owner_workspace ON public.applications USING btree (owner_workspace_id);


--
-- Name: idx_applications_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_applications_workspace ON public.applications USING btree (workspace_id);


--
-- Name: idx_assessment_factor_options_factor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assessment_factor_options_factor ON public.assessment_factor_options USING btree (factor_id);


--
-- Name: idx_assessment_factors_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assessment_factors_namespace ON public.assessment_factors USING btree (namespace_id);


--
-- Name: idx_assessment_factors_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assessment_factors_type ON public.assessment_factors USING btree (factor_type);


--
-- Name: idx_assessment_history_assignment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assessment_history_assignment ON public.assessment_history USING btree (portfolio_assignment_id);


--
-- Name: idx_assessment_thresholds_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assessment_thresholds_namespace ON public.assessment_thresholds USING btree (namespace_id);


--
-- Name: idx_audit_logs_category_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_category_created ON public.audit_logs USING btree (event_category, created_at DESC);


--
-- Name: idx_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id, created_at DESC);


--
-- Name: idx_audit_logs_namespace_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_namespace_created ON public.audit_logs USING btree (namespace_id, created_at DESC);


--
-- Name: idx_audit_logs_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_created ON public.audit_logs USING btree (user_id, created_at DESC);


--
-- Name: idx_budget_transfers_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_date ON public.budget_transfers USING btree (transferred_at);


--
-- Name: idx_budget_transfers_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_from ON public.budget_transfers USING btree (from_application_id);


--
-- Name: idx_budget_transfers_from_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_from_service ON public.budget_transfers USING btree (from_it_service_id);


--
-- Name: idx_budget_transfers_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_to ON public.budget_transfers USING btree (to_application_id);


--
-- Name: idx_budget_transfers_to_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_to_service ON public.budget_transfers USING btree (to_it_service_id);


--
-- Name: idx_budget_transfers_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budget_transfers_workspace ON public.budget_transfers USING btree (workspace_id, fiscal_year);


--
-- Name: idx_contact_orgs_contact; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_orgs_contact ON public.contact_organizations USING btree (contact_id);


--
-- Name: idx_contact_orgs_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contact_orgs_org ON public.contact_organizations USING btree (organization_id);


--
-- Name: idx_contacts_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_email ON public.contacts USING btree (email);


--
-- Name: idx_contacts_individual; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_individual ON public.contacts USING btree (individual_id);


--
-- Name: idx_contacts_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_workspace ON public.contacts USING btree (primary_workspace_id);


--
-- Name: idx_custom_field_definitions_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_field_definitions_namespace ON public.custom_field_definitions USING btree (namespace_id);


--
-- Name: idx_custom_field_values_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_field_values_entity ON public.custom_field_values USING btree (entity_type, entity_id);


--
-- Name: idx_custom_field_values_field; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_field_values_field ON public.custom_field_values USING btree (field_definition_id);


--
-- Name: idx_data_centers_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_centers_active ON public.data_centers USING btree (namespace_id, is_active) WHERE (is_active = true);


--
-- Name: idx_data_centers_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_centers_namespace ON public.data_centers USING btree (namespace_id);


--
-- Name: idx_deployment_profiles_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deployment_profiles_application ON public.deployment_profiles USING btree (application_id);


--
-- Name: idx_deployment_profiles_data_center; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deployment_profiles_data_center ON public.deployment_profiles USING btree (data_center_id);


--
-- Name: idx_deployment_profiles_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deployment_profiles_primary ON public.deployment_profiles USING btree (application_id, is_primary) WHERE (is_primary = true);


--
-- Name: idx_deployment_profiles_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deployment_profiles_workspace ON public.deployment_profiles USING btree (workspace_id);


--
-- Name: idx_dp_contacts_contact; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dp_contacts_contact ON public.deployment_profile_contacts USING btree (contact_id);


--
-- Name: idx_dp_contacts_dp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dp_contacts_dp ON public.deployment_profile_contacts USING btree (deployment_profile_id);


--
-- Name: idx_dp_server_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dp_server_name ON public.deployment_profiles USING btree (server_name) WHERE (server_name IS NOT NULL);


--
-- Name: idx_dp_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dp_vendor ON public.deployment_profiles USING btree (vendor_org_id);


--
-- Name: idx_dpis_deployment_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpis_deployment_profile ON public.deployment_profile_it_services USING btree (deployment_profile_id);


--
-- Name: idx_dpis_it_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpis_it_service ON public.deployment_profile_it_services USING btree (it_service_id);


--
-- Name: idx_dpsp_contract_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpsp_contract_end ON public.deployment_profile_software_products USING btree (contract_end_date);


--
-- Name: idx_dpsp_deployment_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpsp_deployment_profile ON public.deployment_profile_software_products USING btree (deployment_profile_id);


--
-- Name: idx_dpsp_software_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpsp_software_product ON public.deployment_profile_software_products USING btree (software_product_id);


--
-- Name: idx_dpsp_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dpsp_vendor ON public.deployment_profile_software_products USING btree (vendor_org_id);


--
-- Name: idx_dptp_deployment_profile; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dptp_deployment_profile ON public.deployment_profile_technology_products USING btree (deployment_profile_id);


--
-- Name: idx_dptp_technology_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dptp_technology_product ON public.deployment_profile_technology_products USING btree (technology_product_id);


--
-- Name: idx_findings_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_findings_domain ON public.findings USING btree (assessment_domain);


--
-- Name: idx_findings_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_findings_namespace ON public.findings USING btree (namespace_id);


--
-- Name: idx_findings_source_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_findings_source_ref ON public.findings USING btree (source_reference_id) WHERE (source_reference_id IS NOT NULL);


--
-- Name: idx_findings_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_findings_source_type ON public.findings USING btree (source_type);


--
-- Name: idx_findings_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_findings_workspace ON public.findings USING btree (workspace_id);


--
-- Name: idx_ideas_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ideas_namespace ON public.ideas USING btree (namespace_id);


--
-- Name: idx_ideas_promoted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ideas_promoted ON public.ideas USING btree (promoted_to_initiative_id) WHERE (promoted_to_initiative_id IS NOT NULL);


--
-- Name: idx_ideas_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ideas_status ON public.ideas USING btree (status);


--
-- Name: idx_ideas_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ideas_workspace ON public.ideas USING btree (workspace_id);


--
-- Name: idx_individuals_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_individuals_email ON public.individuals USING btree (primary_email);


--
-- Name: idx_individuals_external_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_individuals_external_key ON public.individuals USING btree (external_identity_key);


--
-- Name: idx_initiative_deps_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_deps_source ON public.initiative_dependencies USING btree (source_initiative_id);


--
-- Name: idx_initiative_deps_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_deps_target ON public.initiative_dependencies USING btree (target_initiative_id);


--
-- Name: idx_initiative_deps_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_deps_type ON public.initiative_dependencies USING btree (dependency_type);


--
-- Name: idx_initiative_dps_dp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_dps_dp ON public.initiative_deployment_profiles USING btree (deployment_profile_id);


--
-- Name: idx_initiative_dps_initiative; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_dps_initiative ON public.initiative_deployment_profiles USING btree (initiative_id);


--
-- Name: idx_initiative_services_initiative; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_services_initiative ON public.initiative_it_services USING btree (initiative_id);


--
-- Name: idx_initiative_services_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiative_services_service ON public.initiative_it_services USING btree (it_service_id);


--
-- Name: idx_initiatives_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_domain ON public.initiatives USING btree (assessment_domain);


--
-- Name: idx_initiatives_finding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_finding ON public.initiatives USING btree (source_finding_id) WHERE (source_finding_id IS NOT NULL);


--
-- Name: idx_initiatives_idea; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_idea ON public.initiatives USING btree (source_idea_id) WHERE (source_idea_id IS NOT NULL);


--
-- Name: idx_initiatives_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_namespace ON public.initiatives USING btree (namespace_id);


--
-- Name: idx_initiatives_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_owner ON public.initiatives USING btree (owner_contact_id);


--
-- Name: idx_initiatives_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_status ON public.initiatives USING btree (status);


--
-- Name: idx_initiatives_theme; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_theme ON public.initiatives USING btree (strategic_theme);


--
-- Name: idx_initiatives_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initiatives_workspace ON public.initiatives USING btree (workspace_id);


--
-- Name: idx_integration_contacts_contact; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integration_contacts_contact ON public.integration_contacts USING btree (contact_id);


--
-- Name: idx_integration_contacts_integration; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_integration_contacts_integration ON public.integration_contacts USING btree (integration_id);


--
-- Name: idx_invitation_workspaces_invitation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitation_workspaces_invitation ON public.invitation_workspaces USING btree (invitation_id);


--
-- Name: idx_invitations_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitations_email ON public.invitations USING btree (email);


--
-- Name: idx_invitations_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitations_namespace ON public.invitations USING btree (namespace_id);


--
-- Name: idx_invitations_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitations_token ON public.invitations USING btree (token);


--
-- Name: idx_it_services_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_it_services_namespace ON public.it_services USING btree (namespace_id);


--
-- Name: idx_it_services_service_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_it_services_service_type ON public.it_services USING btree (service_type_id);


--
-- Name: idx_it_services_vendor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_it_services_vendor ON public.it_services USING btree (vendor_org_id);


--
-- Name: idx_it_services_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_it_services_workspace ON public.it_services USING btree (owner_workspace_id);


--
-- Name: idx_namespace_users_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_namespace_users_namespace ON public.namespace_users USING btree (namespace_id);


--
-- Name: idx_namespace_users_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_namespace_users_user ON public.namespace_users USING btree (user_id);


--
-- Name: idx_namespaces_region; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_namespaces_region ON public.namespaces USING btree (region);


--
-- Name: idx_notification_rules_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_rules_namespace ON public.notification_rules USING btree (namespace_id);


--
-- Name: idx_notifications_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_unread ON public.notifications USING btree (user_id, is_read) WHERE (is_read = false);


--
-- Name: idx_notifications_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);


--
-- Name: idx_organizations_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_namespace ON public.organizations USING btree (namespace_id);


--
-- Name: idx_organizations_owner_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_owner_workspace ON public.organizations USING btree (owner_workspace_id);


--
-- Name: idx_organizations_shared; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_shared ON public.organizations USING btree (is_shared) WHERE (is_shared = true);


--
-- Name: idx_portfolio_assignments_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolio_assignments_application ON public.portfolio_assignments USING btree (application_id);


--
-- Name: idx_portfolio_assignments_dp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolio_assignments_dp ON public.portfolio_assignments USING btree (deployment_profile_id);


--
-- Name: idx_portfolio_assignments_portfolio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolio_assignments_portfolio ON public.portfolio_assignments USING btree (portfolio_id);


--
-- Name: idx_portfolio_assignments_time_quadrant; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolio_assignments_time_quadrant ON public.portfolio_assignments USING btree (time_quadrant) WHERE (time_quadrant IS NOT NULL);


--
-- Name: idx_portfolios_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolios_parent ON public.portfolios USING btree (parent_portfolio_id);


--
-- Name: idx_portfolios_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_portfolios_workspace ON public.portfolios USING btree (workspace_id);


--
-- Name: idx_program_initiatives_initiative; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_program_initiatives_initiative ON public.program_initiatives USING btree (initiative_id);


--
-- Name: idx_program_initiatives_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_program_initiatives_program ON public.program_initiatives USING btree (program_id);


--
-- Name: idx_programs_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_namespace ON public.programs USING btree (namespace_id);


--
-- Name: idx_programs_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_owner ON public.programs USING btree (owner_contact_id);


--
-- Name: idx_programs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_status ON public.programs USING btree (status);


--
-- Name: idx_programs_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_programs_workspace ON public.programs USING btree (workspace_id);


--
-- Name: idx_service_type_categories_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_type_categories_namespace ON public.service_type_categories USING btree (namespace_id);


--
-- Name: idx_service_types_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_types_category ON public.service_types USING btree (category_id);


--
-- Name: idx_service_types_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_service_types_namespace ON public.service_types USING btree (namespace_id);


--
-- Name: idx_software_products_manufacturer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_software_products_manufacturer ON public.software_products USING btree (manufacturer_org_id);


--
-- Name: idx_software_products_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_software_products_namespace ON public.software_products USING btree (namespace_id);


--
-- Name: idx_technology_products_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_technology_products_category ON public.technology_products USING btree (category_id);


--
-- Name: idx_technology_products_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_technology_products_namespace ON public.technology_products USING btree (namespace_id);


--
-- Name: idx_tlr_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tlr_status ON public.technology_lifecycle_reference USING btree (current_status);


--
-- Name: idx_tp_lifecycle_ref; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tp_lifecycle_ref ON public.technology_products USING btree (lifecycle_reference_id) WHERE (lifecycle_reference_id IS NOT NULL);


--
-- Name: idx_user_sessions_namespace_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_namespace_id ON public.user_sessions USING btree (current_namespace_id);


--
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_individual; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_individual ON public.users USING btree (individual_id);


--
-- Name: idx_users_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_namespace ON public.users USING btree (namespace_id);


--
-- Name: idx_workflow_definitions_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workflow_definitions_namespace ON public.workflow_definitions USING btree (namespace_id);


--
-- Name: idx_workflow_instances_definition; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workflow_instances_definition ON public.workflow_instances USING btree (workflow_definition_id);


--
-- Name: idx_workspace_budgets_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_budgets_current ON public.workspace_budgets USING btree (workspace_id) WHERE (is_current = true);


--
-- Name: idx_workspace_budgets_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_budgets_workspace ON public.workspace_budgets USING btree (workspace_id);


--
-- Name: idx_workspace_group_members_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_group_members_group ON public.workspace_group_members USING btree (workspace_group_id);


--
-- Name: idx_workspace_group_members_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_group_members_workspace ON public.workspace_group_members USING btree (workspace_id);


--
-- Name: idx_workspace_group_publications_dp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_group_publications_dp ON public.workspace_group_publications USING btree (deployment_profile_id);


--
-- Name: idx_workspace_group_publications_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_group_publications_group ON public.workspace_group_publications USING btree (workspace_group_id);


--
-- Name: idx_workspace_groups_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_groups_namespace ON public.workspace_groups USING btree (namespace_id);


--
-- Name: idx_workspace_users_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_users_user ON public.workspace_users USING btree (user_id);


--
-- Name: idx_workspace_users_workspace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspace_users_workspace ON public.workspace_users USING btree (workspace_id);


--
-- Name: idx_workspaces_namespace; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_workspaces_namespace ON public.workspaces USING btree (namespace_id);


--
-- Name: portfolio_assignments_single_publisher; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX portfolio_assignments_single_publisher ON public.portfolio_assignments USING btree (deployment_profile_id) WHERE (relationship_type = 'publisher'::text);


--
-- Name: portfolios_workspace_id_default_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX portfolios_workspace_id_default_unique ON public.portfolios USING btree (workspace_id) WHERE (is_default = true);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_key ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


--
-- Name: workspaces add_workspace_creator_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER add_workspace_creator_trigger AFTER INSERT ON public.workspaces FOR EACH ROW EXECUTE FUNCTION public.add_creator_to_workspace_users();


--
-- Name: application_integrations audit_application_integrations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_application_integrations AFTER INSERT OR DELETE OR UPDATE ON public.application_integrations FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: applications audit_applications; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_applications AFTER INSERT OR DELETE OR UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: contacts audit_contacts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_contacts AFTER INSERT OR DELETE OR UPDATE ON public.contacts FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: criticality_types audit_criticality_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_criticality_types AFTER INSERT OR DELETE OR UPDATE ON public.criticality_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: data_classification_types audit_data_classification_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_data_classification_types AFTER INSERT OR DELETE OR UPDATE ON public.data_classification_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: data_format_types audit_data_format_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_data_format_types AFTER INSERT OR DELETE OR UPDATE ON public.data_format_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: data_tag_types audit_data_tag_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_data_tag_types AFTER INSERT OR DELETE OR UPDATE ON public.data_tag_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: deployment_profile_technology_products audit_deployment_profile_technology_products; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_deployment_profile_technology_products AFTER INSERT OR DELETE OR UPDATE ON public.deployment_profile_technology_products FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: deployment_profiles audit_deployment_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_deployment_profiles AFTER INSERT OR DELETE OR UPDATE ON public.deployment_profiles FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: findings audit_findings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_findings AFTER INSERT OR DELETE OR UPDATE ON public.findings FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: ideas audit_ideas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_ideas AFTER INSERT OR DELETE OR UPDATE ON public.ideas FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: initiative_dependencies audit_initiative_dependencies; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_initiative_dependencies AFTER INSERT OR DELETE OR UPDATE ON public.initiative_dependencies FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: initiative_deployment_profiles audit_initiative_deployment_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_initiative_deployment_profiles AFTER INSERT OR DELETE OR UPDATE ON public.initiative_deployment_profiles FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: initiative_it_services audit_initiative_it_services; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_initiative_it_services AFTER INSERT OR DELETE OR UPDATE ON public.initiative_it_services FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: initiatives audit_initiatives; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_initiatives AFTER INSERT OR DELETE OR UPDATE ON public.initiatives FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: integration_contacts audit_integration_contacts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_integration_contacts AFTER INSERT OR DELETE OR UPDATE ON public.integration_contacts FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: integration_direction_types audit_integration_direction_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_integration_direction_types AFTER INSERT OR DELETE OR UPDATE ON public.integration_direction_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: integration_frequency_types audit_integration_frequency_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_integration_frequency_types AFTER INSERT OR DELETE OR UPDATE ON public.integration_frequency_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: integration_method_types audit_integration_method_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_integration_method_types AFTER INSERT OR DELETE OR UPDATE ON public.integration_method_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: integration_status_types audit_integration_status_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_integration_status_types AFTER INSERT OR DELETE OR UPDATE ON public.integration_status_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: invitations audit_invitations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_invitations AFTER INSERT OR DELETE OR UPDATE ON public.invitations FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: it_services audit_it_services; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_it_services AFTER INSERT OR DELETE OR UPDATE ON public.it_services FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: namespace_users audit_namespace_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_namespace_users AFTER INSERT OR DELETE OR UPDATE ON public.namespace_users FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: operational_statuses audit_operational_statuses; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_operational_statuses AFTER INSERT OR DELETE OR UPDATE ON public.operational_statuses FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: organizations audit_organizations; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_organizations AFTER INSERT OR DELETE OR UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: platform_admins audit_platform_admins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_platform_admins AFTER INSERT OR DELETE OR UPDATE ON public.platform_admins FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: portfolio_assignments audit_portfolio_assignments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_portfolio_assignments AFTER INSERT OR DELETE OR UPDATE ON public.portfolio_assignments FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: portfolios audit_portfolios; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_portfolios AFTER INSERT OR DELETE OR UPDATE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: program_initiatives audit_program_initiatives; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_program_initiatives AFTER INSERT OR DELETE OR UPDATE ON public.program_initiatives FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: programs audit_programs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_programs AFTER INSERT OR DELETE OR UPDATE ON public.programs FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: sensitivity_types audit_sensitivity_types; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_sensitivity_types AFTER INSERT OR DELETE OR UPDATE ON public.sensitivity_types FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: technology_lifecycle_reference audit_technology_lifecycle_reference; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_technology_lifecycle_reference AFTER INSERT OR DELETE OR UPDATE ON public.technology_lifecycle_reference FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: technology_products audit_technology_products; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_technology_products AFTER INSERT OR DELETE OR UPDATE ON public.technology_products FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: user_sessions audit_user_sessions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_user_sessions AFTER INSERT OR UPDATE ON public.user_sessions FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: users audit_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: vendor_lifecycle_sources audit_vendor_lifecycle_sources; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_vendor_lifecycle_sources AFTER INSERT OR DELETE OR UPDATE ON public.vendor_lifecycle_sources FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: workspace_users audit_workspace_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_workspace_users AFTER INSERT OR DELETE OR UPDATE ON public.workspace_users FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: portfolios check_no_children_before_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_no_children_before_delete BEFORE DELETE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.prevent_parent_portfolio_deletion();


--
-- Name: portfolios check_no_default_on_parent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_no_default_on_parent BEFORE UPDATE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.prevent_default_on_parent_portfolio();


--
-- Name: portfolios check_no_nesting_under_default; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_no_nesting_under_default BEFORE INSERT OR UPDATE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.prevent_children_on_default_portfolio();


--
-- Name: portfolios check_parent_has_no_assignments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_parent_has_no_assignments BEFORE INSERT OR UPDATE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.prevent_children_on_assigned_portfolio();


--
-- Name: portfolio_assignments check_portfolio_is_leaf_before_assignment; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_portfolio_is_leaf_before_assignment BEFORE INSERT OR UPDATE ON public.portfolio_assignments FOR EACH ROW EXECUTE FUNCTION public.prevent_assignment_to_parent_portfolio();


--
-- Name: portfolio_assignments check_portfolio_namespace_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER check_portfolio_namespace_trigger BEFORE INSERT OR UPDATE ON public.portfolio_assignments FOR EACH ROW EXECUTE FUNCTION public.check_portfolio_assignment_namespace();


--
-- Name: technology_lifecycle_reference compute_tlr_status; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER compute_tlr_status BEFORE INSERT OR UPDATE ON public.technology_lifecycle_reference FOR EACH ROW EXECUTE FUNCTION public.compute_lifecycle_status();


--
-- Name: workspaces create_default_portfolio_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_default_portfolio_trigger AFTER INSERT ON public.workspaces FOR EACH ROW EXECUTE FUNCTION public.create_default_portfolio_for_workspace();


--
-- Name: applications create_deployment_profile_on_app_create; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_deployment_profile_on_app_create AFTER INSERT ON public.applications FOR EACH ROW EXECUTE FUNCTION public.create_default_deployment_profile();


--
-- Name: workspace_users enforce_workspace_user_namespace; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enforce_workspace_user_namespace BEFORE INSERT OR UPDATE ON public.workspace_users FOR EACH ROW EXECUTE FUNCTION public.check_workspace_user_namespace();


--
-- Name: namespaces seed_alert_preferences; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER seed_alert_preferences AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.seed_alert_preferences_for_namespace();


--
-- Name: namespaces seed_organization_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER seed_organization_settings AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.seed_organization_settings_for_namespace();


--
-- Name: namespaces seed_software_product_categories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER seed_software_product_categories AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.copy_software_product_categories_to_new_namespace();


--
-- Name: users sync_namespace_admin_on_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_namespace_admin_on_insert AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.sync_namespace_admin_to_workspaces();


--
-- Name: users sync_namespace_admin_on_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER sync_namespace_admin_on_update AFTER UPDATE OF namespace_role ON public.users FOR EACH ROW EXECUTE FUNCTION public.sync_namespace_admin_to_workspaces();


--
-- Name: deployment_profiles trigger_auto_calculate_tech_scores; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_auto_calculate_tech_scores BEFORE INSERT OR UPDATE OF t01, t02, t03, t04, t05, t06, t07, t08, t09, t10, t11, t12, t13, t14, t15 ON public.deployment_profiles FOR EACH ROW EXECUTE FUNCTION public.auto_calculate_deployment_profile_tech_scores();


--
-- Name: namespaces trigger_copy_assessment_factors_to_new_namespace; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_copy_assessment_factors_to_new_namespace AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.copy_assessment_factors_to_new_namespace();


--
-- Name: namespaces trigger_copy_assessment_thresholds_to_new_namespace; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_copy_assessment_thresholds_to_new_namespace AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.copy_assessment_thresholds_to_new_namespace();


--
-- Name: namespaces trigger_copy_service_types_to_new_namespace; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_copy_service_types_to_new_namespace AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.copy_service_types_to_new_namespace();


--
-- Name: namespaces trigger_copy_technology_categories_to_new_namespace; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_copy_technology_categories_to_new_namespace AFTER INSERT ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.copy_technology_categories_to_new_namespace();


--
-- Name: alert_preferences update_alert_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_alert_preferences_updated_at BEFORE UPDATE ON public.alert_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: application_compliance update_application_compliance_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_application_compliance_updated_at BEFORE UPDATE ON public.application_compliance FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: application_roadmap update_application_roadmap_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_application_roadmap_updated_at BEFORE UPDATE ON public.application_roadmap FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: applications update_applications_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON public.applications FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: assessment_factors update_assessment_factors_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_assessment_factors_updated_at BEFORE UPDATE ON public.assessment_factors FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: assessment_thresholds update_assessment_thresholds_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_assessment_thresholds_updated_at BEFORE UPDATE ON public.assessment_thresholds FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: business_assessments update_business_assessments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_business_assessments_updated_at BEFORE UPDATE ON public.business_assessments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: custom_field_values update_custom_field_values_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_custom_field_values_updated_at BEFORE UPDATE ON public.custom_field_values FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: deployment_profiles update_deployment_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_deployment_profiles_updated_at BEFORE UPDATE ON public.deployment_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: deployment_profile_technology_products update_dp_technology_products_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_dp_technology_products_updated_at BEFORE UPDATE ON public.deployment_profile_technology_products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: findings update_findings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_findings_updated_at BEFORE UPDATE ON public.findings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ideas update_ideas_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ideas_updated_at BEFORE UPDATE ON public.ideas FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: initiatives update_initiatives_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_initiatives_updated_at BEFORE UPDATE ON public.initiatives FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: it_services update_it_services_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_it_services_updated_at BEFORE UPDATE ON public.it_services FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: namespaces update_namespaces_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_namespaces_updated_at BEFORE UPDATE ON public.namespaces FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: organization_settings update_organization_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_organization_settings_updated_at BEFORE UPDATE ON public.organization_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: organizations update_organizations_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: portfolio_assignments update_portfolio_assignments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_portfolio_assignments_updated_at BEFORE UPDATE ON public.portfolio_assignments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: portfolio_settings update_portfolio_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_portfolio_settings_updated_at BEFORE UPDATE ON public.portfolio_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: portfolios update_portfolios_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_portfolios_updated_at BEFORE UPDATE ON public.portfolios FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: programs update_programs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON public.programs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: software_products update_software_products_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_software_products_updated_at BEFORE UPDATE ON public.software_products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: technical_assessments update_technical_assessments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_technical_assessments_updated_at BEFORE UPDATE ON public.technical_assessments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: technology_lifecycle_reference update_technology_lifecycle_reference_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_technology_lifecycle_reference_updated_at BEFORE UPDATE ON public.technology_lifecycle_reference FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: vendor_lifecycle_sources update_vendor_lifecycle_sources_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_vendor_lifecycle_sources_updated_at BEFORE UPDATE ON public.vendor_lifecycle_sources FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: workspace_settings update_workspace_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_workspace_settings_updated_at BEFORE UPDATE ON public.workspace_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: workspaces update_workspaces_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_workspaces_updated_at BEFORE UPDATE ON public.workspaces FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: alert_preferences alert_preferences_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: alert_preferences alert_preferences_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: alert_preferences alert_preferences_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: alert_preferences alert_preferences_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_preferences
    ADD CONSTRAINT alert_preferences_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: application_compliance application_compliance_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_compliance
    ADD CONSTRAINT application_compliance_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_contacts application_contacts_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_contacts
    ADD CONSTRAINT application_contacts_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_contacts application_contacts_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_contacts
    ADD CONSTRAINT application_contacts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: application_data_assets application_data_assets_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_data_assets
    ADD CONSTRAINT application_data_assets_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_data_assets application_data_assets_data_steward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_data_assets
    ADD CONSTRAINT application_data_assets_data_steward_id_fkey FOREIGN KEY (data_steward_id) REFERENCES public.users(id);


--
-- Name: application_documents application_documents_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_documents
    ADD CONSTRAINT application_documents_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_documents application_documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_documents
    ADD CONSTRAINT application_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: application_integrations application_integrations_external_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_integrations
    ADD CONSTRAINT application_integrations_external_organization_id_fkey FOREIGN KEY (external_organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: application_integrations application_integrations_source_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_integrations
    ADD CONSTRAINT application_integrations_source_application_id_fkey FOREIGN KEY (source_application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_integrations application_integrations_target_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_integrations
    ADD CONSTRAINT application_integrations_target_application_id_fkey FOREIGN KEY (target_application_id) REFERENCES public.applications(id) ON DELETE SET NULL;


--
-- Name: application_roadmap application_roadmap_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_roadmap
    ADD CONSTRAINT application_roadmap_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_roadmap application_roadmap_replacement_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_roadmap
    ADD CONSTRAINT application_roadmap_replacement_app_id_fkey FOREIGN KEY (replacement_app_id) REFERENCES public.applications(id) ON DELETE SET NULL;


--
-- Name: application_services application_services_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_services
    ADD CONSTRAINT application_services_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_services application_services_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_services
    ADD CONSTRAINT application_services_it_service_id_fkey FOREIGN KEY (it_service_id) REFERENCES public.it_services(id) ON DELETE RESTRICT;


--
-- Name: applications applications_owner_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_owner_workspace_id_fkey FOREIGN KEY (owner_workspace_id) REFERENCES public.workspaces(id) ON DELETE SET NULL;


--
-- Name: applications applications_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: assessment_factor_options assessment_factor_options_factor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_factor_options
    ADD CONSTRAINT assessment_factor_options_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES public.assessment_factors(id) ON DELETE CASCADE;


--
-- Name: assessment_factors assessment_factors_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_factors
    ADD CONSTRAINT assessment_factors_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: assessment_history assessment_history_assessed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_history
    ADD CONSTRAINT assessment_history_assessed_by_fkey FOREIGN KEY (assessed_by) REFERENCES public.users(id);


--
-- Name: assessment_history assessment_history_portfolio_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_history
    ADD CONSTRAINT assessment_history_portfolio_assignment_id_fkey FOREIGN KEY (portfolio_assignment_id) REFERENCES public.portfolio_assignments(id) ON DELETE CASCADE;


--
-- Name: assessment_thresholds assessment_thresholds_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessment_thresholds
    ADD CONSTRAINT assessment_thresholds_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: audit_logs audit_logs_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id);


--
-- Name: budget_transfers budget_transfers_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: budget_transfers budget_transfers_from_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_from_application_id_fkey FOREIGN KEY (from_application_id) REFERENCES public.applications(id) ON DELETE SET NULL;


--
-- Name: budget_transfers budget_transfers_from_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_from_it_service_id_fkey FOREIGN KEY (from_it_service_id) REFERENCES public.it_services(id) ON DELETE SET NULL;


--
-- Name: budget_transfers budget_transfers_to_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_to_application_id_fkey FOREIGN KEY (to_application_id) REFERENCES public.applications(id) ON DELETE SET NULL;


--
-- Name: budget_transfers budget_transfers_to_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_to_it_service_id_fkey FOREIGN KEY (to_it_service_id) REFERENCES public.it_services(id) ON DELETE SET NULL;


--
-- Name: budget_transfers budget_transfers_transferred_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_transferred_by_fkey FOREIGN KEY (transferred_by) REFERENCES public.users(id);


--
-- Name: budget_transfers budget_transfers_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_transfers
    ADD CONSTRAINT budget_transfers_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: business_assessments business_assessments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_assessments
    ADD CONSTRAINT business_assessments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: contact_organizations contact_organizations_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_organizations
    ADD CONSTRAINT contact_organizations_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_organizations contact_organizations_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contact_organizations
    ADD CONSTRAINT contact_organizations_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_individual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individuals(id) ON DELETE SET NULL;


--
-- Name: contacts contacts_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: contacts contacts_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_workspace_id_fkey FOREIGN KEY (primary_workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: custom_field_definitions custom_field_definitions_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_definitions
    ADD CONSTRAINT custom_field_definitions_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: custom_field_values custom_field_values_field_definition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_field_definition_id_fkey FOREIGN KEY (field_definition_id) REFERENCES public.custom_field_definitions(id) ON DELETE CASCADE;


--
-- Name: data_centers data_centers_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_centers
    ADD CONSTRAINT data_centers_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_contacts deployment_profile_contacts_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_contacts
    ADD CONSTRAINT deployment_profile_contacts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_contacts deployment_profile_contacts_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_contacts
    ADD CONSTRAINT deployment_profile_contacts_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_it_services deployment_profile_it_services_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_it_services
    ADD CONSTRAINT deployment_profile_it_services_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_it_services deployment_profile_it_services_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_it_services
    ADD CONSTRAINT deployment_profile_it_services_it_service_id_fkey FOREIGN KEY (it_service_id) REFERENCES public.it_services(id) ON DELETE RESTRICT;


--
-- Name: deployment_profile_software_products deployment_profile_software_products_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_software_products
    ADD CONSTRAINT deployment_profile_software_products_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_software_products deployment_profile_software_products_software_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_software_products
    ADD CONSTRAINT deployment_profile_software_products_software_product_id_fkey FOREIGN KEY (software_product_id) REFERENCES public.software_products(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_software_products deployment_profile_software_products_vendor_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_software_products
    ADD CONSTRAINT deployment_profile_software_products_vendor_org_id_fkey FOREIGN KEY (vendor_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: deployment_profile_technology_products deployment_profile_technology_produc_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_technology_products
    ADD CONSTRAINT deployment_profile_technology_produc_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: deployment_profile_technology_products deployment_profile_technology_produc_technology_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profile_technology_products
    ADD CONSTRAINT deployment_profile_technology_produc_technology_product_id_fkey FOREIGN KEY (technology_product_id) REFERENCES public.technology_products(id) ON DELETE CASCADE;


--
-- Name: deployment_profiles deployment_profiles_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: deployment_profiles deployment_profiles_assessed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_assessed_by_fkey FOREIGN KEY (assessed_by) REFERENCES auth.users(id);


--
-- Name: deployment_profiles deployment_profiles_data_center_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_data_center_id_fkey FOREIGN KEY (data_center_id) REFERENCES public.data_centers(id);


--
-- Name: deployment_profiles deployment_profiles_vendor_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_vendor_org_id_fkey FOREIGN KEY (vendor_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: deployment_profiles deployment_profiles_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_profiles
    ADD CONSTRAINT deployment_profiles_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: findings findings_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: findings findings_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: findings findings_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: ideas ideas_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: ideas ideas_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: ideas ideas_promoted_to_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_promoted_to_initiative_id_fkey FOREIGN KEY (promoted_to_initiative_id) REFERENCES public.initiatives(id) ON DELETE SET NULL;


--
-- Name: ideas ideas_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: ideas ideas_submitted_by_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_submitted_by_contact_id_fkey FOREIGN KEY (submitted_by_contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: ideas ideas_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ideas
    ADD CONSTRAINT ideas_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: initiative_dependencies initiative_dependencies_source_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_dependencies
    ADD CONSTRAINT initiative_dependencies_source_initiative_id_fkey FOREIGN KEY (source_initiative_id) REFERENCES public.initiatives(id) ON DELETE CASCADE;


--
-- Name: initiative_dependencies initiative_dependencies_target_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_dependencies
    ADD CONSTRAINT initiative_dependencies_target_initiative_id_fkey FOREIGN KEY (target_initiative_id) REFERENCES public.initiatives(id) ON DELETE CASCADE;


--
-- Name: initiative_deployment_profiles initiative_deployment_profiles_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_deployment_profiles
    ADD CONSTRAINT initiative_deployment_profiles_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: initiative_deployment_profiles initiative_deployment_profiles_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_deployment_profiles
    ADD CONSTRAINT initiative_deployment_profiles_initiative_id_fkey FOREIGN KEY (initiative_id) REFERENCES public.initiatives(id) ON DELETE CASCADE;


--
-- Name: initiative_it_services initiative_it_services_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_it_services
    ADD CONSTRAINT initiative_it_services_initiative_id_fkey FOREIGN KEY (initiative_id) REFERENCES public.initiatives(id) ON DELETE CASCADE;


--
-- Name: initiative_it_services initiative_it_services_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiative_it_services
    ADD CONSTRAINT initiative_it_services_it_service_id_fkey FOREIGN KEY (it_service_id) REFERENCES public.it_services(id) ON DELETE CASCADE;


--
-- Name: initiatives initiatives_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: initiatives initiatives_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: initiatives initiatives_owner_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_owner_contact_id_fkey FOREIGN KEY (owner_contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: initiatives initiatives_source_finding_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_source_finding_id_fkey FOREIGN KEY (source_finding_id) REFERENCES public.findings(id) ON DELETE SET NULL;


--
-- Name: initiatives initiatives_source_idea_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_source_idea_id_fkey FOREIGN KEY (source_idea_id) REFERENCES public.ideas(id) ON DELETE SET NULL;


--
-- Name: initiatives initiatives_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives
    ADD CONSTRAINT initiatives_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: integration_contacts integration_contacts_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_contacts
    ADD CONSTRAINT integration_contacts_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: integration_contacts integration_contacts_integration_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_contacts
    ADD CONSTRAINT integration_contacts_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES public.application_integrations(id) ON DELETE CASCADE;


--
-- Name: invitation_workspaces invitation_workspaces_invitation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation_workspaces
    ADD CONSTRAINT invitation_workspaces_invitation_id_fkey FOREIGN KEY (invitation_id) REFERENCES public.invitations(id) ON DELETE CASCADE;


--
-- Name: invitation_workspaces invitation_workspaces_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation_workspaces
    ADD CONSTRAINT invitation_workspaces_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: invitations invitations_invited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: invitations invitations_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: it_service_providers it_service_providers_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_service_providers
    ADD CONSTRAINT it_service_providers_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: it_service_providers it_service_providers_it_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_service_providers
    ADD CONSTRAINT it_service_providers_it_service_id_fkey FOREIGN KEY (it_service_id) REFERENCES public.it_services(id) ON DELETE CASCADE;


--
-- Name: it_service_providers it_service_providers_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_service_providers
    ADD CONSTRAINT it_service_providers_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id);


--
-- Name: it_services it_services_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_services
    ADD CONSTRAINT it_services_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: it_services it_services_owner_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_services
    ADD CONSTRAINT it_services_owner_workspace_id_fkey FOREIGN KEY (owner_workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: it_services it_services_service_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_services
    ADD CONSTRAINT it_services_service_type_id_fkey FOREIGN KEY (service_type_id) REFERENCES public.service_types(id);


--
-- Name: it_services it_services_vendor_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.it_services
    ADD CONSTRAINT it_services_vendor_org_id_fkey FOREIGN KEY (vendor_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: namespace_users namespace_users_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_users
    ADD CONSTRAINT namespace_users_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: namespace_users namespace_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace_users
    ADD CONSTRAINT namespace_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: notification_rules notification_rules_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_rules
    ADD CONSTRAINT notification_rules_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: organization_settings organization_settings_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: organizations organizations_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: organizations organizations_owner_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_owner_workspace_id_fkey FOREIGN KEY (owner_workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: organizations organizations_primary_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_primary_workspace_id_fkey FOREIGN KEY (primary_workspace_id) REFERENCES public.workspaces(id);


--
-- Name: platform_admins platform_admins_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_admins
    ADD CONSTRAINT platform_admins_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.platform_admins(id);


--
-- Name: platform_admins platform_admins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_admins
    ADD CONSTRAINT platform_admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: portfolio_assignments portfolio_assignments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_assignments
    ADD CONSTRAINT portfolio_assignments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: portfolio_assignments portfolio_assignments_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_assignments
    ADD CONSTRAINT portfolio_assignments_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: portfolio_assignments portfolio_assignments_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_assignments
    ADD CONSTRAINT portfolio_assignments_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolios(id) ON DELETE CASCADE;


--
-- Name: portfolios portfolios_parent_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_parent_portfolio_id_fkey FOREIGN KEY (parent_portfolio_id) REFERENCES public.portfolios(id) ON DELETE CASCADE;


--
-- Name: portfolios portfolios_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolios
    ADD CONSTRAINT portfolios_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: program_initiatives program_initiatives_initiative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_initiatives
    ADD CONSTRAINT program_initiatives_initiative_id_fkey FOREIGN KEY (initiative_id) REFERENCES public.initiatives(id) ON DELETE CASCADE;


--
-- Name: program_initiatives program_initiatives_program_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.program_initiatives
    ADD CONSTRAINT program_initiatives_program_id_fkey FOREIGN KEY (program_id) REFERENCES public.programs(id) ON DELETE CASCADE;


--
-- Name: programs programs_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: programs programs_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: programs programs_owner_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_owner_contact_id_fkey FOREIGN KEY (owner_contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: programs programs_sponsor_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_sponsor_contact_id_fkey FOREIGN KEY (sponsor_contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: programs programs_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programs
    ADD CONSTRAINT programs_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: service_type_categories service_type_categories_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_type_categories
    ADD CONSTRAINT service_type_categories_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: service_types service_types_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_types
    ADD CONSTRAINT service_types_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.service_type_categories(id) ON DELETE CASCADE;


--
-- Name: service_types service_types_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_types
    ADD CONSTRAINT service_types_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: software_product_categories software_product_categories_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_product_categories
    ADD CONSTRAINT software_product_categories_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: software_products software_products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_products
    ADD CONSTRAINT software_products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.software_product_categories(id) ON DELETE SET NULL;


--
-- Name: software_products software_products_manufacturer_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_products
    ADD CONSTRAINT software_products_manufacturer_org_id_fkey FOREIGN KEY (manufacturer_org_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: software_products software_products_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_products
    ADD CONSTRAINT software_products_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: software_products software_products_owner_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.software_products
    ADD CONSTRAINT software_products_owner_workspace_id_fkey FOREIGN KEY (owner_workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: technical_assessments technical_assessments_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technical_assessments
    ADD CONSTRAINT technical_assessments_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: technology_lifecycle_reference technology_lifecycle_reference_overridden_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_lifecycle_reference
    ADD CONSTRAINT technology_lifecycle_reference_overridden_by_fkey FOREIGN KEY (overridden_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: technology_product_categories technology_product_categories_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_product_categories
    ADD CONSTRAINT technology_product_categories_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: technology_products technology_products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_products
    ADD CONSTRAINT technology_products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.technology_product_categories(id);


--
-- Name: technology_products technology_products_lifecycle_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_products
    ADD CONSTRAINT technology_products_lifecycle_reference_id_fkey FOREIGN KEY (lifecycle_reference_id) REFERENCES public.technology_lifecycle_reference(id) ON DELETE SET NULL;


--
-- Name: technology_products technology_products_manufacturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_products
    ADD CONSTRAINT technology_products_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.organizations(id);


--
-- Name: technology_products technology_products_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technology_products
    ADD CONSTRAINT technology_products_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_current_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_current_namespace_id_fkey FOREIGN KEY (current_namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: users users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: users users_individual_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_individual_id_fkey FOREIGN KEY (individual_id) REFERENCES public.individuals(id) ON DELETE SET NULL;


--
-- Name: users users_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: workflow_definitions workflow_definitions_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_definitions
    ADD CONSTRAINT workflow_definitions_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: workflow_instances workflow_instances_started_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_instances
    ADD CONSTRAINT workflow_instances_started_by_fkey FOREIGN KEY (started_by) REFERENCES public.users(id);


--
-- Name: workflow_instances workflow_instances_workflow_definition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_instances
    ADD CONSTRAINT workflow_instances_workflow_definition_id_fkey FOREIGN KEY (workflow_definition_id) REFERENCES public.workflow_definitions(id) ON DELETE CASCADE;


--
-- Name: workspace_budgets workspace_budgets_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_budgets
    ADD CONSTRAINT workspace_budgets_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: workspace_group_members workspace_group_members_added_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_members
    ADD CONSTRAINT workspace_group_members_added_by_fkey FOREIGN KEY (added_by) REFERENCES auth.users(id);


--
-- Name: workspace_group_members workspace_group_members_workspace_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_members
    ADD CONSTRAINT workspace_group_members_workspace_group_id_fkey FOREIGN KEY (workspace_group_id) REFERENCES public.workspace_groups(id) ON DELETE CASCADE;


--
-- Name: workspace_group_members workspace_group_members_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_members
    ADD CONSTRAINT workspace_group_members_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: workspace_group_publications workspace_group_publications_deployment_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_publications
    ADD CONSTRAINT workspace_group_publications_deployment_profile_id_fkey FOREIGN KEY (deployment_profile_id) REFERENCES public.deployment_profiles(id) ON DELETE CASCADE;


--
-- Name: workspace_group_publications workspace_group_publications_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_publications
    ADD CONSTRAINT workspace_group_publications_published_by_fkey FOREIGN KEY (published_by) REFERENCES auth.users(id);


--
-- Name: workspace_group_publications workspace_group_publications_workspace_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_group_publications
    ADD CONSTRAINT workspace_group_publications_workspace_group_id_fkey FOREIGN KEY (workspace_group_id) REFERENCES public.workspace_groups(id) ON DELETE CASCADE;


--
-- Name: workspace_groups workspace_groups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_groups
    ADD CONSTRAINT workspace_groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: workspace_groups workspace_groups_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_groups
    ADD CONSTRAINT workspace_groups_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: workspace_settings workspace_settings_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_settings
    ADD CONSTRAINT workspace_settings_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: workspace_users workspace_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users
    ADD CONSTRAINT workspace_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: workspace_users workspace_users_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspace_users
    ADD CONSTRAINT workspace_users_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspaces(id) ON DELETE CASCADE;


--
-- Name: workspaces workspaces_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespaces(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: it_service_providers Admins can delete IT service providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete IT service providers in current namespace" ON public.it_service_providers FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: alert_preferences Admins can delete alert_preferences in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete alert_preferences in current namespace" ON public.alert_preferences FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (((namespace_id IS NOT NULL) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)) OR ((workspace_id IS NOT NULL) AND (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))))));


--
-- Name: assessment_factor_options Admins can delete assessment_factor_options in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete assessment_factor_options in current namespac" ON public.assessment_factor_options FOR DELETE USING ((factor_id IN ( SELECT af.id
   FROM public.assessment_factors af
  WHERE ((af.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(af.namespace_id))))));


--
-- Name: assessment_factors Admins can delete assessment_factors in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete assessment_factors in current namespace" ON public.assessment_factors FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: assessment_thresholds Admins can delete assessment_thresholds in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete assessment_thresholds in current namespace" ON public.assessment_thresholds FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: contacts Admins can delete contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete contacts in current namespace" ON public.contacts FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = contacts.primary_workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: custom_field_definitions Admins can delete custom_field_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete custom_field_definitions in current namespace" ON public.custom_field_definitions FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: data_centers Admins can delete data_centers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete data_centers in current namespace" ON public.data_centers FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: findings Admins can delete findings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete findings in current namespace" ON public.findings FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = findings.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))))));


--
-- Name: ideas Admins can delete ideas in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete ideas in current namespace" ON public.ideas FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: individuals Admins can delete individuals in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete individuals in current namespace" ON public.individuals FOR DELETE USING (((id IN ( SELECT c.individual_id
   FROM (public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (c.individual_id IS NOT NULL)))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiative_dependencies Admins can delete initiative_dependencies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete initiative_dependencies" ON public.initiative_dependencies FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.initiatives i
  WHERE ((i.id = initiative_dependencies.source_initiative_id) AND (i.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(i.namespace_id))))));


--
-- Name: initiative_deployment_profiles Admins can delete initiative_deployment_profiles in current nam; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete initiative_deployment_profiles in current nam" ON public.initiative_deployment_profiles FOR DELETE USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_deployment_profiles.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: initiative_it_services Admins can delete initiative_it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete initiative_it_services in current namespace" ON public.initiative_it_services FOR DELETE USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_it_services.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: initiatives Admins can delete initiatives in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete initiatives in current namespace" ON public.initiatives FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = initiatives.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))))));


--
-- Name: integration_contacts Admins can delete integration_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete integration_contacts in current namespace" ON public.integration_contacts FOR DELETE USING (((integration_id IN ( SELECT ai.id
   FROM ((public.application_integrations ai
     JOIN public.applications a ON ((a.id = ai.source_application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: invitation_workspaces Admins can delete invitation_workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete invitation_workspaces in current namespace" ON public.invitation_workspaces FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR ((invitation_id IN ( SELECT i.id
   FROM public.invitations i
  WHERE ((i.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(i.namespace_id)))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))))));


--
-- Name: invitations Admins can delete invitations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete invitations in current namespace" ON public.invitations FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR ((namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: it_service_providers Admins can delete it_service_providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete it_service_providers in current namespace" ON public.it_service_providers FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: it_services Admins can delete it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete it_services in current namespace" ON public.it_services FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: namespace_users Admins can delete namespace_users in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete namespace_users in current namespace" ON public.namespace_users FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: notification_rules Admins can delete notification_rules in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete notification_rules in current namespace" ON public.notification_rules FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organization_settings Admins can delete organization_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete organization_settings in current namespace" ON public.organization_settings FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organizations Admins can delete organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete organizations in current namespace" ON public.organizations FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: program_initiatives Admins can delete program_initiatives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete program_initiatives" ON public.program_initiatives FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_initiatives.program_id) AND (p.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(p.namespace_id))))));


--
-- Name: programs Admins can delete programs in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete programs in current namespace" ON public.programs FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: service_type_categories Admins can delete service_type_categories in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete service_type_categories in current namespace" ON public.service_type_categories FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: service_types Admins can delete service_types in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete service_types in current namespace" ON public.service_types FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_product_categories Admins can delete software_product_categories in current namesp; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete software_product_categories in current namesp" ON public.software_product_categories FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_products Admins can delete software_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete software_products in current namespace" ON public.software_products FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_product_categories Admins can delete technology_product_categories in current name; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete technology_product_categories in current name" ON public.technology_product_categories FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_products Admins can delete technology_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete technology_products in current namespace" ON public.technology_products FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workflow_definitions Admins can delete workflow_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workflow_definitions in current namespace" ON public.workflow_definitions FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_budgets Admins can delete workspace_budgets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workspace_budgets in current namespace" ON public.workspace_budgets FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))));


--
-- Name: workspace_group_members Admins can delete workspace_group_members in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workspace_group_members in current namespace" ON public.workspace_group_members FOR DELETE USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workspace_groups Admins can delete workspace_groups in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workspace_groups in current namespace" ON public.workspace_groups FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_settings Admins can delete workspace_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workspace_settings in current namespace" ON public.workspace_settings FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))));


--
-- Name: workspaces Admins can delete workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can delete workspaces in current namespace" ON public.workspaces FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: it_service_providers Admins can insert IT service providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert IT service providers in current namespace" ON public.it_service_providers FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: alert_preferences Admins can insert alert_preferences in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert alert_preferences in current namespace" ON public.alert_preferences FOR INSERT WITH CHECK ((((namespace_id IS NOT NULL) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)) OR ((workspace_id IS NOT NULL) AND (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: assessment_factor_options Admins can insert assessment_factor_options in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert assessment_factor_options in current namespac" ON public.assessment_factor_options FOR INSERT WITH CHECK ((factor_id IN ( SELECT af.id
   FROM public.assessment_factors af
  WHERE ((af.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(af.namespace_id))))));


--
-- Name: assessment_factors Admins can insert assessment_factors in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert assessment_factors in current namespace" ON public.assessment_factors FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: assessment_thresholds Admins can insert assessment_thresholds in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert assessment_thresholds in current namespace" ON public.assessment_thresholds FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: contacts Admins can insert contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert contacts in current namespace" ON public.contacts FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: custom_field_definitions Admins can insert custom_field_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert custom_field_definitions in current namespace" ON public.custom_field_definitions FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: data_centers Admins can insert data_centers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert data_centers in current namespace" ON public.data_centers FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: individuals Admins can insert individuals in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert individuals in current namespace" ON public.individuals FOR INSERT WITH CHECK ((public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: invitation_workspaces Admins can insert invitation_workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert invitation_workspaces in current namespace" ON public.invitation_workspaces FOR INSERT TO authenticated WITH CHECK ((public.check_is_platform_admin() OR ((invitation_id IN ( SELECT i.id
   FROM public.invitations i
  WHERE ((i.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(i.namespace_id)))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))))));


--
-- Name: invitations Admins can insert invitations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert invitations in current namespace" ON public.invitations FOR INSERT TO authenticated WITH CHECK ((public.check_is_platform_admin() OR ((namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: it_service_providers Admins can insert it_service_providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert it_service_providers in current namespace" ON public.it_service_providers FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: it_services Admins can insert it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert it_services in current namespace" ON public.it_services FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: namespace_users Admins can insert namespace_users in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert namespace_users in current namespace" ON public.namespace_users FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: notification_rules Admins can insert notification_rules in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert notification_rules in current namespace" ON public.notification_rules FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organization_settings Admins can insert organization_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert organization_settings in current namespace" ON public.organization_settings FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organizations Admins can insert organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert organizations in current namespace" ON public.organizations FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: service_type_categories Admins can insert service_type_categories in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert service_type_categories in current namespace" ON public.service_type_categories FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: service_types Admins can insert service_types in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert service_types in current namespace" ON public.service_types FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_product_categories Admins can insert software_product_categories in current namesp; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert software_product_categories in current namesp" ON public.software_product_categories FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_products Admins can insert software_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert software_products in current namespace" ON public.software_products FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_product_categories Admins can insert technology_product_categories in current name; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert technology_product_categories in current name" ON public.technology_product_categories FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_products Admins can insert technology_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert technology_products in current namespace" ON public.technology_products FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workflow_definitions Admins can insert workflow_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workflow_definitions in current namespace" ON public.workflow_definitions FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_budgets Admins can insert workspace_budgets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workspace_budgets in current namespace" ON public.workspace_budgets FOR INSERT WITH CHECK ((workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))));


--
-- Name: workspace_group_members Admins can insert workspace_group_members in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workspace_group_members in current namespace" ON public.workspace_group_members FOR INSERT WITH CHECK (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workspace_groups Admins can insert workspace_groups in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workspace_groups in current namespace" ON public.workspace_groups FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_settings Admins can insert workspace_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workspace_settings in current namespace" ON public.workspace_settings FOR INSERT WITH CHECK ((workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))));


--
-- Name: workspaces Admins can insert workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can insert workspaces in current namespace" ON public.workspaces FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: it_service_providers Admins can update IT service providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update IT service providers in current namespace" ON public.it_service_providers FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: alert_preferences Admins can update alert_preferences in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update alert_preferences in current namespace" ON public.alert_preferences FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (((namespace_id IS NOT NULL) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)) OR ((workspace_id IS NOT NULL) AND (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))))) WITH CHECK ((public.check_is_platform_admin() OR (((namespace_id IS NOT NULL) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)) OR ((workspace_id IS NOT NULL) AND (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))))));


--
-- Name: assessment_factor_options Admins can update assessment_factor_options in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update assessment_factor_options in current namespac" ON public.assessment_factor_options FOR UPDATE USING ((factor_id IN ( SELECT af.id
   FROM public.assessment_factors af
  WHERE ((af.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(af.namespace_id)))))) WITH CHECK ((factor_id IN ( SELECT af.id
   FROM public.assessment_factors af
  WHERE ((af.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(af.namespace_id))))));


--
-- Name: assessment_factors Admins can update assessment_factors in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update assessment_factors in current namespace" ON public.assessment_factors FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: assessment_thresholds Admins can update assessment_thresholds in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update assessment_thresholds in current namespace" ON public.assessment_thresholds FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: contacts Admins can update contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update contacts in current namespace" ON public.contacts FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = contacts.primary_workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = contacts.primary_workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: custom_field_definitions Admins can update custom_field_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update custom_field_definitions in current namespace" ON public.custom_field_definitions FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: data_centers Admins can update data_centers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update data_centers in current namespace" ON public.data_centers FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: individuals Admins can update individuals in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update individuals in current namespace" ON public.individuals FOR UPDATE USING (((id IN ( SELECT c.individual_id
   FROM (public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (c.individual_id IS NOT NULL)))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR (id = ( SELECT users.individual_id
   FROM public.users
  WHERE (users.id = auth.uid())))))) WITH CHECK ((public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR (id = ( SELECT users.individual_id
   FROM public.users
  WHERE (users.id = auth.uid())))));


--
-- Name: invitation_workspaces Admins can update invitation_workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update invitation_workspaces in current namespace" ON public.invitation_workspaces FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR ((invitation_id IN ( SELECT i.id
   FROM public.invitations i
  WHERE ((i.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(i.namespace_id)))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id())))))) WITH CHECK ((public.check_is_platform_admin() OR ((invitation_id IN ( SELECT i.id
   FROM public.invitations i
  WHERE ((i.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(i.namespace_id)))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))))));


--
-- Name: invitations Admins can update invitations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update invitations in current namespace" ON public.invitations FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR ((namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)))) WITH CHECK ((public.check_is_platform_admin() OR ((namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: it_service_providers Admins can update it_service_providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update it_service_providers in current namespace" ON public.it_service_providers FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: it_services Admins can update it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update it_services in current namespace" ON public.it_services FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: namespace_users Admins can update namespace_users in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update namespace_users in current namespace" ON public.namespace_users FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id)))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: namespaces Admins can update namespaces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update namespaces" ON public.namespaces FOR UPDATE USING ((public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(id))) WITH CHECK ((public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(id)));


--
-- Name: notification_rules Admins can update notification_rules in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update notification_rules in current namespace" ON public.notification_rules FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organization_settings Admins can update organization_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update organization_settings in current namespace" ON public.organization_settings FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: organizations Admins can update organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update organizations in current namespace" ON public.organizations FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: service_type_categories Admins can update service_type_categories in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update service_type_categories in current namespace" ON public.service_type_categories FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: service_types Admins can update service_types in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update service_types in current namespace" ON public.service_types FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_product_categories Admins can update software_product_categories in current namesp; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update software_product_categories in current namesp" ON public.software_product_categories FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: software_products Admins can update software_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update software_products in current namespace" ON public.software_products FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_product_categories Admins can update technology_product_categories in current name; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update technology_product_categories in current name" ON public.technology_product_categories FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: technology_products Admins can update technology_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update technology_products in current namespace" ON public.technology_products FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workflow_definitions Admins can update workflow_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workflow_definitions in current namespace" ON public.workflow_definitions FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_budgets Admins can update workspace_budgets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workspace_budgets in current namespace" ON public.workspace_budgets FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))) WITH CHECK ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))));


--
-- Name: workspace_group_members Admins can update workspace_group_members in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workspace_group_members in current namespace" ON public.workspace_group_members FOR UPDATE USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workspace_groups Admins can update workspace_groups in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workspace_groups in current namespace" ON public.workspace_groups FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workspace_settings Admins can update workspace_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workspace_settings in current namespace" ON public.workspace_settings FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))) WITH CHECK ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text))))));


--
-- Name: workspaces Admins can update workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update workspaces in current namespace" ON public.workspaces FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: portfolio_settings All users can view portfolio_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view portfolio_settings" ON public.portfolio_settings FOR SELECT USING (true);


--
-- Name: remediation_efforts All users can view remediation_efforts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view remediation_efforts" ON public.remediation_efforts FOR SELECT USING (true);


--
-- Name: service_type_categories All users can view service_type_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view service_type_categories" ON public.service_type_categories FOR SELECT USING (true);


--
-- Name: service_types All users can view service_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view service_types" ON public.service_types FOR SELECT USING (true);


--
-- Name: software_product_categories All users can view software_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view software_product_categories" ON public.software_product_categories FOR SELECT USING (true);


--
-- Name: standard_regions All users can view standard_regions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view standard_regions" ON public.standard_regions FOR SELECT USING (true);


--
-- Name: technology_product_categories All users can view technology_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "All users can view technology_product_categories" ON public.technology_product_categories FOR SELECT USING (true);


--
-- Name: dr_statuses Anyone can view DR statuses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view DR statuses" ON public.dr_statuses FOR SELECT USING (true);


--
-- Name: cloud_providers Anyone can view cloud providers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view cloud providers" ON public.cloud_providers FOR SELECT USING (true);


--
-- Name: countries Anyone can view countries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view countries" ON public.countries FOR SELECT USING (true);


--
-- Name: criticality_types Anyone can view criticality_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view criticality_types" ON public.criticality_types FOR SELECT USING (true);


--
-- Name: data_classification_types Anyone can view data_classification_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view data_classification_types" ON public.data_classification_types FOR SELECT USING (true);


--
-- Name: data_format_types Anyone can view data_format_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view data_format_types" ON public.data_format_types FOR SELECT USING (true);


--
-- Name: data_tag_types Anyone can view data_tag_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view data_tag_types" ON public.data_tag_types FOR SELECT USING (true);


--
-- Name: environments Anyone can view environments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view environments" ON public.environments FOR SELECT USING (true);


--
-- Name: hosting_types Anyone can view hosting types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view hosting types" ON public.hosting_types FOR SELECT USING (true);


--
-- Name: integration_direction_types Anyone can view integration_direction_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view integration_direction_types" ON public.integration_direction_types FOR SELECT USING (true);


--
-- Name: integration_frequency_types Anyone can view integration_frequency_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view integration_frequency_types" ON public.integration_frequency_types FOR SELECT USING (true);


--
-- Name: integration_method_types Anyone can view integration_method_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view integration_method_types" ON public.integration_method_types FOR SELECT USING (true);


--
-- Name: integration_status_types Anyone can view integration_status_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view integration_status_types" ON public.integration_status_types FOR SELECT USING (true);


--
-- Name: invitation_workspaces Anyone can view invitation_workspaces for signup; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view invitation_workspaces for signup" ON public.invitation_workspaces FOR SELECT USING (true);


--
-- Name: invitations Anyone can view invitations for signup; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view invitations for signup" ON public.invitations FOR SELECT USING (true);


--
-- Name: lifecycle_statuses Anyone can view lifecycle statuses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view lifecycle statuses" ON public.lifecycle_statuses FOR SELECT USING (true);


--
-- Name: namespace_role_options Anyone can view namespace_role_options; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view namespace_role_options" ON public.namespace_role_options FOR SELECT USING (true);


--
-- Name: operational_statuses Anyone can view operational_statuses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view operational_statuses" ON public.operational_statuses FOR SELECT USING (true);


--
-- Name: sensitivity_types Anyone can view sensitivity_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view sensitivity_types" ON public.sensitivity_types FOR SELECT USING (true);


--
-- Name: technology_lifecycle_reference Anyone can view technology_lifecycle_reference; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view technology_lifecycle_reference" ON public.technology_lifecycle_reference FOR SELECT USING (true);


--
-- Name: vendor_lifecycle_sources Anyone can view vendor_lifecycle_sources; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view vendor_lifecycle_sources" ON public.vendor_lifecycle_sources FOR SELECT USING (true);


--
-- Name: workspace_role_options Anyone can view workspace_role_options; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view workspace_role_options" ON public.workspace_role_options FOR SELECT USING (true);


--
-- Name: deployment_profiles Authorized users can update deployment_profiles in current name; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authorized users can update deployment_profiles in current name" ON public.deployment_profiles FOR UPDATE USING (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (((dp_type = 'application'::text) AND (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = deployment_profiles.id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((dp_type = ANY (ARRAY['software_product'::text, 'infrastructure'::text, 'cost_bundle'::text])) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = deployment_profiles.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))))) WITH CHECK (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (((dp_type = 'application'::text) AND (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = deployment_profiles.id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((dp_type = ANY (ARRAY['software_product'::text, 'infrastructure'::text, 'cost_bundle'::text])) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = deployment_profiles.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: deployment_profile_it_services Editors can delete DP IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete DP IT services in current namespace" ON public.deployment_profile_it_services FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: deployment_profile_contacts Editors can delete DP contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete DP contacts in current namespace" ON public.deployment_profile_contacts FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: deployment_profile_technology_products Editors can delete DP technology products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete DP technology products in current namespace" ON public.deployment_profile_technology_products FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: it_services Editors can delete IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete IT services in current namespace" ON public.it_services FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: application_contacts Editors can delete application contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application contacts in current namespace" ON public.application_contacts FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (application_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: application_compliance Editors can delete application_compliance in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_compliance in current namespace" ON public.application_compliance FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_compliance.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_contacts Editors can delete application_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_contacts in current namespace" ON public.application_contacts FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_contacts.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_data_assets Editors can delete application_data_assets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_data_assets in current namespace" ON public.application_data_assets FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_data_assets.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_documents Editors can delete application_documents in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_documents in current namespace" ON public.application_documents FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_documents.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_integrations Editors can delete application_integrations in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_integrations in current namespac" ON public.application_integrations FOR DELETE USING (((source_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_integrations.source_application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_roadmap Editors can delete application_roadmap in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_roadmap in current namespace" ON public.application_roadmap FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_roadmap.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: application_services Editors can delete application_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete application_services in current namespace" ON public.application_services FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_services.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: applications Editors can delete applications in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete applications in current namespace" ON public.applications FOR DELETE USING (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = applications.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: assessment_history Editors can delete assessment_history in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete assessment_history in current namespace" ON public.assessment_history FOR DELETE USING (((portfolio_assignment_id IN ( SELECT pa.id
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.id = assessment_history.portfolio_assignment_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: budget_transfers Editors can delete budget_transfers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete budget_transfers in current namespace" ON public.budget_transfers FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: business_assessments Editors can delete business_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete business_assessments in current namespace" ON public.business_assessments FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = business_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: contact_organizations Editors can delete contact organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete contact organizations in current namespace" ON public.contact_organizations FOR DELETE USING ((contact_id IN ( SELECT c.id
   FROM public.contacts c
  WHERE ((c.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(c.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: custom_field_values Editors can delete custom_field_values in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete custom_field_values in current namespace" ON public.custom_field_values FOR DELETE TO authenticated USING ((public.check_is_platform_admin() OR ((field_definition_id IN ( SELECT custom_field_definitions.id
   FROM public.custom_field_definitions
  WHERE (custom_field_definitions.namespace_id = public.get_current_namespace_id()))) AND (((entity_type = 'application'::text) AND (entity_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'deployment_profile'::text) AND (entity_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'contact'::text) AND (entity_id IN ( SELECT c.id
   FROM ((public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'it_service'::text) AND (entity_id IN ( SELECT it_services.id
   FROM public.it_services
  WHERE (it_services.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'software_product'::text) AND (entity_id IN ( SELECT software_products.id
   FROM public.software_products
  WHERE (software_products.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'organization'::text) AND (entity_id IN ( SELECT organizations.id
   FROM public.organizations
  WHERE (organizations.namespace_id = public.get_current_namespace_id()))))))));


--
-- Name: deployment_profile_contacts Editors can delete deployment_profile_contacts in current names; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete deployment_profile_contacts in current names" ON public.deployment_profile_contacts FOR DELETE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_contacts.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: deployment_profile_it_services Editors can delete deployment_profile_it_services in current na; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete deployment_profile_it_services in current na" ON public.deployment_profile_it_services FOR DELETE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_it_services.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: deployment_profile_software_products Editors can delete deployment_profile_software_products in curr; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete deployment_profile_software_products in curr" ON public.deployment_profile_software_products FOR DELETE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_software_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: deployment_profile_technology_products Editors can delete deployment_profile_technology_products in cu; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete deployment_profile_technology_products in cu" ON public.deployment_profile_technology_products FOR DELETE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_technology_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: deployment_profiles Editors can delete deployment_profiles in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete deployment_profiles in current namespace" ON public.deployment_profiles FOR DELETE USING (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = deployment_profiles.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: organizations Editors can delete organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete organizations in current namespace" ON public.organizations FOR DELETE USING (((owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR ((is_shared = true) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: portfolio_assignments Editors can delete portfolio_assignments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete portfolio_assignments in current namespace" ON public.portfolio_assignments FOR DELETE USING (((portfolio_id IN ( SELECT p.id
   FROM (public.portfolios p
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.portfolios p
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((p.id = portfolio_assignments.portfolio_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: portfolios Editors can delete portfolios in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete portfolios in current namespace" ON public.portfolios FOR DELETE USING (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = portfolios.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: technical_assessments Editors can delete technical_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete technical_assessments in current namespace" ON public.technical_assessments FOR DELETE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = technical_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = 'admin'::text)))))));


--
-- Name: workflow_instances Editors can delete workflow_instances in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can delete workflow_instances in current namespace" ON public.workflow_instances FOR DELETE USING ((workflow_definition_id IN ( SELECT wd.id
   FROM public.workflow_definitions wd
  WHERE ((wd.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(wd.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: deployment_profile_it_services Editors can insert DP IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert DP IT services in current namespace" ON public.deployment_profile_it_services FOR INSERT WITH CHECK ((deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: deployment_profile_contacts Editors can insert DP contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert DP contacts in current namespace" ON public.deployment_profile_contacts FOR INSERT WITH CHECK ((deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: deployment_profile_technology_products Editors can insert DP technology products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert DP technology products in current namespace" ON public.deployment_profile_technology_products FOR INSERT WITH CHECK ((deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: it_services Editors can insert IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert IT services in current namespace" ON public.it_services FOR INSERT WITH CHECK ((owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: application_contacts Editors can insert application contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application contacts in current namespace" ON public.application_contacts FOR INSERT WITH CHECK ((application_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: application_compliance Editors can insert application_compliance in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_compliance in current namespace" ON public.application_compliance FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: application_contacts Editors can insert application_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_contacts in current namespace" ON public.application_contacts FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: application_data_assets Editors can insert application_data_assets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_data_assets in current namespace" ON public.application_data_assets FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: application_documents Editors can insert application_documents in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_documents in current namespace" ON public.application_documents FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: application_integrations Editors can insert application_integrations in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_integrations in current namespac" ON public.application_integrations FOR INSERT WITH CHECK (((source_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_integrations.source_application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_roadmap Editors can insert application_roadmap in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_roadmap in current namespace" ON public.application_roadmap FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: application_services Editors can insert application_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert application_services in current namespace" ON public.application_services FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: applications Editors can insert applications in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert applications in current namespace" ON public.applications FOR INSERT WITH CHECK (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: assessment_history Editors can insert assessment_history in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert assessment_history in current namespace" ON public.assessment_history FOR INSERT WITH CHECK (((portfolio_assignment_id IN ( SELECT pa.id
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: budget_transfers Editors can insert budget_transfers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert budget_transfers in current namespace" ON public.budget_transfers FOR INSERT WITH CHECK ((workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))));


--
-- Name: business_assessments Editors can insert business_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert business_assessments in current namespace" ON public.business_assessments FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: contact_organizations Editors can insert contact organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert contact organizations in current namespace" ON public.contact_organizations FOR INSERT WITH CHECK ((contact_id IN ( SELECT c.id
   FROM public.contacts c
  WHERE ((c.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(c.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: custom_field_values Editors can insert custom_field_values in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert custom_field_values in current namespace" ON public.custom_field_values FOR INSERT WITH CHECK (((field_definition_id IN ( SELECT custom_field_definitions.id
   FROM public.custom_field_definitions
  WHERE (custom_field_definitions.namespace_id = public.get_current_namespace_id()))) AND (((entity_type = 'application'::text) AND (entity_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'deployment_profile'::text) AND (entity_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'contact'::text) AND (entity_id IN ( SELECT c.id
   FROM ((public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'it_service'::text) AND (entity_id IN ( SELECT its.id
   FROM public.it_services its
  WHERE (its.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'software_product'::text) AND (entity_id IN ( SELECT sp.id
   FROM public.software_products sp
  WHERE (sp.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'organization'::text) AND (entity_id IN ( SELECT o.id
   FROM public.organizations o
  WHERE (o.namespace_id = public.get_current_namespace_id())))))));


--
-- Name: deployment_profile_contacts Editors can insert deployment_profile_contacts in current names; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert deployment_profile_contacts in current names" ON public.deployment_profile_contacts FOR INSERT WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: deployment_profile_it_services Editors can insert deployment_profile_it_services in current na; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert deployment_profile_it_services in current na" ON public.deployment_profile_it_services FOR INSERT WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: deployment_profile_software_products Editors can insert deployment_profile_software_products in curr; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert deployment_profile_software_products in curr" ON public.deployment_profile_software_products FOR INSERT WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: deployment_profile_technology_products Editors can insert deployment_profile_technology_products in cu; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert deployment_profile_technology_products in cu" ON public.deployment_profile_technology_products FOR INSERT WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: deployment_profiles Editors can insert deployment_profiles in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert deployment_profiles in current namespace" ON public.deployment_profiles FOR INSERT WITH CHECK (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: findings Editors can insert findings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert findings in current namespace" ON public.findings FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = findings.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))));


--
-- Name: ideas Editors can insert ideas in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert ideas in current namespace" ON public.ideas FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = ideas.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text, 'steward'::text]))))))));


--
-- Name: initiative_dependencies Editors can insert initiative_dependencies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert initiative_dependencies" ON public.initiative_dependencies FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.initiatives i
  WHERE ((i.id = initiative_dependencies.source_initiative_id) AND (i.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(i.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = i.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: initiative_deployment_profiles Editors can insert initiative_deployment_profiles in current na; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert initiative_deployment_profiles in current na" ON public.initiative_deployment_profiles FOR INSERT WITH CHECK (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_deployment_profiles.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiative_it_services Editors can insert initiative_it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert initiative_it_services in current namespace" ON public.initiative_it_services FOR INSERT WITH CHECK (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_it_services.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiatives Editors can insert initiatives in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert initiatives in current namespace" ON public.initiatives FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = initiatives.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))));


--
-- Name: integration_contacts Editors can insert integration_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert integration_contacts in current namespace" ON public.integration_contacts FOR INSERT WITH CHECK (((integration_id IN ( SELECT ai.id
   FROM ((public.application_integrations ai
     JOIN public.applications a ON ((a.id = ai.source_application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: organizations Editors can insert organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert organizations in current namespace" ON public.organizations FOR INSERT WITH CHECK (((owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR ((is_shared = true) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: portfolio_assignments Editors can insert portfolio_assignments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert portfolio_assignments in current namespace" ON public.portfolio_assignments FOR INSERT WITH CHECK (((portfolio_id IN ( SELECT p.id
   FROM (public.portfolios p
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: portfolios Editors can insert portfolios in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert portfolios in current namespace" ON public.portfolios FOR INSERT WITH CHECK (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: program_initiatives Editors can insert program_initiatives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert program_initiatives" ON public.program_initiatives FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_initiatives.program_id) AND (p.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(p.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = p.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: programs Editors can insert programs in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert programs in current namespace" ON public.programs FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = programs.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: technical_assessments Editors can insert technical_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert technical_assessments in current namespace" ON public.technical_assessments FOR INSERT WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: workflow_instances Editors can insert workflow_instances in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can insert workflow_instances in current namespace" ON public.workflow_instances FOR INSERT WITH CHECK ((workflow_definition_id IN ( SELECT wd.id
   FROM public.workflow_definitions wd
  WHERE ((wd.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(wd.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: deployment_profile_it_services Editors can update DP IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update DP IT services in current namespace" ON public.deployment_profile_it_services FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: deployment_profile_contacts Editors can update DP contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update DP contacts in current namespace" ON public.deployment_profile_contacts FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: deployment_profile_technology_products Editors can update DP technology products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update DP technology products in current namespace" ON public.deployment_profile_technology_products FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (deployment_profile_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: it_services Editors can update IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update IT services in current namespace" ON public.it_services FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: application_contacts Editors can update application contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application contacts in current namespace" ON public.application_contacts FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (application_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (application_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: application_compliance Editors can update application_compliance in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_compliance in current namespace" ON public.application_compliance FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_compliance.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_compliance.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_contacts Editors can update application_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_contacts in current namespace" ON public.application_contacts FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_contacts.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_contacts.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_data_assets Editors can update application_data_assets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_data_assets in current namespace" ON public.application_data_assets FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_data_assets.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_data_assets.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_documents Editors can update application_documents in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_documents in current namespace" ON public.application_documents FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_documents.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_documents.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_integrations Editors can update application_integrations in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_integrations in current namespac" ON public.application_integrations FOR UPDATE USING (((source_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_integrations.source_application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((source_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_integrations.source_application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_roadmap Editors can update application_roadmap in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_roadmap in current namespace" ON public.application_roadmap FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_roadmap.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_roadmap.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: application_services Editors can update application_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update application_services in current namespace" ON public.application_services FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_services.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = application_services.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: assessment_history Editors can update assessment_history in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update assessment_history in current namespace" ON public.assessment_history FOR UPDATE USING (((portfolio_assignment_id IN ( SELECT pa.id
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.id = assessment_history.portfolio_assignment_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((portfolio_assignment_id IN ( SELECT pa.id
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.id = assessment_history.portfolio_assignment_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: budget_transfers Editors can update budget_transfers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update budget_transfers in current namespace" ON public.budget_transfers FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))) WITH CHECK ((public.check_is_platform_admin() OR (workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))));


--
-- Name: business_assessments Editors can update business_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update business_assessments in current namespace" ON public.business_assessments FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = business_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = business_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: contact_organizations Editors can update contact organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update contact organizations in current namespace" ON public.contact_organizations FOR UPDATE USING ((contact_id IN ( SELECT c.id
   FROM public.contacts c
  WHERE ((c.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(c.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))))) WITH CHECK ((contact_id IN ( SELECT c.id
   FROM public.contacts c
  WHERE ((c.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(c.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: custom_field_values Editors can update custom_field_values in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update custom_field_values in current namespace" ON public.custom_field_values FOR UPDATE TO authenticated USING ((public.check_is_platform_admin() OR ((field_definition_id IN ( SELECT custom_field_definitions.id
   FROM public.custom_field_definitions
  WHERE (custom_field_definitions.namespace_id = public.get_current_namespace_id()))) AND (((entity_type = 'application'::text) AND (entity_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'deployment_profile'::text) AND (entity_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'contact'::text) AND (entity_id IN ( SELECT c.id
   FROM ((public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'it_service'::text) AND (entity_id IN ( SELECT it_services.id
   FROM public.it_services
  WHERE (it_services.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'software_product'::text) AND (entity_id IN ( SELECT software_products.id
   FROM public.software_products
  WHERE (software_products.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'organization'::text) AND (entity_id IN ( SELECT organizations.id
   FROM public.organizations
  WHERE (organizations.namespace_id = public.get_current_namespace_id())))))))) WITH CHECK ((public.check_is_platform_admin() OR ((field_definition_id IN ( SELECT custom_field_definitions.id
   FROM public.custom_field_definitions
  WHERE (custom_field_definitions.namespace_id = public.get_current_namespace_id()))) AND (((entity_type = 'application'::text) AND (entity_id IN ( SELECT a.id
   FROM ((public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'deployment_profile'::text) AND (entity_id IN ( SELECT dp.id
   FROM ((public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'contact'::text) AND (entity_id IN ( SELECT c.id
   FROM ((public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))) OR ((entity_type = 'it_service'::text) AND (entity_id IN ( SELECT it_services.id
   FROM public.it_services
  WHERE (it_services.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'software_product'::text) AND (entity_id IN ( SELECT software_products.id
   FROM public.software_products
  WHERE (software_products.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'organization'::text) AND (entity_id IN ( SELECT organizations.id
   FROM public.organizations
  WHERE (organizations.namespace_id = public.get_current_namespace_id()))))))));


--
-- Name: deployment_profile_contacts Editors can update deployment_profile_contacts in current names; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update deployment_profile_contacts in current names" ON public.deployment_profile_contacts FOR UPDATE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_contacts.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_contacts.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: deployment_profile_it_services Editors can update deployment_profile_it_services in current na; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update deployment_profile_it_services in current na" ON public.deployment_profile_it_services FOR UPDATE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_it_services.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_it_services.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: deployment_profile_software_products Editors can update deployment_profile_software_products in curr; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update deployment_profile_software_products in curr" ON public.deployment_profile_software_products FOR UPDATE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_software_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_software_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: deployment_profile_technology_products Editors can update deployment_profile_technology_products in cu; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update deployment_profile_technology_products in cu" ON public.deployment_profile_technology_products FOR UPDATE USING (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_technology_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.deployment_profiles dp
     JOIN public.workspace_users wu ON ((wu.workspace_id = dp.workspace_id)))
  WHERE ((dp.id = deployment_profile_technology_products.deployment_profile_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: findings Editors can update findings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update findings in current namespace" ON public.findings FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = findings.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = findings.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))));


--
-- Name: ideas Editors can update ideas in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update ideas in current namespace" ON public.ideas FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = ideas.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = ideas.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiative_dependencies Editors can update initiative_dependencies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update initiative_dependencies" ON public.initiative_dependencies FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.initiatives i
  WHERE ((i.id = initiative_dependencies.source_initiative_id) AND (i.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(i.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = i.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.initiatives i
  WHERE ((i.id = initiative_dependencies.source_initiative_id) AND (i.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(i.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = i.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: initiative_deployment_profiles Editors can update initiative_deployment_profiles in current na; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update initiative_deployment_profiles in current na" ON public.initiative_deployment_profiles FOR UPDATE USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_deployment_profiles.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_deployment_profiles.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiative_it_services Editors can update initiative_it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update initiative_it_services in current namespace" ON public.initiative_it_services FOR UPDATE USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_it_services.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.initiatives i
     JOIN public.workspace_users wu ON ((wu.workspace_id = i.workspace_id)))
  WHERE ((i.id = initiative_it_services.initiative_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: initiatives Editors can update initiatives in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update initiatives in current namespace" ON public.initiatives FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = initiatives.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR ((workspace_id IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = initiatives.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))));


--
-- Name: integration_contacts Editors can update integration_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update integration_contacts in current namespace" ON public.integration_contacts FOR UPDATE USING (((integration_id IN ( SELECT ai.id
   FROM ((public.application_integrations ai
     JOIN public.applications a ON ((a.id = ai.source_application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id())))) WITH CHECK (((integration_id IN ( SELECT ai.id
   FROM ((public.application_integrations ai
     JOIN public.applications a ON ((a.id = ai.source_application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()))));


--
-- Name: organizations Editors can update organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update organizations in current namespace" ON public.organizations FOR UPDATE USING (((owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR ((is_shared = true) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id)))) WITH CHECK (((owner_workspace_id IN ( SELECT w.id
   FROM (public.workspaces w
     JOIN public.workspace_users wu ON ((wu.workspace_id = w.id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))) OR ((is_shared = true) AND (namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: portfolio_assignments Editors can update portfolio_assignments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update portfolio_assignments in current namespace" ON public.portfolio_assignments FOR UPDATE USING (((portfolio_id IN ( SELECT p.id
   FROM (public.portfolios p
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.portfolios p
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((p.id = portfolio_assignments.portfolio_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((portfolio_id IN ( SELECT p.id
   FROM (public.portfolios p
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.portfolios p
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((p.id = portfolio_assignments.portfolio_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: portfolios Editors can update portfolios in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update portfolios in current namespace" ON public.portfolios FOR UPDATE USING (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = portfolios.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = portfolios.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: program_initiatives Editors can update program_initiatives; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update program_initiatives" ON public.program_initiatives FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_initiatives.program_id) AND (p.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(p.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = p.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_initiatives.program_id) AND (p.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(p.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.workspace_id = p.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: programs Editors can update programs in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update programs in current namespace" ON public.programs FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = programs.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id) OR (EXISTS ( SELECT 1
   FROM public.workspace_users wu
  WHERE ((wu.workspace_id = programs.workspace_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: technical_assessments Editors can update technical_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update technical_assessments in current namespace" ON public.technical_assessments FOR UPDATE USING (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = technical_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM (public.applications a
     JOIN public.workspace_users wu ON ((wu.workspace_id = a.workspace_id)))
  WHERE ((a.id = technical_assessments.application_id) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workflow_instances Editors can update workflow_instances in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Editors can update workflow_instances in current namespace" ON public.workflow_instances FOR UPDATE USING ((workflow_definition_id IN ( SELECT wd.id
   FROM public.workflow_definitions wd
  WHERE ((wd.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(wd.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))))) WITH CHECK ((workflow_definition_id IN ( SELECT wd.id
   FROM public.workflow_definitions wd
  WHERE ((wd.namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(wd.namespace_id) OR (EXISTS ( SELECT 1
           FROM public.workspace_users wu
          WHERE ((wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))))));


--
-- Name: workspace_users Namespace admins can add workspace members in their namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can add workspace members in their namespace" ON public.workspace_users FOR INSERT WITH CHECK (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM public.workspaces w
  WHERE ((w.id = workspace_users.workspace_id) AND public.check_is_namespace_admin_of_namespace(w.namespace_id)))))));


--
-- Name: workspaces Namespace admins can create workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can create workspaces in current namespace" ON public.workspaces FOR INSERT WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: workspaces Namespace admins can delete workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can delete workspaces in current namespace" ON public.workspaces FOR DELETE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: workspace_users Namespace admins can remove workspace members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can remove workspace members" ON public.workspace_users FOR DELETE USING (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM public.workspaces w
  WHERE ((w.id = workspace_users.workspace_id) AND public.check_is_namespace_admin_of_namespace(w.namespace_id)))))));


--
-- Name: workspace_users Namespace admins can update workspace members; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can update workspace members" ON public.workspace_users FOR UPDATE USING (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM public.workspaces w
  WHERE ((w.id = workspace_users.workspace_id) AND public.check_is_namespace_admin_of_namespace(w.namespace_id))))))) WITH CHECK (((workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM public.workspaces w
  WHERE ((w.id = workspace_users.workspace_id) AND public.check_is_namespace_admin_of_namespace(w.namespace_id)))))));


--
-- Name: workspaces Namespace admins can update workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can update workspaces in current namespace" ON public.workspaces FOR UPDATE USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id)))) WITH CHECK (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: workspace_users Namespace admins can view all workspace members in their namesp; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Namespace admins can view all workspace members in their namesp" ON public.workspace_users FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.workspaces w
  WHERE ((w.id = workspace_users.workspace_id) AND public.check_is_namespace_admin_of_namespace(w.namespace_id)))));


--
-- Name: audit_logs Platform admins can delete audit logs for retention; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete audit logs for retention" ON public.audit_logs FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: namespaces Platform admins can delete namespaces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete namespaces" ON public.namespaces FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: platform_admins Platform admins can delete platform_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete platform_admins" ON public.platform_admins FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: portfolio_settings Platform admins can delete portfolio_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete portfolio_settings" ON public.portfolio_settings FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: remediation_efforts Platform admins can delete remediation_efforts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete remediation_efforts" ON public.remediation_efforts FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: service_type_categories Platform admins can delete service_type_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete service_type_categories" ON public.service_type_categories FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: service_types Platform admins can delete service_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete service_types" ON public.service_types FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: software_product_categories Platform admins can delete software_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete software_product_categories" ON public.software_product_categories FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: technology_lifecycle_reference Platform admins can delete technology_lifecycle_reference; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete technology_lifecycle_reference" ON public.technology_lifecycle_reference FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: technology_product_categories Platform admins can delete technology_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete technology_product_categories" ON public.technology_product_categories FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: users Platform admins can delete users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete users" ON public.users FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: vendor_lifecycle_sources Platform admins can delete vendor_lifecycle_sources; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can delete vendor_lifecycle_sources" ON public.vendor_lifecycle_sources FOR DELETE USING (public.check_is_platform_admin());


--
-- Name: namespaces Platform admins can insert namespaces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert namespaces" ON public.namespaces FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: platform_admins Platform admins can insert platform_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert platform_admins" ON public.platform_admins FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: portfolio_settings Platform admins can insert portfolio_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert portfolio_settings" ON public.portfolio_settings FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: remediation_efforts Platform admins can insert remediation_efforts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert remediation_efforts" ON public.remediation_efforts FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: service_type_categories Platform admins can insert service_type_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert service_type_categories" ON public.service_type_categories FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: service_types Platform admins can insert service_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert service_types" ON public.service_types FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: software_product_categories Platform admins can insert software_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert software_product_categories" ON public.software_product_categories FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: technology_lifecycle_reference Platform admins can insert technology_lifecycle_reference; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert technology_lifecycle_reference" ON public.technology_lifecycle_reference FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: technology_product_categories Platform admins can insert technology_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert technology_product_categories" ON public.technology_product_categories FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: users Platform admins can insert users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert users" ON public.users FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: vendor_lifecycle_sources Platform admins can insert vendor_lifecycle_sources; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can insert vendor_lifecycle_sources" ON public.vendor_lifecycle_sources FOR INSERT WITH CHECK (public.check_is_platform_admin());


--
-- Name: criticality_types Platform admins can manage criticality_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage criticality_types" ON public.criticality_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: data_classification_types Platform admins can manage data_classification_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage data_classification_types" ON public.data_classification_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: data_format_types Platform admins can manage data_format_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage data_format_types" ON public.data_format_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: data_tag_types Platform admins can manage data_tag_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage data_tag_types" ON public.data_tag_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: integration_direction_types Platform admins can manage integration_direction_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage integration_direction_types" ON public.integration_direction_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: integration_frequency_types Platform admins can manage integration_frequency_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage integration_frequency_types" ON public.integration_frequency_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: integration_method_types Platform admins can manage integration_method_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage integration_method_types" ON public.integration_method_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: integration_status_types Platform admins can manage integration_status_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage integration_status_types" ON public.integration_status_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: sensitivity_types Platform admins can manage sensitivity_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can manage sensitivity_types" ON public.sensitivity_types USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: platform_admins Platform admins can update platform_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update platform_admins" ON public.platform_admins FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: portfolio_settings Platform admins can update portfolio_settings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update portfolio_settings" ON public.portfolio_settings FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: remediation_efforts Platform admins can update remediation_efforts; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update remediation_efforts" ON public.remediation_efforts FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: service_type_categories Platform admins can update service_type_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update service_type_categories" ON public.service_type_categories FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: service_types Platform admins can update service_types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update service_types" ON public.service_types FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: software_product_categories Platform admins can update software_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update software_product_categories" ON public.software_product_categories FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: technology_lifecycle_reference Platform admins can update technology_lifecycle_reference; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update technology_lifecycle_reference" ON public.technology_lifecycle_reference FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: technology_product_categories Platform admins can update technology_product_categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update technology_product_categories" ON public.technology_product_categories FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: vendor_lifecycle_sources Platform admins can update vendor_lifecycle_sources; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can update vendor_lifecycle_sources" ON public.vendor_lifecycle_sources FOR UPDATE USING (public.check_is_platform_admin()) WITH CHECK (public.check_is_platform_admin());


--
-- Name: platform_admins Platform admins can view platform_admins; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Platform admins can view platform_admins" ON public.platform_admins FOR SELECT USING (public.check_is_platform_admin());


--
-- Name: workspace_group_publications Publishers can delete workspace_group_publications in current n; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Publishers can delete workspace_group_publications in current n" ON public.workspace_group_publications FOR DELETE USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = workspace_group_publications.deployment_profile_id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workspace_group_publications Publishers can insert workspace_group_publications in current n; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Publishers can insert workspace_group_publications in current n" ON public.workspace_group_publications FOR INSERT WITH CHECK (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = workspace_group_publications.deployment_profile_id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: applications Publishers can update applications in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Publishers can update applications in current namespace" ON public.applications FOR UPDATE USING (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id IN ( SELECT deployment_profiles.id
           FROM public.deployment_profiles
          WHERE (deployment_profiles.application_id = applications.id))) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR public.check_is_namespace_admin_of_namespace(public.get_current_namespace_id()) OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id IN ( SELECT deployment_profiles.id
           FROM public.deployment_profiles
          WHERE (deployment_profiles.application_id = applications.id))) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: workspace_group_publications Publishers can update workspace_group_publications in current n; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Publishers can update workspace_group_publications in current n" ON public.workspace_group_publications FOR UPDATE USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = workspace_group_publications.deployment_profile_id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text])))))))) WITH CHECK (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (EXISTS ( SELECT 1
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspace_users wu ON ((wu.workspace_id = p.workspace_id)))
  WHERE ((pa.deployment_profile_id = workspace_group_publications.deployment_profile_id) AND (pa.relationship_type = 'publisher'::text) AND (wu.user_id = auth.uid()) AND (wu.role = ANY (ARRAY['admin'::text, 'editor'::text]))))))));


--
-- Name: audit_logs Service role can insert audit logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Service role can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (true);


--
-- Name: notifications System can insert notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK ((public.check_is_platform_admin() OR (user_id = auth.uid())));


--
-- Name: notifications Users can delete own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (((user_id = auth.uid()) OR public.check_is_platform_admin()));


--
-- Name: user_sessions Users can insert own session; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own session" ON public.user_sessions FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: notifications Users can update own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (((user_id = auth.uid()) OR public.check_is_platform_admin())) WITH CHECK (((user_id = auth.uid()) OR public.check_is_platform_admin()));


--
-- Name: users Users can update own profile or admins can update namespace use; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile or admins can update namespace use" ON public.users FOR UPDATE USING (((id = auth.uid()) OR public.check_is_platform_admin() OR (id IN ( SELECT DISTINCT wu.user_id
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(w.namespace_id)))))) WITH CHECK (((id = auth.uid()) OR public.check_is_platform_admin() OR (id IN ( SELECT DISTINCT wu.user_id
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND public.check_is_namespace_admin_of_namespace(w.namespace_id))))));


--
-- Name: user_sessions Users can update own session; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own session" ON public.user_sessions FOR UPDATE USING ((auth.uid() = user_id));


--
-- Name: deployment_profile_it_services Users can view DP IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view DP IT services in current namespace" ON public.deployment_profile_it_services FOR SELECT USING ((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: deployment_profile_contacts Users can view DP contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view DP contacts in current namespace" ON public.deployment_profile_contacts FOR SELECT USING ((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: deployment_profile_software_products Users can view DP software products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view DP software products in current namespace" ON public.deployment_profile_software_products FOR SELECT USING ((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: deployment_profile_technology_products Users can view DP technology products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view DP technology products in current namespace" ON public.deployment_profile_technology_products FOR SELECT USING ((deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: it_service_providers Users can view IT service providers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view IT service providers in current namespace" ON public.it_service_providers FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: it_services Users can view IT services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view IT services in current namespace" ON public.it_services FOR SELECT USING ((owner_workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: namespaces Users can view accessible namespaces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view accessible namespaces" ON public.namespaces FOR SELECT USING ((public.check_is_platform_admin() OR (id = public.get_current_namespace_id()) OR (id IN ( SELECT namespace_users.namespace_id
   FROM public.namespace_users
  WHERE (namespace_users.user_id = auth.uid())))));


--
-- Name: users Users can view accessible users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view accessible users" ON public.users FOR SELECT USING (((id = auth.uid()) OR public.check_is_platform_admin() OR (id IN ( SELECT DISTINCT wu.user_id
   FROM (public.workspace_users wu
     JOIN public.workspaces w ON ((w.id = wu.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id())))));


--
-- Name: alert_preferences Users can view alert_preferences in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view alert_preferences in current namespace" ON public.alert_preferences FOR SELECT USING ((((namespace_id IS NOT NULL) AND (namespace_id = public.get_current_namespace_id())) OR ((workspace_id IS NOT NULL) AND (workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))))));


--
-- Name: application_contacts Users can view application contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application contacts in current namespace" ON public.application_contacts FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: application_services Users can view application services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application services in current namespace" ON public.application_services FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: application_compliance Users can view application_compliance in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application_compliance in current namespace" ON public.application_compliance FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: application_data_assets Users can view application_data_assets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application_data_assets in current namespace" ON public.application_data_assets FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: application_documents Users can view application_documents in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application_documents in current namespace" ON public.application_documents FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: application_integrations Users can view application_integrations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application_integrations in current namespace" ON public.application_integrations FOR SELECT USING ((((source_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) AND ((target_application_id IS NULL) OR (target_application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))))) OR public.check_is_platform_admin()));


--
-- Name: application_roadmap Users can view application_roadmap in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view application_roadmap in current namespace" ON public.application_roadmap FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: applications Users can view applications in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view applications in current namespace" ON public.applications FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: assessment_factor_options Users can view assessment_factor_options in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view assessment_factor_options in current namespace" ON public.assessment_factor_options FOR SELECT USING ((factor_id IN ( SELECT assessment_factors.id
   FROM public.assessment_factors
  WHERE (assessment_factors.namespace_id = public.get_current_namespace_id()))));


--
-- Name: assessment_factors Users can view assessment_factors in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view assessment_factors in current namespace" ON public.assessment_factors FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: assessment_history Users can view assessment_history in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view assessment_history in current namespace" ON public.assessment_history FOR SELECT USING ((portfolio_assignment_id IN ( SELECT pa.id
   FROM ((public.portfolio_assignments pa
     JOIN public.portfolios p ON ((p.id = pa.portfolio_id)))
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: assessment_thresholds Users can view assessment_thresholds in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view assessment_thresholds in current namespace" ON public.assessment_thresholds FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: audit_logs Users can view audit logs in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view audit logs in current namespace" ON public.audit_logs FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: budget_transfers Users can view budget_transfers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view budget_transfers in current namespace" ON public.budget_transfers FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: business_assessments Users can view business_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view business_assessments in current namespace" ON public.business_assessments FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: contact_organizations Users can view contact organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view contact organizations in current namespace" ON public.contact_organizations FOR SELECT USING ((contact_id IN ( SELECT contacts.id
   FROM public.contacts
  WHERE (contacts.namespace_id = public.get_current_namespace_id()))));


--
-- Name: contacts Users can view contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view contacts in current namespace" ON public.contacts FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: custom_field_definitions Users can view custom_field_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view custom_field_definitions in current namespace" ON public.custom_field_definitions FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: custom_field_values Users can view custom_field_values in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view custom_field_values in current namespace" ON public.custom_field_values FOR SELECT USING (((field_definition_id IN ( SELECT custom_field_definitions.id
   FROM public.custom_field_definitions
  WHERE (custom_field_definitions.namespace_id = public.get_current_namespace_id()))) AND (((entity_type = 'application'::text) AND (entity_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'deployment_profile'::text) AND (entity_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'contact'::text) AND (entity_id IN ( SELECT c.id
   FROM (public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'it_service'::text) AND (entity_id IN ( SELECT its.id
   FROM public.it_services its
  WHERE (its.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'software_product'::text) AND (entity_id IN ( SELECT sp.id
   FROM public.software_products sp
  WHERE (sp.namespace_id = public.get_current_namespace_id())))) OR ((entity_type = 'organization'::text) AND (entity_id IN ( SELECT o.id
   FROM public.organizations o
  WHERE (o.namespace_id = public.get_current_namespace_id())))))));


--
-- Name: data_centers Users can view data_centers in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view data_centers in current namespace" ON public.data_centers FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: deployment_profiles Users can view deployment profiles in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view deployment profiles in current namespace" ON public.deployment_profiles FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: findings Users can view findings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view findings in current namespace" ON public.findings FOR SELECT USING ((((namespace_id = public.get_current_namespace_id()) AND ((workspace_id IS NULL) OR (workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))))) OR public.check_is_platform_admin()));


--
-- Name: ideas Users can view ideas in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view ideas in current namespace" ON public.ideas FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: individuals Users can view individuals in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view individuals in current namespace" ON public.individuals FOR SELECT USING (((id IN ( SELECT c.individual_id
   FROM (public.contacts c
     JOIN public.workspaces w ON ((w.id = c.primary_workspace_id)))
  WHERE ((w.namespace_id = public.get_current_namespace_id()) AND (c.individual_id IS NOT NULL)))) OR (id = ( SELECT users.individual_id
   FROM public.users
  WHERE (users.id = auth.uid()))) OR public.check_is_platform_admin()));


--
-- Name: initiative_dependencies Users can view initiative_dependencies via initiative namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view initiative_dependencies via initiative namespace" ON public.initiative_dependencies FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.initiatives i
  WHERE ((i.id = initiative_dependencies.source_initiative_id) AND ((i.namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin())))));


--
-- Name: initiative_deployment_profiles Users can view initiative_deployment_profiles in current namesp; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view initiative_deployment_profiles in current namesp" ON public.initiative_deployment_profiles FOR SELECT USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) OR public.check_is_platform_admin()));


--
-- Name: initiative_it_services Users can view initiative_it_services in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view initiative_it_services in current namespace" ON public.initiative_it_services FOR SELECT USING (((initiative_id IN ( SELECT initiatives.id
   FROM public.initiatives
  WHERE (initiatives.namespace_id = public.get_current_namespace_id()))) OR public.check_is_platform_admin()));


--
-- Name: initiatives Users can view initiatives in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view initiatives in current namespace" ON public.initiatives FOR SELECT USING ((((namespace_id = public.get_current_namespace_id()) AND ((workspace_id IS NULL) OR (workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))))) OR public.check_is_platform_admin()));


--
-- Name: integration_contacts Users can view integration_contacts in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view integration_contacts in current namespace" ON public.integration_contacts FOR SELECT USING (((integration_id IN ( SELECT ai.id
   FROM ((public.application_integrations ai
     JOIN public.applications a ON ((a.id = ai.source_application_id)))
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))) OR public.check_is_platform_admin()));


--
-- Name: notification_rules Users can view notification_rules in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view notification_rules in current namespace" ON public.notification_rules FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: organization_settings Users can view organization_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view organization_settings in current namespace" ON public.organization_settings FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: organizations Users can view organizations in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view organizations in current namespace" ON public.organizations FOR SELECT USING (((owner_workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) OR ((is_shared = true) AND (namespace_id = public.get_current_namespace_id()))));


--
-- Name: notifications Users can view own notifications; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (((user_id = auth.uid()) OR public.check_is_platform_admin()));


--
-- Name: user_sessions Users can view own session; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own session" ON public.user_sessions FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: portfolio_assignments Users can view portfolio assignments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view portfolio assignments in current namespace" ON public.portfolio_assignments FOR SELECT USING ((portfolio_id IN ( SELECT p.id
   FROM (public.portfolios p
     JOIN public.workspaces w ON ((w.id = p.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: portfolios Users can view portfolios in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view portfolios in current namespace" ON public.portfolios FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: program_initiatives Users can view program_initiatives via program namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view program_initiatives via program namespace" ON public.program_initiatives FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.programs p
  WHERE ((p.id = program_initiatives.program_id) AND ((p.namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin())))));


--
-- Name: programs Users can view programs in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view programs in current namespace" ON public.programs FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: software_products Users can view software products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view software products in current namespace" ON public.software_products FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: technical_assessments Users can view technical_assessments in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view technical_assessments in current namespace" ON public.technical_assessments FOR SELECT USING ((application_id IN ( SELECT a.id
   FROM (public.applications a
     JOIN public.workspaces w ON ((w.id = a.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id()))));


--
-- Name: technology_products Users can view technology_products in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view technology_products in current namespace" ON public.technology_products FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: namespace_users Users can view their own namespace roles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own namespace roles" ON public.namespace_users FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: workflow_definitions Users can view workflow_definitions in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workflow_definitions in current namespace" ON public.workflow_definitions FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: workflow_instances Users can view workflow_instances in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workflow_instances in current namespace" ON public.workflow_instances FOR SELECT USING ((workflow_definition_id IN ( SELECT workflow_definitions.id
   FROM public.workflow_definitions
  WHERE (workflow_definitions.namespace_id = public.get_current_namespace_id()))));


--
-- Name: workspace_users Users can view workspace memberships in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace memberships in current namespace" ON public.workspace_users FOR SELECT USING (((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))) AND (public.check_is_platform_admin() OR (user_id = auth.uid()))));


--
-- Name: workspace_budgets Users can view workspace_budgets in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace_budgets in current namespace" ON public.workspace_budgets FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: workspace_group_members Users can view workspace_group_members in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace_group_members in current namespace" ON public.workspace_group_members FOR SELECT USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (workspace_id IN ( SELECT w.id
   FROM public.workspaces w
  WHERE (w.namespace_id = public.get_current_namespace_id())))));


--
-- Name: workspace_group_publications Users can view workspace_group_publications in current namespac; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace_group_publications in current namespac" ON public.workspace_group_publications FOR SELECT USING (((workspace_group_id IN ( SELECT wg.id
   FROM public.workspace_groups wg
  WHERE (wg.namespace_id = public.get_current_namespace_id()))) AND (deployment_profile_id IN ( SELECT dp.id
   FROM (public.deployment_profiles dp
     JOIN public.workspaces w ON ((w.id = dp.workspace_id)))
  WHERE (w.namespace_id = public.get_current_namespace_id())))));


--
-- Name: workspace_groups Users can view workspace_groups in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace_groups in current namespace" ON public.workspace_groups FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) OR public.check_is_platform_admin()));


--
-- Name: workspace_settings Users can view workspace_settings in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspace_settings in current namespace" ON public.workspace_settings FOR SELECT USING ((workspace_id IN ( SELECT workspaces.id
   FROM public.workspaces
  WHERE (workspaces.namespace_id = public.get_current_namespace_id()))));


--
-- Name: workspaces Users can view workspaces in current namespace; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view workspaces in current namespace" ON public.workspaces FOR SELECT USING (((namespace_id = public.get_current_namespace_id()) AND (public.check_is_platform_admin() OR public.check_is_workspace_member(id) OR public.check_is_namespace_admin_of_namespace(namespace_id))));


--
-- Name: alert_preferences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.alert_preferences ENABLE ROW LEVEL SECURITY;

--
-- Name: application_compliance; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_compliance ENABLE ROW LEVEL SECURITY;

--
-- Name: application_contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: application_data_assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_data_assets ENABLE ROW LEVEL SECURITY;

--
-- Name: application_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: application_integrations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_integrations ENABLE ROW LEVEL SECURITY;

--
-- Name: application_roadmap; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_roadmap ENABLE ROW LEVEL SECURITY;

--
-- Name: application_services; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.application_services ENABLE ROW LEVEL SECURITY;

--
-- Name: applications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

--
-- Name: assessment_factor_options; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assessment_factor_options ENABLE ROW LEVEL SECURITY;

--
-- Name: assessment_factors; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assessment_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: assessment_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assessment_history ENABLE ROW LEVEL SECURITY;

--
-- Name: assessment_thresholds; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.assessment_thresholds ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: budget_transfers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.budget_transfers ENABLE ROW LEVEL SECURITY;

--
-- Name: business_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.business_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: cloud_providers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cloud_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: contact_organizations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.contact_organizations ENABLE ROW LEVEL SECURITY;

--
-- Name: contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: countries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;

--
-- Name: criticality_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.criticality_types ENABLE ROW LEVEL SECURITY;

--
-- Name: custom_field_definitions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.custom_field_definitions ENABLE ROW LEVEL SECURITY;

--
-- Name: custom_field_values; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.custom_field_values ENABLE ROW LEVEL SECURITY;

--
-- Name: data_centers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.data_centers ENABLE ROW LEVEL SECURITY;

--
-- Name: data_classification_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.data_classification_types ENABLE ROW LEVEL SECURITY;

--
-- Name: data_format_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.data_format_types ENABLE ROW LEVEL SECURITY;

--
-- Name: data_tag_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.data_tag_types ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_profile_contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_profile_contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_profile_it_services; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_profile_it_services ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_profile_software_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_profile_software_products ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_profile_technology_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_profile_technology_products ENABLE ROW LEVEL SECURITY;

--
-- Name: deployment_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.deployment_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: dr_statuses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dr_statuses ENABLE ROW LEVEL SECURITY;

--
-- Name: environments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.environments ENABLE ROW LEVEL SECURITY;

--
-- Name: findings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.findings ENABLE ROW LEVEL SECURITY;

--
-- Name: hosting_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hosting_types ENABLE ROW LEVEL SECURITY;

--
-- Name: ideas; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ideas ENABLE ROW LEVEL SECURITY;

--
-- Name: individuals; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.individuals ENABLE ROW LEVEL SECURITY;

--
-- Name: initiative_dependencies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.initiative_dependencies ENABLE ROW LEVEL SECURITY;

--
-- Name: initiative_deployment_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.initiative_deployment_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: initiative_it_services; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.initiative_it_services ENABLE ROW LEVEL SECURITY;

--
-- Name: initiatives; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.initiatives ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_contacts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_contacts ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_direction_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_direction_types ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_frequency_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_frequency_types ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_method_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_method_types ENABLE ROW LEVEL SECURITY;

--
-- Name: integration_status_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.integration_status_types ENABLE ROW LEVEL SECURITY;

--
-- Name: invitation_workspaces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invitation_workspaces ENABLE ROW LEVEL SECURITY;

--
-- Name: invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: it_service_providers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.it_service_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: it_services; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.it_services ENABLE ROW LEVEL SECURITY;

--
-- Name: lifecycle_statuses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lifecycle_statuses ENABLE ROW LEVEL SECURITY;

--
-- Name: namespace_role_options; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.namespace_role_options ENABLE ROW LEVEL SECURITY;

--
-- Name: namespace_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.namespace_users ENABLE ROW LEVEL SECURITY;

--
-- Name: namespaces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.namespaces ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: operational_statuses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.operational_statuses ENABLE ROW LEVEL SECURITY;

--
-- Name: organization_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.organization_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: organizations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_admins; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_admins ENABLE ROW LEVEL SECURITY;

--
-- Name: portfolio_assignments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portfolio_assignments ENABLE ROW LEVEL SECURITY;

--
-- Name: portfolio_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portfolio_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: portfolios; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.portfolios ENABLE ROW LEVEL SECURITY;

--
-- Name: program_initiatives; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.program_initiatives ENABLE ROW LEVEL SECURITY;

--
-- Name: programs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

--
-- Name: remediation_efforts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.remediation_efforts ENABLE ROW LEVEL SECURITY;

--
-- Name: sensitivity_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sensitivity_types ENABLE ROW LEVEL SECURITY;

--
-- Name: service_type_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.service_type_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: service_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.service_types ENABLE ROW LEVEL SECURITY;

--
-- Name: software_product_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.software_product_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: software_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.software_products ENABLE ROW LEVEL SECURITY;

--
-- Name: standard_regions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.standard_regions ENABLE ROW LEVEL SECURITY;

--
-- Name: technical_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.technical_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: technology_lifecycle_reference; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.technology_lifecycle_reference ENABLE ROW LEVEL SECURITY;

--
-- Name: technology_product_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.technology_product_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: technology_products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.technology_products ENABLE ROW LEVEL SECURITY;

--
-- Name: user_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: vendor_lifecycle_sources; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.vendor_lifecycle_sources ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_definitions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workflow_definitions ENABLE ROW LEVEL SECURITY;

--
-- Name: workflow_instances; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workflow_instances ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_budgets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_budgets ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_group_members; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_group_members ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_group_publications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_group_publications ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_groups ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_role_options; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_role_options ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: workspace_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspace_users ENABLE ROW LEVEL SECURITY;

--
-- Name: workspaces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict yIjvezCuWFH4JHwC5XzYhqCHLCmI1IOugzEnaZugLTPnf28Xe0kfCe13q5Fzayt

