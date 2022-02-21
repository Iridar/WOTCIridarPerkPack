class X2Effect_ToxinAptitude extends X2Effect_Persistent;

var float DamageModifier;

// I'd prefer to use just the GetPreDefaultAttackingDamageModifier_CH(), but relying on it alone may result in not getting any bonus damage at all. 
// So have to do a banana plan - use GetAttackingDamageModifier if the bonus damage is less than 1, 
// and GetPreDefaultAttackingDamageModifier_CH if the bonus damage is higher or equal to 1.
// The goal is increase damage by 20%, but at least by +1.

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{ 
	local float DamageBonus;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	WeaponDamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(AppliedData.EffectRef));
	
	DamageBonus = GetDamageBonus(WeaponDamageEffect, NewGameState, AppliedData, TargetDamageable, CurrentDamage);

	if (DamageBonus != 0 && DamageBonus < 1.0f)
	{
		return 1;
	}
	
	return 0; 
}

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{ 
	local float DamageBonus;

	DamageBonus = GetDamageBonus(WeaponDamageEffect, NewGameState, ApplyEffectParameters, Target, CurrentDamage);
	if (DamageBonus >= 1)
	{
		return DamageBonus;
	}

	return 0.0f;
}

private function float GetDamageBonus(X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState, EffectAppliedData ApplyEffectParameters, Damageable Target, float CurrentDamage)
{
	local XComGameState_Unit TargetUnit;
	local array<name> EffectDamageTypes;

	// Increase poison damage
	if (WeaponDamageEffect != none)
	{
		WeaponDamageEffect.GetEffectDamageTypes(NewGameState, ApplyEffectParameters, EffectDamageTypes);

		if (EffectDamageTypes.Find('Poison') != INDEX_NONE)
		{
			return CurrentDamage * DamageModifier;
		}
	}

	// Increase damage to poisoned targets
	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none && TargetUnit.IsPoisoned())
	{
		return CurrentDamage * DamageModifier;
	}

	return 0.0; 
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_ToxinAptitude_Effect"
	bDisplayInSpecialDamageMessageUI = true
}