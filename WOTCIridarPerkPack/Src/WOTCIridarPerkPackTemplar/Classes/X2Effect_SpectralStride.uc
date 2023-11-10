class X2Effect_SpectralStride extends X2Effect_PersistentTraversalChange;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_ApplyMITV			ApplyMITV;
	local X2Action_PlaySound	SoundAction;
	local X2Action_PlayEffect			EffectAction;

	if (EffectApplyResult == 'AA_Success')
	{
		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		ApplyMITV.MITVPath = "FX_Templar_Ghost.M_Ghost_Character_Reveal_MITV"; // "FX_Warlock_SpectralArmy.M_SpectralArmy_Activate_MITV"; //

		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		EffectAction.EffectName = "FX_Warlock_SpectralArmy.P_SpectralArmy_End";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'CIN_Root';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';
	
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		EffectAction.EffectName = "FX_Templar_Ghost.P_Ghost_Target_Persistent";
		EffectAction.AttachToUnit = true;
		EffectAction.AttachToSocketName = 'FX_Chest';
		EffectAction.AttachToSocketsArrayName = 'BoneSocketActor';

		SoundAction = X2Action_PlaySound(class'X2Action_PlaySound'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAction.SoundCue = "IRISpectralStride.Templar_Ghost_Target_Cue";

		SoundAction = X2Action_PlaySound(class'X2Action_PlaySound'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAction.SoundCue = "IRISpectralStride.Templar_Ghost_Target_Loop_Cue";
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlaySound	SoundAction;
	local X2Action_PlayDeathEffect		EffectAction;
	local XGUnit						VisualizeUnit;
	local XComUnitPawn					UnitPawn;

	VisualizeUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (VisualizeUnit != none)
	{
		UnitPawn = VisualizeUnit.GetPawn();
		if (UnitPawn != none && UnitPawn.Mesh != none)
		{
			EffectAction = X2Action_PlayDeathEffect(class'X2Action_PlayDeathEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			EffectAction.EffectName = "FX_Templar_Ghost.P_Ghost_Target_Dissolve";
			EffectAction.PawnMesh = UnitPawn.Mesh;
			EffectAction.AttachToSocketName = 'FX_Chest';
		}
	}

	SoundAction = X2Action_PlaySound(class'X2Action_PlaySound'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	SoundAction.SoundCue = "IRISpectralStride.Stop_Templar_Ghost_Target_Loop_Cue";

	class'X2Action_RemoveMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_TM_SpectralStride_Effect"
}
