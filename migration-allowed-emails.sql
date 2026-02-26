-- ============================================
-- Migration: Add allowed_emails table + tighten RLS
-- Run this in Supabase SQL Editor if you
-- already ran the original supabase-setup.sql
-- ============================================

-- 1. Create the allowed_emails table
create table if not exists public.allowed_emails (
  email text primary key,
  added_at timestamptz default now()
);

alter table public.allowed_emails enable row level security;

create policy "Anyone can check allowed emails"
  on public.allowed_emails for select
  using (true);

-- 2. Drop old permissive insert policies
drop policy if exists "Users can insert their own profile" on public.members;
drop policy if exists "Authenticated users can insert projects" on public.projects;
drop policy if exists "Authenticated users can upload avatars" on storage.objects;
drop policy if exists "Authenticated users can upload project images" on storage.objects;

-- 3. Recreate with allowed_emails check
create policy "Users can insert their own profile"
  on public.members for insert
  with check (
    auth.uid() = id
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

create policy "Authenticated users can insert projects"
  on public.projects for insert
  with check (
    auth.uid() = member_id
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

create policy "Authenticated users can upload avatars"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

create policy "Authenticated users can upload project images"
  on storage.objects for insert
  with check (
    bucket_id = 'project-images'
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

-- 4. Add project_url column to projects
alter table public.projects add column if not exists project_url text;

-- 5. Add your friends' emails here!
-- insert into public.allowed_emails (email) values
--   ('friend1@gmail.com'),
--   ('friend2@gmail.com'),
--   ('friend3@gmail.com');
