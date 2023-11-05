class X2Effect_Overcharge extends X2Effect_Persistent;

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

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_Overcharge_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', AbilityActivated_Listener, ELD_OnStateSubmitted,, UnitState,, AbilityState);	
}

static private function EventListenerReturn AbilityActivated_Listener(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Unit				SourceUnit;
    local XComGameState_Unit				TargetUnit;
	local XComGameStateContext_Ability		AbilityContext;
	local XComGameState_Effect_TemplarFocus	FocusState;
	local XComGameState						NewGameState;
	local array<name>						SupportedAbilities;
		
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	SupportedAbilities = `GetConfigArrayName("IRI_TM_Overcharge_SupportedAbilities");
	if (SupportedAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) == INDEX_NONE)
		return ELR_NoInterrupt;
		
	TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none || TargetUnit.IsDead())
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none || !SourceUnit.IsAbleToAct())
		return ELR_NoInterrupt;

	FocusState = SourceUnit.GetTemplarFocusEffectState();
	if (FocusState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Overcharge Flyover");
		`XEVENTMGR.TriggerEvent('X2Effect_Overcharge_Event', CallbackData, SourceUnit, NewGameState);	
		`GAMERULES.SubmitGameState(NewGameState);

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Overcharge Focus");
		FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
		SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
		FocusState.SetFocusLevel(FocusState.FocusLevel + 1, SourceUnit, NewGameState);	
		`GAMERULES.SubmitGameState(NewGameState);
	}

    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_TM_X2Effect_Overcharge_Effect"
}