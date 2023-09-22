class X2Action_HideUnit extends X2Action;

// Next time you need this might wanna use invisible MITV instead: 
// ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
// ApplyMITV.MITVPath = "FX_Cyberus_Materials.M_Cyberus_Invisible_MITV";

simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		UnitPawn.Mesh.SetHidden(true);
	}

Begin:

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}
