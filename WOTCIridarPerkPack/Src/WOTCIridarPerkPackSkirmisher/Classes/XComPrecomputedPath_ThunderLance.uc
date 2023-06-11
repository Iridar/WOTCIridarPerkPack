class XComPrecomputedPath_ThunderLance extends XComPrecomputedPath;

var XComPrecomputedPath GrenadePath;
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
		UpdateGrenadePathFn();
	}

	DrawPath();

	if( bSplineDirty || true)
	{
		PathLength = akKeyframes[iNumKeyframes - 1].fTime - akKeyframes[0].fTime;
		kRenderablePath.UpdatePathRenderData(kSplineInfo,PathLength,none,`CAMERASTACK.GetCameraLocationAndOrientation().Location);
		bSplineDirty = FALSE;
	}
}