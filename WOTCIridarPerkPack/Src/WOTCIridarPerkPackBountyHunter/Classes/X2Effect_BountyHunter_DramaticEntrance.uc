class X2Effect_BountyHunter_DramaticEntrance extends X2Effect_Persistent;

// Based on Quick Feet from Extended Perk Pack.

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
	local XComGameStateHistory		History;
	local XComGameState_Ability		AbilityState;
	local X2AbilityTemplate			AbilityTemplate;
	local UnitValue					UV;

	History = `XCOMHISTORY;
	if(!SourceUnit.WasConcealed(History.GetEventChainStartIndex()))
	{
		//`AMLOG("Unit wasn't concealed, exiting");
		return false;
	}
	if (SourceUnit.GetUnitValue(EffectName, UV))
	{
		//`AMLOG("Unit value is present, exiting");
		return false;
	}
	if(!kAbility.IsAbilityInputTriggered() || kAbility.RetainConcealmentOnActivation(AbilityContext))
	{
		//`AMLOG(kAbility.GetMyTemplateName() @ "is not valid for Dramatic Entrance");
		return false;
	}
	AbilityTemplate = kAbility.GetMyTemplate();
	if (AbilityTemplate == none)
		return false;

	if (!AbilityTemplate.TargetEffectsDealDamage(kAbility.GetSourceWeapon(), kAbility))
	{
		//`AMLOG(kAbility.GetMyTemplateName() @ "is doesn't deal damage");
		return false; 
	}

	// Exit early if the unit is affected by Followthrough, it has its own piece of code to handle this ability.
	//if (class'BountyHunter'.static.IsAbilityValidForFollowthrough(kAbility) && SourceUnit.IsUnitAffectedByEffectName(class'X2Effect_BountyHunter_Folowthrough'.default.EffectName))
	//{
	//	`AMLOG("Followthrough effect is present, exiting");
	//	return false;
	//}

	//`AMLOG("Triggering Dramatic Entrance");
    SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);
	SourceUnit.SetUnitFloatValue(EffectName, 1.0f, eCleanup_BeginTurn);

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	`XEVENTMGR.TriggerEvent(EffectName, AbilityState, SourceUnit, NewGameState);

	return false;
}

static final function MaybeTriggerExplosiveAction(out XComGameState_Unit NewUnitState, XComGameState NewGameState, optional bool bNeedToModifyUnitState)
{
	local XComGameState_Effect		EffectState;
	local XComGameState_Ability		AbilityState;
	local UnitValue					UV;

	if (bNeedToModifyUnitState)
	{
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(NewUnitState.Class, NewUnitState.ObjectID));
	}
	EffectState = NewUnitState.GetUnitAffectedByEffectState(default.EffectName);
	if (EffectState == none)
	{
		//`AMLOG("Dramatic Entrance effect is not present, exiting");
		return;
	}
	if (NewUnitState.GetUnitValue(default.EffectName, UV))
	{
		//`AMLOG("Unit value is present, exiting");
		return;
	}

	//`AMLOG("Triggering Dramatic Entrance");

	NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);
	NewUnitState.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	`XEVENTMGR.TriggerEvent(default.EffectName, AbilityState, NewUnitState, NewGameState);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_ExplosiveAction_Effect"
}