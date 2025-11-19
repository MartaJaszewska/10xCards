-- migration: temporarily disable RLS for local/dev on core tables
-- WARNING: this removes per-user isolation; OK only while you are the sole user.

-- flashcards: disable row level security
alter table public.flashcards disable row level security;

-- generations: disable row level security
alter table public.generations disable row level security;

-- generation_error_logs: disable row level security
alter table public.generation_error_logs disable row level security;

-- end of migration: 20251119123000_disable_rls_for_local_dev.sql


