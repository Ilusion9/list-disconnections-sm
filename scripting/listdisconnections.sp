#include <sourcemod>
#pragma newdecls required

public Plugin myinfo =
{
	name = "List Disconnections",
	author = "Ilusion9",
	description = "Informations about the last disconnected players",
	version = "2.0",
	url = "https://github.com/Ilusion9/"
};

enum struct PlayerInfo
{
	char Steam[64];
	char Name[64];
	char Ip[64];
	int Time;
}

ArrayList g_List_Players;
ConVar g_Cvar_ListSize;

public void OnPluginStart()
{
	g_List_Players = new ArrayList(sizeof(PlayerInfo));
	g_Cvar_ListSize = CreateConVar("sm_disconnections_list_size", "15", "How many players will be shown in the disconnections list?", FCVAR_NONE, true, 1.0);
	
	RegConsoleCmd("sm_disconnections", Command_ListDisconnections);
	AutoExecConfig(true, "listdisconnections");
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	RemovePlayerFromList(steamId);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	PlayerInfo info;
	info.Time = GetTime();
	
	if (!GetClientAuthId(client, AuthId_Steam2, info.Steam, sizeof(PlayerInfo::Steam)))
	{
		Format(info.Steam, sizeof(PlayerInfo::Steam), "N/A");
	}
	
	if (!GetClientName(client, info.Name, sizeof(PlayerInfo::Name)))
	{
		Format(info.Name, sizeof(PlayerInfo::Name), "N/A");
	}
	
	if (!GetClientIP(client, info.Ip, sizeof(PlayerInfo::Ip)))
	{
		Format(info.Ip, sizeof(PlayerInfo::Ip), "N/A");
	}
	
	RemovePlayerFromList(info.Steam);
	if (!g_List_Players.Length)
	{
		g_List_Players.PushArray(info);
		return;
	}
	
	g_List_Players.ShiftUp(0);
	g_List_Players.SetArray(0, info);
	if (g_List_Players.Length > g_Cvar_ListSize.IntValue)
	{
		g_List_Players.Resize(g_Cvar_ListSize.IntValue);
	}
}

public Action Command_ListDisconnections(int client, int args)
{
	char time[64];
	PlayerInfo info;
	
	PrintToConsole(client, "Disconnections List:");
	for (int i = 0; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(i, info);
		
		// Transform the unix time into "d h m ago" format type
		FormatTimeDuration(time, sizeof(time), GetTime() - info.Time);
		PrintToConsole(client, "  %2d. %s : %s : %s : %s ago", i + 1, info.Steam, info.Name, info.Ip, time);
	}
	
	return Plugin_Handled;
}

void RemovePlayerFromList(const char[] steamId)
{
	PlayerInfo info;
	for (int i = 0; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(i, info);
		if (steamId[8] != info.Steam[8])
		{
			continue;
		}
		
		if (StrEqual(steamId[10], info.Steam[10], true))
		{
			g_List_Players.Erase(i);
			return;
		}
	}
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
