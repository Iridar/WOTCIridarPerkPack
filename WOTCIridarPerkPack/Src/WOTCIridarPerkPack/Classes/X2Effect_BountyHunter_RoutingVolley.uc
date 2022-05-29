class X2Effect_BountyHunter_RoutingVolley extends X2Effect_Suppression;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'OverrideReactionFireSlomo', OnOverrideReactionFireSlomo, ELD_Immediate);	

	super.RegisterForEvents(EffectGameState);
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
	if (AbilityContext.InputContext.AbilityTemplateName == 'IRI_BH_RoutingVolley_Attack')
	{
		`AMLOG("Setting as reaction fire");
		Tuple.Data[0].b = true;
	}

    return ELR_NoInterrupt;
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{ 
	local XComGameState_Effect NewEffectState;

	//	A rough check to filter out abilities that do not cost an action point.
	//if (SourceUnit.ActionPoints.Length != PreCostActionPoints.Length || SourceUnit.ReserveActionPoints.Length != PreCostReservePoints.Length)
	//{
		if (EffectState.GrantsThisTurn != 0 && kAbility.IsAbilityInputTriggered())
		{
			`AMLOG(SourceUnit.GetFullName() @ "activated ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "setting Grants this turn.");
			NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', EffectState.ObjectID));
			NewEffectState.GrantsThisTurn = 0;
		}
	//}
	return false; 
}
