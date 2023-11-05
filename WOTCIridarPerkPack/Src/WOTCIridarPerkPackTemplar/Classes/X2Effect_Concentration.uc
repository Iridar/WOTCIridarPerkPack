class X2Effect_Concentration extends X2Effect_Persistent;

// TODO: Particle effect

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	//local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	//UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//EventMgr.RegisterForEvent(EffectObj, 'X2Effect_Concentration_Event', TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
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
		//EffectState.RemoveEffect(NewGameState, NewGameState, true);
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
/*
static private function ConcentrationEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameStateHistory	History;
	local XComGameState_Effect	EffectState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.bRemoved)
			continue;

		if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID != ApplyEffectParameters.SourceStateObjectRef.ObjectID)
			continue;

		if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
			continue;
			
		if (EffectState.GetX2Effect().EffectName != 'IRI_TM_Concentration_Effect')
			continue;

		EffectState.RemoveEffect(NewGameState, NewGameState, true);
	}
}
*/
/*
static private function ConcentrationEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Effect_TemplarFocus	FocusState;
	local XComGameState_Unit				SourceUnit;
	local XComGameState_Unit				TargetUnit;
	local UnitValue							UV;

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
	{
		SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}
	if (SourceUnit == none || !SourceUnit.IsAbleToAct())
		return;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit.IsAlive());

	FocusState = SourceUnit.GetTemplarFocusEffectState();
	if (FocusState != none)
	{
		FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
		FocusState.SetFocusLevel(FocusState.FocusLevel + UV.fValue, UnitState, NewGameState);		
	}
	// TODO: Trigger Flyover
}*/



defaultproperties
{
	//EffectAddedFn = ConcentrationEffectAdded;
	//EffectRemovedFn = ConcentrationEffectRemoved;
	bRemoveWhenTargetDies = true
	bRemoveWhenSourceDies = true
	EffectName = "IRI_TM_Concentration_Effect"
	DuplicateResponse = eDupe_Allow
}
