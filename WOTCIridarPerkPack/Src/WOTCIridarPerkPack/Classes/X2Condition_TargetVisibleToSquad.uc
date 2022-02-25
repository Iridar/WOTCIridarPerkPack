class X2Condition_TargetVisibleToSquad extends X2Condition;

var bool bReverseCondition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	if (bReverseCondition)
	{
		if (!class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(kTarget.ObjectID))
		{
			return 'AA_Success';
		}
		return 'AA_NotVisible';
	}
	else
	{
		if (class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(kTarget.ObjectID))
		{
			return 'AA_Success';
		}
		return 'AA_NotVisible';
	}
}
