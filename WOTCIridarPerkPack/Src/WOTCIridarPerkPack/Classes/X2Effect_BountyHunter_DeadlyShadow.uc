class X2Effect_BountyHunter_DeadlyShadow extends X2Effect_Shadow;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_DeadlyShadow_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	
	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_DeadlyShadow_Event', AbilityState, SourceUnit, NewGameState);
	
	
	/*
	native function RegisterForEvent( ref Object SourceObj, 
									Name EventID, 
									delegate<OnEventDelegate> NewDelegate, 
									optional EventListenerDeferral Deferral=ELD_Immediate, 
									optional int Priority=50, 
									optional Object PreFilterObject, 
									optional bool bPersistent, 
									optional Object CallbackData );*/

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_Immediate,, UnitState,, EffectObj);	
	EventMgr.RegisterForEvent(EffectObj, 'RetainConcealmentOnActivation', OnRetainConcealmentOnActivation, ELD_Immediate, 10, ,, UnitState);	

	EventMgr.RegisterForEvent(EffectObj, 'UnitConcealmentBroken', OnTargetConcealmentBroken, ELD_OnStateSubmitted,, UnitState,, EffectObj);
	
	super.RegisterForEvents(EffectGameState);
}

static private function EventListenerReturn OnTargetConcealmentBroken(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_EffectRemoved	EffectRemovedState;
	local XComGameState							NewGameState;
	local XComGameState_Unit					TargetUnitState;
	local XComGameStateHistory					History;
	local XComGameState_Effect					EffectState;

	History = `XCOMHISTORY;
	EffectState = XComGameState_Effect(CallbackData);

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState != none && !TargetUnitState.IsConcealed() && !EffectState.bRemoved)
	{
		EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
		NewGameState = History.CreateNewGameState(true, EffectRemovedState);
		EffectState.RemoveEffect(NewGameState, GameState);

		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// Technical challenge: I want to use reaper shadow animations, which are added by a persistent effect. These animations, among other things, contain custom FireStart / FireStop animations
// for the vektor rifle. The problem is that animations from persistent effects are applied after soldier animations for currently active weapon,
// so these custom animations intended for vektor end up overriding pistol FireStart / FireStop animations, which results in the soldier firing their pistol while holding vektor. Looks jank AF.
// Solution: list to abilities activated by this unit and if they come from a pistol while concealed, insert custom Merge Vis function,
// which will swap Exit / Enter Cover actions with custom versions that use different Fire Start / Fire Stop animations.
static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local XComGameState_Effect			EffectState;
	local XComGameStateContext_Ability	AbilityContext;
	local X2AbilityTemplate				AbilityTemplate;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none || AbilityTemplate.bSkipExitCoverWhenFiring)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
		
	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none || AbilityState.SourceWeapon.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return ELR_NoInterrupt;
	
	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (UnitState != none && UnitState.IsConcealed())
	{
		// TODO: Wrap the MergeVisualizationFn, if it exists
		`AMLOG("Adding Merge Vis delegate");
		AbilityContext.MergeVisualizationFn = ConcealedPistolShot_MergeVisualization;
	}

    return ELR_NoInterrupt;
}

