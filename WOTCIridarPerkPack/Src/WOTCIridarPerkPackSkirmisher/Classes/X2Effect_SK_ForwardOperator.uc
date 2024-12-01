class X2Effect_SK_ForwardOperator extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;
	local XComGameState_Ability	AbilityState;
	local XComGameStateHistory	History;

	EventMgr = `XEVENTMGR;
	History = `XCOMHISTORY;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	`AMLOG("Running");

	if (UnitState != none && AbilityState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, 'IRI_X2Effect_SK_ForwardOperator_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
		EventMgr.RegisterForEvent(EffectObj, 'ProcessReflexMove', OnProcessReflexMove, ELD_Immediate,, ,, AbilityState);	

		`AMLOG("Registered");
	}
}

static private function EventListenerReturn OnProcessReflexMove(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit	UnitState;
	local XComGameState_Unit	NewUnitState;
	local XComGameState_Ability	AbilityState;

	`AMLOG("Running");

	AbilityState = XComGameState_Ability(CallbackData);
	`AMLOG("AbilityState:" @ AbilityState.GetMyTemplateName() @ AbilityState.iCooldown);
	if (AbilityState == none || AbilityState.iCooldown > 0)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	`AMLOG("UnitState:" @ UnitState.GetFullName());
	if (UnitState == none)
		return ELR_NoInterrupt;

	if (UnitState.ControllingPlayer != `TACTICALRULES.GetCachedUnitActionPlayerRef())
		return ELR_NoInterrupt;

	`AMLOG("This unit's turn");

	NewUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (NewUnitState == none)
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	// Note: this may or may not work with turn-ending abilities that involve movement, as they might consume the ability point after it's been given.
	// Skirmishers don't have abilities like that, so I guess it's not a concern for now.
	NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);

	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
	AbilityState.iCooldown++;

	`XEVENTMGR.TriggerEvent('IRI_X2Effect_SK_ForwardOperator_Event', AbilityState, NewUnitState, NewGameState);

	`AMLOG("Adding action, triggering flyover");

    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_SK_ForwardOperator_Effect"
}
