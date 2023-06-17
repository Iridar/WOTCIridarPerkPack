class X2Effect_Waylay extends X2Effect_Persistent;

var private const name UnitValueName;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;
	
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState != none)
	{
		EffectObj = EffectGameState;
		EventMgr = `XEVENTMGR;
		EventMgr.RegisterForEvent(EffectObj, 'OverrideDamageRemovesReserveActionPoints', OnOverrideDamageRemovesReserveActionPoints, ELD_Immediate,, UnitState,, EffectObj);	
		EventMgr.RegisterForEvent(EffectObj, 'IRI_Waylay_ShowFlyover', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	}
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{
	local XComGameState_Ability	AbilityState;
	local X2EventManager		EventMgr;
	local UnitValue				UV;
	local bool					bShowFlyover;

	if (AbilityContext.InputContext.AbilityTemplateName == 'OverwatchShot')
	{
		if (SourceUnit.GetUnitValue(UnitValueName, UV))
			return false;

		SourceUnit.ReserveActionPoints = PreCostReservePoints;
		SourceUnit.SetUnitFloatValue(UnitValueName, 1.0f, eCleanup_BeginTurn);

		bShowFlyover = true;
	}
	else if (AbilityContext.InputContext.AbilityTemplateName == 'Overwatch')
	{
		bShowFlyover = true;
	}

	if (bShowFlyover)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent('IRI_Waylay_ShowFlyover', AbilityState, SourceUnit, NewGameState);
		}
	}

	return false; 
}

static private function EventListenerReturn OnOverrideDamageRemovesReserveActionPoints(Object EventData, Object EventSource, XComGameState NewGameState, Name EventID, Object CallbackObject)
{
    local XComGameState_Unit	UnitState;
    local XComLWTuple			Tuple;
	local X2EventManager		EventMgr;
	local XComGameState_Effect	EffectState;
	local XComGameState_Ability	AbilityState;

    UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none || UnitState.IsDead())
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackObject);
	if (EffectState != none)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent('IRI_Waylay_ShowFlyover', AbilityState, UnitState, NewGameState);
		}
	}

    Tuple.Data[0].b = false;

    return ELR_NoInterrupt;
}


defaultproperties
{
	UnitValueName = "IRI_SK_Waylay_Value"
	//DuplicateResponse = eDupe_Ignore
}