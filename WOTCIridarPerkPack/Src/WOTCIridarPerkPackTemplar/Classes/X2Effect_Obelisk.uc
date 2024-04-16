class X2Effect_Obelisk extends X2Effect_Pillar;

// Needs doing: Apply Pillar Fix (there is no pillar fix, it's buggedddddd)

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	return `GetConfigInt('IRI_TM_Obelisk_Duration');
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Ability	AbilityState;
	local StateObjectReference	AbilityRef;
	local Object				EffectObj;
	local XComGameStateHistory	History;

	super.RegisterForEvents(EffectGameState);

	EffectObj = EffectGameState;
	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (UnitState == none)
		return;
	
	AbilityRef = UnitState.FindAbility('IRI_TM_Obelisk_Volt', EffectGameState.ApplyEffectParameters.ItemStateObjectRef);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	`AMLOG("Registered for events");

	`XEVENTMGR.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted,, ,, AbilityState);	
}

static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt; 

	`AMLOG("Running for:" @ XComGameState_Ability(CallbackData).GetMyTemplateName() @ "used by:" @ XComGameState_Unit(EventSource).GetFullName());

	AbilityState.TypicalAttackListener(EventData, EventSource, GameState, InEventID, AbilityState);
	
    return ELR_NoInterrupt;
}

defaultproperties
{
	EffectName = "IRI_TM_Obelisk_Effect"
}
