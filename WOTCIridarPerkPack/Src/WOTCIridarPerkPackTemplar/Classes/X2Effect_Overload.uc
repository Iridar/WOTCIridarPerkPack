class X2Effect_Overload extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, EffectName, EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local X2EventManager		EventMgr;
	local XComGameState_Ability	AbilityState;
	local StateObjectReference	UnitRef;
	local bool					bShowFlyover;

	`AMLOG("Running for unit:" @ SourceUnit.GetFullName() @ "ability:" @ AbilityContext.InputContext.AbilityTemplateName);

	if (UnitRefTriggersOverload(AbilityContext.InputContext.PrimaryTarget, NewGameState))
	{
		SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		bShowFlyover = true;
	}
	else 
	{
		foreach AbilityContext.InputContext.MultiTargets(UnitRef)
		{
			if (UnitRefTriggersOverload(UnitRef, NewGameState))
			{
				SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
				bShowFlyover = true;
			}
		}
	}

	if (bShowFlyover)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent(EffectName, AbilityState, SourceUnit, NewGameState);
		}
	}
	
	return false;
}


static private function bool UnitRefTriggersOverload(const StateObjectReference UnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit			TargetUnit;
	local DamageResult					DmgResult;
	local X2Effect_ApplyWeaponDamage	DamageEffect;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitRef.ObjectID));
	if (TargetUnit == none || TargetUnit.IsAlive() || TargetUnit.DamageResults.Length == 0)
		return false;

	`AMLOG("Target Unit dead:" @ TargetUnit.GetFullName());

	DmgResult = TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1];

	DamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(DmgResult.SourceEffect.EffectRef));

	`AMLOG("Got damage effect:" @ DamageEffect != none @ "Tag:" @ DamageEffect.DamageTag);

	if (DamageEffect == none || DamageEffect.DamageTag != 'IRI_TM_Volt')
		return false;

	`AMLOG("Triggering Overload.");

	return true;
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_TM_Overload_Effect"
}
