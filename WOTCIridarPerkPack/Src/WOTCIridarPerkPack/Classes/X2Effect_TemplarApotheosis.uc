class X2Effect_TemplarApotheosis extends X2Effect_Persistent;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{ 
	local X2AbilityCost_Focus	FocusCost;
	local X2AbilityCost			AbilityCost;
	local X2AbilityTemplate		AbilityTemplate;
	local X2EventManager		EventMgr;
	local XComGameState_Ability	AbilityState;
	local int i;

	AbilityTemplate = kAbility.GetMyTemplate();

	`LOG(GetFuncName() @ AbilityTemplate.DataName,, 'IRITEST');

	foreach AbilityTemplate.AbilityCosts(AbilityCost)
	{
		FocusCost = X2AbilityCost_Focus(AbilityCost);
		if (FocusCost != none && FocusCost.FocusAmount > 0 && !FocusCost.GhostOnlyCost)
		{
			SourceUnit.ActionPoints = PreCostActionPoints;
			`LOG("Restoring action points",, 'IRITEST');

			for (i = SourceUnit.ActionPoints.Length - 1; i >= 0; i--)
			{
				if (SourceUnit.ActionPoints[i] == class'X2CharacterTemplateManager'.default.StandardActionPoint)
				{
					`LOG("Take away one standard AP",, 'IRITEST');
					SourceUnit.ActionPoints.Remove(i, 1);
					break;
				}
			}
			if (SourceUnit.ActionPoints.Length > 0)
			{
				AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('IRI_Apotheosis').ObjectID));
				EventMgr = `XEVENTMGR;
				EventMgr.TriggerEvent('X2Effect_TemplarApotheosis_Event', AbilityState, SourceUnit, NewGameState);
			}
			return false;
		}
	}
	return false; 
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_TemplarApotheosis_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	
	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_TemplarApotheosis_Event', AbilityState, SourceUnit, NewGameState);
	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted,, UnitState);		
}

static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit				UnitState;
	local XComGameState_Effect_TemplarFocus TemplarFocus;
	local XComGameState_Effect_TemplarFocus OldTemplarFocus;
	local XComGameState						NewGameState;
	local X2EventManager					EventMgr;
	local XComGameState_Ability				AbilityState;

	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState.GetMyTemplateName() == 'FocusKillTracker')
		return ELR_NoInterrupt;
		
	UnitState = XComGameState_Unit(EventSource);

	TemplarFocus = UnitState.GetTemplarFocusEffectState();
	OldTemplarFocus = XComGameState_Effect_TemplarFocus(`XCOMHISTORY.GetGameStateForObjectID(TemplarFocus.ObjectID,, GameState.HistoryIndex - 1));

	if (TemplarFocus.FocusLevel > OldTemplarFocus.FocusLevel)
	{
		`LOG(GetFuncName() @ XComGameState_Ability(EventData).GetMyTemplateName() @ "increasing focus level",, 'IRITEST');

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		TemplarFocus = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(TemplarFocus.Class, TemplarFocus.ObjectID));
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		TemplarFocus.SetFocusLevel(TemplarFocus.FocusLevel + 1, UnitState, NewGameState);

		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(UnitState.FindAbility('IRI_Apotheosis').ObjectID));
		EventMgr = `XEVENTMGR;
		EventMgr.TriggerEvent('X2Effect_TemplarApotheosis_Event', AbilityState, UnitState, NewGameState);

		`GAMERULES.SubmitGameState(NewGameState);
	}
	
    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_Apotheosis_Effect"
}