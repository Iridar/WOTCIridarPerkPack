class X2Condition_NotVisibleToEnemies extends X2Condition;

//	Conditions succeeds if the unit is currently not visible to any enemies. Originally created by Musashi.

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local int NumEnemyViewers;

	NumEnemyViewers = class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(kTarget.ObjectID);

	if (NumEnemyViewers > 0) return 'AA_AbilityUnavailable';

	return 'AA_Success'; 
}