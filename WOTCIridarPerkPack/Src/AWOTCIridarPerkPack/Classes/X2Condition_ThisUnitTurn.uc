class X2Condition_ThisUnitTurn extends X2Condition;

var bool bReverseCondition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameState_Unit	UnitState;
	
	UnitState = XComGameState_Unit(kTarget);
	
	if (UnitState == none)
		return 'AA_NotAUnit';

	if (bReverseCondition)
	{
		if (UnitState.ControllingPlayer != `TACTICALRULES.GetCachedUnitActionPlayerRef())
			return 'AA_Success'; 
	}
	else
	{
		if (UnitState.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef())
			return 'AA_Success'; 
	}

	return 'AA_AbilityUnavailable';
}
