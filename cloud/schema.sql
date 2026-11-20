-- Читательский навигатор: защищённое хранение результатов.
-- Запустите в SQL Editor вашего проекта Supabase один раз.
-- ПЕРЕД применением заполните список учителей ниже отдельной инструкцией.
create table if not exists public.teacher_access (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.student_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 120),
  class_name text not null default '8' check (char_length(class_name) between 1 and 24),
  updated_at timestamptz not null default now()
);
create table if not exists public.student_results (
  user_id uuid not null references auth.users(id) on delete cascade,
  module_id int not null check (module_id between 1 and 8),
  score int not null default 0 check (score between 0 and 6),
  evaluated_count int not null default 0 check (evaluated_count between 0 and 4),
  checked_answers jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id,module_id)
);

alter table public.teacher_access enable row level security;
alter table public.student_profiles enable row level security;
alter table public.student_results enable row level security;

-- Учителя добавляются исключительно владельцем проекта через SQL Editor.
-- Рядовые пользователи не могут назначить себя учителями.
create or replace function public.is_navigator_teacher()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists(select 1 from public.teacher_access where user_id = (select auth.uid()));
$$;
revoke all on function public.is_navigator_teacher() from public;
grant execute on function public.is_navigator_teacher() to authenticated;

drop policy if exists teacher_check_self on public.teacher_access;
create policy teacher_check_self on public.teacher_access
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists student_profile_self_read on public.student_profiles;
create policy student_profile_self_read on public.student_profiles
  for select to authenticated using (user_id = (select auth.uid()) or public.is_navigator_teacher());
drop policy if exists student_profile_self_insert on public.student_profiles;
create policy student_profile_self_insert on public.student_profiles
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists student_profile_self_update on public.student_profiles;
create policy student_profile_self_update on public.student_profiles
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists result_read on public.student_results;
create policy result_read on public.student_results
  for select to authenticated using (user_id = (select auth.uid()) or public.is_navigator_teacher());
drop policy if exists result_insert on public.student_results;
create policy result_insert on public.student_results
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists result_update on public.student_results;
create policy result_update on public.student_results
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.teacher_access from anon, authenticated;
revoke all on public.student_profiles from anon, authenticated;
revoke all on public.student_results from anon, authenticated;
grant select on public.teacher_access to authenticated;
grant select,insert,update on public.student_profiles to authenticated;
grant select,insert,update on public.student_results to authenticated;

-- ПОСЛЕ регистрации учителя в Supabase Auth внесите его UUID самостоятельно:
-- insert into public.teacher_access(user_id) values ('UUID-УЧИТЕЛЯ');
-- Никогда не сохраняйте пароль или service_role / secret key в публичном GitHub.
