#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "Players History",
    author = "Ilusion9",
    description = "Informations of disconnected players.",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

enum struct PlayerInfo
{
	char steam[64];
	char name[128];
	int time;
}

ArrayList g_Players;
ConVar g_Cvar_Size;

public void OnPluginStart()
{
	/* Create a list of PlayerInfo */
	g_Players = new ArrayList(sizeof(PlayerInfo));
	
	/* Hook the disconnect event */
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	/* Register a new command */
	RegConsoleCmd("sm_playerhistory", Command_PlayerHistory);
	
	/* Register a new convar */
	g_Cvar_Size = CreateConVar("sm_playerhistory_size", "10", _, 0, true, 1.0);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{	
	PlayerInfo info;
	
	/* Get the steamid of the player */
	event.GetString("networkid", info.steam, sizeof(PlayerInfo::steam));
	
	/* Don't save informations about bots */
	if (StrEqual(info.steam, "BOT")) return;
	
	/* Get the name of the player */
	event.GetString("name", info.name, sizeof(PlayerInfo::name));
	
	/* Get the time when this player is disconnecting */
	info.time = GetTime();
	
	if (g_Players.Length)
	{
		/* See the list as a stack, so we can keep the latest disconnections at the top */
		g_Players.ShiftUp(0);
		g_Players.SetArray(0, info);
		
		/* Keep maximum "sm_playerhistory_size" players in the list */
		if (g_Players.Length > g_Cvar_Size.IntValue) g_Players.Resize(g_Cvar_Size.IntValue);
	}
	else
	{
		/* If the list is empty, see it as normal */
		g_Players.PushArray(info);
	}
}

public Action Command_PlayerHistory(int client, int args)
{
	char time[64];
	PlayerInfo info;

	PrintToConsole(client, "Players History");
	PrintToConsole(client, "-------------------------");
	
	/* Display all informations saved into the list */
	for (int i = 0; i < g_Players.Length; i++)
	{
		/* Get the object from the arraylist */
		g_Players.GetArray(i, info);
		
		/* Transform the unix time into "d h m ago" format */
		FormatTimeDuration(time, sizeof(time), GetTime() - info.time);
		
		/* Print the data to the client's console */
		PrintToConsole(client, "%02d. %s \"%s\" - %s ago", i + 1, info.steam, info.name, time);
	}
	
	return Plugin_Handled;
}

int FormatTimeDuration(char[] buffer, int maxlen, int time)
{
	int days = time / 86400;
	int hours = (time / 3600) % 24;
	int minutes = (time / 60) % 60;

	if (days)
	{
		return Format(buffer, maxlen, "%dd %dh %dm", days, hours, minutes);		
	}

	if (hours)
	{
		return Format(buffer, maxlen, "%dh %dm", hours, minutes);		
	}
	
	if (minutes)
	{
		return Format(buffer, maxlen, "%dm", minutes);		
	}
	
	return Format(buffer, maxlen, "%ds", time % 60);		
}
