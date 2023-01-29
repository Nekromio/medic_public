#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>
#include <sdktools_sound>
#include <sdktools_tempents>
#include <multicolors>

ConVar
	cvEnable,
	cvMinHealth,
	cvMaxHealth,
	cvCost,
	cvShowCall,
	cvMaxUse,
	cvSound;

int
	iOffsetMoney,
	iMaxUsePlayers[MAXPLAYERS+1];

char
	sSound[256];

Plugin myinfo = 
{
	name = "[Fork] Medic/Медик",
	author = "tuty, Nek.'a 2x2 | ggwp.site ",
	description = "Возможность вызова медика",
	version = "1.0.4",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	LoadTranslations("medic.phrases");

	cvEnable = CreateConVar("sm_medic_enable", "1", "Включить/выключить плагин", _, true, _, true, 1.0);
	
	cvMinHealth = CreateConVar("sm_medic_minhealth", "40", "Минимальное количество хп для использования медика", _, true, 0.0);
	
	cvMaxHealth = CreateConVar("sm_medic_maxhealth", "100", "Максимальное количество хп при лечении", _, true, 0.0);
	
	cvCost = CreateConVar("sm_medic_cost", "2000", "Количество денег необходимая для вызова медика", _, true, 0.0);
	
	cvShowCall = CreateConVar("sm_medic_showcall", "1", "Оповещать других игроков о факте вызова медика", _, true, 0.0);
	
	cvMaxUse = CreateConVar("sm_medic_maxuse", "1", "Сколько раз за 1 раунд игрок может использовать медика", _, true, 0.0);
	
	cvSound = CreateConVar("sm_medic_sound", "misc/medic.wav", "Трек, что будет проигрываться при вызове медика");
	
	iOffsetMoney = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_medic", Command_Medic);
	RegConsoleCmd("sm_doctor", Command_Medic);
	
	AutoExecConfig(true, "medic_all");
}

public void OnClientConnected(int client)
{
	iMaxUsePlayers[client] = 0;
}

public void OnClientDisconnect(int client)
{
	iMaxUsePlayers[client] = 0;
}

public void OnMapStart()
{
	char sBuffer[256];
	cvSound.GetString(sBuffer, sizeof(sBuffer));
	if(sBuffer[0])
	{
		sSound = sBuffer;
		PrecacheSound(sBuffer, true);
		Format(sBuffer, sizeof(sBuffer) - 1, "sound/%s", sSound);
		AddFileToDownloadsTable(sBuffer);
	}
}

Action Event_PlayerSpawn(Event hEvent, const char[] sName, bool dontBroadcast)
{
	if(!cvEnable.BoolValue)
		return;
	
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	iMaxUsePlayers[client] = 0;
}

Action Command_Medic(int client, any args)
{
	if(!cvEnable.BoolValue)
		return Plugin_Handled;
		
	if(!IsClientInGame(client))
		return Plugin_Handled;
		
	if(!IsPlayerAlive(client))
		return Plugin_Handled;

	if(iMaxUsePlayers[client] >= cvMaxUse.IntValue)
	{
		CPrintToChat(client, "%t", "Tag", "Limit", cvMaxUse.IntValue);
		return Plugin_Handled;
	}
	
	int iMoney = GetClientMoney(client);
	
	if(iMoney < cvCost.IntValue && cvCost.IntValue != 0)
	{
		CPrintToChat(client, "%t", "Tag", "Not enough cash", cvCost.IntValue);
		return Plugin_Handled;
	}
	
	int health = GetClientHealth(client);
	if(health >= cvMinHealth.IntValue)
	{
		CPrintToChat(client, "%t", "Tag", "Too much health");	
		return Plugin_Handled;
	}
	
	iMaxUsePlayers[client]++;

	SetEntProp(client, Prop_Data, "m_iHealth", cvMaxHealth.IntValue);
	SetClientMoney(client, iMoney - cvCost.IntValue);
	
	CPrintToChat(client, "%t", "Tag", "The medic helped");	
	
	if(cvShowCall.IntValue)
	{
		char sName[32];
		GetClientName(client, sName, sizeof(sName) - 1);
		for(int i = 1; i <= MaxClients; i++) if(i != client && IsClientInGame(i) && !IsFakeClient(i))
			CPrintToChat(i, "%t", "Tag", "I called a medic", sName, cvMaxHealth.IntValue-health);
	}
	
	float fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	
	if(iMaxUsePlayers[client] <= cvMaxUse.IntValue)
		EmitAmbientSound(sSound, fOrigin, client, SNDLEVEL_CONVO);
	AttachClientIcon(client);
	
	return Plugin_Changed;
}	

stock void SetClientMoney(int iIndex, int iMoney)
{
	if(iOffsetMoney != -1)
	{
		SetEntData(iIndex, iOffsetMoney, iMoney);
	}
}

stock int GetClientMoney(int iIndex)
{
	if(iOffsetMoney != -1)
	{
		return GetEntData(iIndex, iOffsetMoney);
	}
	
	return 0;
}

stock void AttachClientIcon(int iIndex)
{
	TE_Start("RadioIcon");
	TE_WriteNum("m_iAttachToClient", iIndex);
	TE_SendToAll();
}