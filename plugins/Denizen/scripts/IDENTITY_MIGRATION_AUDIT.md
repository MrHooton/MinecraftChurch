# Minecraft Church Identity / Floodgate Migration Audit

## Current staged state

This repository is intentionally **not** changing either of these settings yet:

- `server.properties`: `online-mode=false`
- Floodgate: `username-prefix: ""`

The current safeguarding/verification system was built around unprefixed Minecraft names. Adding the conventional Floodgate prefix now would break existing name validation and authorization assumptions. The immediate goal is therefore to make UUID identity observable and collision-safe before changing authentication mode.

## Hardening now implemented

### UUID-first Denizen registration

`identity_hardening.dsc` provides `identity_register_player`.

Rules:

1. A known UUID is treated as the authoritative identity.
2. A name already attached to a different non-empty UUID is never silently rebound.
3. A legacy name record with no UUID can be backfilled once.
4. A new UUID + new name creates a normal `known_players` row.
5. Collisions/mismatches are written to `logs/identity_audit.log` and announced to console.

`doorkeeper_fixed.dsc` now sends join registration through this task instead of the older name-first upsert.

### Admin audit command

Use:

```text
/identityaudit
```

This compares the executing player's live Paper name/UUID with `known_players` and reports:

- live name
- live UUID
- currently detected platform
- number of matching DB rows by UUID
- number of matching DB rows by name
- DB platform and permission level
- UUID/name mismatch status

Database-only lookup for a stored player:

```text
/identityaudit PlayerName
```

This does not authenticate the named player. It only displays the currently stored `known_players` information.

### API registration

`api/routes/players.js` now uses the same policy:

- UUID match -> update by UUID
- same name + different UUID -> HTTP 409 identity collision
- same name + empty UUID -> backfill UUID
- no UUID supplied -> refresh metadata without changing identity
- new name/UUID -> create record

The API's current no-prefix username validator has deliberately been preserved.

## Production deployment sequence

Do not switch `online-mode` as part of the hardening deployment.

1. Deploy the changed Denizen scripts.
2. Reload Denizen or restart during the normal maintenance process.
3. Have known Java and Bedrock users join normally.
4. Run `/identityaudit` while logged in as an administrator.
5. Review `logs/identity_audit.log` for `UUID_MISMATCH` or `NAME_COLLISION` entries.
6. Export the live identity stores before authentication migration.

## Live data needed before online-mode migration

Git intentionally excludes several UUID-bound stores. Preserve/export at minimum:

- `usercache.json`
- `ops.json`
- world `playerdata`, `stats`, and `advancements`
- LuckPerms H2 database
- Denizen `player_flags`
- Multiverse-Inventories player data
- MySQL `known_players`
- MySQL verification/access tables
- Floodgate data needed for linked Bedrock identities

Build a crosswalk containing:

| Current name | Platform | Current Paper UUID | known_players UUID | Authenticated/canonical UUID | Permission level | Notes |
|---|---|---|---|---|---|---|

## Go/no-go rule for switching `online-mode=true`

Do not switch until active staff/verified players have a documented current UUID -> canonical UUID mapping and there is a backup/rollback path for UUID-bound state.

## Prefix decision

Keep `username-prefix: ""` during this migration unless the safeguarding and verification system is intentionally redesigned for prefixed Bedrock names. UUID-first identity plus explicit collision handling is the immediate compatibility strategy.

## Known follow-up work

After the identity crosswalk is collected:

1. Change LuckPerms grant application to resolve/validate UUID before assigning a group.
2. Change verification/access-grant records to carry canonical identity rather than relying on name alone.
3. Migrate old offline Java UUID state to authenticated Java UUIDs.
4. Switch Java authentication to `online-mode=true` in a controlled maintenance window.
5. Test existing Java, Bedrock-only, linked Bedrock/Java, and same-visible-name collision cases.
