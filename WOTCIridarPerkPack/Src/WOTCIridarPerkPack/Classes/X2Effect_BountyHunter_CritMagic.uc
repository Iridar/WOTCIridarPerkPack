class X2Effect_BountyHunter_CritMagic extends X2Effect_Persistent;

function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) 
{ 
	if (class'XComGameStateContext_Ability'.static.IsHitResultHit(CurrentResult))
	{
		NewHitResult = eHit_Crit;
		`AMLOG("Making crit guaranteed");
		return true;
	}
	return false;
}

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local ShotBreakdown		Breakdown;
	local float				Multiplier;
	local AvailableTarget	AvTarget;

	AvTarget.PrimaryTarget.ObjectID = XComGameState_BaseObject(Target).ObjectID;
	AbilityState.GetMyTemplate().AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);

	Multiplier = Breakdown.ResultTable[eHit_Crit];
	Multiplier /= 100;

	`AMLOG("Target:" @ XComGameState_Unit(Target).GetFullName() @ "Crit chance:" @ Multiplier @ "Current damage:" @ CurrentDamage @ ", modified by:" @ CurrentDamage * Multiplier);

	return CurrentDamage * Multiplier; 
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_BountyHunter_CritMagic_Effect"
}