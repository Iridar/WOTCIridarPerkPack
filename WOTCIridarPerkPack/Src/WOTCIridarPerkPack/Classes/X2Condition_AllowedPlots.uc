class X2Condition_AllowedPlots extends X2Condition;

var array<string> AllowedPlots;
/*
CityCenter
Wilderness
Shanty
SmallTown
Slums
Facility
Rooftops
MP_Test
Abandoned
Tunnels_Sewer
Tunnels_Subway
Stronghold
*/

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData	BattleData;
	local XComGameState_MissionSite MissionSite;
	local XComGameStateHistory		History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleData != none)
	{
		MissionSite = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));
		if (MissionSite != none)
		{
			
			`LOG("Current PlotMapName:" @ MissionSite.GeneratedMission.Plot.strType,, 'IRITEST');

			if (AllowedPlots.Find(MissionSite.GeneratedMission.Plot.strType) != INDEX_NONE)
			{
				return 'AA_Success';
			}
		}
	
	}
	return 'AA_AbilityUnavailable';
}