static private function ConcealedPistolShot_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local X2Action_ExitCover				ExitCoverAction;
	local X2Action_BountyHunter_ExitCover	NewExitCoverAction;
	local XComGameStateContext_Ability		AbilityContext;
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_MarkerNamed				ReplaceAction;
	local X2Action_BountyHunter_EnterCover	NewEnterCoverAction;
	local X2Action							ChildAction;
	local XComGameState_Ability				AbilityState;
	local XComGameState_Unit				UnitState;

	`AMLOG("Running");

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	if (AbilityContext == none)
		return;

	VisMgr.GetNodesOfType(BuildTree, class'X2Action_ExitCover', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
	foreach FindActions(FindAction)
	{
		ExitCoverAction = X2Action_ExitCover(FindAction);
		ActionMetadata = ExitCoverAction.Metadata;
		NewExitCoverAction = X2Action_BountyHunter_ExitCover(class'X2Action_BountyHunter_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true,, ExitCoverAction.ParentActions));
	
		NewExitCoverAction.bIsForSuppression = ExitCoverAction.bIsForSuppression;
		NewExitCoverAction.bUsePreviousGameState = ExitCoverAction.bUsePreviousGameState;
		NewExitCoverAction.bDoNotAddFramingCamera = ExitCoverAction.bDoNotAddFramingCamera;
		NewExitCoverAction.bSkipFOWReveal = ExitCoverAction.bSkipFOWReveal;

		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		ReplaceAction.SetName("Exit Cover Stub");
		VisMgr.ReplaceNode(ReplaceAction, ExitCoverAction);

		`AMLOG("Replacing Exit Cover action");
	}
	
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	if (UnitState  != none)
	{
		AbilityState = XComGameState_Ability(AbilityContext.AssociatedState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		if (AbilityState == none)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		}
		if (AbilityState != none)
		{
			FindActions.Length = 0;
			VisMgr.GetNodesOfType(BuildTree, class'X2Action_EnterCover', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
			foreach FindActions(FindAction)
			{
				ActionMetadata = FindAction.Metadata;
				NewEnterCoverAction = X2Action_BountyHunter_EnterCover(class'X2Action_BountyHunter_EnterCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, FindAction.ParentActions));

				if (TriggerRetainConcealmentOnActivationOverride(AbilityState, AbilityContext, AbilityContext.AssociatedState) || UnitState.HasSoldierAbility('SomePassive'))
				{
					NewEnterCoverAction.OutOfCoverAnim = 'NO_FireStop_Shadow';
				}
				else
				{
					NewEnterCoverAction.OutOfCoverAnim = 'NO_FireStop_NoShadow';
				}

				foreach FindAction.ChildActions(ChildAction)
				{
					VisMgr.ConnectAction(ChildAction, BuildTree, false, NewEnterCoverAction);
				}

				ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
				ReplaceAction.SetName("Enter Cover Stub");
				VisMgr.ReplaceNode(ReplaceAction, FindAction);

				`AMLOG("Replacing Enter Cover action");
			}
		}
	}

	AbilityContext.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
}




// Technical Challenge: I need Deadly Shadow to have the same detection radius as Shadow, but otherwise behave like regular concealment.
// This can be achieved by using regular concealment and modifying detection radius via stat modifiers, but any additional stat modifiers
// will reduce detection radius to zero, which I don't want.
// So to get the detection radius I need, I still set the bSuperConcealed flag, but remove it the moment the game considers running the "chance to break super concealment" roll.
static private function EventListenerReturn OnRetainConcealmentOnActivation(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple					Tuple;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			UnitState;
	local XComGameState_Ability			AbilityState;
	local XComGameStateHistory			History;
	local X2AbilityTemplate				AbilityTemplate;

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
	
	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none) 
		return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none) 
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (UnitState == none) 
		return ELR_NoInterrupt;

	// If we're here then this ability does not allow to retain concealment.

	// If the unit has the passive and this is a concelment-breaking attack, don't break concealment.
	if (UnitState.HasSoldierAbility('SomeAbility') && AbilityTemplate.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) && AbilityTemplate.Hostility == eHostility_Offensive)
	{
		Tuple.Data[0].b = true;
	}
	else
	{
		// Concealment is about to break.
		// Remove the super concealment flag.
		UnitState.bHasSuperConcealment = false;
	}

	return ELR_NoInterrupt;
}

// If not in cover, play crouching down animation
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayAnimation	PlayAnimation;
	local XGUnit					Unit;

	if (EffectApplyResult == 'AA_Success')
	{
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if (Unit != none && Unit.m_eCoverState == eCS_None)
		{
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
			PlayAnimation.Params.AnimName = 'HL_Stand2Crouch';
		}
	}	
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

// If /*effect ticked off naturally*/ and we're not in cover, play standing up animation
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayAnimation	PlayAnimation;
	local XGUnit					Unit;

	//if (XComGameStateContext_TickEffect(VisualizeGameState.GetContext()) != none)
	//{
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if (Unit != none && Unit.m_eCoverState == eCS_None)
		{
			`AMLOG("Playing crouch to stand animations");
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
			PlayAnimation.Params.AnimName = 'LL_Crouch2Stand';
		}
	//}
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
}

/*

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	
	super.OnEffectAdded(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	
	if (UnitState != none)
	{
		
	}

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}







*/

static private function bool TriggerRetainConcealmentOnActivationOverride(XComGameState_Ability AbilityState, XComGameStateContext_Ability AbilityContext, XComGameState GameState)
{
	local XComLWTuple	Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'RetainConcealmentOnActivation';
	Tuple.Data.Add(1);
		
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = AbilityState.RetainConcealmentOnActivation(AbilityContext);

	`XEVENTMGR.TriggerEvent('RetainConcealmentOnActivation', Tuple, AbilityContext, GameState);

	return Tuple.Data[0].b;
}

static private function ShadowPassiveEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	XComGameState_Unit(kNewTargetState).bHasSuperConcealment = true;
}

static private function ShadowEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}

	// TODO: Break concealment only if the unit wasn't already concealed?
	`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
}

defaultproperties
{
	//bBringRemoveVisualizationForward = true
	EffectAddedFn = ShadowPassiveEffectAdded
	EffectRemovedFn = ShadowEffectRemoved
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_DeadlyShadow_Effect"
}