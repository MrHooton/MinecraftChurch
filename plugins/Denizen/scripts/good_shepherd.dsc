# ======================================================
# good_shepherd.dsc
# Denizen + Citizens
# Sheepfold -> Pasture -> Still Waters
#
# World: GoodShepherd
# NPC: Citizens NPC named "GoodShepherd"
#
# Updated for current Denizen Run command syntax:
# - Player/NPC context is passed with named definitions (def.name:)
# - Player-facing commands use explicit targets
# - Sequential child queues use ~run so movement does not overlap
# ======================================================

good_shepherd_world:
  type: world
  debug: false
  events:
    on system time secondly:
      - foreach <server.online_players> as:p:
        - run gs_invite_check def.p:<[p]>

# ------------------------------------------------------
# CONSTANTS
# ------------------------------------------------------

gs_constants:
  type: data
  debug: false
  sheepfold_loc: "l@99,72,-204,GoodShepherd"
  pasture_pause_loc: "l@131.69,70,-256.09,GoodShepherd"
  stillwater_loc: "l@63.27,63,-326.4,GoodShepherd"

# ------------------------------------------------------
# INVITATION
# ------------------------------------------------------

gs_invite_check:
  type: task
  debug: false
  definitions: p
  script:
    - if <[p]> == null:
      - stop
    - if <[p].world.name> != GoodShepherd:
      - stop
    - if <[p].flag[gs_seen_intro]||false>:
      - stop
    - if <[p].flag[gs_running_intro]||false>:
      - stop

    - define shepherd <npc[GoodShepherd]||null>
    - if <[shepherd]> == null:
      - stop

    - define sheepfold <script[gs_constants].data_key[sheepfold_loc].as_location>
    - if <[p].location.distance[<[sheepfold]>]> > 14:
      - stop

    - if <[p].flag[gs_invited_recently]||false>:
      - stop
    - flag <[p]> gs_invited_recently:true expire:20s

    - run gs_invitation_moment def.p:<[p]> def.shepherd:<[shepherd]>

gs_invitation_moment:
  type: task
  debug: false
  definitions: p|shepherd
  script:
    - define sheepfold <script[gs_constants].data_key[sheepfold_loc].as_location>

    - execute as_server "npc select <[shepherd].id>"
    - execute as_server "npc ai true"

    - if <[shepherd].location.distance[<[sheepfold]>]> > 6:
      - ~walk <[shepherd]> <[sheepfold]>
      - wait 10t

    - look <[shepherd]> <[p].eye_location>
    - actionbar "<gold>The Good Shepherd is waiting..." targets:<[p]>

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

    - flag <[p]> gs_running_intro:true
    - flag <[p]> gs_pasture_pause_done:!
    - run gs_intro_sequence def.p:<[p]> def.shepherd:<[shepherd]>

# ------------------------------------------------------
# SHEEP HERD
# ------------------------------------------------------

gs_attach_sheep_herd:
  type: task
  debug: false
  definitions: shepherd
  script:
    - define herd <[shepherd].location.find_entities[within=18;type=sheep].take[6]>
    - if <[herd].is_empty>:
      - stop
    - flag <[shepherd]> gs_herd_entities:<[herd]>
    - follow followers:<[herd]> target:<[shepherd]> lead:2.5 max:20 speed:0.85 allow_wander

gs_stop_sheep_herd:
  type: task
  debug: false
  definitions: shepherd
  script:
    - define herd <[shepherd].flag[gs_herd_entities]||<list[]>>
    - if <[herd].is_empty>:
      - stop
    - follow followers:<[herd]> stop

# ------------------------------------------------------
# PATH
# ------------------------------------------------------

