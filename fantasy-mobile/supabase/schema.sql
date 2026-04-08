create extension if not exists pgcrypto;

create table if not exists public.users_profile (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique,
    display_name text not null,
    avatar_url text,
    created_at timestamptz not null default now()
);

create table if not exists public.seasons (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    year integer not null,
    status text not null default 'upcoming',
    created_at timestamptz not null default now()
);

create table if not exists public.teams (
    id uuid primary key default gen_random_uuid(),
    external_key text unique,
    name text not null,
    short_name text,
    logo_url text,
    created_at timestamptz not null default now()
);

create table if not exists public.players (
    id uuid primary key default gen_random_uuid(),
    external_key text unique,
    team_id uuid references public.teams(id) on delete set null,
    full_name text not null,
    position text,
    bats text,
    throws text,
    status text not null default 'active',
    created_at timestamptz not null default now()
);

create table if not exists public.games (
    id uuid primary key default gen_random_uuid(),
    season_id uuid references public.seasons(id) on delete set null,
    external_key text unique,
    starts_at timestamptz,
    home_team_id uuid not null references public.teams(id) on delete restrict,
    away_team_id uuid not null references public.teams(id) on delete restrict,
    status text not null default 'scheduled',
    home_score integer,
    away_score integer,
    source_updated_at timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.player_game_stats (
    id uuid primary key default gen_random_uuid(),
    game_id uuid not null references public.games(id) on delete cascade,
    player_id uuid not null references public.players(id) on delete cascade,
    stat_line_json jsonb not null default '{}'::jsonb,
    fantasy_points_cached numeric(10, 2) not null default 0,
    updated_at timestamptz not null default now(),
    unique (game_id, player_id)
);

create table if not exists public.leagues (
    id uuid primary key default gen_random_uuid(),
    owner_user_id uuid not null references auth.users(id) on delete cascade,
    season_id uuid references public.seasons(id) on delete set null,
    name text not null,
    privacy text not null default 'private',
    invite_code text unique not null,
    scoring_type text not null default 'points',
    roster_config_json jsonb not null default '{}'::jsonb,
    draft_state text not null default 'pending',
    created_at timestamptz not null default now()
);

create table if not exists public.league_members (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null default 'member',
    joined_at timestamptz not null default now(),
    unique (league_id, user_id)
);

create table if not exists public.fantasy_teams (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    created_at timestamptz not null default now(),
    unique (league_id, user_id)
);

create table if not exists public.drafts (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    type text not null default 'snake',
    status text not null default 'scheduled',
    starts_at timestamptz,
    current_pick_number integer not null default 0,
    current_round integer not null default 1,
    created_at timestamptz not null default now(),
    unique (league_id)
);

create table if not exists public.draft_picks (
    id uuid primary key default gen_random_uuid(),
    draft_id uuid not null references public.drafts(id) on delete cascade,
    league_id uuid not null references public.leagues(id) on delete cascade,
    fantasy_team_id uuid not null references public.fantasy_teams(id) on delete cascade,
    round_number integer not null,
    pick_number integer not null,
    player_id uuid not null references public.players(id) on delete restrict,
    made_at timestamptz not null default now(),
    unique (draft_id, player_id),
    unique (draft_id, pick_number)
);

create table if not exists public.rosters (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    fantasy_team_id uuid not null references public.fantasy_teams(id) on delete cascade,
    player_id uuid not null references public.players(id) on delete restrict,
    slot_code text not null,
    acquired_via text not null default 'draft',
    created_at timestamptz not null default now(),
    unique (league_id, player_id)
);

create table if not exists public.lineup_entries (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    fantasy_team_id uuid not null references public.fantasy_teams(id) on delete cascade,
    player_id uuid not null references public.players(id) on delete restrict,
    game_week_key text not null,
    slot_code text not null,
    locked_at timestamptz,
    created_at timestamptz not null default now(),
    unique (fantasy_team_id, player_id, game_week_key)
);

create table if not exists public.standings_snapshots (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    game_week_key text not null,
    fantasy_team_id uuid not null references public.fantasy_teams(id) on delete cascade,
    wins integer not null default 0,
    losses integer not null default 0,
    ties integer not null default 0,
    points_for numeric(10, 2) not null default 0,
    rank integer,
    generated_at timestamptz not null default now(),
    unique (league_id, game_week_key, fantasy_team_id)
);

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null,
    payload_json jsonb not null default '{}'::jsonb,
    read_at timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.provider_runs (
    id uuid primary key default gen_random_uuid(),
    provider_name text not null,
    run_type text not null,
    status text not null,
    started_at timestamptz not null default now(),
    finished_at timestamptz,
    meta_json jsonb not null default '{}'::jsonb
);

alter table public.users_profile enable row level security;
alter table public.leagues enable row level security;
alter table public.league_members enable row level security;
alter table public.fantasy_teams enable row level security;
alter table public.notifications enable row level security;

create policy if not exists "users_profile_select_own"
on public.users_profile for select
using (auth.uid() = id);

create policy if not exists "users_profile_insert_own"
on public.users_profile for insert
with check (auth.uid() = id);

create policy if not exists "users_profile_update_own"
on public.users_profile for update
using (auth.uid() = id);

create policy if not exists "leagues_member_select"
on public.leagues for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = leagues.id and m.user_id = auth.uid()
    )
);

create policy if not exists "leagues_owner_insert"
on public.leagues for insert
with check (owner_user_id = auth.uid());

create policy if not exists "league_members_select_own_leagues"
on public.league_members for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = league_members.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists "fantasy_teams_select_own_leagues"
on public.fantasy_teams for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = fantasy_teams.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists "notifications_select_own"
on public.notifications for select
using (user_id = auth.uid());
