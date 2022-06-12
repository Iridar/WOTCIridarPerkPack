class X2Effect_BountyHunter_CritMagic extends X2Effect_Persistent;

// Guarantees crits on units that don't see the shooter,
// and increases base damage by crit chance.

var private X2Condition_Visibility VisibilityCondition;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	//`AMLOG(Attacker.GetFullName() @ Attacker.GetFullName() @ VisibilityCondition.MeetsConditionWithSource(Target, Attacker));

	if (VisibilityCondition.MeetsConditionWithSource(Target, Attacker) != 'AA_Success')
		return;

	ShotMod.ModType = eHit_Crit;
	ShotMod.Value = 100;
	ShotMod.Reason = FriendlyName;

	ShotModifiers.AddItem(ShotMod);	
}

// Need this bit for Bomb Raider / Biggest Booms to work properly.
function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) 
{ 
	if (VisibilityCondition.MeetsConditionWithSource(TargetUnit, Attacker) == 'AA_Success' && 
		class'XComGameStateContext_Ability'.static.IsHitResultHit(CurrentResult))
	{
		NewHitResult = eHit_Crit;
		return true;
	}
	return false;
}

static final function int GetCritDamageBonus(const XComGameState_Unit Attacker, const XComGameState_Unit TargetUnit, const XComGameState_Ability AbilityState)
{
	local ShotBreakdown			Breakdown;
	local float					Multiplier;
	local AvailableTarget		AvTarget;
	local X2WeaponTemplate		WeaponTemplate;
	local XComGameState_Item	ItemState;
	local X2AbilityTemplate		Template;
	local float					CritChance;

	ItemState = AbilityState.GetSourceWeapon();
	if (ItemState == none)
		return 0;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate == none)
		return 0;

	Template = AbilityState.GetMyTemplate();
	if (Template == none)
		return 0;
	
	AvTarget.PrimaryTarget.ObjectID = TargetUnit.ObjectID;
	Template.AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);

	// Take away 100% we've added previously
	CritChance = Breakdown.ResultTable[eHit_Crit] - 100;

	// Crit chance has been penalized by something. Provide no damage bonus. 
	// (if we don't do the check, we're gonna end up reducing damage)
	if (CritChance < 0) 
		return 0;

	Multiplier = CritChance / 100.0f;

	`AMLOG("Base crit damage:" @ WeaponTemplate.BaseDamage.Crit @ "multiplier:" @ Multiplier @ "damage bonus:" @ int(WeaponTemplate.BaseDamage.Crit * Multiplier));

	return WeaponTemplate.BaseDamage.Crit * Multiplier;
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local XComGameState_Unit	TargetUnit;

	TargetUnit = XComGameState_Unit(TargetDamageable);
	if (TargetUnit != none && VisibilityCondition.MeetsConditionWithSource(TargetUnit, Attacker) == 'AA_Success')
	{
		return GetCritDamageBonus(Attacker, TargetUnit, AbilityState);
	}
	return 0; 
}


static final function bool IsCritGuaranteed(const XComGameState_Unit Attacker, const XComGameState_Unit TargetUnit)
{
	return default.VisibilityCondition.MeetsConditionWithSource(TargetUnit, Attacker) == 'AA_Success';
}
/*
function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) 
{ 
	if (VisibilityCondition.MeetsConditionWithSource(TargetUnit, Attacker) == 'AA_Success' && 
		class'XComGameStateContext_Ability'.static.IsHitResultHit(CurrentResult))
	{
		NewHitResult = eHit_Crit;
		//`AMLOG("Making crit guaranteed");
		return true;
	}
	return false;
}*/
/*
function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local float					Multiplier;
	local XComGameState_Unit	TargetUnit;

	TargetUnit = XComGameState_Unit(Target);
	if (TargetUnit != none && VisibilityCondition.MeetsConditionWithSource(TargetUnit, SourceUnit) == 'AA_Success')
	{
		Multiplier = GetDamageModifier(SourceUnit, TargetUnit, AbilityState);
		//`AMLOG("Target:" @ TargetUnit.GetFullName() @ "Crit chance:" @ Multiplier @ "Current damage:" @ CurrentDamage @ ", modified by:" @ CurrentDamage * Multiplier);

		return CurrentDamage * Multiplier; 
	}

	return 0;
}

static final function float GetDamageModifier(const XComGameState_Unit Attacker, const XComGameState_Unit TargetUnit, const XComGameState_Ability AbilityState)
{
	local ShotBreakdown			Breakdown;
	local float					Multiplier;
	local AvailableTarget		AvTarget;
	local X2AbilityTemplate		Template;

	Template = AbilityState.GetMyTemplate();
	if (Template != none)
	{
		AvTarget.PrimaryTarget.ObjectID = TargetUnit.ObjectID;
	
		Template.AbilityToHitCalc.GetShotBreakdown(AbilityState, AvTarget, Breakdown);

		Multiplier = Breakdown.ResultTable[eHit_Crit] / 100.0f;
	}
	return Multiplier;
}
*/

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_BountyHunter_CritMagic_Effect"

	Begin Object Class=X2Condition_Visibility Name=DefaultVisibilityCondition
        bExcludeGameplayVisible = true; //condition will FAIL if there is GameplayVisibility FROM the target TO the source
    End Object
    VisibilityCondition = DefaultVisibilityCondition;
}