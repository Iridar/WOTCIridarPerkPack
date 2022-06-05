class X2AbilityTarget_BountyHunter_ShadowTeleport extends X2AbilityTarget_MovingMelee;

simulated function name GetPrimaryTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets)
{
	local AvailableTarget				Target;
	local array<StateObjectReference>	VisibleUnits;
	local StateObjectReference			VisibleUnit;
	//local X2AbilityTemplate				Template;

	//Template = Ability.GetMyTemplate();
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(Ability.OwnerStateObject.ObjectID, VisibleUnits/*, Template.AbilityTargetConditions*/);

	foreach VisibleUnits(VisibleUnit)
	{
		Target.PrimaryTarget = VisibleUnit;
		Targets.AddItem(Target);
	}

	return 'AA_Success';
}

simulated function name CheckFilteredPrimaryTargets(const XComGameState_Ability Ability, const out array<AvailableTarget> Targets)
{
	if (Targets.Length > 0)
	{
		return 'AA_Success';
	}
	return 'AA_NoTargets';
}
