class X2Action_HideUnit extends X2Action;

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
