class X2Effect_BountyHunter_Terminate extends X2Effect_Persistent config(Game);

var private config array<name> TerminateExcludedAbilities;
var private config array<name> TerminateVisualizeBurstFireAbilities;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	// This effect is applied to the target, but we're listening for ability activations from the shooter.
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, 45, UnitState,, EffectObj);	
}

static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Ability         AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Ability			ExtraShotAbilityState;
	local StateObjectReference			AbilityRef;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Effect			EffectState;
	local bool							bBurstFireVis;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt) return ELR_NoInterrupt;
		
	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none) return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none) return ELR_NoInterrupt;

	if (!IsAbilityValidForTerminate(AbilityState, AbilityTemplate)) 
		return ELR_NoInterrupt;
	
	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none) return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)	return ELR_NoInterrupt;

	bBurstFireVis = default.TerminateVisualizeBurstFireAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE &&	
					AbilityContext.InputContext.ItemObject.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID;

	if (bBurstFireVis)
	{
		AbilityRef = SourceUnit.FindAbility('IRI_BH_Terminate_ExtraShot_SkipFireAction', EffectState.ApplyEffectParameters.ItemStateObjectRef);
	}
	else
	{
		AbilityRef = SourceUnit.FindAbility('IRI_BH_Terminate_ExtraShot', EffectState.ApplyEffectParameters.ItemStateObjectRef);
	}
	if (AbilityRef.ObjectID == 0) return ELR_NoInterrupt;

	ExtraShotAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (ExtraShotAbilityState == none) return ELR_NoInterrupt;

	if (bBurstFireVis)
	{
		AbilityContext.PostBuildVisualizationFn.AddItem(Terminate_ReplaceFireAction_PostBuildVis);
	}

	ExtraShotAbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false, GameState.HistoryIndex);

    return ELR_NoInterrupt;
}

static private function Terminate_ReplaceFireAction_PostBuildVis(XComGameState VisualizeGameState)
{
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local XComGameStateVisualizationMgr		VisMgr;
	local XComGameStateContext_Ability		AbilityContext;
	local X2Action_Fire						FireAction;
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_Fire_CustomAnim			NewFireAction;
	local X2Action_WaitForAnotherAction		WaitAction;

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_Fire', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);

	foreach FindActions(FindAction)
	{
		FireAction = X2Action_Fire(FindAction);
		if (FireAction.PrimaryTargetID == AbilityContext.InputContext.PrimaryTarget.ObjectID)
		{
			break;
		}
	}

	if (FireAction == none)
		return;

	ActionMetadata = FireAction.Metadata;
	NewFireAction = X2Action_Fire_CustomAnim(class'X2Action_Fire_CustomAnim'.static.CreateVisualizationAction(AbilityContext, ActionMetadata.VisualizeActor));

	if (AbilityContext.InputContext.AbilityTemplateName == 'IRI_BH_BurstFire')
	{
		NewFireAction.CustomAnim = 'FF_IRI_BH_BurstFire_Double';
	}
	else
	{
		NewFireAction.CustomAnim = 'FF_IRI_BH_BurstFire';
	}

	NewFireAction.SetMetadata(ActionMetadata);
	NewFireAction.SetFireParameters(true, FireAction.PrimaryTargetID, FireAction.bNotifyMultiTargetsAtOnce);
	NewFireAction.AbilityContext=FireAction.AbilityContext;
	NewFireAction.VisualizeGameState=FireAction.VisualizeGameState;
	NewFireAction.SourceUnitState=FireAction.SourceUnitState;
	NewFireAction.SourceItemGameState=FireAction.SourceItemGameState;
	NewFireAction.AbilityTemplate=FireAction.AbilityTemplate;
	NewFireAction.kPerkContent=FireAction.kPerkContent;
	NewFireAction.bUpdatedMusicState=FireAction.bUpdatedMusicState;
	NewFireAction.FOWViewer=FireAction.FOWViewer;
	NewFireAction.SourceFOWViewer=FireAction.SourceFOWViewer;
	NewFireAction.AllowInterrupt=FireAction.AllowInterrupt;

	//	We replace the original Fire Action, but the X2Action_WaitForAnotherAction will still be waiting on it up until the garbage collecter remembers
	//	it needs to remove the original Fire Action that was destroyed by Replace Node, causing a hangup in game. So we make the Wait Action wait on the new fire action instead.
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_WaitForAnotherAction', FindActions);
	foreach FindActions(FindAction)
	{
		WaitAction = X2Action_WaitForAnotherAction(FindAction);
		if (WaitAction.ActionToWaitFor == FireAction) 
		{
			WaitAction.ActionToWaitFor = NewFireAction;
		}
	}

	`AMLOG("Replacing First Fire Action");
	VisMgr.ReplaceNode(NewFireAction, FireAction);		
	//	#### END OF REPLACE
}

static private function bool IsAbilityValidForTerminate(const XComGameState_Ability AbilityState, const X2AbilityTemplate AbilityTemplate)
{
	if (default.TerminateExcludedAbilities.Find(AbilityTemplate.DataName) != INDEX_NONE)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's in the exclusion list.");
		return false;
	}

	if (AbilityState.IsMeleeAbility())
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's a melee ability.");
		return false;
	}

	if (AbilityTemplate.bUseThrownGrenadeEffects || AbilityTemplate.bUseLaunchedGrenadeEffects) 
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's a grenade throw or launch.");
		return false;
	}

	if (!AbilityTemplate.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it doesn't deal damage.");
		return false;
	}

	if (AbilityTemplate.AbilityMultiTargetStyle != none && !AbilityTemplate.AbilityMultiTargetStyle.IsA(class'X2AbilityMultiTarget_BurstFire'.Name))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's multi target");
		return false;
	}

	if (!AbilityState.IsAbilityInputTriggered())
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's not user input triggered");
		return false;
	}

	if (AbilityTemplate.AbilityMultiTargetStyle != none && !AbilityTemplate.AbilityMultiTargetStyle.IsA(class'X2AbilityMultiTarget_BurstFire'.Name))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's multi target");
		return false;
	}

	if (AbilityTemplate.Hostility != eHostility_Offensive)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's not offensive.");
		return false;
	}

	if (AbilityTemplate.AbilityTargetStyle == none || !AbilityTemplate.AbilityTargetStyle.IsA(class'X2AbilityTarget_Single'.Name))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid because it's not single target style.");
		return false;
	}

	`AMLOG(AbilityTemplate.DataName @ "Ability is valid.");

	return true;
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_Terminate_Effect"
}