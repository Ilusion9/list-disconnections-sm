#include <sourcemod>
#pragma newdecls required

public Plugin myinfo =
{
	name = "List Disconnections",
	author = "Ilusion9",
	description = "Informations about the last disconnected players.",
	version = "2.1",
	url = "https://github.com/Ilusion9/"
};

enum struct PlayerInfo
{
	char steamId[64];
	char clientName[64];
	char clientIp[64];
	int unixTime;
}

ArrayList g_List_Players;
ConVar g_Cvar_MaxLength;

public void OnPluginStart()
{	
	g_List_Players = new ArrayList(sizeof(PlayerInfo));
	g_Cvar_MaxLength = CreateConVar("sm_disconnections_maxsize", "15", "How many players will be shown in the disconnections list?", FCVAR_NONE, true, 0.0);
	
	g_Cvar_MaxLength.AddChangeHook(ConVarChange_DisconnectionsSize);
	RegConsoleCmd("sm_disconnections", Command_ListDisconnections);
}

public void ConVarChange_DisconnectionsSize(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_List_Players.Length > g_Cvar_MaxLength.IntValue)
	{
		g_List_Players.Resize(g_Cvar_MaxLength.IntValue);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) || !g_Cvar_MaxLength.IntValue)
	{
		return;
	}
	
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	RemovePlayerFromList(steamId);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client) || !g_Cvar_MaxLength.IntValue)
	{
		return;
	}
	
	PlayerInfo info;	
	info.unixTime = GetTime();
	
	if (!GetClientAuthId(client, AuthId_Steam2, info.steamId, sizeof(PlayerInfo::steamId)))
	{
		Format(info.steamId, sizeof(PlayerInfo::steamId), "N/A");
	}
	
	if (!GetClientName(client, info.clientName, sizeof(PlayerInfo::clientName)))
	{
		Format(info.clientName, sizeof(PlayerInfo::clientName), "N/A");
	}
	
	if (!GetClientIP(client, info.clientIp, sizeof(PlayerInfo::clientIp)))
	{
		Format(info.clientIp, sizeof(PlayerInfo::clientIp), "N/A");
	}
	
	RemovePlayerFromList(info.steamId);
	if (!g_List_Players.Length)
	{
		g_List_Players.PushArray(info);
		return;
	}
	
	g_List_Players.ShiftUp(0);
	g_List_Players.SetArray(0, info);
	if (g_List_Players.Length > g_Cvar_MaxLength.IntValue)
	{
		g_List_Players.Resize(g_Cvar_MaxLength.IntValue);
	}
}

public Action Command_ListDisconnections(int client, int args)
{
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		PrintToChat(client, "See console for output.");
	}
	
	PrintToConsole(client, "Disconnections List:");
	if (!g_List_Players.Length)
	{
		PrintToConsole(client, "No data available.");
		return Plugin_Handled;
	}
	
	PrintToConsole(client, "\n");
	char time[64];
	PlayerInfo info;
	
	g_List_Players.GetArray(0, info);
	int steamLen = strlen(info.steamId);
	int nameLen = strlen(info.clientName);
	int ipLen = strlen(info.clientIp);
	
	int length;
	for (int i = 1; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(0, info);
		length = strlen(info.steamId);
		steamLen = length > steamLen ? length : steamLen;

		length = strlen(info.clientName);
		nameLen = length > nameLen ? length : nameLen;
		
		length = strlen(info.clientIp);
		ipLen = length > ipLen ? length : ipLen;
	}
		
	char steamTitle[64] = "Steam";
	char nameTitle[64] = "Name";
	char ipTitle[64] = "Ip";
	FillStringWithSpaces(steamTitle, steamLen);
	FillStringWithSpaces(nameTitle, nameLen);
	FillStringWithSpaces(ipTitle, ipLen);
	
	PrintToConsole(client, "#   %s   %s   %s   Disconnected", steamTitle, nameTitle, ipTitle);

	for (int i = 0; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(i, info);
		FillStringWithSpaces(info.steamId, steamLen);
		FillStringWithSpaces(info.clientName, nameLen);
		FillStringWithSpaces(info.clientIp, ipLen);
		
		// Transform the unix time into "d h m ago" format type
		FormatTimeDuration(time, sizeof(time), GetTime() - info.unixTime);
		PrintToConsole(client, "%02d. %s   %s   %s   %s ago", i + 1, info.steamId, info.clientName, info.clientIp, time);
	}
	
	return Plugin_Handled;
}

void RemovePlayerFromList(const char[] steamId)
{
	PlayerInfo info;
	for (int i = 0; i < g_List_Players.Length; i++)
	{
		g_List_Players.GetArray(i, info);
		if (steamId[8] != info.steamId[8])
		{
			continue;
		}
		
		if (StrEqual(steamId[10], info.steamId[10], true))
		{
			g_List_Players.Erase(i);
			return;
		}
	}
}

void FillStringWithSpaces(char[] buffer, int maxlen)
{
	int index, length = strlen(buffer);
	if (length >= maxlen)
	{
		return;
	}
	
	for (index = length; index < maxlen; index++)
	{
		buffer[index] = ' ';
	}
	buffer[index] = '\0';
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
