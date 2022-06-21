class X2Effect_BountyHunter_NightRounds extends X2Effect_Persistent;

var int BonusCritDamage;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);
	if (TargetUnit == none || TargetUnit.CanTakeCover())
		return 0;

	if (Attacker.IsConcealed() && EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID == AbilityState.SourceWeapon.ObjectID && AppliedData.AbilityResultContext.HitResult == eHit_Crit)
	{
		return BonusCritDamage;
	}
	return 0; 
}

defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_NightRounds_Effect"
}
