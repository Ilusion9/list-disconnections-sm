#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
    name = "List disconnections",
    author = "Ilusion9",
    description = "Informations of disconnected players.",
    version = "2.0",
    url = "https://github.com/Ilusion9/"
};

enum struct PlayerInfo
{
	char steam[64];
	char name[64];
	int time;
}

ArrayList g_Players;
ConVar g_Cvar_MaxSize;

public void OnPluginStart()
{
	g_Players = new ArrayList(sizeof(PlayerInfo));
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	RegConsoleCmd("sm_listdc", Command_ListDc);
	RegConsoleCmd("sm_lastdc", Command_ListDc);

	g_Cvar_MaxSize = CreateConVar("sm_disconnections_size", "10", _, 0, true, 1.0);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{	
	PlayerInfo info;
	event.GetString("networkid", info.steam, sizeof(PlayerInfo::steam));
	
	if (StrEqual(info.steam, "BOT", false)) {
		return;
	}
	
	event.GetString("name", info.name, sizeof(PlayerInfo::name));
	info.time = GetTime();
	
	if (g_Players.Length)
	{
		g_Players.ShiftUp(0);
		g_Players.SetArray(0, info);
		
		if (g_Players.Length > g_Cvar_MaxSize.IntValue) {
			g_Players.Resize(g_Cvar_MaxSize.IntValue);
		}
	}
	else {
		g_Players.PushArray(info);
	}
}

public Action Command_ListDc(int client, int args)
{
	char time[64];
	PlayerInfo info;

	PrintToConsole(client, "Last %d disconnections", g_Players.Length);
	PrintToConsole(client, "-------------------------");
	
	for (int i = 0; i < g_Players.Length; i++)
	{
		g_Players.GetArray(i, info);
		
		FormatTimeDuration(time, sizeof(time), GetTime() - info.time);
		PrintToConsole(client, "%02d. %s \"%s\" - %s ago", i + 1, info.steam, info.name, time);
	}
	
	return Plugin_Handled;
}

int FormatTimeDuration(char[] buffer, int maxlen, int time)
{
	int days = time / 86400;
	int hours = (time / 3600) % 24;
	int minutes = (time / 60) % 60;

	if (days) {
		return Format(buffer, maxlen, "%dd %dh %dm", days, hours, minutes);		
	}

	if (hours) {
		return Format(buffer, maxlen, "%dh %dm", hours, minutes);		
	}
	
	if (minutes) {
		return Format(buffer, maxlen, "%dm", minutes);		
	}
	
	return Format(buffer, maxlen, "%ds", time % 60);		
}
