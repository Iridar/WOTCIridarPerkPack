class X2Effect_BaseDamageBonus extends X2Effect_Persistent;

var float	DamageMod;
var name	AbilityName;
var bool	bOnlyPrimaryTarget;

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local float BonusDamage;

	if (bOnlyPrimaryTarget)
	{
		if (ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID != ApplyEffectParameters.TargetStateObjectRef.ObjectID)
			return 0;
	}

	if (IsAbilityValidForBonusDamage(AbilityState))
	{
		BonusDamage += CurrentDamage * DamageMod;
	}
	
	return BonusDamage; 
}

private function bool IsAbilityValidForBonusDamage(const XComGameState_Ability AbilityState)
{
	return AbilityState.GetMyTemplateName() == AbilityName;
}

defaultproperties
{
	DuplicateResponse = eDupe_Allow
	bDisplayInSpecialDamageMessageUI=true
}
