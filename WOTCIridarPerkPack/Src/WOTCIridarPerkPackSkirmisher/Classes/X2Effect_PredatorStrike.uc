class X2Effect_PredatorStrike extends X2Effect_Executed;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	// Same as original, just without visualization.
}

defaultproperties
{
	bAppliesDamage = true
	DamageTypes(0) = "Melee"
}