class X2Effect_SP_ConstantReadiness extends X2Effect_Persistent config(Game);

var private config array<name> OverwatchAbilities;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local XComGameState_Player	PlayerState;
	local XComGameStateHistory	History;
	local Object				EffectObj;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, EffectName, EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	}

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));
	if (PlayerState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnEnded', TurnEndListener, ELD_OnStateSubmitted,, PlayerState,, EffectObj);	
	}

	super.RegisterForEvents(EffectGameState);
}

static private function EventListenerReturn TurnEndListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability	AbilityState;
	local XComGameState_Effect	EffectState;
	local XComGameState_Unit	UnitState;
	local UnitValue				AttacksThisTurn;
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability	OverwatchAbilityState;
	local XComGameStateHistory	History;
	local XComGameState			NewGameState;
	local name					OverwatchAbilityName;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;
		
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState == none)
		return ELR_NoInterrupt;
		
	UnitState.GetUnitValue('AttacksThisTurn', AttacksThisTurn);
	if (AttacksThisTurn.fValue != 0)
		return ELR_NoInterrupt;

	foreach default.OverwatchAbilities(OverwatchAbilityName)
	{
		AbilityRef = UnitState.FindAbility(OverwatchAbilityName);
		OverwatchAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (OverwatchAbilityState == none|| OverwatchAbilityState.CanActivateAbility(UnitState,, true) != 'AA_Success')
			continue;

		if (UnitState.NumActionPoints() == 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));							
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);					
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
							
		if (OverwatchAbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false))
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
			if (AbilityState != none)
			{
				`XEVENTMGR.TriggerEvent(default.EffectName, AbilityState, UnitState, GameState);
			}
			return ELR_NoInterrupt;
		}
	}
	
	return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_SP_ConstantReadiness_Effect"
}