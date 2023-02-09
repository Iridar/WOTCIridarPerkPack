class X2Effect_BountyHunter_DeadlyShadow extends X2Effect_Shadow;

var private name AlreadyConcealedValue;
var private name AlreadySuperConcealedValue;

// Technical Challenge: I need Deadly Shadow to have the same detection radius as Shadow, but otherwise behave like regular concealment.
// This can be achieved by using regular concealment and modifying detection radius via stat modifiers, 
// but any additional stat modifiers will reduce detection radius to zero, which I don't want.
// So to get the detection radius I need, I still set the bSuperConcealed flag, but remove it the moment the game considers running the "chance to break super concealment" roll.

// Allows the unit in Deadly Shadow remain concealed if the squad concealment is broken. 
function bool RetainIndividualConcealment(XComGameState_Effect EffectState, XComGameState_Unit UnitState)
{
	return true;
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'RetainConcealmentOnActivation', OnRetainConcealmentOnActivation, ELD_Immediate, 10, ,, UnitState);	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_Immediate,, UnitState,, EffectObj);	
	EventMgr.RegisterForEvent(EffectObj, 'TacticalHUD_UpdateReaperHUD', OnTacticalHUD_UpdateReaperHUD, ELD_Immediate, 10, UnitState);	
		
	super.RegisterForEvents(EffectGameState);
}

static private function EventListenerReturn OnTacticalHUD_UpdateReaperHUD(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none) 
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none) 
		return ELR_NoInterrupt;

	Tuple.Data[0].b = true; // bShowReaperUI
	Tuple.Data[3].b = true; // bShowReaperShotHUD
	
	if (UnitState.HasSoldierAbility('IRI_BH_DarkNight_Passive'))
	{
		Tuple.Data[1].f = 0;	 // CurrentConcealLossCH
		Tuple.Data[2].f = 0;	 // ModifiedLossCH
	}
	else
	{
		Tuple.Data[1].f = 1;	 // CurrentConcealLossCH
		Tuple.Data[2].f = 1;	 // ModifiedLossCH
	}
}

// Responsible for preserving concealment when attacking if the unit has a specific passive ability.
static private function EventListenerReturn OnRetainConcealmentOnActivation(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple					Tuple;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			UnitState;
	local XComGameState_Ability			AbilityState;

	// Exit early if this ability retains concealment.
	Tuple = XComLWTuple(EventData);
	if (Tuple == none || Tuple.Data[0].b) 
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(EventSource);
	if (AbilityContext == none) 
		return ELR_NoInterrupt;

	// EventSource is Context, so can't use object filter when registering for the event.
	// Do this check to make sure the unit in this event is the same unit to which this effect is applied.
	UnitState = XComGameState_Unit(CallbackData);
	if (UnitState == none || AbilityContext.InputContext.SourceObject.ObjectID != UnitState.ObjectID)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none)
		return ELR_NoInterrupt;

	// If the unit has the passive that makes all attacks not break concealment
	if (class'BountyHunter'.static.IsAbilityValidForDarkNight(AbilityState) && UnitState.HasSoldierAbility('IRI_BH_DarkNight_Passive'))
	{
		// Then don't break concealment
		Tuple.Data[0].b = true;
	}

	return ELR_NoInterrupt;
}

// Responsible for bypassing the Reaper roll when activating abilities that normally break concelament.
static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit			UnitState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt; 

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt; 
	
	// Exit early if the unit has the passive that allows to always retain concealment when attacking.
	if (class'BountyHunter'.static.IsAbilityValidForDarkNight(AbilityState) && UnitState.HasSoldierAbility('IRI_BH_DarkNight_Passive'))
		return ELR_NoInterrupt; 

	//// Exit early if the unit is affected by Followthrough, it has its own listener for this event, let it handle this.
	//if (class'BountyHunter'.static.IsAbilityValidForFollowthrough(AbilityState) && UnitState.IsUnitAffectedByEffectName(class'X2Effect_BountyHunter_Folowthrough'.default.EffectName))
	//{
	//	`AMLOG(UnitState.GetFullName() @ AbilityState.GetMyTemplateName() @ "exiting early because unit is affected by Followthrough.");
	//	return ELR_NoInterrupt; 
	//}

	if (!AbilityState.RetainConcealmentOnActivation(AbilityContext))
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
		if (UnitState == none)
			return ELR_NoInterrupt; 

		//`AMLOG(UnitState.GetFullName() @ AbilityState.GetMyTemplateName() @ "breaking super concealment.");
		UnitState.bHasSuperConcealment = false;
	}
	
    return ELR_NoInterrupt;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		// Mark the unit with a unit value if they were already concealed when the effect was applied.
		if (UnitState.IsConcealed())
		{
			UnitState.SetUnitFloatValue(AlreadyConcealedValue, 1, eCleanup_BeginTactical);
		}

		// Record the super concealment status.
		if (UnitState.IsSuperConcealed())
		{
			UnitState.SetUnitFloatValue(AlreadySuperConcealedValue, 1, eCleanup_BeginTactical);
		}
	}
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static private function ShadowPassiveEffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	XComGameState_Unit(kNewTargetState).bHasSuperConcealment = true;
}

static private function ShadowEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Unit	UnitState;
	local UnitValue				UV;
	local XComGameState_Effect	AnimEffect;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}
	if (UnitState == none)
		return;

	// Restore the super concealment status.
	UnitState.bHasSuperConcealment = UnitState.GetUnitValue(default.AlreadySuperConcealedValue, UV);

	// Break concealment when the effect runs out, but only if the unit wasn't already concealed when the effect was applied.
	if (!UnitState.GetUnitValue(default.AlreadyConcealedValue, UV))
	{
		`XEVENTMGR.TriggerEvent('EffectBreakUnitConcealment', UnitState, UnitState, NewGameState);
	}

	// Cleanse the tracking for cleanliness.
	UnitState.ClearUnitValue(default.AlreadyConcealedValue);
	UnitState.ClearUnitValue(default.AlreadySuperConcealedValue);

	// No reaper animations outside of Nightfall.
	AnimEffect = UnitState.GetUnitAffectedByEffectState('IRI_BH_Nightfall_Anim_Effect');
	if (AnimEffect != none)
	{
		AnimEffect.RemoveEffect(NewGameState, NewGameState, true);
	}
}

// Display flyover when this effect naturally runs out.
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	if (RemovedEffect.iTurnsRemaining == 0)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, `GetLocalizedString("IRI_BH_Nightfall_Ended"), '', eColor_Attention,, 1, false);
	}
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
}

defaultproperties
{
	//bBringRemoveVisualizationForward = true
	AlreadyConcealedValue = "IRI_BountyHunter_DeadlyShadow_AlreadyConcealed"
	AlreadySuperConcealedValue = "IRI_BountyHunter_DeadlyShadow_AlreadySupConcealed"
	bRemoveWhenTargetConcealmentBroken = true
	EffectAddedFn = ShadowPassiveEffectAdded
	EffectRemovedFn = ShadowEffectRemoved
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_DeadlyShadow_Effect"
}
