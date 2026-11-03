# Legacy API-based Doorkeeper retired.
# The active doorkeeper_assign and player_join_registration containers are in
# doorkeeper_fixed.dsc. Keep this data-only marker so config deployment overwrites
# older servers' duplicate assignment without requiring remote file deletion.
doorkeeper_legacy_retired:
  type: data
  active_script: doorkeeper_fixed.dsc

