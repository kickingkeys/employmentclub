-- ============================================
-- Migration: Add social links to members
-- Run this in Supabase SQL Editor if you
-- already ran the original supabase-setup.sql
-- ============================================

alter table public.members add column if not exists twitter text;
alter table public.members add column if not exists instagram text;
alter table public.members add column if not exists linkedin text;
alter table public.members add column if not exists github text;
