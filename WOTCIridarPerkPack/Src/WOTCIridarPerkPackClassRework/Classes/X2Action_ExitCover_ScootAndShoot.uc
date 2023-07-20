class X2Action_ExitCover_ScootAndShoot extends X2Action_ExitCover;

function Init()
{
	super.Init();

	// Apparently X2Action_ExitCover barely does anything if the ability involves movement.
	bIsEndMoveAbility = false;
}