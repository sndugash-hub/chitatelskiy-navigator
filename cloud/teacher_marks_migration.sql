-- Читательский навигатор: оценки открытых ответов только учителем.
-- Вставить в Supabase SQL Editor и выполнить один раз.
-- Не меняет существующие ответы учащихся.
create table if not exists public.teacher_marks (
  user_id uuid not null references auth.users(id) on delete cascade,
  module_id integer not null check (module_id between 1 and 8),
  question_index integer not null check (question_index between 0 and 3),
  points integer not null check (points between 0 and 2),
  teacher_id uuid not null references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (user_id, module_id, question_index)
);

alter table public.teacher_marks enable row level security;
revoke all on public.teacher_marks from public, anon, authenticated;
grant select, insert, update on public.teacher_marks to authenticated;

drop policy if exists navigator_marks_read on public.teacher_marks;
create policy navigator_marks_read on public.teacher_marks for select to authenticated
using (user_id = (select auth.uid()) or public.is_navigator_teacher());

drop policy if exists navigator_marks_insert_teacher on public.teacher_marks;
create policy navigator_marks_insert_teacher on public.teacher_marks for insert to authenticated
with check (public.is_navigator_teacher() and teacher_id = (select auth.uid()));

drop policy if exists navigator_marks_update_teacher on public.teacher_marks;
create policy navigator_marks_update_teacher on public.teacher_marks for update to authenticated
using (public.is_navigator_teacher())
with check (public.is_navigator_teacher() and teacher_id = (select auth.uid()));
