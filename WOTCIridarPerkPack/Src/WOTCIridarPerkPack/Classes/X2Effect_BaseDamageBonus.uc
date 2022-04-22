class X2Effect_BaseDamageBonus extends X2Effect_Persistent;

var float	DamageMod;
var bool	bOnlyWhileConcealed;

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	if (bOnlyWhileConcealed && !TargetUnit.IsConcealed())
	{
		return false;
	}
	return true; 
}

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local float BonusDamage;

	if (IsEffectCurrentlyRelevant(EffectState, SourceUnit))
	{
		BonusDamage += CurrentDamage * DamageMod;
	}
	
	return BonusDamage; 
}

defaultproperties
{
	EffectName = "X2Effect_BaseDamageBonus_Effect"
	DuplicateResponse = eDupe_Allow
	bDisplayInSpecialDamageMessageUI=true
}
