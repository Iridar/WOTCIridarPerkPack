class X2Effect_PredatorStrikeReveal extends X2Effect_TargetDefinition;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_TimedWait TimedWait;

	if (EffectApplyResult == 'AA_Success')
	{
		TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		TimedWait.DelayTimeSec = 2.75f;

		class'X2StatusEffects'.static.AddEffectCameraPanToAffectedUnitToTrack(ActionMetadata, VisualizeGameState.GetContext(), 2.0f);
		AddFlyover(VisualizeGameState, ActionMetadata, EffectApplyResult);
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

private function AddFlyover(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameStateContext_Ability	AbilityContext;

	if (EffectApplyResult != 'AA_Success')
		return;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	
	if (AbilityContext == none)
		return;
		
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	if (AbilityTemplate == none)
		return;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Bad, AbilityTemplate.IconImage, 1.0f, true); 
}