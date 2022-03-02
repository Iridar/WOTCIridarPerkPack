class X2Condition_UnitInSquad extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local StateObjectReference UnitRef;

	UnitRef.ObjectID = kTarget.ObjectID;

	if (`XCOMHQ.IsUnitInSquad(UnitRef))
	{
		return 'AA_Success'; 
	}
	return 'AA_UnitIsWrongType';
}