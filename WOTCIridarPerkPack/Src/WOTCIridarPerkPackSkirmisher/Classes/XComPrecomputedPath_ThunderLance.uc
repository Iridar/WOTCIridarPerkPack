class XComPrecomputedPath_ThunderLance extends XComPrecomputedPath;

// This custom path has two functions.

// 1. For the Targeting Method, it uses the UpdateGrenadePathFn delegate
// to allow the targeting method to alter the trajectory of the path
// every time it ticks, which is more often than targeting method's Update().

// 2. For the Fire Action, it overrides the MoveAlongPath() function,
// which basically makes the projectile follow the main grapple projectile.

var X2Action_Fire_ThunderLance FireAction;

var delegate<UpdateGrenadePath> UpdateGrenadePathFn;
delegate UpdateGrenadePath();

// #1.
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

// #2.
simulated function bool MoveAlongPath(float fTime, Actor pActor)
{
	local X2UnifiedProjectile_ThunderLance	MainProjectile;
	local X2UnifiedProjectile				Projectile;

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		MainProjectile = X2UnifiedProjectile_ThunderLance(Projectile);
		if (MainProjectile != none)
		{
			pActor.SetLocation(MainProjectile.Projectiles[0].TargetAttachActor.Location);
			pActor.SetRotation(MainProjectile.Projectiles[0].TargetAttachActor.Rotation);

			`AMLOG("Moving projectile.." @ MainProjectile.Projectiles[0].TargetAttachActor.Location);

			return fTime >= akKeyframes[iNumKeyframes-1].fTime;
		}
	}

	// Just teleport the projectile to the end if we can't find the main projectile, which shouldn't be happening really.
	pActor.SetLocation(akKeyframes[iNumKeyframes-1].vLoc);
	pActor.SetRotation(akKeyframes[iNumKeyframes-1].rRot);

	return fTime >= akKeyframes[iNumKeyframes-1].fTime;
}
