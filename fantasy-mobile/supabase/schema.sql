create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create or replace function public.generate_invite_code()
returns text
language plpgsql
as $$
declare
    chars constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    output text := '';
begin
    for i in 1..8 loop
        output := output || substr(chars, 1 + floor(random() * length(chars))::integer, 1);
    end loop;

    return output;
end;
$$;

create table if not exists public.users_profile (
    id uuid primary key references auth.users(id) on delete cascade,
    username text unique,
    display_name text not null,
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.seasons (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    year integer not null,
    status text not null default 'upcoming',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.teams (
    id uuid primary key default gen_random_uuid(),
    external_key text unique,
    name text not null,
    short_name text,
    logo_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
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
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
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
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
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
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.league_members (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null default 'member',
    joined_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (league_id, user_id)
);

create table if not exists public.fantasy_teams (
    id uuid primary key default gen_random_uuid(),
    league_id uuid not null references public.leagues(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
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
    updated_at timestamptz not null default now(),
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
    updated_at timestamptz not null default now(),
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
    updated_at timestamptz not null default now(),
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
    updated_at timestamptz not null default now(),
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
    updated_at timestamptz not null default now(),
    unique (league_id, game_week_key, fantasy_team_id)
);

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null,
    payload_json jsonb not null default '{}'::jsonb,
    read_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.provider_runs (
    id uuid primary key default gen_random_uuid(),
    provider_name text not null,
    run_type text not null,
    status text not null,
    started_at timestamptz not null default now(),
    finished_at timestamptz,
    meta_json jsonb not null default '{}'::jsonb,
    updated_at timestamptz not null default now()
);

drop trigger if exists set_users_profile_updated_at on public.users_profile;
create trigger set_users_profile_updated_at
before update on public.users_profile
for each row execute function public.set_updated_at();

drop trigger if exists set_seasons_updated_at on public.seasons;
create trigger set_seasons_updated_at
before update on public.seasons
for each row execute function public.set_updated_at();

drop trigger if exists set_teams_updated_at on public.teams;
create trigger set_teams_updated_at
before update on public.teams
for each row execute function public.set_updated_at();

drop trigger if exists set_players_updated_at on public.players;
create trigger set_players_updated_at
before update on public.players
for each row execute function public.set_updated_at();

drop trigger if exists set_games_updated_at on public.games;
create trigger set_games_updated_at
before update on public.games
for each row execute function public.set_updated_at();

drop trigger if exists set_leagues_updated_at on public.leagues;
create trigger set_leagues_updated_at
before update on public.leagues
for each row execute function public.set_updated_at();

drop trigger if exists set_league_members_updated_at on public.league_members;
create trigger set_league_members_updated_at
before update on public.league_members
for each row execute function public.set_updated_at();

drop trigger if exists set_fantasy_teams_updated_at on public.fantasy_teams;
create trigger set_fantasy_teams_updated_at
before update on public.fantasy_teams
for each row execute function public.set_updated_at();

drop trigger if exists set_drafts_updated_at on public.drafts;
create trigger set_drafts_updated_at
before update on public.drafts
for each row execute function public.set_updated_at();

drop trigger if exists set_draft_picks_updated_at on public.draft_picks;
create trigger set_draft_picks_updated_at
before update on public.draft_picks
for each row execute function public.set_updated_at();

drop trigger if exists set_rosters_updated_at on public.rosters;
create trigger set_rosters_updated_at
before update on public.rosters
for each row execute function public.set_updated_at();

drop trigger if exists set_lineup_entries_updated_at on public.lineup_entries;
create trigger set_lineup_entries_updated_at
before update on public.lineup_entries
for each row execute function public.set_updated_at();

drop trigger if exists set_standings_snapshots_updated_at on public.standings_snapshots;
create trigger set_standings_snapshots_updated_at
before update on public.standings_snapshots
for each row execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

drop trigger if exists set_provider_runs_updated_at on public.provider_runs;
create trigger set_provider_runs_updated_at
before update on public.provider_runs
for each row execute function public.set_updated_at();

alter table public.users_profile enable row level security;
alter table public.seasons enable row level security;
alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.games enable row level security;
alter table public.player_game_stats enable row level security;
alter table public.leagues enable row level security;
alter table public.league_members enable row level security;
alter table public.fantasy_teams enable row level security;
alter table public.drafts enable row level security;
alter table public.draft_picks enable row level security;
alter table public.rosters enable row level security;
alter table public.lineup_entries enable row level security;
alter table public.standings_snapshots enable row level security;
alter table public.notifications enable row level security;

create policy if not exists users_profile_select_own
on public.users_profile for select
using (auth.uid() = id);

create policy if not exists users_profile_insert_own
on public.users_profile for insert
with check (auth.uid() = id);

create policy if not exists users_profile_update_own
on public.users_profile for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy if not exists seasons_public_read
on public.seasons for select
using (true);

create policy if not exists teams_public_read
on public.teams for select
using (true);

create policy if not exists players_public_read
on public.players for select
using (true);

create policy if not exists games_public_read
on public.games for select
using (true);

create policy if not exists player_game_stats_public_read
on public.player_game_stats for select
using (true);

create policy if not exists leagues_member_select
on public.leagues for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = leagues.id and m.user_id = auth.uid()
    )
);

create policy if not exists leagues_owner_update
on public.leagues for update
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

create policy if not exists league_members_select_own_leagues
on public.league_members for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = league_members.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists fantasy_teams_select_own_leagues
on public.fantasy_teams for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = fantasy_teams.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists drafts_select_own_leagues
on public.drafts for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = drafts.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists draft_picks_select_own_leagues
on public.draft_picks for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = draft_picks.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists rosters_select_own_leagues
on public.rosters for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = rosters.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists lineup_entries_select_own_leagues
on public.lineup_entries for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = lineup_entries.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists standings_snapshots_select_own_leagues
on public.standings_snapshots for select
using (
    exists (
        select 1
        from public.league_members m
        where m.league_id = standings_snapshots.league_id and m.user_id = auth.uid()
    )
);

create policy if not exists notifications_select_own
on public.notifications for select
using (user_id = auth.uid());

create policy if not exists notifications_update_own
on public.notifications for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

create or replace function public.create_league_with_team(
    league_name text,
    team_name text,
    season_id uuid default null,
    privacy text default 'private'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    current_user_id uuid := auth.uid();
    created_league_id uuid;
    created_fantasy_team_id uuid;
    invite_code_value text;
begin
    if current_user_id is null then
        raise exception 'not_authenticated';
    end if;

    for attempt in 1..5 loop
        begin
            invite_code_value := public.generate_invite_code();

            insert into public.leagues (
                owner_user_id,
                season_id,
                name,
                privacy,
                invite_code
            ) values (
                current_user_id,
                season_id,
                trim(league_name),
                coalesce(nullif(trim(privacy), ''), 'private'),
                invite_code_value
            ) returning id into created_league_id;

            exit;
        exception
            when unique_violation then
                if attempt = 5 then
                    raise;
                end if;
        end;
    end loop;

    insert into public.league_members (league_id, user_id, role)
    values (created_league_id, current_user_id, 'owner');

    insert into public.fantasy_teams (league_id, user_id, name)
    values (created_league_id, current_user_id, trim(team_name))
    returning id into created_fantasy_team_id;

    return jsonb_build_object(
        'league_id', created_league_id,
        'fantasy_team_id', created_fantasy_team_id,
        'invite_code', invite_code_value
    );
end;
$$;

create or replace function public.join_league_by_code(
    invite_code_input text,
    team_name text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    current_user_id uuid := auth.uid();
    target_league_id uuid;
    created_fantasy_team_id uuid;
begin
    if current_user_id is null then
        raise exception 'not_authenticated';
    end if;

    select id
    into target_league_id
    from public.leagues
    where invite_code = upper(trim(invite_code_input))
    limit 1;

    if target_league_id is null then
        raise exception 'invalid_invite_code';
    end if;

    if exists (
        select 1
        from public.league_members
        where league_id = target_league_id and user_id = current_user_id
    ) then
        raise exception 'already_joined';
    end if;

    insert into public.league_members (league_id, user_id, role)
    values (target_league_id, current_user_id, 'member');

    insert into public.fantasy_teams (league_id, user_id, name)
    values (target_league_id, current_user_id, trim(team_name))
    returning id into created_fantasy_team_id;

    return jsonb_build_object(
        'league_id', target_league_id,
        'fantasy_team_id', created_fantasy_team_id
    );
end;
$$;

grant execute on function public.create_league_with_team(text, text, uuid, text) to authenticated;
grant execute on function public.join_league_by_code(text, text) to authenticated;
