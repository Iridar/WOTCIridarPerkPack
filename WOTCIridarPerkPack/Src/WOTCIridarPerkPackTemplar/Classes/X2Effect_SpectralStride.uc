class X2Effect_SpectralStride extends X2Effect_PersistentTraversalChange;
/*
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_ApplyMITV ApplyMITV;

	if (EffectApplyResult == 'AA_Success')
	{
		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Reveal_MITV";
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	class'X2Action_RemoveMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, , EffectApplyResult, RemovedEffect);
}
*/

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_TM_X2Effect_SpectralStride_Effect"
}