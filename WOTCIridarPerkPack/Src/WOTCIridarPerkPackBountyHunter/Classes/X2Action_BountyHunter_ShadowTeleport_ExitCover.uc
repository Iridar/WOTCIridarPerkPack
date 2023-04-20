class X2Action_BountyHunter_ShadowTeleport_ExitCover extends X2Action_ExitCover;

function Init()
{
	super.Init();

	TargetLocation = AbilityContext.InputContext.TargetLocations[0];
	AimAtLocation = TargetLocation;

	// So that exit cover visualization is not skipped
	bIsEndMoveAbility = false;
}
