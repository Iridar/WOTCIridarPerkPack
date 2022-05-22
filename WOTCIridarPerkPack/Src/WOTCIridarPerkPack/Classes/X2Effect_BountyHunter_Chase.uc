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

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_Immediate, 90, UnitState);	
}

static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
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
				`AMLOG("Unit already had Lightning Reflex, setting Unit Value.");
				UnitState.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);
			}
			UnitState.bLightningReflexes = true;
		}
		else if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1] == UnitState.TileLocation)
		{
			if (!UnitState.GetUnitValue(default.EffectName, UV))
			{
				`AMLOG(UnitState.GetFullName() @ "final tile of movement, taking away Lightning Reflex");
				UnitState.bLightningReflexes = false;
			}
			else `AMLOG(UnitState.GetFullName() @ "final tile of movement, but unit had Lightning Reflex prior to Chase, not taking them away.");
		}
	}	
	
    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_Chase_Effect"
}