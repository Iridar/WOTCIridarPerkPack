class X2Action_ShowUnit extends X2Action;

simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		UnitPawn.Mesh.SetHidden(false);
	}

Begin:

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}
