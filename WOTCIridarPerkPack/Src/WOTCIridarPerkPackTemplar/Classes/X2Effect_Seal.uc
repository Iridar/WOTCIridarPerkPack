class X2Effect_Seal extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnKillMail_Immediate, ELD_Immediate,, none,, EffectObj);	
	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnKillMail_OSS, ELD_OnStateSubmitted,, none,, EffectObj);	
}

static private function EventListenerReturn OnKillMail_Immediate(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
	local XComGameState_Effect				EffectState;
	local XComGameState_Unit				KilledUnit;
    local XComGameState_Unit				KillerUnit;

	KilledUnit = XComGameState_Unit(EventData);
	if (KilledUnit == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;
	
	// Check the unit that got killed is actually the target of this effect
	if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != KilledUnit.ObjectID)
		return ELR_NoInterrupt;

	// Get the latest version of the Unit State
	KilledUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(KilledUnit.ObjectID));
	if (KilledUnit == none)
		return ELR_NoInterrupt;

	KillerUnit = XComGameState_Unit(EventSource);
	if (KillerUnit == none)
		return ELR_NoInterrupt;

	// If the target was killed by the Templar, mark the killed unit with a unit value, 
	// so that effect removed visualization knows the effect was cleansed and doesn't play the pillar effect.
	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == KillerUnit.ObjectID)
	{
		KilledUnit.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
	}
	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnKillMail_OSS(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Effect					EffectState;
	local XComGameState_Effect					CycleEffect;
	local XComGameState_Unit					KilledUnit;
	local XComGameState_Unit					SourceUnit;
    local XComGameState_Unit					KillerUnit;
	local XComGameState_Ability					AbilityState;
	local XComGameState_Effect_TemplarFocus		FocusState;
	local XComGameState							NewGameState;
	local XComGameStateHistory					History;
	local UnitValue								UV;
	local StateObjectReference					EffectRef;
	local XComGameStateContext_EffectRemoved	EffectRemovedContext;

	KilledUnit = XComGameState_Unit(EventData);
	if (KilledUnit == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;
	
	// Check the unit that got killed is actually the target of this effect
	if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != KilledUnit.ObjectID)
		return ELR_NoInterrupt;

	KillerUnit = XComGameState_Unit(EventSource);
	if (KillerUnit == none)
		return ELR_NoInterrupt;

	// If the target was killed by the Templar, don't do anything.
	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == KillerUnit.ObjectID)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none || !SourceUnit.IsAbleToAct())
		return ELR_NoInterrupt;

	// Don't give Focus if we already gave Focus this turn.
	if (SourceUnit.GetUnitValue(default.EffectName, UV))
		return ELR_NoInterrupt;

	// Trigger only when enemy is killed by an ally.
	if (!KillerUnit.IsFriendlyUnit(SourceUnit))
		return ELR_NoInterrupt;

	FocusState = SourceUnit.GetTemplarFocusEffectState();
	if (FocusState != none)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SourceUnit.FindAbility('IRI_TM_Seal').ObjectID));
		if (AbilityState != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Seal Flyover");
			SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
			AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
			`GAMERULES.SubmitGameState(NewGameState);
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Seal Focus");
		FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
		SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
		FocusState.SetFocusLevel(FocusState.FocusLevel + 1, SourceUnit, NewGameState);	

		// Mark the unit so that we don't give additional Focus until next turn.
		SourceUnit.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
		`GAMERULES.SubmitGameState(NewGameState);

		// Cleanse all instances of Seal effect, as they're not gonna do anything this turn anyway.
		NewGameState = none;
		foreach SourceUnit.AppliedEffects(EffectRef)
		{
			CycleEffect = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (CycleEffect == none || CycleEffect.bRemoved || CycleEffect.ObjectID == EffectState.ObjectID) // Don't cleanse ourselves though, lol
				continue;

			if (CycleEffect.GetX2Effect().EffectName == default.EffectName)
			{
				if (NewGameState == none)
				{
					//NewGameState = class'XComGameStateContext_EffectRemoved'.static.CreateChangeState("Remove Seal Effects");
					//XComGameStateContext_EffectRemoved(NewGameState.GetContext()).BuildVisualizationFn = SealEffect_CleanseVisualization;

					EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
					NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
					
					 // Mark the unit so that effect removed visuzliation knows the effect was cleansed and doesn't play the pillar effect.
					KilledUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', CycleEffect.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
					KilledUnit.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
				}
				CycleEffect.RemoveEffect(NewGameState, NewGameState, true);
			}
		}
		if (NewGameState != none)
		{
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

    return ELR_NoInterrupt;
}


static private function TriggerAbilityFlyoverVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Ability', AbilityState)
		{
			break;
		}
		if (AbilityState == none)
		{
			`RedScreenOnce("Ability state missing from" @ GetFuncName() @ "-jbouscher @gameplay");
			return;
		}

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage, `DEFAULTFLYOVERLOOKATTIME, true);
		}
		break;
	}
}

static private function SealEffect_RemovedVisualizationFn(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayDeathEffect	EffectAction;
	local XGUnit					VisualizeUnit;
	local XComUnitPawn				UnitPawn;
	local XComGameState_Unit		UnitState;
	local UnitValue					UV;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState == none || UnitState.IsAlive() || UnitState.GetUnitValue(default.EffectName, UV))
		return;

	VisualizeUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (VisualizeUnit == none)
		return;

	UnitPawn = VisualizeUnit.GetPawn();
	if (UnitPawn == none || UnitPawn.Mesh == none)
		return;

	// Use a custom effect that will get the effect location from the pawn mesh when running, not when building visualization.
	EffectAction = X2Action_PlayDeathEffect(class'X2Action_PlayDeathEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	EffectAction.EffectName = "IRIVolt.PS_Concentration_Death";
	EffectAction.PawnMesh = UnitPawn.Mesh;
	EffectAction.AttachToSocketName = 'FX_Chest';
}

defaultproperties
{
	EffectRemovedVisualizationFn = SealEffect_RemovedVisualizationFn
	bRemoveWhenTargetDies = true
	bRemoveWhenSourceDies = true

	// This effect name is expected by the Class Rework mod. Don't change.
	EffectName = "IRI_TM_Seal_Effect"
	
	//DuplicateResponse = eDupe_Allow
}
