class X2Condition_Concentration extends X2Condition;

// Can't apply the effect if we're already applying it to someone else.
var private X2Condition_UnitEffectsApplying UniqueEffectCondition;

// Can't apply the effect to the target if we already applied it to the target
var private X2Condition_UnitEffectsWithAbilitySource EffectCondition;

// Can't apply the effect if we're missing the Concentration ability
var private X2Condition_AbilityProperty AbilityCondition;


event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	`AMLOG(EffectCondition.ExcludeEffects.Length @ XComGameState_Unit(kTarget).GetFullName() @ EffectCondition.CallMeetsCondition(kTarget));

	return EffectCondition.CallMeetsCondition(kTarget);
}


event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local name RetVal;

	

	RetVal = EffectCondition.CallMeetsConditionWithSource(kTarget, kSource);

	`AMLOG(XComGameState_Unit(kTarget).GetFullName() @ XComGameState_Unit(kSource).GetFullName() @ "RetVal:" @ RetVal);
	if (RetVal != 'AA_Success')
	{
		return RetVal;
	}
	`AMLOG(UniqueEffectCondition.ExcludeEffects.Length @ XComGameState_Unit(kTarget).GetFullName() @ XComGameState_Unit(kSource).GetFullName() @ "UniqueEffectCondition:" @ UniqueEffectCondition.CallMeetsCondition(kSource));
	return UniqueEffectCondition.CallMeetsCondition(kSource);
}

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) 
{
	
	`AMLOG(AbilityCondition.OwnerHasSoldierAbilities.Length @ XComGameState_Unit(kTarget).GetFullName() @ AbilityCondition.CallAbilityMeetsCondition(kAbility, kTarget));
	return AbilityCondition.CallAbilityMeetsCondition(kAbility, kTarget);
}

defaultproperties
{	
    Begin Object Class=X2Condition_UnitEffectsApplying Name=DefaultUniqueEffectCondition
	ExcludeEffects(0) = (EffectName = "IRI_TM_Concentration_Effect", Reason = "AA_DuplicateEffectIgnored")
    End Object
    UniqueEffectCondition = DefaultUniqueEffectCondition;

    Begin Object Class=X2Condition_UnitEffectsWithAbilitySource Name=DefaultEffectCondition
	ExcludeEffects(0) = (EffectName = "IRI_TM_Concentration_Effect", Reason = "AA_DuplicateEffectIgnored")
    End Object
    EffectCondition = DefaultEffectCondition;

	Begin Object Class=X2Condition_AbilityProperty Name=DefaultAbilityCondition
    OwnerHasSoldierAbilities(0) = "IRI_TM_Concentration"
    End Object
    AbilityCondition = DefaultAbilityCondition;
}