gs_path_to_stillwater:
  type: data
  debug: false
  points:
    - "l@98,72,-204,GoodShepherd"
    - "l@101,72,-204,GoodShepherd"
    - "l@104,72,-210,GoodShepherd"
    - "l@108,72,-215,GoodShepherd"
    - "l@109,72,-219,GoodShepherd"
    - "l@109,72,-225,GoodShepherd"
    - "l@110,70,-234,GoodShepherd"
    - "l@115,70,-237,GoodShepherd"
    - "l@122,70,-245,GoodShepherd"
    - "l@127,70,-250,GoodShepherd"
    - "l@134,70,-259,GoodShepherd"
    - "l@133,70,-264,GoodShepherd"
    - "l@130,70,-268,GoodShepherd"
    - "l@116,70,-268,GoodShepherd"
    - "l@111,71,-267,GoodShepherd"
    - "l@93,71,-271,GoodShepherd"
    - "l@90,71,-278,GoodShepherd"
    - "l@83,71,-281,GoodShepherd"
    - "l@81,71,-287,GoodShepherd"
    - "l@75,71,-291,GoodShepherd"
    - "l@74,71,-298,GoodShepherd"
    - "l@72,70,-308,GoodShepherd"
    - "l@68,67,-314,GoodShepherd"
    - "l@65,65,-318,GoodShepherd"
    - "l@64,64,-322,GoodShepherd"
    - "l@64,63,-327,GoodShepherd"
    - "l@63,63,-330,GoodShepherd"
    - "l@62,63,-332,GoodShepherd"

# ------------------------------------------------------
# MOVEMENT HELPERS
# ------------------------------------------------------

gs_wait_for_nearness:
  type: task
  debug: false
  definitions: p|shepherd
  script:
    - while <[p].location.distance[<[shepherd].location>]> > 10:
      - actionbar "<gray>Stay close to the Good Shepherd..." targets:<[p]>
      - wait 10t

gs_walk_npc_to:
  type: task
  debug: false
  definitions: p|shepherd|dest|subtitle
  script:
    - if !<[p].flag[gs_running_intro]||false>:
      - stop
    - ~run gs_wait_for_nearness def.p:<[p]> def.shepherd:<[shepherd]>
    - define subtitle <[subtitle].if_null[]>
    - if <[subtitle].length> > 0:
      - title "subtitle:<gold><[subtitle]>" stay:40t targets:<[p]>
    - ~walk <[shepherd]> <[dest]>
    - wait 10t

# ------------------------------------------------------
# STORY SEQUENCE
# ------------------------------------------------------

gs_intro_sequence:
  type: task
  debug: false
  definitions: p|shepherd
  script:
    - execute as_server "npc select <[shepherd].id>"
    - execute as_server "npc ai true"

    - ~run gs_attach_sheep_herd def.shepherd:<[shepherd]>

    - ~run gs_walk_npc_to def.p:<[p]> def.shepherd:<[shepherd]> def.dest:<script[gs_constants].data_key[sheepfold_loc].as_location> def.subtitle:"Here is the sheepfold."

    - define pasture_pause <script[gs_constants].data_key[pasture_pause_loc].as_location>
    - define stillwater <script[gs_constants].data_key[stillwater_loc].as_location>

    - foreach <script[gs_path_to_stillwater].data_key[points].as_list> as:pt:
      - define dest <[pt].as_location>
      - if <[p].flag[gs_pasture_pause_done]||false> == false:
        - if <[dest].distance[<[pasture_pause]>]> < 6:
          - ~run gs_walk_npc_to def.p:<[p]> def.shepherd:<[shepherd]> def.dest:<[pasture_pause]> def.subtitle:"The Good Shepherd leads the sheep to green pastures."
          - flag <[p]> gs_pasture_pause_done:true
          - wait 3s
      - ~run gs_walk_npc_to def.p:<[p]> def.shepherd:<[shepherd]> def.dest:<[dest]>

    - ~run gs_walk_npc_to def.p:<[p]> def.shepherd:<[shepherd]> def.dest:<[stillwater]> def.subtitle:"He leads them beside still waters."

    - ~run gs_stop_sheep_herd def.shepherd:<[shepherd]>
    - define linger 0
    - while <[linger]> < 10:
      - if !<[p].flag[gs_running_intro]||false>:
        - stop
      - if <[p].location.distance[<[shepherd].location>]> <= 10:
        - define linger <[linger].add[1]>
        - actionbar "<gray>This is a quiet place. Stay close." targets:<[p]>
      - else:
        - define linger 0
        - actionbar "<gray>This is a quiet place. Come close." targets:<[p]>
      - wait 1s

    - flag <[p]> gs_seen_intro:true
    - flag <[p]> gs_running_intro:false
    - title "title:<gold>I wonder..." "subtitle:<gray>What do you notice here, by the still water?" stay:120t targets:<[p]>
