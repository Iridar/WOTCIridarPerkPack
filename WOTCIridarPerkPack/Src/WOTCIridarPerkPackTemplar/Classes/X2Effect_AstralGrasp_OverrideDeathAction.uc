class X2Effect_AstralGrasp_OverrideDeathAction extends X2Effect_OverrideDeathAction;

simulated function X2Action AddX2ActionsForVisualization_Death(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	local X2Action					AddAction;
	local X2Action_ApplyMITV		ApplyMITV;
	//local X2Action_AstralGrasp		GetOverHereTarget;
	local X2Action_TimedWait		TimedWait;
	local X2Action					CommonParent;

	if( DeathActionClass != none && DeathActionClass.static.AllowOverrideActionDeath(ActionMetadata, Context))
	{
		if (ActionMetadata.LastActionAdded != none)
		{
			CommonParent = ActionMetadata.LastActionAdded;
		}
		else
		{
			CommonParent = class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		}

		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, Context, false, CommonParent));
		ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Destruct_Start_MITV";

		AddAction = class'X2Action'.static.CreateVisualizationActionClass( DeathActionClass, Context, ActionMetadata.VisualizeActor );
		class'X2Action'.static.AddActionToVisualizationTree(AddAction, ActionMetadata, Context, false, CommonParent);

		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Dissolve_MITV";

		TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		TimedWait.DelayTimeSec = 3.0f;

		class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	}

	return AddAction;
}
