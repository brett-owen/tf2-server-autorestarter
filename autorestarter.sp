#include <sourcemod>

#define PLUGIN_VERSION "0.1"

public Plugin autorestarter =
{
	name = "Server Autorestarter",
	author = "Pye",
	description = "Restarts the server if it is currently empty every sm_autorestarter_timer seconds",
	version = PLUGIN_VERSION,
	url = ""
};

Handle cvar_Enabled = INVALID_HANDLE; 
Handle cvar_Timer = INVALID_HANDLE; 

Handle player_IDs;
int player_Count = 0;

public OnPluginStart()
{
    cvar_Enabled = CreateConVar("sm_autorestarter_enabled", "1.0", "1 to enable plugin. Restarts server if empty");
    cvar_Timer = CreateConVar("sm_autorestarter_timer", "3600.0", "Interval to check for server being empty, in seconds");
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
    player_IDs = CreateTrie();
}

public OnConfigsExecuted()
{
    if(!GetConVarBool(cvar_Enabled))
        return;
    char cvarStr[32];
    GetConVarString(cvar_Timer, cvarStr, sizeof(cvarStr));
    CreateTimer(StringToFloat(cvarStr), Timer_AutoRestart, TIMER_REPEAT);
}

public OnClientPostAdminCheck(int client)
{
    if(!isValidClient(client))
        return;
    if(!GetConVarBool(cvar_Enabled))
        return;

    char index[16];
    IntToString(GetClientUserId(client), index, sizeof(index));
    if(SetTrieValue(player_IDs, index, 1, false))
    {
        player_Count++;
    }
    return;
}

public Action:Event_PlayerDisconnect(Handle event, const String:name[], bool dontBroadcast)
{
    if(!GetConVarBool(cvar_Enabled))
        return;
    int userid = GetEventInt(event, "userid");
    if(!userid)
        return;

    char index[16];
    IntToString(userid, index, sizeof(index));
    if(RemoveFromTrie(player_IDs, index))
    {
        player_Count--;
    }
    if(player_Count == 0)
      CreateTimer(60.0, Timer_AutoRestart);
}

public Action:Timer_AutoRestart(Handle timer)
{
    if(!GetConVarBool(cvar_Enabled))
        return;
    if(player_Count > 0)
        return;

    LogToGame("Server empty, restarting.");
    ServerCommand("_restart");
    return;
}

bool isValidClient(int client)
{
    if(client < 1 || client > MaxClients)
        return false;
    if(!IsClientConnected(client))
        return false;
    if(IsClientInKickQueue(client))
        return false;
    if(IsClientSourceTV(client))
        return false;
    return IsClientInGame(client);
}