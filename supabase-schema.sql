create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  project text not null,
  type text not null default '深度研究',
  status text not null default '待拆解'
    check (status in ('待拆解', '进行中', '等待', '待审核', '已完成')),
  duration integer not null default 45 check (duration >= 0),
  due_at timestamptz,
  followup_date date,
  location text not null default '',
  waiting_for text not null default '',
  notes text not null default '',
  is_today boolean not null default false,
  is_deep boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.tasks enable row level security;

revoke all on table public.tasks from anon;
grant select, insert, update, delete on table public.tasks to authenticated;

drop policy if exists "Users manage their own tasks" on public.tasks;
create policy "Users manage their own tasks"
on public.tasks
for all
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create or replace function public.set_tasks_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at
before update on public.tasks
for each row execute function public.set_tasks_updated_at();

create index if not exists tasks_user_updated_idx
on public.tasks (user_id, updated_at desc);
