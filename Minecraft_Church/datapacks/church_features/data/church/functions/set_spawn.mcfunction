# Set the world spawn point at the Howell First United Methodist Church
# Coordinates can be adjusted based on the actual church location
# Usage: /function church:set_spawn

# Set world spawn at the church location (adjust x, y, z coordinates as needed)
# Default coordinates: x=0, y=100, z=0 (adjust to actual church entrance location)
setworldspawn 0 100 0

# Optional: Send confirmation message to nearest player
tellraw @a {"text":"World spawn point has been set at the Howell First United Methodist Church","color":"gold"}
