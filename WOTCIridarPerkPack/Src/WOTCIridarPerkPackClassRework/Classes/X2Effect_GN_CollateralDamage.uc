class X2Effect_GN_CollateralDamage extends X2Effect_Persistent;

var float DamageMod;

function float GetPostDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	if (AbilityState.GetMyTemplateName() == 'IRI_GN_CollateralDamage')
	{
		return CurrentDamage * DamageMod;
	}
	return 0;
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_GN_CollateralDamage_Effect"
}