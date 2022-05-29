class X2Effect_BountyHunter_RoutingVolley extends X2Effect_Suppression;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager			EventMgr;
	local Object					EffectObj;
	local XComGameState_Unit		TargetUnit;

	super.RegisterForEvents(EffectGameState);

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
		return;

	EventMgr.RegisterForEvent(EffectObj, 'OverrideReactionFireSlomo', OnOverrideReactionFireSlomo, ELD_Immediate);	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', RoutingVolleyTriggerListener, ELD_OnStateSubmitted,, TargetUnit,, EffectObj);	
	`AMLOG("Succesfully registered all listeners");
}

static private function EventListenerReturn RoutingVolleyTriggerListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local XComGameState_Effect			EffectState;
	local XComGameStateHistory			History;
	local XComGameState					NewGameState;
	local StateObjectReference			AbilityRef;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none || EffectState.GrantsThisTurn != 0)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	AbilityRef = SourceUnit.FindAbility('IRI_BH_RoutingVolley_Attack', EffectState.ApplyEffectParameters.ItemStateObjectRef);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return ELR_NoInterrupt;

	// Repurposing the overwatch listener so it works with any ability activation.
	`AMLOG("Attempting trigger by ability:" @ AbilityContext.InputContext.AbilityTemplateName);
	//AbilityState.TypicalOverwatchListener(EventSource, EventSource, GameState, Event, CallbackData);
	if (ActivateOverwatchAbility(AbilityState, TargetUnit, AbilityContext))
	{
		`AMLOG("Triggered successfully, increasing Grants This Turn");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Increasing GrantsThisTurn for Routing Volley");
		EffectState = XComGameState_Effect(NewGameState.ModifyStateObject(EffectState.Class, EffectState.ObjectID));
		EffectState.GrantsThisTurn = 1;
		`GAMERULES.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

static private function bool ActivateOverwatchAbility(XComGameState_Ability AbilityState, XComGameState_Unit TargetUnit, XComGameStateContext_Ability AbilityContext)
{
	local XComGameState_Unit	ChainStartTarget;
	local XComGameStateHistory	History;
	local int					ChainStartIndex;
	local Name					CycleEffectName;

	if (class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
			return false;

	if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit) == 'AA_Success')
	{
		// Check effects on target unit at the start of this chain.
		History = `XCOMHISTORY;
		ChainStartIndex = History.GetEventChainStartIndex();
		if (ChainStartIndex != INDEX_NONE)
		{
			ChainStartTarget = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID, , ChainStartIndex));
			foreach class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeEffects(CycleEffectName)
			{
				if (ChainStartTarget.IsUnitAffectedByEffectName(CycleEffectName))
				{
					return false;
				}
			}
		}
		return AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
	}
	else
	{
		`AMLOG("Cannot activate Routing Volley Attack, because:" @ AbilityState.CanActivateAbilityForObserverEvent(TargetUnit));
	}
	return false;
}

static function EventListenerReturn OnOverrideReactionFireSlomo(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComLWTuple					Tuple;
    local XComGameStateContext_Ability	AbilityContext;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

    AbilityContext = XComGameStateContext_Ability(Tuple.Data[1].o);
	if (AbilityContext == none)
		return ELR_NoInterrupt;
	
	// Make this ability visualize as a reaction fire even though it is not.
	if (AbilityContext.InputContext.AbilityTemplateName == 'IRI_BH_RoutingVolley_Attack')
	{
		Tuple.Data[0].b = true;
	}

    return ELR_NoInterrupt;
}


function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{ 
	local XComGameState_Effect NewEffectState;

	//	A rough check to filter out abilities that do not cost an action point.
	//if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length || SourceUnit.ReserveActionPoints.Length != PreCostReservePoints.Length)
	//{
		if (EffectState.GrantsThisTurn != 0 && kAbility.IsAbilityInputTriggered())
		{
			`AMLOG(SourceUnit.GetFullName() @ "activated ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "resetting GrantsThisTurn.");
			NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', EffectState.ObjectID));
			NewEffectState.GrantsThisTurn = 0;
		}
	//}
	return false; 
}
