class X2Effect_BountyHunter_BombRaider extends X2Effect_BiggestBooms;

// Same as original, we just add an additional bonus if the soldier has Dead of Night and is not seen by the target.
// Dead of Night itself will handle additional damage bonus.

var int BonusCritChanceWhenUnseen;
var private X2Condition_Visibility VisibilityCondition;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo BoomInfo;

	if (bIndirectFire)
	{
		BoomInfo.ModType = eHit_Crit;
		BoomInfo.Value = default.CRIT_CHANCE_BONUS;

		if (Attacker.HasSoldierAbility('IRI_BH_Nightfall_Passive') && VisibilityCondition.MeetsConditionWithSource(Target, Attacker) == 'AA_Success')
		{
			// Add Dead of Night crit chance bonus here, since Dead of Night itself cannot add it without allowing critting for all abilities that normally cannot crit.
			BoomInfo.Value += BonusCritChanceWhenUnseen;
		}

		`AMLOG("Bomb Raider Increasing crit chance by:" @ BoomInfo.Value);

		BoomInfo.Reason = FriendlyName;
		ShotModifiers.AddItem(BoomInfo);
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_BountyHunter_BombRaider_Effect"
	bDisplayInSpecialDamageMessageUI = true

	Begin Object Class=X2Condition_Visibility Name=DefaultVisibilityCondition
        bExcludeGameplayVisible = true; //condition will FAIL if there is GameplayVisibility FROM the target TO the source
    End Object
    VisibilityCondition = DefaultVisibilityCondition;
}
