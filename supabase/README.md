# Supabase Backend Setup

This directory contains the database schema and migration scripts for TodoApp's cloud synchronization.

## Quick Setup Instructions

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard) and select your project.
2. In the left navigation bar, open the **SQL Editor**.
3. Create a **New query**.
4. Copy the entire contents of [`schema.sql`](./schema.sql) and paste them into the SQL Editor.
5. Click **Run** (or `Cmd + Enter` / `Ctrl + Enter`).

## What this creates:
- `public.tasks`: The main table storing all task data with millisecond timestamps (`bigint`), JSON subtasks, categories, focus statistics, and recurrence metadata.
- **Foreign Key Constraint**: `user_id uuid references auth.users(id) on delete cascade` ensuring that tasks are tied to authenticated Supabase accounts.
- **Indexes**: Fast indexing on `user_id` and composite `(user_id, updated_at)` for incremental delta synchronization.
- **Row Level Security (RLS)**: Strict security policies ensuring each authenticated user can only view, insert, edit, and delete their own tasks.
