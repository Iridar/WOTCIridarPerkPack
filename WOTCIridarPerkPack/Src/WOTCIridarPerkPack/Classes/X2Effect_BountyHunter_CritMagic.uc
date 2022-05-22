class X2Effect_BountyHunter_CritMagic extends X2Effect_Persistent;

// Guarantees crits on units that don't see the shooter,
// and increases base damage by crit chance.
// TODO: Display 100% crit chance somehow.

var private X2Condition_Visibility VisibilityCondition;

function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) 
{ 
	if (VisibilityCondition.MeetsConditionWithSource(TargetUnit, Attacker) == 'AA_Success' &&
		class'XComGameStateContext_Ability'.static.IsHitResultHit(CurrentResult))
	{
		NewHitResult = eHit_Crit;
		`AMLOG("Making crit guaranteed");
		return true;
	}
	return false;
}

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local ShotBreakdown			Breakdown;
	local float					Multiplier;
	local AvailableTarget		AvTarget;
	local XComGameState_Unit	TargetUnit;

	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none && VisibilityCondition.MeetsConditionWithSource(TargetUnit, SourceUnit) == 'AA_Success')
	{
		AvTarget.PrimaryTarget.ObjectID = TargetUnit.ObjectID;
		AbilityState.GetMyTemplate().AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);

		Multiplier = Breakdown.ResultTable[eHit_Crit] / 100.0f;

		`AMLOG("Target:" @ TargetUnit.GetFullName() @ "Crit chance:" @ Multiplier @ "Current damage:" @ CurrentDamage @ ", modified by:" @ CurrentDamage * Multiplier);

		return CurrentDamage * Multiplier; 
	}

	return 0;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_BountyHunter_CritMagic_Effect"

	Begin Object Class=X2Condition_Visibility Name=DefaultVisibilityCondition
        bExcludeGameplayVisible = true; //condition will FAIL if there is GameplayVisibility FROM the target TO the source
    End Object
    VisibilityCondition = DefaultVisibilityCondition;
}