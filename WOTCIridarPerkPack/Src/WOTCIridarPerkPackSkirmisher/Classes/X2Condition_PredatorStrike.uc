class X2Condition_PredatorStrike extends X2Condition;

var float BelowHealthPercent;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit	SourceUnit;
	local XComGameState_Unit	TargetUnit;
	local float TargetCurrentHP;
	local float TargetMaxHP;
	//local float ShooterMaxHP;
	
	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);
	
	if (SourceUnit != none && TargetUnit != none)
	{
		TargetCurrentHP = TargetUnit.GetCurrentStat(eStat_HP);
		TargetMaxHP = TargetUnit.GetMaxStat(eStat_HP);
		//ShooterMaxHP = SourceUnit.GetMaxStat(eStat_HP);
		if (/*TargetCurrentHP < ShooterMaxHP && */TargetCurrentHP / TargetMaxHP < BelowHealthPercent)
		{
			return 'AA_Success'; 
		}
	}
	return 'AA_AbilityUnavailable';
}
