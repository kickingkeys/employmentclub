-- ============================================
-- Employment Club — Supabase Setup
-- Run this in the Supabase SQL Editor
-- ============================================

-- 0. Allowed emails (invite-only access control)
create table if not exists public.allowed_emails (
  email text primary key,
  added_at timestamptz default now()
);

alter table public.allowed_emails enable row level security;

-- Anyone can check if their email is allowed (needed for frontend check)
create policy "Anyone can check allowed emails"
  on public.allowed_emails for select
  using (true);

-- 1. Members table (user profiles)
create table if not exists public.members (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  avatar_url text,
  twitter text,
  instagram text,
  linkedin text,
  github text,
  created_at timestamptz default now()
);

alter table public.members enable row level security;

create policy "Anyone can view members"
  on public.members for select
  using (true);

create policy "Users can insert their own profile"
  on public.members for insert
  with check (
    auth.uid() = id
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

create policy "Users can update their own profile"
  on public.members for update
  using (auth.uid() = id);

-- 2. Projects table
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  title text not null,
  description text,
  image_url text not null,
  project_url text,
  canvas_x integer default 0,
  canvas_y integer default 0,
  rotation float default 0,
  width integer default 250,
  created_at timestamptz default now()
);

alter table public.projects enable row level security;

create policy "Anyone can view projects"
  on public.projects for select
  using (true);

create policy "Authenticated users can insert projects"
  on public.projects for insert
  with check (
    auth.uid() = member_id
    and exists (
      select 1 from public.allowed_emails
      where email = auth.jwt()->>'email'
    )
  );

create policy "Users can update their own projects"
  on public.projects for update
  using (auth.uid() = member_id);

create policy "Users can delete their own projects"
  on public.projects for delete
  using (auth.uid() = member_id);

-- 3. Enable realtime on projects table
alter publication supabase_realtime add table public.projects;
alter publication supabase_realtime add table public.members;

-- 4. Storage buckets
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('project-images', 'project-images', true)
on conflict (id) do nothing;

-- Storage policies: anyone can read, authenticated can upload
create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

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

create policy "Users can update their own avatars"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Anyone can view project images"
  on storage.objects for select
  using (bucket_id = 'project-images');

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
