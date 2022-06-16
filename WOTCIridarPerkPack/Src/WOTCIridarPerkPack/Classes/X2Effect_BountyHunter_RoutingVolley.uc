class X2Effect_BountyHunter_RoutingVolley extends X2Effect_Suppression;

// Routing Volley = Terminate

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
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', TerminateTriggerListener, ELD_OnStateSubmitted,, TargetUnit,, EffectObj);	
	`AMLOG("Succesfully registered all listeners");
}



static private function EventListenerReturn TerminateTriggerListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local XComGameState_Effect			EffectState;
	local XComGameStateHistory			History;
	local XComGameState					NewGameState;
	local StateObjectReference			AbilityRef;
	local UnitValue						UV;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none || !AbilityState.IsAbilityInputTriggered())
		return ELR_NoInterrupt;

	`AMLOG("Attempting trigger by ability:" @ AbilityContext.InputContext.AbilityTemplateName);

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	TargetUnit.GetUnitValue('IRI_BH_Terminate_UnitValue', UV);
	if (UV.fValue == History.GetEventChainStartIndex())
	{
		`AMLOG("Terminate already responded to:" @ int(UV.fValue) @ "event chain start index, skipping this ability activation");
		return ELR_NoInterrupt;
	}

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	AbilityRef = SourceUnit.FindAbility('IRI_BH_Terminate_Attack', EffectState.ApplyEffectParameters.ItemStateObjectRef);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return ELR_NoInterrupt;

	if (ActivateOverwatchAbility(AbilityState, TargetUnit, AbilityContext))
	{
		`AMLOG("Triggered successfully, increasing Grants This Turn, setting Event Chain Start Index:" @ History.GetEventChainStartIndex());
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Setting Unit Value for Terminate");
		TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
		TargetUnit.SetUnitFloatValue('IRI_BH_Terminate_UnitValue', History.GetEventChainStartIndex(), eCleanup_BeginTurn);
		`GAMERULES.SubmitGameState(NewGameState);

		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID));
		if (TargetUnit == none || TargetUnit.IsDead())
			return ELR_NoInterrupt;

		// Trigger resuppress if target unit is still alive and not moving.
		if (AbilityContext.InputContext.MovementPaths.Length == 0)
		{
			AbilityRef = SourceUnit.FindAbility('IRI_BH_Terminate_Resuppress', EffectState.ApplyEffectParameters.ItemStateObjectRef);
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AbilityState == none)
				return ELR_NoInterrupt;

			AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);
		}
		
	}
	return ELR_NoInterrupt;
}

// Copy of XCGS_Ability::TypicalOverwatchListener
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
		`AMLOG("Cannot activate Terminate Attack, because:" @ AbilityState.CanActivateAbilityForObserverEvent(TargetUnit));
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
	if (AbilityContext.InputContext.AbilityTemplateName == 'IRI_BH_Terminate_Attack')
	{
		Tuple.Data[0].b = true;
	}

    return ELR_NoInterrupt;
}

/*
function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{ 
	local XComGameState_Effect NewEffectState;

	if (EffectState.GrantsThisTurn != 0 && kAbility.IsAbilityInputTriggered())
	{
		`AMLOG(SourceUnit.GetFullName() @ "activated ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "resetting GrantsThisTurn.");
		NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', EffectState.ObjectID));
		NewEffectState.GrantsThisTurn = 0;
	}

	return false; 
}
*/
simulated function AddX2ActionsForVisualization_RemovedSource(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_EnterCover Action;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState SuppressionGameState;

	History = `XCOMHISTORY;

	class'X2Action_StopSuppression'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	Action = X2Action_EnterCover(class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RemovedEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	SuppressionGameState = History.GetGameStateFromHistory(UnitState.m_SuppressionHistoryIndex);
	Action.AbilityContext = XComGameStateContext_Ability(SuppressionGameState.GetContext());
}

simulated function CleansedSuppressionVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState, SuppressionEffect;
	local X2Action_EnterCover Action;
	local XComGameState_Unit UnitState;
	local XComGameState SuppressionGameState;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.bRemoved && EffectState.GetX2Effect() == self)
		{
			SuppressionEffect = EffectState;
			break;
		}
	}
	if (SuppressionEffect != none)
	{
		History = `XCOMHISTORY;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(SuppressionEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		ActionMetadata.VisualizeActor = History.GetVisualizer(SuppressionEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID);
		History.GetCurrentAndPreviousGameStatesForObjectID(SuppressionEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		if (ActionMetadata.StateObject_NewState == none)
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;

		class'X2Action_StopSuppression'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		Action = X2Action_EnterCover(class'X2Action_EnterCover'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

		SuppressionGameState = History.GetGameStateFromHistory(UnitState.m_SuppressionHistoryIndex);
		Action.AbilityContext = XComGameStateContext_Ability(SuppressionGameState.GetContext());
	}
}