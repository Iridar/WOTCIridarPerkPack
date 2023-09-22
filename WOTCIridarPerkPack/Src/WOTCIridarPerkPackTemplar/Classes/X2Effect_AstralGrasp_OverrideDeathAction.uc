class X2Effect_AstralGrasp_OverrideDeathAction extends X2Effect_OverrideDeathAction;

simulated function X2Action AddX2ActionsForVisualization_Death(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	local X2Action					AddAction;
	local X2Action_ApplyMITV		ApplyMITV;
	local X2Action_AstralGrasp		GetOverHereTarget;

	if( DeathActionClass != none && DeathActionClass.static.AllowOverrideActionDeath(ActionMetadata, Context))
	{
		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Dissolve_MITV";

		AddAction = class'X2Action'.static.CreateVisualizationActionClass( DeathActionClass, Context, ActionMetadata.VisualizeActor );
		class'X2Action'.static.AddActionToVisualizationTree(AddAction, ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

		class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	}

	return AddAction;
}
