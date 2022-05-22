class X2Effect_BountyHunter_Chase extends X2Effect_Persistent;

// Gives and takes Lightning Reflex during Chase.

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated_LightningReflex, ELD_Immediate, 90, UnitState);	
	//EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated_Overwatch, ELD_OnStateSubmitted,, ,, EffectObj);	
}

static private function EventListenerReturn OnAbilityActivated_LightningReflex(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local UnitValue						UV;
		
	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none || AbilityState.GetMyTemplateName() != 'IRI_BH_ChasingShot')
		 return ELR_NoInterrupt;
	
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt) // Process only during the interrupt step.
		 return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		 return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (UnitState == none)
		 return ELR_NoInterrupt;

	if (AbilityContext.InputContext.MovementPaths.Length > 0 && 
		AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length > 0)
	{
		if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[0] == UnitState.TileLocation)
		{
			`AMLOG(UnitState.GetFullName() @ "first tile of movement, granting Lightning Reflex");
			if (UnitState.bLightningReflexes)
			{
				`AMLOG("Unit already had Lightning Reflex, setting Unit Value of 2.");
				UnitState.SetUnitFloatValue(default.EffectName, 2.0f, eCleanup_BeginTurn);
			}
			else
			{
				`AMLOG("Unit did not have Lightning Reflex, setting Unit Value of 1.");
				UnitState.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
			}
			UnitState.bLightningReflexes = true;
		}
		else if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1] == UnitState.TileLocation)
		{
			UnitState.GetUnitValue(default.EffectName, UV);
			if (UV.fValue == 2.0f)
			{
				`AMLOG(UnitState.GetFullName() @ "final tile of movement, taking away Lightning Reflex");
				UnitState.bLightningReflexes = false;
			}
			else `AMLOG(UnitState.GetFullName() @ "final tile of movement, but unit had Lightning Reflex prior to Chase, not taking them away.");

			// Unit reached destination, remove Unit Value.
			UnitState.ClearUnitValue(default.EffectName);
		}
	}	
	
    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnAbilityActivated_Overwatch(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Unit            ChasingUnit;
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local UnitValue						UV;
	local XComGameState_Effect			EffectState;
		
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt) 
		 return ELR_NoInterrupt; // Process only outside the interrupt step.

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		 return ELR_NoInterrupt;

	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID)
		return ELR_NoInterrupt; // Proceed only if the ability is targeted at the source of the Chase Effect i.e. unit doing the Chase.

	ChasingUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (ChasingUnit == none || !ChasingUnit.GetUnitValue(default.EffectName, UV))
		return ELR_NoInterrupt; // Proceed only if the unit was actually chasing

	AbilityContext.PostBuildVisualizationFn.AddItem(ChasingShot_PostBuildVisualization);
	
    return ELR_NoInterrupt;
}

static private function ChasingShot_PostBuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr					VisMgr;
	local X2Action_BountyHunter_ApplyWeaponDamageToUnit	ApplyWeaponDamageToUnit;
	local X2Action										FindAction;
	local array<X2Action>								FindActions;
	local XComGameStateContext_Ability					AbilityContext;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	VisMgr = `XCOMVISUALIZATIONMGR;

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', FindActions,, AbilityContext.InputContext.PrimaryTarget.ObjectID);
	`AMLOG("Found this many damage unit actions:" @ FindActions.Length);
	foreach FindActions(FindAction)
	{
		ApplyWeaponDamageToUnit = X2Action_BountyHunter_ApplyWeaponDamageToUnit(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_BountyHunter_ApplyWeaponDamageToUnit', AbilityContext));
		ApplyWeaponDamageToUnit.OriginatingEffect = X2Action_ApplyWeaponDamageToUnit(FindAction).OriginatingEffect;
		VisMgr.ReplaceNode(ApplyWeaponDamageToUnit, FindAction);
	}

	`log("======================================",, 'IRIPISTOLVIZ');
	`log("Build Tree",, 'IRIPISTOLVIZ');
	PrintActionRecursive(VisMgr.BuildVisTree.TreeRoot, 0);
	`log("--------------------------------------",, 'IRIPISTOLVIZ');
}

static function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;

	`LOG("Action layer: " @ iLayer @ ": " @ Action.Class.Name @ Action.StateChangeContext.AssociatedState.HistoryIndex,, 'IRIPISTOLVIZ'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_Chase_Effect"
}