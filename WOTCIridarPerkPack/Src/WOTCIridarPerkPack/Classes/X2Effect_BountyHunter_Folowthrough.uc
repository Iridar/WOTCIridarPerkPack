class X2Effect_BountyHunter_Folowthrough extends X2Effect_Persistent;

// This effect is tracked in two ways.
// 1. Effect is present. It means Followthrough has not yet successfully retriggered anything.
// 2. Unit Value is present. It means the next ability activated may be retriggered by Followthrough.
// If an ability is activated, and both Effect and Unit Value are present, then we'll attempt to retrigger that ability.
// If Effect is present, but Unit Value is not, then the activated ability *is* us retriggereing the ability by Followthrough, so we do nothing.

// Ideally, order of events looks like this:

// A. When concealed:
// 1. Player is concealed and activates Followthrough, which applies the Unit Value.
// 2. Player activates attack that normally breaks concealment.
// 3. DeadlyShadow::OnAbilityActivated_IMM runs. It sees the unit is affected by Followthrough Effect and the ability is valid for Followthrough and does nothing.
//  --- Alternative: ability is not valid for Followthrough, and removes the super concealment flag from the unit, letting the ability activation break concealment.
// 4. XCGS_Unit::OnAbilityActivated_OSS runs. It triggers the event RetainConcealmentOnActivation.
// 5. Followthrough::OnRetainConcealmentOnActivation_IMM runs. It sees the ability is valid for Followthrough and that the Unit Value is present, and keeps the unit concealed.
//  --- Alternative: ability is not valid for Followthrough, and the event listener does nothing, which would make the ability break concealment.
// 6. DeadlyShadow::OnRetainConcealmentOnActivation_IMM runs and does nothing.
// ?. Sometime during the above, Followthrough::PostAbilityCostPaid runs, sees the unit value is present, and stores the action points the unit had after activating the ability in the custom effect state.
// Then it restores the AP to what it was before the ability activation.
// 8. Followthrough::OnAbilityActivated runs. It seens the ability is valid for Followthrough and removes the unit value from the unit. 
// It also checks if the ability normally breaks concealment, and if so, removes the super concealment flag from the unit, so that reactivating the ability reliably breaks concealment.
//  --- Alternative: ability is not valid for Followthrough, and the event listener does nothing.
// Then the listener attempts to retrigger the ability, and there are two scenarios possible:
// A. Ability activates successfully. This should break concealment, since we removed the super concealment flag previously. We mop up by removing the Followthrough effect from the unit.
// B. Ability fails to activate. Then we enter the failsafe scenario. Using the Effect State, the unit's AP are restored to what they were before the retrigger. 
// Unit value is reapplied so that the player can attempt to activate Followthrough again with some other ability, though they may not have enough AP for that anymore.
// We also manually break concealment at this point. The intention is that concealement preservation is temporary, just for the ability retrigger by Followthrough.

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{ 
	local UnitValue UV;

	return TargetUnit.GetUnitValue(EffectName, UV); 
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_Folowthrough_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'RetainConcealmentOnActivation', OnRetainConcealmentOnActivation, ELD_Immediate, 15, ,, UnitState);	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, 40, UnitState,, EffectObj);	

	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_Folowthrough_Event', AbilityState, SourceUnit, NewGameState);

}

// Some abilities can be activated only while unit is unseen (in concealment). So when the soldier triggers an ability that is eligible for Followthrough,
// we must keep the unit in concealment, and let the retrigger break the concealment.

