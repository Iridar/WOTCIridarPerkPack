class X2Effect_PredatorStrike extends X2Effect_ApplyWeaponDamage;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local int TotalToKill; 
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;
	
	TotalToKill = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);
	TargetUnit.TakeEffectDamage(self, TotalToKill, 0, 0, ApplyEffectParameters, NewGameState, false, false, true, DamageTypes);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	// Don't need any vis from this effect.
}

defaultproperties
{
	bBypassSustainEffects = true
	bIgnoreBaseDamage = true
	//bAppliesDamage = true
	DamageTypes(0) = "Melee"
}