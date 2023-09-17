class X2Effect_ApplySpiritLinkDamage extends X2Effect_ApplyWeaponDamage;

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Unit	LinkedUnit;
	local XComGameStateHistory	History;
	local DamageResult			DmgResult;
	local UnitValue				UV;

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));
	if (TargetUnit == none)
		return EffectDamageValue;

	if (!TargetUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return EffectDamageValue;

	LinkedUnit = XComGameState_Unit(History.GetGameStateForObjectID(UV.fValue));
	if (LinkedUnit == none || LinkedUnit.DamageResults.Length == 0)
		return EffectDamageValue;

	DmgResult = LinkedUnit.DamageResults[LinkedUnit.DamageResults.Length - 1];

	EffectDamageValue.Damage = DmgResult.DamageAmount;

	`AMLOG("Mirroring:" @ EffectDamageValue.Damage @ "damage from:" @ LinkedUnit.GetFullName() @ "to:" @ TargetUnit.GetFullName());

	return EffectDamageValue; 
}

simulated function bool ModifyDamageValue(out WeaponDamageValue DamageValue, Damageable Target, out array<Name> AppliedDamageTypes)
{
	return false;
}

defaultproperties
{
	DamageTypes(0) = "Psi"
	bIgnoreBaseDamage = true
	bAllowFreeKill = false
	bAllowWeaponUpgrade = false
	bBypassShields = true
	bIgnoreArmor = true
}
