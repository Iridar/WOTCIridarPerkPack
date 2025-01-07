class X2Effect_RifleGrenade extends X2Effect_Persistent;

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{ 
	if (NewGameState != none) // So it doesn't affect damage preview
	{
		if (ApplyEffectParameters.AbilityInputContext.AbilityTemplateName == 'IRI_BH_RifleGrenade' &&
			ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		{
			return `GetConfigFloat("IRI_BH_RifleGrenade_DamageBonusPercent") * CurrentDamage; 
		}
	}
	return 0.0f;
}

function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters) 
{
	if (ApplyEffectParameters.AbilityInputContext.AbilityTemplateName == 'IRI_BH_RifleGrenade' &&
			ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
	{
		return 999; 
	}
	return 0; 
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_RifleGrenade_Effect"
	bDisplayInSpecialDamageMessageUI = true
}
