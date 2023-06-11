class X2Action_Fire_ThunderLance extends X2Action_Fire;

var private bool locbMainImpactNotify;
var private Vector locHitLocation;
var private bool bProcessingDelay;

var private XComPrecomputedPath_ThunderLance CustomPath;
/*
[0064.49] WOTCIridarPerkPack: Executing Playing animation: 3.0504
[0064.50] WOTCIridarPerkPack: Executing Playing animation: 3.0576
[0064.50] WOTCIridarPerkPack: ProjectileNotifyHit PROJECTILE HIT: True -694.18,1547.28,16.00
[0064.51] WOTCIridarPerkPack: Executing Playing animation: 3.0660
*/

function Init()
{
	local PrecomputedPathData PathData;

	super.Init();

	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_ThunderLance');
	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	//CustomPath.ActivatePath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	CustomPath.SetupPath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	//CustomPath.bOverrideEndTime = true;
	CustomPath.SetHidden(true);
}
function CompleteAction()
{
	CustomPath.Destroy();

	super.CompleteAction();
}

/*
// Delay the hit notification so that the grenade explodes when the grapple is retracted
function ProjectileNotifyHit(bool bMainImpactNotify, Vector HitLocation)
{	
	locbMainImpactNotify = bMainImpactNotify;
	locHitLocation = HitLocation;

	//`AMLOG ("PROJECTILE HIT SETTING TIMER:" @ bMainImpactNotify @ HitLocation);

	bProcessingDelay = true;
	
	self.SetTimer(2.0f, false, nameof(DelayedProjectileNotifyHit)); // # Explosition Delay #
}

private function DelayedProjectileNotifyHit()
{
	//`AMLOG ("PROJECTILE HIT PLAYING HIT:" @ locbMainImpactNotify @ locHitLocation);

	super.ProjectileNotifyHit(locbMainImpactNotify, locHitLocation);

	bProcessingDelay = false;
}

function bool ShouldWaitToComplete()
{
	if (bProcessingDelay)
	{
		return true;
	}
	return ProjectilesInFlight();
}
*/
function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{	
	local int i;

	`AMLOG("Adding new volley:" @ NewProjectile.Class.Name);


	if (X2UnifiedProjectile_ThunderLance(NewProjectile) == none)
	{
		UpdateGrenadePath();

		for (i = 0; i < NewProjectile.Projectiles.Length; i++)
		{
			NewProjectile.Projectiles[i].GrenadePath = CustomPath;
		}
	}
	super.AddProjectileVolley(NewProjectile);
}

private function UpdateGrenadePath()
{
	//local vector	PathStartLocation;
	local float		iKeyframes;
	local vector PathEndLocation;
//	local float		PathLength;
	local float		i;

	//PathStartLocation = FiringUnit.Location;
	//PathStartLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;

	iKeyframes = CustomPath.iNumKeyframes;

	CustomPath.UpdateTrajectory();

	//CustomPath.bUseOverrideSourceLocation = true;
	//CustomPath.OverrideSourceLocation = PathStartLocation;

	PathEndLocation = TargetLocation;

	CustomPath.bUseOverrideTargetLocation = true;
	CustomPath.OverrideTargetLocation = PathEndLocation;

	//CustomPath.akKeyframes[0].vLoc = PathEndLocation;
	CustomPath.akKeyframes[0].fTime = 0.0f;

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		CustomPath.akKeyframes[i].vLoc = PathEndLocation;
		CustomPath.akKeyframes[i].fTime = 1.95f + 0.05f * i / iKeyframes;
	}

	//PathLength = GrenadePath.akKeyframes[GrenadePath.iNumKeyframes - 1].fTime - GrenadePath.akKeyframes[0].fTime;
	//GrenadePath.kRenderablePath.UpdatePathRenderData(GrenadePath.kSplineInfo, PathLength, none, `CAMERASTACK.GetCameraLocationAndOrientation().Location);
}
/*
defaultproperties
{
	NotifyTargetTimer = 2.0f
}*/