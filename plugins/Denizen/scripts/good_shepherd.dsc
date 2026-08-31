# ======================================================
# good_shepherd_invite_to_stillwater.dsc
# Denizen + Citizens
# Sections: Invitation at Sheepfold -> Pasture -> Pause at Still Waters
#
# World: GoodShepherd
# NPC:   Citizens NPC named "GoodShepherd"
#
# What this script does:
# - Watches for players near the Sheepfold entrance.
# - Invites them, then starts the walk if they linger nearby.
# - Shepherd walks along your waypoint path (hard-coded from your Citizens waypoint list).
# - Up to 6 nearby sheep are recruited at Sheepfold and follow the Shepherd.
# - Shepherd pauses at Pasture (short pause) and then at StillWater (longer “quiet place” pause).
#
# Notes:
# - This version does NOT rely on Multiverse Anchors in the script.
# - Sheep-follow uses Denizen 'follow' command.
# - If you later change the path again, update the location list in gs_path_to_stillwater.
# ======================================================

good_shepherd_world:
  type: world
  debug: false
  events:

    # Heartbeat: once per second per online player.
    on system time secondly:
      - foreach <server.online_players> as:p:
        - run gs_invite_check player:<[p]>

# ------------------------------------------------------
# CONSTANTS (single source of truth)
# ------------------------------------------------------

gs_constants:
  type: data
  debug: false
  sheepfold_loc: "l@99,72,-204,GoodShepherd"
  pasture_pause_loc: "l@131.69,70,-256.09,GoodShepherd"
  stillwater_loc: "l@63.27,63,-326.4,GoodShepherd"

# ------------------------------------------------------
# INVITATION: check whether we should invite / auto-start
# ------------------------------------------------------

gs_invite_check:
  type: task
  debug: false
  script:
  - define p <player||<context.player>>
  - if <[p]> == null:
    - stop

  # Only run in the GoodShepherd world
  - if <[p].world.name> != GoodShepherd:
    - stop

  # Do not auto-start once the player has already seen this segment.
  - if <[p].flag[gs_seen_intro]||false>:
    - stop

  # If the player is currently running the intro walk, do nothing.
  - if <[p].flag[gs_running_intro]||false>:
    - stop

  - define shepherd <npc[GoodShepherd]||null>
  - if <[shepherd]> == null:
    - stop

  - define sheepfold <script[gs_constants].data_key[sheepfold_loc].as_location>

  # Only invite when player is near the Sheepfold entrance.
  - if <[p].location.distance[<[sheepfold]>]> > 14:
    - stop

  # Rate-limit invitations (avoid spam).
  - if <[p].flag[gs_invited_recently]||false>:
    - stop
  - flag <[p]> gs_invited_recently:true expire:20s

  - run gs_invitation_moment player:<[p]> def:shepherd:<[shepherd]>

gs_invitation_moment:
  type: task
  debug: false
  definitions: shepherd
  script:
  - define p <player||<context.player>>
  - define shepherd <[shepherd]>
  - define sheepfold <script[gs_constants].data_key[sheepfold_loc].as_location>

  # Ensure Shepherd is positioned at Sheepfold (and awake).
  - execute as_server "npc select <[shepherd].id>"
  - execute as_server "npc ai true"

  - if <[shepherd].location.distance[<[sheepfold]>]> > 6:
    - ~walk <[shepherd]> <[sheepfold]>
    - wait 10t

  - look <[shepherd]> <[p].eye_location>
  - actionbar "<gold>The Good Shepherd is waiting..."

  # "Consent by lingering": player stays near shepherd for 6 seconds.
  - define linger 0
  - while <[linger]> < 6:
    - if <[p].flag[gs_seen_intro]||false>:
      - stop
    - if <[p].flag[gs_running_intro]||false>:
      - stop

    - if <[p].location.distance[<[shepherd].location>]> <= 9:
      - define linger <[linger].add[1]>
    - else:
      - stop
    - wait 1s

  # Start the intro walk.
  - flag <[p]> gs_running_intro:true
  - run gs_intro_sequence player:<[p]> def:shepherd:<[shepherd]>

# ------------------------------------------------------
# SHEEP: recruit and follow the Shepherd (up to 6)
# ------------------------------------------------------

gs_attach_sheep_herd:
  type: task
  debug: false
  definitions: shepherd
  script:
  - define shepherd <[shepherd]>

  # Grab up to 6 nearby sheep (adjust radius if your pen is bigger).
  - define herd <[shepherd].location.find_entities[within=18;type=sheep].take[6]>

  - if <[herd].is_empty>:
    - stop

  # Store them so we can stop/restart without losing the list.
  - flag npc:<[shepherd]> gs_herd_entities:<[herd]>

  # Make them follow the shepherd.
  - follow followers:<[herd]> target:<[shepherd]> lead:2.5 max:20 speed:0.85 allow_wander

gs_stop_sheep_herd:
  type: task
  debug: false
  definitions: shepherd
  script:
  - define shepherd <[shepherd]>
  - define herd <[shepherd].flag[gs_herd_entities]||<list[]>>
  - if <[herd].is_empty>:
    - stop
  - follow followers:<[herd]> stop

# ------------------------------------------------------
# PATH: your waypoint list (ordered walk targets)
# ------------------------------------------------------

