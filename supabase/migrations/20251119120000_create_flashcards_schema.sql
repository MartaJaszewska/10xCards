-- migration: create core tables for 10xcards (flashcards, generations, generation_error_logs)
-- purpose : initial domain schema for user-owned flashcards and ai generation tracking
-- notes   :
--   - all data is scoped to supabase auth users via foreign keys to auth.users(id)
--   - row level security (rls) is enabled and configured for each table
--   - policies are defined per-operation (select/insert/update/delete) for the "authenticated" role
--   - the "anon" role has no direct access to these tables
--   - destructive operations are intentionally omitted in this migration
--   - this migration is intended to be idempotent at the schema level when re-applied in a fresh database

-- ############################################################
-- # helper trigger function for updated_at maintenance
-- ############################################################

-- this trigger function sets the "updated_at" column to "now()" on every row update.
-- we define it in the public schema so it can be reused by multiple tables.
create or replace function public.set_updated_at_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;


-- ############################################################
-- # table: generations
-- ############################################################

-- this table stores metadata about successful ai flashcard generations per user.
-- each row corresponds to a single generation request and its aggregate stats.
create table if not exists public.generations (
  id                      bigserial primary key,

  -- owner of the generation; references supabase auth.users
  user_id                 uuid not null
                              references auth.users(id)
                              on delete cascade,

  -- model identifier used for this generation (e.g. "gpt-5.1", "openai-gpt4o-mini")
  model                   varchar not null,

  -- how many flashcards were generated in this run (regardless of later acceptance)
  generated_count         integer not null,

  -- how many generated flashcards were accepted without manual edits (nullable for legacy rows)
  accepted_unedited_count integer null,

  -- how many generated flashcards were accepted after manual edits (nullable for legacy rows)
  accepted_edited_count   integer null,

  -- hash of the source text used for generation (e.g. sha256 in hex)
  source_text_hash        varchar not null,

  -- length of the source text in characters; constrained to a safe range for this product
  source_text_length      integer not null
                              check (source_text_length between 1000 and 10000),

  -- total generation duration in milliseconds
  generation_duration     integer not null,

  -- timestamps
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

comment on table public.generations is
  'ai generation metadata; per-user tracking of flashcard generation requests and aggregate stats';

comment on column public.generations.user_id is
  'owner of the generation; references auth.users(id); rows are deleted when the user is deleted';

comment on column public.generations.model is
  'ai model used for this generation session; stored for analytics and debugging';

comment on column public.generations.generated_count is
  'number of flashcards generated in this session, regardless of later acceptance';

comment on column public.generations.accepted_unedited_count is
  'number of generated flashcards accepted without any user edits';

comment on column public.generations.accepted_edited_count is
  'number of generated flashcards accepted after user edits';

comment on column public.generations.source_text_hash is
  'hash of the source text used for generation; enables deduplication and analytics without storing raw text';

comment on column public.generations.source_text_length is
  'length of input text in characters; constrained between 1000 and 10000 for product assumptions';

comment on column public.generations.generation_duration is
  'duration of the ai generation process in milliseconds';

comment on column public.generations.created_at is
  'timestamp when the generation record was created';

comment on column public.generations.updated_at is
  'timestamp of the last modification of this generation record; maintained by trigger';


-- ############################################################
-- # table: generation_error_logs
-- ############################################################

-- this table stores error information for failed generation attempts.
-- it allows debugging and analytics without exposing sensitive data.
create table if not exists public.generation_error_logs (
  id                 bigserial primary key,

  -- owner of the generation attempt; references supabase auth.users
  user_id            uuid not null
                         references auth.users(id)
                         on delete cascade,

  -- model identifier used when the error occurred
  model              varchar not null,

  -- hash of the source text used for the failed generation
  source_text_hash   varchar not null,

  -- length of the source text in characters; constrained to a safe range
  source_text_length integer not null
                         check (source_text_length between 1000 and 10000),

  -- short machine-friendly error code (e.g. "validation_error", "provider_timeout")
  error_code         varchar(100) not null,

  -- human-readable error message, for diagnostics and support
  error_message      text not null,

  -- creation timestamp; records are append-only
  created_at         timestamptz not null default now()
);

comment on table public.generation_error_logs is
  'error logs for failed ai flashcard generation attempts; per-user, append-only';

comment on column public.generation_error_logs.user_id is
  'owner of the failed generation attempt; references auth.users(id); rows are deleted when the user is deleted';

comment on column public.generation_error_logs.model is
  'ai model used when the error occurred; useful for debugging model-specific issues';

comment on column public.generation_error_logs.source_text_hash is
  'hash of the source text that caused the error; avoids storing raw text while enabling diagnostics';

comment on column public.generation_error_logs.source_text_length is
  'length of the source text in characters for the failed request; constrained between 1000 and 10000';

comment on column public.generation_error_logs.error_code is
  'short, machine-friendly error code (e.g. validation_error, provider_timeout)';

comment on column public.generation_error_logs.error_message is
  'human-readable error message for support and debugging; may be shown in internal tooling';

comment on column public.generation_error_logs.created_at is
  'timestamp when the error log entry was created; records are append-only';


-- ############################################################
-- # table: flashcards
-- ############################################################

-- this table stores individual flashcards owned by users.
-- each flashcard may optionally be linked back to a generation record.
create table if not exists public.flashcards (
  id            bigserial primary key,

  -- card front (question / prompt); short for fast review
  front         varchar(200) not null,

  -- card back (answer / explanation); longer but still bounded
  back          varchar(500) not null,

  -- origin of the card: fully ai-generated, ai-generated but later edited, or fully manual
  source        varchar not null
                    check (source in ('ai-full', 'ai-edited', 'manual')),

  -- timestamps
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  -- optional link to the generation this card came from
  generation_id bigint null
                     references public.generations(id)
                     on delete set null,

  -- owner of the card; references supabase auth.users
  user_id       uuid not null
                     references auth.users(id)
                     on delete cascade
);

comment on table public.flashcards is
  'user-owned flashcards; each card optionally linked to an ai generation record';

comment on column public.flashcards.id is
  'primary key of the flashcard record';

comment on column public.flashcards.front is
  'front side of the flashcard (question/prompt); optimized for short, scannable text';

comment on column public.flashcards.back is
  'back side of the flashcard (answer/explanation); can be longer but is still bounded';

comment on column public.flashcards.source is
  'origin of the flashcard: ai-full, ai-edited, or manual; used for analytics and product decisions';

comment on column public.flashcards.created_at is
  'timestamp when the flashcard was created';

comment on column public.flashcards.updated_at is
  'timestamp of the last modification of this flashcard; maintained by trigger';

comment on column public.flashcards.generation_id is
  'optional reference to the ai generation that produced this flashcard; null for fully manual cards';

comment on column public.flashcards.user_id is
  'owner of the flashcard; references auth.users(id); rows are deleted when the user is deleted';


-- ############################################################
-- # indexes
-- ############################################################

-- indexes support efficient per-user queries and navigation from cards to generations.

-- user-based access pattern: "fetch all generations for user"
create index if not exists idx_generations_user_id
  on public.generations (user_id);

-- user-based access pattern: "fetch all error logs for user"
create index if not exists idx_generation_error_logs_user_id
  on public.generation_error_logs (user_id);

-- typical flashcard queries: "all cards for user", "cards for user + generation"
create index if not exists idx_flashcards_user_id
  on public.flashcards (user_id);

create index if not exists idx_flashcards_generation_id
  on public.flashcards (generation_id);


-- ############################################################
-- # triggers
-- ############################################################

-- trigger: automatically maintain updated_at on flashcards.
-- this ensures any update to a flashcard row bumps the updated_at timestamp, which is
-- useful for sync, conflict resolution, and "recently updated" views.
drop trigger if exists set_flashcards_updated_at on public.flashcards;

create trigger set_flashcards_updated_at
before update on public.flashcards
for each row
execute function public.set_updated_at_timestamp();

-- trigger: automatically maintain updated_at on generations.
-- this ensures any changes to generation metadata (e.g. corrected counts) update the audit timestamp.
drop trigger if exists set_generations_updated_at on public.generations;

create trigger set_generations_updated_at
before update on public.generations
for each row
execute function public.set_updated_at_timestamp();


-- ############################################################
-- # row level security (rls) configuration
-- ############################################################

-- all tables created in this migration are user-scoped and must enforce rls.
-- we enable rls and also force it, so even privileged roles cannot bypass it accidentally.

-- rls for public.generations
alter table public.generations enable row level security;
alter table public.generations force row level security;

-- rls for public.generation_error_logs
alter table public.generation_error_logs enable row level security;
alter table public.generation_error_logs force row level security;

-- rls for public.flashcards
alter table public.flashcards enable row level security;
alter table public.flashcards force row level security;


-- ############################################################
-- # rls policies: generations
-- ############################################################

-- policy model:
--   - one policy per operation (select, insert, update, delete)
--   - scoped to the "authenticated" role
--   - data access is strictly scoped to "user_id = auth.uid()"

-- select policies
drop policy if exists generations_select_authenticated on public.generations;

create policy generations_select_authenticated
on public.generations
as permissive
for select
to authenticated
using (user_id = auth.uid());

-- insert policies
drop policy if exists generations_insert_authenticated on public.generations;

create policy generations_insert_authenticated
on public.generations
as permissive
for insert
to authenticated
with check (user_id = auth.uid());

-- update policies
drop policy if exists generations_update_authenticated on public.generations;

create policy generations_update_authenticated
on public.generations
as permissive
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- delete policies
drop policy if exists generations_delete_authenticated on public.generations;

create policy generations_delete_authenticated
on public.generations
as permissive
for delete
to authenticated
using (user_id = auth.uid());


-- ############################################################
-- # rls policies: generation_error_logs
-- ############################################################

-- for error logs we use the same "user_id = auth.uid()" scoping.
-- this keeps diagnostic information strictly per-user and avoids cross-tenant leaks.

-- select policies
drop policy if exists generation_error_logs_select_authenticated on public.generation_error_logs;

create policy generation_error_logs_select_authenticated
on public.generation_error_logs
as permissive
for select
to authenticated
using (user_id = auth.uid());

-- insert policies
drop policy if exists generation_error_logs_insert_authenticated on public.generation_error_logs;

create policy generation_error_logs_insert_authenticated
on public.generation_error_logs
as permissive
for insert
to authenticated
with check (user_id = auth.uid());

-- update policies
drop policy if exists generation_error_logs_update_authenticated on public.generation_error_logs;

create policy generation_error_logs_update_authenticated
on public.generation_error_logs
as permissive
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- delete policies
drop policy if exists generation_error_logs_delete_authenticated on public.generation_error_logs;

create policy generation_error_logs_delete_authenticated
on public.generation_error_logs
as permissive
for delete
to authenticated
using (user_id = auth.uid());


-- ############################################################
-- # rls policies: flashcards
-- ############################################################

-- flashcards are the core user-owned resource.
-- access is strictly per-user; there is no cross-user sharing in the mvp.

-- select policies
drop policy if exists flashcards_select_authenticated on public.flashcards;

create policy flashcards_select_authenticated
on public.flashcards
as permissive
for select
to authenticated
using (user_id = auth.uid());

-- insert policies
drop policy if exists flashcards_insert_authenticated on public.flashcards;

create policy flashcards_insert_authenticated
on public.flashcards
as permissive
for insert
to authenticated
with check (user_id = auth.uid());

-- update policies
drop policy if exists flashcards_update_authenticated on public.flashcards;

create policy flashcards_update_authenticated
on public.flashcards
as permissive
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- delete policies
drop policy if exists flashcards_delete_authenticated on public.flashcards;

create policy flashcards_delete_authenticated
on public.flashcards
as permissive
for delete
to authenticated
using (user_id = auth.uid());


-- end of migration: 20251119120000_create_flashcards_schema.sql


