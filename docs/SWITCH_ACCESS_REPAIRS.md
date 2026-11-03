# Switch access: startup script repairs

The November 3, 2026 startup log shows Geyser 2.12.1-b1284 and
MCXboxBroadcast build 162 loading successfully. The Xbox account HowellFUMC
authenticated and created a session. Geyser registered external signaling at
https://youngcove.wdn.gg because Java already occupies TCP port 25588.

## Changes

- Repair the malformed safeguarding join event. Check protected worlds on joins,
  teleports, and quits. Merge the duplicate teleport keys so world supervision
  and configured foyer checks both run, including when the foyer is disabled.
- Keep cancellation messages running with `determine passively cancelled`.
- Replace the obsolete API Doorkeeper with a data-only retirement marker. The
  existing `doorkeeper_fixed.dsc` remains the sole owner of `doorkeeper_assign`
  and preserves UUID registration and the delayed lobby arrival teleport.
- Bring the earlier Good Shepherd queue repairs forward from the existing
  repair branch: use named definitions, explicit player targets, and waited child
  queues. Remove inline waypoint comments that Denizen rewrites inside quoted
  data, preserve all 28 waypoints, and correct the nearby-sheep lookup syntax.
- Use explicit, null-safe data-action definitions for request display fields,
  including the `created` definition implicated by the log. Reject nonnumeric
  request IDs in the view task and fix malformed request-count tags.
- Allow deployment of the exact MCXboxBroadcast `config.yml` path. Extension
  JARs, authentication caches, keys, and other files remain excluded.

## Validation and limits

Local checks reproduce the three original script-loading failures and verify
that the repaired scripts parse after Denizen-style preprocessing. Duplicate
keys, command-list structure, waypoint preservation, request definitions, and
the deployment allowlist are checked. These are structural checks, not a live
Paper/Denizen execution or a proof of safeguarding behavior.

The admin DEFINE diagnostic needs confirmation after deployment: the log's
server-side script may differ from the Git copy. Database queries, game tags,
NPC walking, and Switch connectivity require testing on the server.

## Deployment and server verification

1. Update ViaVersion separately and remove its superseded JAR from the active
   plugin directory. The supplied log advertises ViaVersion 5.12.2.
2. Deploy the four changed Denizen files together. The data-only Doorkeeper
   marker must overwrite the old file; simply omitting it leaves the old
   duplicate assignment on the server. Keep `doorkeeper_fixed.dsc` present.
3. Restart and check that the three parse failures and the admin DEFINE error
   no longer appear. Check that the safeguarding background monitor starts.
4. Verify lobby arrival and one verification-code request. View a pending
   request with empty approval fields and confirm the details display.
5. With approved test accounts, check protected-world access with fewer than
   two supervisors, with two supervisors, and when a supervisor disconnects.
   Check the configured foyer boundary as well as world-wide enforcement.
6. Add HowellFUMC as a Microsoft/Xbox friend from a Switch player's account and
   test joining its advertised session. Confirm lobby arrival and NPC interaction.

The repository's Geyser and broadcast configuration copies predate the live
plugin updates. Synchronize their newly generated live versions before a full
configuration deployment; this repair does not overwrite them or deploy JARs.
