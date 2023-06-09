class X2Effect_PredatorStrike extends X2Effect_ApplyWeaponDamage;

// Effect simplified to just execute the enemy, without visualization, which is handled elsewhere.

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local int TotalToKill; 
	local XComGameState_Unit SourceUnit;
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;
	
	TotalToKill = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
	TargetUnit.TakeEffectDamage(self, TotalToKill, 0, 0, ApplyEffectParameters, NewGameState, false, false, true, DamageTypes);

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	`AMLOG("Running");

	// Trigger the event that will activate the Reveal Enemy ability. Do it here to so it triggers only if the ability has hit.
	if (TargetUnit.GetTeam() == eTeam_Alien && TargetUnit.GetMyTemplate().bIsAdvent)
	{	
		`AMLOG("Triggering event");
		`XEVENTMGR.TriggerEvent('IRI_SK_PredatorStrike_Activated', TargetUnit, SourceUnit, NewGameState);
	}
}

// Visualize only misses and only against units that can't play the skulljack animation.
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XGUnit TargetUnit;
	local XComUnitPawn TargetPawn;

	TargetUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (TargetUnit == none)
	{
		super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
		return;
	}
	TargetPawn = TargetUnit.GetPawn();
	if (TargetPawn == none)
	{
		super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
		return;
	}
	if (!TargetPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedStart') && EffectApplyResult != 'AA_Success')
	{
		super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	}
}

// Don't need damage preview for this ability.
simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
}

defaultproperties
{
	bBypassSustainEffects = true
	bIgnoreBaseDamage = true
	DamageTypes(0) = "Melee"
}