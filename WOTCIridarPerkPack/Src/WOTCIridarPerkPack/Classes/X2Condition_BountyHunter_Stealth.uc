class X2Condition_BountyHunter_Stealth extends X2Condition;

// Adjusted copy of X2Condition_Stealth.

var bool bCheckFlanking;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit UnitState;
	local array<XComGameState_Item> arrItems;
	local XComGameState_Item ItemIter;

	UnitState = XComGameState_Unit(kTarget);

	if (UnitState == none)
		return 'AA_NotAUnit';

	// Disallow use if already in Deadly Shadow.
	if (UnitState.IsUnitAffectedByEffectName(class'X2Effect_BountyHunter_DeadlyShadow'.default.EffectName))
		return 'AA_UnitIsConcealed';

	// Check flanking only when not concealed already
	if (bCheckFlanking && !UnitState.IsConcealed() && class'X2TacticalVisibilityHelpers'.static.GetNumFlankingEnemiesOfTarget(kTarget.ObjectID) > 0)
		return 'AA_UnitIsFlanked';

	arrItems = UnitState.GetAllInventoryItems();
	foreach arrItems(ItemIter)
	{
		if (ItemIter.IsMissionObjectiveItem() && !ItemIter.GetMyTemplate().bOkayToConcealAsObjective)
			return 'AA_NotWithAnObjectiveItem';
	}

	return 'AA_Success'; 
}

DefaultProperties
{
	bCheckFlanking = true;
}