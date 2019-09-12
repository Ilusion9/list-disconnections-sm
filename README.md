# Description
This plugin will display informations about the last disconnected players.

# Dependencies
You need at least sourcemod 1.10, because this plugin is using enum structs.

# Alliedmods
https://forums.alliedmods.net/showthread.php?t=314886

# Commands
```
sm_listdc - show the last disconnected players
```

# ConVars
```
sm_listdc_size 10 // How many players will be shown in the disconnections list?
sm_listdc_remove_duplicates 1 // Remove duplicate steamids from the disconnections list?
```

# Output example
```
Disconnections list
-------------------------
01. STEAM_1:1:123456XX "decoy" - 50s ago
02. STEAM_1:1:123456XY "Ilusion9" - 3m ago
03. STEAM_1:1:123456YZ "Fallen" - 1h 47m ago
```
