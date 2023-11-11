class X2Effect_Concentration extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted,, none,, EffectObj);	
}

static private function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Effect				EffectState;
	local XComGameState_Unit				KilledUnit;
	local XComGameState_Unit				SourceUnit;
    local XComGameState_Unit				KillerUnit;
	local XComGameState_Ability				AbilityState;
	local XComGameState_Effect_TemplarFocus	FocusState;
	local XComGameState						NewGameState;
	local XComGameStateHistory				History;

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

	// If the target was killed by the Templar, we don't care.
	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == KillerUnit.ObjectID)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none || !SourceUnit.IsAbleToAct())
		return ELR_NoInterrupt;

	// Trigger only when enemy is killed by an ally.
	if (!KillerUnit.IsFriendlyUnit(SourceUnit))
		return ELR_NoInterrupt;

	`AMLOG(XComGameState_Unit(EventData).GetFullName() @ "killed by:" @ KillerUnit.GetFullName() @ "Source unit:" @ SourceUnit.GetFullName());

	FocusState = SourceUnit.GetTemplarFocusEffectState();
	`AMLOG("Current Focus:" @ FocusState.FocusLevel);
	if (FocusState != none)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SourceUnit.FindAbility('IRI_TM_Concentration').ObjectID));
		`AMLOG("Found flyover ability:" @ AbilityState != none @ AbilityState.GetMyTemplateName() @ "on source unit:" @ SourceUnit.GetFullName());
		if (AbilityState != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Concentration Flyover");
			SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
			AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
			`GAMERULES.SubmitGameState(NewGameState);
		}

		`AMLOG("Increasing Focus to:" @ FocusState.FocusLevel + 1);

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Concentration Focus");
		FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
		SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
		FocusState.SetFocusLevel(FocusState.FocusLevel + 1, SourceUnit, NewGameState);	
		`GAMERULES.SubmitGameState(NewGameState);
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

static private function ConcentrationEffectRemovedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayDeathEffect	EffectAction;
	local XGUnit					VisualizeUnit;
	local XComUnitPawn				UnitPawn;

	VisualizeUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (VisualizeUnit == none)
		return;

	UnitPawn = VisualizeUnit.GetPawn();
	if (UnitPawn == none || UnitPawn.Mesh == none)
		return;

	// TODO: Play this effect only when killed not by the templar... somehow.

	// Use a custom effect that will get the effect location from the pawn mesh when running, not when building visualization.
	EffectAction = X2Action_PlayDeathEffect(class'X2Action_PlayDeathEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	EffectAction.EffectName = "IRIVolt.PS_Concentration_Death";
	EffectAction.PawnMesh = UnitPawn.Mesh;
	EffectAction.AttachToSocketName = 'FX_Chest';
}

defaultproperties
{
	//EffectAddedFn = ConcentrationEffectAdded;
	//EffectRemovedFn = ConcentrationEffectRemoved;
	EffectRemovedVisualizationFn = ConcentrationEffectRemovedVisualization
	bRemoveWhenTargetDies = true
	bRemoveWhenSourceDies = true
	EffectName = "IRI_TM_Concentration_Effect"
	DuplicateResponse = eDupe_Allow
}
