class X2Effect_BountyHunter_CustomZeroIn extends X2Effect_Persistent;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage', BHCustomZeroInListener, ELD_OnStateSubmitted, 40, ,, EffectObj);
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
		ShotMod.Value = ShotsValue.fValue * `GetConfigInt('IRI_BH_BigGameHunter_CritBonus');
		ShotModifiers.AddItem(ShotMod);

		//ShotMod.ModType = eHit_Success;
		//ShotMod.Reason = FriendlyName;
		//ShotMod.Value = ShotsValue.fValue * `GetConfigInt('IRI_BH_CustomZeroIn_AimBonus');
		//ShotModifiers.AddItem(ShotMod);
	}
}

static private function EventListenerReturn BHCustomZeroInListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState					NewGameState;
	local UnitValue						UValue;
	local XComGameState_Effect			EffectState;
	local XComGameState_Unit			EffectUnit;
	local XComGameState_Unit			TargetUnit;
	local DamageResult					DmgResult;

	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none || TargetUnit.IsDead() || TargetUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	DmgResult = TargetUnit.DamageResults[TargetUnit.DamageResults.Length - 1];

	// Proceed only if the last damage effect was applied by us.
	if (DmgResult.SourceEffect.SourceStateObjectRef.ObjectID != EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	EffectUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (EffectUnit == none)
		return ELR_NoInterrupt;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Custom ZeroIn Increment");
	EffectUnit = XComGameState_Unit(NewGameState.ModifyStateObject(EffectUnit.Class, EffectUnit.ObjectID));

	EffectUnit.GetUnitValue('IRI_BH_CustomZeroInTarget', UValue);

	// If the target was not the primary target of this attack, then just wipe the unit values to remove the bonus.
	if (DmgResult.SourceEffect.TargetStateObjectRef.ObjectID != TargetUnit.ObjectID)
	{
		EffectUnit.ClearUnitValue('IRI_BH_CustomZeroInTarget');
		EffectUnit.ClearUnitValue('IRI_BH_CustomZeroInShots');
	}
	else if (UValue.fValue == TargetUnit.ObjectID)
	{
		// We're targeting the same target. Increment unit value to provide a stronger bonus.
		UValue.fValue = 0;
		EffectUnit.GetUnitValue('IRI_BH_CustomZeroInShots', UValue);

		EffectUnit.SetUnitFloatValue('IRI_BH_CustomZeroInShots', UValue.fValue + 1, eCleanup_BeginTactical);
	}
	else
	{
		// We've targeted a different target
		EffectUnit.SetUnitFloatValue('IRI_BH_CustomZeroInTarget', TargetUnit.ObjectID, eCleanup_BeginTactical);
		EffectUnit.SetUnitFloatValue('IRI_BH_CustomZeroInShots', 1, eCleanup_BeginTactical);
	}

	//	show flyover for boost
	NewGameState.ModifyStateObject(class'XComGameState_Ability', EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID);		//	for the vis function
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectState.TriggerAbilityFlyoverVisualizationFn;
	
	`GAMERULES.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_CustomZeroIn_Effect"
}