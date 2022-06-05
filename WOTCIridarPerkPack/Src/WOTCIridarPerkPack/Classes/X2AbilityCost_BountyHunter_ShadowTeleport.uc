class X2AbilityCost_BountyHunter_ShadowTeleport extends X2AbilityCost_ActionPoints;

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit ModifiedUnitState;

	if (`CHEATMGR != none && `CHEATMGR.bUnlimitedActions)
		return;

	//super.ApplyCost(AbilityContext, kAbility, AffectState, AffectWeapon, NewGameState);

	ModifiedUnitState = XComGameState_Unit(AffectState);
	ModifiedUnitState.ActionPoints.Length = 0;
	ModifiedUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
}

defaultproperties
{
	iNumPoints = 1
	bConsumeAllPoints = true
}