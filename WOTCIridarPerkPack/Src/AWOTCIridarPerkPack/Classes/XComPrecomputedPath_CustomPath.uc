class XComPrecomputedPath_CustomPath extends XComPrecomputedPath;

// This custom path is made for use in a Targeting Method, 
// where it uses the UpdateGrenadePathFn delegate to allow the targeting method to alter the trajectory of the path every time it ticks, 
// which is more often than targeting method's Update().

var delegate<UpdateGrenadePath> UpdateGrenadePathFn;
delegate UpdateGrenadePath();

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
		bSplineDirty = FALSE; // it's like super extra false if you write it in caps
	}
}
