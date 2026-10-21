# Roblox-Lua-Examples

Roblox Lua scripting examples.

## PlayerData.server.lua
Server script that creates leaderstats (Coins) and a Gems counter, and saves/loads both with DataStoreService.

- Retries failed DataStore calls with a growing delay
- Skips saving if a player's data failed to load, so progress is never overwritten with zeros
- Autosaves every 60 seconds and saves on player leave and server shutdown (`BindToClose`)

Place in `ServerScriptService`.
