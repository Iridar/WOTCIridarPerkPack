class XComGameState_Effect_CritMagic extends XComGameState_Effect;

// Once again, LWOTC causes compatibility issues.
// Normally I just want to use GetShotBreakdown() to get the crit chance, 
// but LWOTC inserts a OverrideFinalHitChanceFns delegate, which caps the crit chance.
// So with LWOTC active we insert our own delegate in front of it, and get the crit chance from there.

var private int CritChance;

final function int GetUncappedCritChance(X2AbilityTemplate Template, XComGameState_Ability AbilityState, Damageable TargetDamageable)
{
	local ShotBreakdown						Breakdown;
	local XComGameState_Unit				TargetUnit;
	local AvailableTarget					AvTarget;

	`AMLOG("Running");

	TargetUnit = XComGameState_Unit(TargetDamageable);
	if (TargetUnit == none)
		return 0;

	Template = AbilityState.GetMyTemplate();
	if (Template == none)
		return 0;

	AvTarget.PrimaryTarget.ObjectID = TargetUnit.ObjectID;

	// Mad scientist laughter
	if (class'X2DLCInfo_WOTCIridarPerkPackBountyHunter'.default.bLWOTC)
	{
		Template.AbilityToHitCalc.OverrideFinalHitChanceFns.InsertItem(0, CritChanceHack);
		Template.AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);
		Template.AbilityToHitCalc.OverrideFinalHitChanceFns.RemoveItem(CritChanceHack);

		`AMLOG("Returning Crit Chance for LWOTC:" @ CritChance);
		return CritChance;
	}

	Template.AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);

	return Breakdown.ResultTable[eHit_Crit];	
}

private function bool CritChanceHack(X2AbilityToHitCalc AbilityToHitCalc, out ShotBreakdown ShotBreakdown)
{
	CritChance = ShotBreakdown.ResultTable[eHit_Crit];

	// Skip vanilla logic, since we don't care what happens afterwards.
	return true;
}
