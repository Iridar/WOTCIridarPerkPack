class X2Effect_BountyHunter_UnrelentingPressure extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability			AbilityState;
	local XComGameStateHistory History;
	local Object EffectObj;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, EffectName, EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', UnrelentingPressureListener, ELD_OnStateSubmitted,, UnitState,, AbilityState);	
}

static private function EventListenerReturn UnrelentingPressureListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			UnrelentingPressureState;
	local XComGameState_Ability			BurstFireState;
	local StateObjectReference			AbilityRef;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Ability			ActivatedAbility;
	local XComGameState					NewGameState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt) 
		return ELR_NoInterrupt;

	`AMLOG("Running:" @ AbilityContext.InputContext.AbilityTemplateName);
	
	// It was a crit.
	if (AbilityContext.ResultContext.HitResult != eHit_Crit)
		return ELR_NoInterrupt;

	`AMLOG("It was a crit");

	ActivatedAbility = XComGameState_Ability(EventData);
	if (ActivatedAbility == none)
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	// Make sure it was not Burst Fire itself that was activated.
	AbilityRef = SourceUnit.FindAbility('IRI_BH_BurstFire', AbilityContext.InputContext.ItemObject);
	if (AbilityRef.ObjectID == 0 || AbilityRef.ObjectID == ActivatedAbility.ObjectID)
		return ELR_NoInterrupt;

	// And Burst Fire is actually on cooldown
	BurstFireState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (BurstFireState == none || BurstFireState.iCooldown == 0)
		return ELR_NoInterrupt;

	// Make sure the crit came from the same weapon the Unrelenting Pressure is attached to (should be the same weapon to which Burst Fire is attached to as well)
	UnrelentingPressureState = XComGameState_Ability(CallbackData);
	if (UnrelentingPressureState == none)
		return ELR_NoInterrupt;

	`AMLOG("Reducing cooldown");

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reduce Burst Fire Cooldown");
	BurstFireState = XComGameState_Ability(NewGameState.ModifyStateObject(BurstFireState.Class, BurstFireState.ObjectID));
	BurstFireState.iCooldown -= `GetConfigInt('IRI_BH_UnrelentingPressure_CooldownReduction');
	if (BurstFireState.iCooldown < 0)
		BurstFireState.iCooldown = 0;

	`XEVENTMGR.TriggerEvent(default.EffectName, UnrelentingPressureState, SourceUnit, NewGameState);

	`GAMERULES.SubmitGameState(NewGameState);
	
	return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_UnrelentingPressure_Effect"
}