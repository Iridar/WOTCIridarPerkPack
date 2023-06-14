class X2Action_Fire_ThunderLance extends X2Action_Fire;

var privatewrite XComPrecomputedPath_ThunderLance CustomPath;

function Init()
{
	super.Init();

	InitCustomPath();
}

private function InitCustomPath()
{
	local PrecomputedPathData PathData;

	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_ThunderLance');
	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	CustomPath.SetupPath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	CustomPath.SetWeaponAndTargetLocation(WeaponVisualizer.GetEntity(), Unit.GetTeam(), TargetLocation, PathData);
	CustomPath.SetHidden(true);
	CustomPath.FireAction = self;
}

// This runs from XGUnitPawnNativeBase whenever a unit fires a projectile.
// We use it as an insertion point to register the fired projectile for events,
// so that we can tweak its parameters once it's fired.
function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{	
	local int i;

	if (NewProjectile != none)
	{
		// Skip the grapple projectile fired by the "launch" ability itself, we don't need to mess with it.
		if (X2UnifiedProjectile_ThunderLance(NewProjectile) == none)
		{
			for (i = 0; i < NewProjectile.Projectiles.Length; i++)
			{
				// Register each projectile element for events. Have to do it in a holder object, because apparently
				// only one listener for the same event name can exist on one object.
				// so if the projectile has multiple projectile elements we'd be in a mess.
				class'X2ThunderLanceEventHolder'.static.RegisterProjectile(self, NewProjectile.Projectiles[i].ProjectileElement);
			}
		}
	}
	super.AddProjectileVolley(NewProjectile);
}

// A grenade path is just needed to bypass some logic in X2UnifiedProjectile, it doesn't actually do anything.
final function UpdateGrenadePath()
{
	local float		iKeyframes;
	local vector	PathEndLocation;
	local float		i;
	
	PathEndLocation = TargetLocation;

	CustomPath.bUseOverrideTargetLocation = true;
	CustomPath.OverrideTargetLocation = PathEndLocation;

	CustomPath.UpdateTrajectory();
	iKeyframes = CustomPath.iNumKeyframes;

	CustomPath.akKeyframes[0].fTime = 0.0f;

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		CustomPath.akKeyframes[i].vLoc = PathEndLocation;
		CustomPath.akKeyframes[i].fTime = 10; // Doesn't matter what to put here, the detonation will happen by event.
	}
}
