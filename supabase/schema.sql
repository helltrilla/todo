-- ==============================================================================
-- TodoApp Supabase Database Schema
-- ==============================================================================
-- Run this script in your Supabase project's SQL Editor (Dashboard -> SQL Editor)
-- to create the tasks table and setup Row Level Security (RLS).
-- ==============================================================================

-- 1. Create Tasks Table
create table if not exists public.tasks (
  id bigint primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  value text default '',
  created_at bigint not null,
  due_date bigint,
  completed_at bigint,
  reminder_offset_minutes integer,
  priority_index integer default -1,
  is_completed boolean default false,
  is_archived boolean default false,
  is_pinned boolean default false,
  category text default 'Personal',
  subtasks jsonb default '[]'::jsonb,
  recurrence text default 'none',
  has_spawned_next boolean default false,
  pomodoro_count integer default 0,
  focus_minutes integer default 0,
  updated_at bigint not null
);

-- 2. Indexes for fast lookups & syncing
create index if not exists idx_tasks_user_id on public.tasks(user_id);
create index if not exists idx_tasks_updated_at on public.tasks(user_id, updated_at);

-- 3. Enable Row Level Security (RLS)
alter table public.tasks enable row level security;

-- 4. Policies: Strict isolation per authenticated user
drop policy if exists "Users can select own tasks" on public.tasks;
create policy "Users can select own tasks"
  on public.tasks for select
  using (auth.uid() = user_id);

drop policy if exists "Users can insert own tasks" on public.tasks;
create policy "Users can insert own tasks"
  on public.tasks for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can update own tasks" on public.tasks;
create policy "Users can update own tasks"
  on public.tasks for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can delete own tasks" on public.tasks;
create policy "Users can delete own tasks"
  on public.tasks for delete
  using (auth.uid() = user_id);
