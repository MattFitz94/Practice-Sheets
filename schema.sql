-- ============================================================
--  GOLF PRACTICE APP — DATABASE SCHEMA
--  Paste this whole file into Supabase → SQL Editor → Run.
--  It creates every table, the coach/player link, and the
--  security rules that decide who can see and change what.
-- ============================================================

-- 1. PROFILES ------------------------------------------------
-- One row per user. Created automatically when someone signs up.
-- 'role' is either 'coach' or 'player'.
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  role text not null default 'player' check (role in ('coach','player')),
  created_at timestamptz default now()
);

-- 2. COACH ↔ PLAYER LINKS ------------------------------------
-- Connects a coach to each player they work with.
-- One coach can have many players; a player can have many coaches.
create table coach_players (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references profiles(id) on delete cascade,
  player_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique (coach_id, player_id)
);

-- 3. DRILL LIBRARY -------------------------------------------
-- The shared list of drills. 'owner_id' is the coach who added it.
-- 'goal' holds the pass criteria, e.g. '70% or more inside 5%'.
create table drills (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references profiles(id) on delete set null,
  name text not null,
  category text not null,     -- Driving, Approach, Putting, Short Game, Performance, etc.
  default_club text,          -- these 'default_*' + distance/why are the VLOOKUP source:
  default_minutes numeric,    -- picking the drill in the grid fills these into the row
  default_balls int,
  distance text,              -- e.g. '125-175'
  default_mental numeric,     -- 1-10
  default_physical numeric,   -- 1-10
  why text,                   -- e.g. 'Performance', 'Technique'
  goal text,                  -- pass/fail criteria
  created_at timestamptz default now()
);

-- 4. ASSIGNMENTS ---------------------------------------------
-- A coach assigning a drill to a player for a given day.
create table assignments (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references profiles(id) on delete cascade,
  player_id uuid not null references profiles(id) on delete cascade,
  drill_id uuid not null references drills(id) on delete cascade,
  day date not null,
  target_balls int,
  note text,
  created_at timestamptz default now()
);

-- 5. SESSION ROWS (the day grid) -----------------------------
-- One row per drill line in a player's day — this IS the
-- spreadsheet grid. A coach can seed rows for a player; the
-- player fills in results, ticks 'completed', and adds notes.
create table sessions (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references profiles(id) on delete cascade,
  created_by uuid references profiles(id) on delete set null, -- coach or player who added the row
  drill_id uuid references drills(id) on delete set null,
  logged_on date not null default current_date,   -- the day this row belongs to
  sort int default 0,                             -- row order within the day
  -- editable result columns (default from the drill, overwritten by actuals):
  minutes numeric default 0,
  balls int default 0,
  distance text,
  mental numeric,             -- 1-10
  physical numeric,           -- 1-10
  -- player-only columns:
  completed boolean default false,
  completed_notes text,
  -- shared free-text:
  notes text,
  created_at timestamptz default now()
);
create index sessions_player_day on sessions (player_id, logged_on);

-- ============================================================
--  SECURITY (Row Level Security)
--  Turns on per-row permissions so each person only touches
--  their own data. Without this, everyone could read everything.
-- ============================================================

alter table profiles      enable row level security;
alter table coach_players enable row level security;
alter table drills        enable row level security;
alter table assignments   enable row level security;
alter table sessions      enable row level security;

-- Everyone can read their own profile and profiles they're linked to.
create policy "read own profile" on profiles
  for select using ( auth.uid() = id
    or id in (select player_id from coach_players where coach_id = auth.uid())
    or id in (select coach_id  from coach_players where player_id = auth.uid()) );

create policy "update own profile" on profiles
  for update using ( auth.uid() = id );

create policy "insert own profile" on profiles
  for insert with check ( auth.uid() = id );

-- Coaches manage their own coach-player links.
create policy "coach manages links" on coach_players
  for all using ( auth.uid() = coach_id ) with check ( auth.uid() = coach_id );
create policy "player sees own links" on coach_players
  for select using ( auth.uid() = player_id );

-- Drills: anyone linked can read; the owning coach can add/edit/delete.
create policy "read drills" on drills
  for select using ( true );
create policy "coach writes own drills" on drills
  for all using ( auth.uid() = owner_id ) with check ( auth.uid() = owner_id );

-- Assignments: coach manages theirs; player reads what's assigned to them.
create policy "coach manages assignments" on assignments
  for all using ( auth.uid() = coach_id ) with check ( auth.uid() = coach_id );
create policy "player reads assignments" on assignments
  for select using ( auth.uid() = player_id );

-- Sessions: player owns their own rows; their coaches can read
-- AND write rows for them (so the coach can seed the day grid).
create policy "player manages own sessions" on sessions
  for all using ( auth.uid() = player_id ) with check ( auth.uid() = player_id );
create policy "coach reads player sessions" on sessions
  for select using (
    player_id in (select player_id from coach_players where coach_id = auth.uid())
  );
create policy "coach writes player sessions" on sessions
  for insert with check (
    player_id in (select player_id from coach_players where coach_id = auth.uid())
  );
create policy "coach edits player sessions" on sessions
  for update using (
    player_id in (select player_id from coach_players where coach_id = auth.uid())
  );
create policy "coach deletes player sessions" on sessions
  for delete using (
    player_id in (select player_id from coach_players where coach_id = auth.uid())
  );

-- ============================================================
--  AUTO-CREATE A PROFILE WHEN SOMEONE SIGNS UP
-- ============================================================
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, full_name, role)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', new.email),
          coalesce(new.raw_user_meta_data->>'role', 'player'));
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ============================================================
--  HELPER: find a player's profile id by their email
--  Lets a coach link a player by typing their email, without
--  being able to read the whole user table.
-- ============================================================
create or replace function find_profile_by_email(e text)
returns uuid language sql security definer as $$
  select u.id from auth.users u where lower(u.email) = lower(e) limit 1;
$$;