// Responsible for keeping the unit in concealment when activating an ability that will be retriggered by Followthrough.
static private function EventListenerReturn OnRetainConcealmentOnActivation(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple					Tuple;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;
	local XComGameStateHistory			History;
	local UnitValue						UV;
	local XComGameState_Unit			UnitState;

	// Don't proceed if this ability retains concealment.
	Tuple = XComLWTuple(EventData);
	if (Tuple == none || Tuple.Data[0].b) 
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(EventSource);
	if (AbilityContext == none) 
		return ELR_NoInterrupt;

	// EventSource is Context, so can't use object filter when registering for the event.
	// Do this check to make sure the unit in this event is the same unit to which this effect is applied.
	if (XComGameState_Unit(CallbackData) == none || 
		AbilityContext.InputContext.SourceObject.ObjectID != XComGameState_Unit(CallbackData).ObjectID)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (UnitState == none) 
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none) 
		return ELR_NoInterrupt;

	// don't break concealment if attacks never break concealment.
	if (class'BountyHunter'.static.IsAbilityValidForDeadlierShadow(AbilityState) && UnitState.HasSoldierAbility('IRI_BH_DeadlierShadow_Passive'))
	{
		Tuple.Data[0].b = true;
		return ELR_NoInterrupt;
	}
	
	// If unit value is present, it means this ability activation will trigger Followthrough. Don't break concelament.
	if (class'BountyHunter'.static.IsAbilityValidForFollowthrough(AbilityState) && UnitState.GetUnitValue(default.EffectName, UV))
	{
		Tuple.Data[0].b = true;
	}

	return ELR_NoInterrupt;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	
	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		`AMLOG("Effect applied, setting unit value.");
		UnitState.SetUnitFloatValue(EffectName, 1.0f, eCleanup_BeginTurn);
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

// Responsible for Followthrough's functionality in retriggering abilities.
// Also breaks unit's concealment when failing to retrigger.
static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState					NewGameState;
	local UnitValue						UV;
	local bool							bRetainConcealment;
	local XComGameState_Effect_BountyHunter_Followthrough EffectState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	// Exit if there's no Unit Value on the unit, which indicates that this listener is currently running for the ability activated by Followthrough itself.
	if (!UnitState.GetUnitValue(default.EffectName, UV))
	{
		`AMLOG("Exiting because no Unit Value");
		return ELR_NoInterrupt;
	}

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	`AMLOG(UnitState.GetFullName() @ AbilityState.GetMyTemplateName() @ "running");
	
	if (!class'BountyHunter'.static.IsAbilityValidForFollowthrough(AbilityState))
	{
		`AMLOG(UnitState.GetFullName() @ AbilityState.GetMyTemplateName() @ "Exiting because ability is not valid for Followthrough");
		return ELR_NoInterrupt;
	}
	EffectState = XComGameState_Effect_BountyHunter_Followthrough(CallbackData);
	if (EffectState == none)
	{
		`AMLOG("Exiting because no Effect State");
		return ELR_NoInterrupt;
	}
	
	bRetainConcealment = AbilityState.RetainConcealmentOnActivation(AbilityContext) || class'BountyHunter'.static.IsAbilityValidForDeadlierShadow(AbilityState) && UnitState.HasSoldierAbility('IRI_BH_DeadlierShadow_Passive');

	// Prepare to attempt to retrigger the ability.
	// Clear the unit value so this event listener itself and PostAbilityCostPaid will not mess with the retrigger.
	// If the attack should break concealment, remove the super concealment flag.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Followthrough Unit Value");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.ClearUnitValue(default.EffectName);
	if (!bRetainConcealment)
	{
		UnitState.bHasSuperConcealment = false;
	}
	`GAMERULES.SubmitGameState(NewGameState);

	`AMLOG("Cleared Unit Value, retriggering ability, which will break concealment:" @ !bRetainConcealment);

	if (AbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false))
	{
		// TODO: Get context here and insert a Merge Vis function to block enter->exit cover between shots.
		`AMLOG("Triggered ability successfully, removing effect.");

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Followthrough Unit Value");
		EffectState.RemoveEffect(NewGameState, NewGameState, true);
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		`AMLOG("Failed to retrigger ability, restoring AP, readding Unit Value");

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Followthrough Unit Value");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
		UnitState.ActionPoints = EffectState.ActionPoints;
		UnitState.ReserveActionPoints = EffectState.ReserveActionPoints;
		if (!bRetainConcealment)
		{
			`AMLOG("Breaking concealment.");
			UnitState.bHasSuperConcealment = false;
			`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
		}
		`GAMERULES.SubmitGameState(NewGameState);
	}
	
    return ELR_NoInterrupt;
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{
	local X2AbilityTemplate AbilityTemplate;
	local UnitValue UV;
	local XComGameState_Effect_BountyHunter_Followthrough FollowthroughEffectState;

	if (SourceUnit.GetUnitValue(EffectName, UV))
	{
		AbilityTemplate = kAbility.GetMyTemplate();

		if (AbilityTemplate != none && AbilityTemplate.TargetEffectsDealDamage(kAbility.GetSourceWeapon(), kAbility))
		{
			`AMLOG("Restoring action points");

			// Store unit's action points in Effect State so they can be restored later in case Followthrough fails to activate for whatever reason.
			FollowthroughEffectState = XComGameState_Effect_BountyHunter_Followthrough(NewGameState.ModifyStateObject(class'XComGameState_Effect_BountyHunter_Followthrough', EffectState.ObjectID));
			FollowthroughEffectState.ActionPoints = SourceUnit.ActionPoints;
			FollowthroughEffectState.ReserveActionPoints = SourceUnit.ReserveActionPoints;

			SourceUnit.ActionPoints = PreCostActionPoints;
			SourceUnit.ReserveActionPoints = PreCostReservePoints;

			return true; 
		}
	}

	return false;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_Folowthrough_Effect"
	GameStateEffectClass = class'XComGameState_Effect_BountyHunter_Followthrough'
}