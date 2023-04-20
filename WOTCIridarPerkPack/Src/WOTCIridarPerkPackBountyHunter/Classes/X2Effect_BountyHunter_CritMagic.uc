class X2Effect_BountyHunter_CritMagic extends X2Effect_Persistent;

// Gives bonus crit chance against enemies that don't see us.
// If total crit chance is above 100%, overflow crit chance grants bonus crit damage.

var int BonusCritChance;
var int GrantCritDamageForCritChanceOverflow;

var private X2Condition_Visibility VisibilityCondition;

// Note: this crit chance modifier will be logged, but disregarded for attacks that normally don't allow crits, such as explosives, even with the effect that allows them to crit.
// In order for this crit chance modifier to count for them, this specific effect would need to allow crit override.
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	`AMLOG("Crit Magic:" @ Attacker.GetFullName() @ Attacker.GetFullName() @ VisibilityCondition.MeetsConditionWithSource(Target, Attacker));

	if (VisibilityCondition.MeetsConditionWithSource(Target, Attacker) != 'AA_Success')
		return;

	ShotMod.ModType = eHit_Crit;
	ShotMod.Value = BonusCritChance;
	ShotMod.Reason = FriendlyName;

	`AMLOG("Crit Magic increasing crit chance by:" @ ShotMod.Value);

	ShotModifiers.AddItem(ShotMod);	
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local X2AbilityTemplate					Template;
	local XComGameState_Effect_CritMagic	CritMagic;
	local int								CritChance;

	if (AppliedData.AbilityResultContext.HitResult != eHit_Crit)
		return 0;

	Template = AbilityState.GetMyTemplate();
	if (Template == none || Template.AbilityToHitCalc == none)
		return 0;

	CritMagic = XComGameState_Effect_CritMagic(EffectState);
	if (CritMagic == none)
		return 0;

	CritChance = CritMagic.GetUncappedCritChance(Template, AbilityState, TargetDamageable);

	`LOG("Uncapped crit chance:" @ CritChance,, 'IRITEST');

	// Take away 100%, since we're interested only in overflow crit chance.
	CritChance = CritChance - 100;
	if (CritChance < 0) 
		return 0;

	`AMLOG("Crit chance overflow:" @ CritChance @ "bonus damage:" @ CritChance / GrantCritDamageForCritChanceOverflow);

	return CritChance / GrantCritDamageForCritChanceOverflow;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_BountyHunter_CritMagic_Effect"
	bDisplayInSpecialDamageMessageUI=true
	GameStateEffectClass = class'XComGameState_Effect_CritMagic'

	Begin Object Class=X2Condition_Visibility Name=DefaultVisibilityCondition
        bExcludeGameplayVisible = true; //condition will FAIL if there is GameplayVisibility FROM the target TO the source
    End Object
    VisibilityCondition = DefaultVisibilityCondition;
}