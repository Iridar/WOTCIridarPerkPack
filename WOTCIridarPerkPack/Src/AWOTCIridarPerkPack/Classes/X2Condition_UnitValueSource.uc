class X2Condition_UnitValueSource extends X2Condition_UnitValue;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	return 'AA_Success'; 
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit SourceUnit;
	
	SourceUnit = XComGameState_Unit(kSource);
	if (SourceUnit == none)
		return 'AA_NotAUnit';
	
	return super.CallMeetsCondition(SourceUnit); 
}
