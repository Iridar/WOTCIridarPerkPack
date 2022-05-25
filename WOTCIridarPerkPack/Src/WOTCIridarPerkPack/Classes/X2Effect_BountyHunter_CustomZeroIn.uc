class X2Effect_BountyHunter_CustomZeroIn extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', BHCustomZeroInListener, ELD_OnStateSubmitted,, `XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID),, EffectObj);
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;
	local UnitValue ShotsValue, TargetValue;

	Attacker.GetUnitValue('IRI_BH_CustomZeroInShots', ShotsValue);
	Attacker.GetUnitValue('IRI_BH_CustomZeroInTarget', TargetValue);
		
	if (ShotsValue.fValue > 0 && TargetValue.fValue == Target.ObjectID)
	{
		ShotMod.ModType = eHit_Crit;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * `GetConfigInt('IRI_BH_CustomZeroIn_CritBonus');
		ShotModifiers.AddItem(ShotMod);

		ShotMod.ModType = eHit_Success;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = ShotsValue.fValue * `GetConfigInt('IRI_BH_CustomZeroIn_AimBonus');
		ShotModifiers.AddItem(ShotMod);
	}
}

static private function EventListenerReturn BHCustomZeroInListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;
	local XComGameState					NewGameState;
	local XComGameState_Unit			UnitState;
	local X2AbilityTemplate				Template;
	local UnitValue						UValue;
	local XComGameState_Effect			EffectGameState;
	local array<name>					IncludedAbilities;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	Template = AbilityState.GetMyTemplate();
	if (Template == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	EffectGameState = XComGameState_Effect(CallbackData);
	if (EffectGameState == none)
		return ELR_NoInterrupt;

	IncludedAbilities = `GetConfigArrayName('IRI_BH_CustomZeroIn_InclusionList');
	if (IncludedAbilities.Find(Template.DataName) != INDEX_NONE || 
		AbilityState.IsAbilityInputTriggered() && Template.Hostility == eHostility_Offensive && Template.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Custom ZeroIn Increment");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

		UnitState.GetUnitValue('IRI_BH_CustomZeroInTarget', UValue);
		if (UValue.fValue == AbilityContext.InputContext.PrimaryTarget.ObjectID)
		{
			// We're targeting the same target
			UValue.fValue = 0;
			UnitState.GetUnitValue('IRI_BH_CustomZeroInShots', UValue);

			UnitState.SetUnitFloatValue('IRI_BH_CustomZeroInShots', UValue.fValue + 1, eCleanup_BeginTurn);
		}
		else
		{
			// We've targeted a different target
			UnitState.SetUnitFloatValue('IRI_BH_CustomZeroInTarget', AbilityContext.InputContext.PrimaryTarget.ObjectID, eCleanup_BeginTurn);
			UnitState.SetUnitFloatValue('IRI_BH_CustomZeroInShots', 1, eCleanup_BeginTurn);
		}

		if (UnitState.ActionPoints.Length > 0)
		{
			//	show flyover for boost, but only if they have actions left to potentially use them
			NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectGameState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);		//	create this for the vis function
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectGameState.TriggerAbilityFlyoverVisualizationFn;
		}
		`GAMERULES.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_CustomZeroIn_Effect"
}