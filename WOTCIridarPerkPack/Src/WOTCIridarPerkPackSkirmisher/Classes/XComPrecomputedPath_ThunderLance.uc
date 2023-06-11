class XComPrecomputedPath_ThunderLance extends XComPrecomputedPath;

//var bool bOverrideEndTime;

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
		bSplineDirty = FALSE;
	}
}
/*
simulated function float GetEndTime()
{
	if (bOverrideEndTime)
	{
		return 2.0f;
	}
	return super.GetEndTime();
}*/
simulated function bool MoveAlongPath(float fTime, Actor pActor)
{
	local XKeyframe KF;

	KF = ExtractInterpolatedKeyframe(fTime);

	`AMLOG(fTime);

	pActor.SetLocation(akKeyframes[iNumKeyframes-1].vLoc);
	pActor.SetRotation(akKeyframes[iNumKeyframes-1].rRot);

	if (fTime >= akKeyframes[iNumKeyframes-1].fTime)
	{
		return true;
	}
	else 
	{
		return false;
	}
}