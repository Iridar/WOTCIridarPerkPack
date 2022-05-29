class X2Effect_BountyHunter_UpdateSuppressionHistoryIndex extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	TargetUnit.m_SuppressionHistoryIndex = `XCOMHISTORY.GetNumGameStates(); // the NewGameState is pending submission, so its index will be the next index in the history
}
/*
simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_MoveTurn				MoveTurn;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			TargetUnit;

	if (EffectApplyResult == 'AA_Success')
	{
		AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
		TargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if (TargetUnit != none && TargetUnit.IsAlive())
		{
			MoveTurn = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
			MoveTurn.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
		}
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}
*/