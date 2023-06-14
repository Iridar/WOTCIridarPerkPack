class XComPrecomputedPath_ThunderLance extends XComPrecomputedPath;

// This custom path has two functions.

// 1. For the Targeting Method, it uses the UpdateGrenadePathFn delegate
// to allow the targeting method to alter the trajectory of the path
// every time it ticks, which is more often than targeting method's Update().

// 2. For the Fire Action, it overrides the MoveAlongPath() function,
// which basically makes the projectile teleport to the end location instantly,
// and then wait for the amount of time specified in the Fire Action.

var delegate<UpdateGrenadePath> UpdateGrenadePathFn;
delegate UpdateGrenadePath();

var X2Action_Fire_ThunderLance FireAction;

simulated event Tick(float DeltaTime)
{	
	local float PathLength;

	if (kRenderablePath.HiddenGame)
	{
		return;
	}
	if (m_bBlasterBomb)
	{
		CalculateBlasterBombTrajectoryToTarget();
	}
	else
	{
		UpdateTrajectory();
		if (UpdateGrenadePathFn != none)
		{
			UpdateGrenadePathFn();
		}
	}

	DrawPath();

	if( bSplineDirty || true)
	{
		PathLength = akKeyframes[iNumKeyframes - 1].fTime - akKeyframes[0].fTime;
		kRenderablePath.UpdatePathRenderData(kSplineInfo,PathLength,none,`CAMERASTACK.GetCameraLocationAndOrientation().Location);
		bSplineDirty = FALSE;
	}
}

simulated function bool MoveAlongPath(float fTime, Actor pActor)
{
	pActor.SetLocation(akKeyframes[iNumKeyframes-1].vLoc);
	pActor.SetRotation(akKeyframes[iNumKeyframes-1].rRot);

	return fTime >= akKeyframes[iNumKeyframes-1].fTime;
}
