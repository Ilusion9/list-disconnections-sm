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
	char steam[65];
	char name[65];
	int time;
};

ArrayList g_Players;
ConVar g_Cvar_Size;

public void OnPluginStart()
{
	g_Players = new ArrayList(sizeof(PlayerInfo));
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	
	RegConsoleCmd("sm_playerhistory", Command_PlayerHistory);
	g_Cvar_Size = CreateConVar("sm_playerhistory_size", "20", _, 0, true, 1.0);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	PlayerInfo info;
	event.GetString("networkid", info.steam, sizeof(PlayerInfo::steam));
	
	if (StrEqual(info.steam, "BOT"))
	{
		return;
	}
	
	event.GetString("name", info.name, sizeof(PlayerInfo::name));
	info.time = GetTime();
	
	if (g_Players.Length)
	{
		g_Players.ShiftUp(0);
		g_Players.SetArray(0, info);
	}
	else
	{
		g_Players.PushArray(info);
	}
	
	if (g_Players.Length > g_Cvar_Size.IntValue)
	{
		g_Players.Resize(g_Cvar_Size.IntValue);
	}
}

public Action Command_PlayerHistory(int client, int args)
{
	PrintToConsole(client, "Players History: \n");
	
	for (int i = 0; i < g_Players.Length; i++)
	{
		PlayerInfo info;
		g_Players.GetArray(i, info);

		char time[65];
		FormatTimeDuration(time, sizeof(time), GetTime() - info.time);
		PrintToConsole(client, "%02d. %s - %s - %s ago", i + 1, info.steam, info.name, time);
	}
	
	return Plugin_Handled;
}

int FormatTimeDuration(char[] buffer, int maxlen, int time)
{
	int hours = time / 3600;
	int minutes = (time / 60) % 60;

	if (hours > 0)
	{
		return Format(buffer, maxlen, "%dh %dm", hours, minutes);		
	}
	
	if (minutes > 0)
	{
		return Format(buffer, maxlen, "%dm", minutes);		
	}
	
	return Format(buffer, maxlen, "%ds", time % 60);		
}
