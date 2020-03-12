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

enum struct PlayerInfoDisplay
{
	char steamId[64];
	int steamLen;
	char clientName[64];
	int nameLen;
	char clientIp[64];
	int ipLen;
	char disconTime[64];
}

ArrayList g_List_LastPlayers;
ConVar g_Cvar_MaxLength;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_List_LastPlayers = new ArrayList(sizeof(PlayerInfo));
	g_Cvar_MaxLength = CreateConVar("sm_disconnections_maxsize", "15", "How many players will be shown in the disconnections history?", FCVAR_NONE, true, 0.0);
	
	g_Cvar_MaxLength.AddChangeHook(ConVarChange_DisconnectionsSize);
	RegConsoleCmd("sm_disconnections", Command_ListDisconnections);
}

public void ConVarChange_DisconnectionsSize(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_List_LastPlayers.Length > g_Cvar_MaxLength.IntValue)
	{
		g_List_LastPlayers.Resize(g_Cvar_MaxLength.IntValue);
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
		Format(info.steamId, sizeof(PlayerInfo::steamId), "n/a");
	}
	
	if (!GetClientName(client, info.clientName, sizeof(PlayerInfo::clientName)))
	{
		Format(info.clientName, sizeof(PlayerInfo::clientName), "n/a");
	}
	
	if (!GetClientIP(client, info.clientIp, sizeof(PlayerInfo::clientIp)))
	{
		Format(info.clientIp, sizeof(PlayerInfo::clientIp), "n/a");
	}
	
	RemovePlayerFromList(info.steamId);
	if (!g_List_LastPlayers.Length)
	{
		g_List_LastPlayers.PushArray(info);
		return;
	}
	
	g_List_LastPlayers.ShiftUp(0);
	g_List_LastPlayers.SetArray(0, info);
	if (g_List_LastPlayers.Length > g_Cvar_MaxLength.IntValue)
	{
		g_List_LastPlayers.Resize(g_Cvar_MaxLength.IntValue);
	}
}

public Action Command_ListDisconnections(int client, int args)
{
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		PrintToChat(client, "%t", "See console for output");
	}
	
	PrintToConsole(client, "Disconnections List:");
	if (!g_List_LastPlayers.Length)
	{
		PrintToConsole(client, "No data available.");
		return Plugin_Handled;
	}
	
	PrintToConsole(client, " ");
	
	PlayerInfo info;
	int maxFormatSteamLen = 5, maxFormatNameLen = 4, maxFormatIpLen = 2, currentTime = GetTime();
	PlayerInfoDisplay[] infoDisplay = new PlayerInfoDisplay[g_List_LastPlayers.Length];
	
	for (int i = 0; i < g_List_LastPlayers.Length; i++)
	{
		g_List_LastPlayers.GetArray(i, info);
		
		infoDisplay[i].steamLen = Format(infoDisplay[i].steamId, sizeof(PlayerInfoDisplay::steamId), "%s", info.steamId);
		infoDisplay[i].nameLen = Format(infoDisplay[i].clientName, sizeof(PlayerInfoDisplay::clientName), "%s", info.clientName);
		infoDisplay[i].ipLen = Format(infoDisplay[i].clientIp, sizeof(PlayerInfoDisplay::clientIp), "%s", info.clientIp);
		FormatTimeDuration(infoDisplay[i].disconTime, sizeof(PlayerInfoDisplay::disconTime), currentTime - info.unixTime);
		
		maxFormatSteamLen = infoDisplay[i].steamLen > maxFormatSteamLen ? infoDisplay[i].steamLen : maxFormatSteamLen;
		maxFormatNameLen = infoDisplay[i].nameLen > maxFormatNameLen ? infoDisplay[i].nameLen : maxFormatNameLen;
		maxFormatIpLen = infoDisplay[i].ipLen > maxFormatIpLen ? infoDisplay[i].ipLen : maxFormatIpLen;
	}
	
	char steamTitle[sizeof(PlayerInfoDisplay::steamId)] = "Steam";
	char nameTitle[sizeof(PlayerInfoDisplay::clientName)] = "Name";
	char ipTitle[sizeof(PlayerInfoDisplay::clientIp)] = "Ip";
	char disconTitle[sizeof(PlayerInfoDisplay::disconTime)] = "Disconnected";
	
	FillString(steamTitle, sizeof(steamTitle), 5, maxFormatSteamLen);
	FillString(nameTitle, sizeof(nameTitle), 4, maxFormatNameLen);
	FillString(ipTitle, sizeof(ipTitle), 2, maxFormatIpLen);
	
	PrintToConsole(client, "#   %s   %s   %s   %s", steamTitle, nameTitle, ipTitle, disconTitle);

	for (int i = 0; i < g_List_LastPlayers.Length; i++)
	{
		FillString(infoDisplay[i].steamId, sizeof(PlayerInfoDisplay::steamId), infoDisplay[i].steamLen, maxFormatSteamLen);
		FillString(infoDisplay[i].clientName, sizeof(PlayerInfoDisplay::clientName), infoDisplay[i].nameLen, maxFormatNameLen);
		FillString(infoDisplay[i].clientIp, sizeof(PlayerInfoDisplay::clientIp), infoDisplay[i].ipLen, maxFormatIpLen);
		
		PrintToConsole(client, "%02d. %s   %s   %s   %s ago", i + 1, infoDisplay[i].steamId, infoDisplay[i].clientName, infoDisplay[i].clientIp, infoDisplay[i].disconTime);
	}
	
	return Plugin_Handled;
}

void RemovePlayerFromList(const char[] steamId)
{
	PlayerInfo info;
	for (int i = 0; i < g_List_LastPlayers.Length; i++)
	{
		g_List_LastPlayers.GetArray(i, info);
		if (steamId[8] != info.steamId[8])
		{
			continue;
		}
		
		if (StrEqual(steamId[10], info.steamId[10], true))
		{
			g_List_LastPlayers.Erase(i);
			return;
		}
	}
}

// Fill string with "space" characters
void FillString(char[] buffer, int maxsize, int start, int end)
{
	int index;
	if (start >= end || start >= maxsize)
	{
		return;
	}
	
	for (index = start; index < end && index < maxsize; index++)
	{
		buffer[index] = ' ';
	}
	buffer[end] = '\0';
}

// Transform unix time into "d h m" format type
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
