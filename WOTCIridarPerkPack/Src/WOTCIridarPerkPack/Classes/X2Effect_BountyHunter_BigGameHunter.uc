class X2Effect_BountyHunter_BigGameHunter extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_BountyHunter_BigGameHunter_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	
	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_BountyHunter_BigGameHunter_Event', AbilityState, SourceUnit, NewGameState);
	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', AbilityActivated_Listener, ELD_OnStateSubmitted, 30, UnitState,, EffectObj);	
	/*
	native function RegisterForEvent( ref Object SourceObj, 
									Name EventID, 
									delegate<OnEventDelegate> NewDelegate, 
									optional EventListenerDeferral Deferral=ELD_Immediate, 
									optional int Priority=50, 
									optional Object PreFilterObject, 
									optional bool bPersistent, 
									optional Object CallbackData );*/
	
	//super.RegisterForEvents(EffectGameState);
}

static function EventListenerReturn AbilityActivated_Listener(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Ability								BGHAbilityState;
    local XComGameState_Ability								AbilityState;
	local XComGameStateContext_Ability						AbilityContext;
	local XComGameState_Effect_BountyHunter_BigGameHunter	EffecState;
	local XComGameState										NewGameState;
	local XComGameState_Unit								UnitState;
	local StateObjectReference								AbilityRef;
	local XComGameStateHistory								History;
	local array<name>										IncludedAbilities;
	local X2AbilityTemplate									Template;
		
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	Template = AbilityState.GetMyTemplate();
	if (Template == none)
		return ELR_NoInterrupt;

	IncludedAbilities = `GetConfigArrayName('IRI_BH_BigGameHunter_InclusionList');
	if (AbilityState.IsAbilityInputTriggered() && Template.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) || 
		IncludedAbilities.Find(Template.DataName) != INDEX_NONE)
	{	
		EffecState = XComGameState_Effect_BountyHunter_BigGameHunter(CallbackData);
		if (EffecState == none)
			return ELR_NoInterrupt;

		`AMLOG("Running for ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "it was a crit:" @ AbilityContext.ResultContext.HitResult == eHit_Crit @ "previous crits:" @ EffecState.iNumConsecutiveCrits);

		// We already critted this target once previously, and this is a crit as well. Trigger additional attack.
		if (AbilityContext.ResultContext.HitResult == eHit_Crit && EffecState.TargetObjectID == AbilityContext.InputContext.PrimaryTarget.ObjectID && EffecState.iNumConsecutiveCrits > 0)
		{
			History = `XCOMHISTORY;
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
			if (UnitState == none)
				return ELR_NoInterrupt;

			AbilityRef = UnitState.FindAbility('IRI_BH_BigGameHunter');
			BGHAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (BGHAbilityState == none)
				return ELR_NoInterrupt;

			`AMLOG("Triggering ability and resetting counter:" @ BGHAbilityState != none);

			BGHAbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false);

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Big Game Hunter Effect State");
			EffecState = XComGameState_Effect_BountyHunter_BigGameHunter(NewGameState.ModifyStateObject(EffecState.Class, EffecState.ObjectID));
			EffecState.iNumConsecutiveCrits = 0;
			`GAMERULES.SubmitGameState(NewGameState);
		}
		else // We attacked something else or we didn't crit. Reset the tracker.
		{
			`AMLOG("Unit attacked another target");

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Big Game Hunter Effect State");
			EffecState = XComGameState_Effect_BountyHunter_BigGameHunter(NewGameState.ModifyStateObject(EffecState.Class, EffecState.ObjectID));
			EffecState.TargetObjectID = AbilityContext.InputContext.PrimaryTarget.ObjectID;
			if (AbilityContext.ResultContext.HitResult == eHit_Crit)
			{
				`AMLOG("This attack has crit, setting counter to 1");
				EffecState.iNumConsecutiveCrits = 1;
			}
			else
			{
				`AMLOG("This attack did not crit, setting counter to 0");
				EffecState.iNumConsecutiveCrits = 0;
			}
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_BigGameHunter_Effect"
	GameStateEffectClass = class'XComGameState_Effect_BountyHunter_BigGameHunter'
}