gs_path_to_stillwater:
  type: data
  debug: false
  # Ordered points derived from your Citizens waypoint dump.
  # (We walk location-to-location for reliability; this is independent of the Citizens waypoint trait.)
  points:
  - "l@98,72,-204,GoodShepherd"     # 22
  - "l@101,72,-204,GoodShepherd"    # 23
  - "l@104,72,-210,GoodShepherd"    # 24
  - "l@108,72,-215,GoodShepherd"    # 25
  - "l@109,72,-219,GoodShepherd"    # 20
  - "l@109,72,-225,GoodShepherd"    # 21
  - "l@110,70,-234,GoodShepherd"    # 10
  - "l@115,70,-237,GoodShepherd"    # 11
  - "l@122,70,-245,GoodShepherd"    # 12
  - "l@127,70,-250,GoodShepherd"    # 13
  - "l@134,70,-259,GoodShepherd"    # 14
  - "l@133,70,-264,GoodShepherd"    # 15
  - "l@130,70,-268,GoodShepherd"    # 16
  - "l@116,70,-268,GoodShepherd"    # 17
  - "l@111,71,-267,GoodShepherd"    # 18
  - "l@93,71,-271,GoodShepherd"     # 19
  - "l@90,71,-278,GoodShepherd"     # 0
  - "l@83,71,-281,GoodShepherd"     # 1
  - "l@81,71,-287,GoodShepherd"     # 2
  - "l@75,71,-291,GoodShepherd"     # 3
  - "l@74,71,-298,GoodShepherd"     # 26
  - "l@72,70,-308,GoodShepherd"     # 27
  - "l@68,67,-314,GoodShepherd"     # 6
  - "l@65,65,-318,GoodShepherd"     # 7
  - "l@64,64,-322,GoodShepherd"     # 8
  - "l@64,63,-327,GoodShepherd"     # 9
  - "l@63,63,-330,GoodShepherd"     # 4
  - "l@62,63,-332,GoodShepherd"     # 5

# ------------------------------------------------------
# UTILITY: keep pacing and do reliable NPC walking
# ------------------------------------------------------

gs_wait_for_nearness:
  type: task
  debug: false
  definitions: shepherd
  script:
  - while <player.location.distance[<[shepherd].location>]> > 10:
    - actionbar "<gray>Stay close to the Good Shepherd..."
    - wait 10t

gs_walk_npc_to:
  type: task
  debug: false
  definitions: shepherd|dest|subtitle
  script:
  - if !<player.flag[gs_running_intro]||false>:
    - stop
  - run gs_wait_for_nearness def:shepherd:<[shepherd]>
  - if <[subtitle].exists>:
    - title "subtitle:<gold><[subtitle]>" stay:40t
  - ~walk <[shepherd]> <[dest]>
  - wait 10t

# ------------------------------------------------------
# STORY: Sheepfold -> Pasture pause -> StillWater pause
# ------------------------------------------------------

gs_intro_sequence:
  type: task
  debug: false
  definitions: shepherd
  script:
  - define shepherd <[shepherd]>

  - execute as_server "npc select <[shepherd].id>"
  - execute as_server "npc ai true"

  # Recruit sheep at the start.
  - run gs_attach_sheep_herd def:shepherd:<[shepherd]>

  # Stage 1: Sheepfold (explicit line)
  - run gs_walk_npc_to def:shepherd:<[shepherd]>|dest:<script[gs_constants].data_key[sheepfold_loc].as_location>|subtitle:"Here is the sheepfold."

  # Walk the waypoint list. Pause when we reach pasture pause location.
  - define pasture_pause <script[gs_constants].data_key[pasture_pause_loc].as_location>
  - define stillwater <script[gs_constants].data_key[stillwater_loc].as_location>

  - foreach <script[gs_path_to_stillwater].data_key[points].as_list> as:pt:
    - define dest <[pt].as_location>

    # If we're near the pasture pause point, do the pasture beat once.
    - if <player.flag[gs_pasture_pause_done]||false> == false:
      - if <[dest].distance[<[pasture_pause]>]> < 6:
        - run gs_walk_npc_to def:shepherd:<[shepherd]>|dest:<[pasture_pause]>|subtitle:"The Good Shepherd leads the sheep to green pastures."
        - flag player gs_pasture_pause_done:true
        - wait 3s

    # Continue along the path
    - run gs_walk_npc_to def:shepherd:<[shepherd]>|dest:<[dest]>

  # Final step: ensure we land precisely at StillWater, then do the quiet pause.
  - run gs_walk_npc_to def:shepherd:<[shepherd]>|dest:<[stillwater]>|subtitle:"He leads them beside still waters."

  # Quiet pause at Still Water (requires closeness)
  - run gs_stop_sheep_herd def:shepherd:<[shepherd]>
  - define linger 0
  - while <[linger]> < 10:
    - if !<player.flag[gs_running_intro]||false>:
      - stop
    - if <player.location.distance[<[shepherd].location>]> <= 10:
      - define linger <[linger].add[1]>
      - actionbar "<gray>This is a quiet place. Stay close."
    - else:
      - define linger 0
      - actionbar "<gray>This is a quiet place. Come close."
    - wait 1s

  # Mark this segment complete.
  - flag player gs_seen_intro:true
  - flag player gs_running_intro:false
  - title "title:<gold>I wonder..." "subtitle:<gray>What do you notice here, by the still water?" stay:120t

