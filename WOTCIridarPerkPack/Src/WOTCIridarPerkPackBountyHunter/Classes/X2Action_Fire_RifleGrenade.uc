class X2Action_Fire_RifleGrenade extends X2Action_Fire;



/*
var private XGUnit LocFiringUnit;
var privatewrite XComPrecomputedPath_CustomPath CustomPath;

function Init()
{
	super.Init();

	InitCustomPath();
	LocFiringUnit = XGUnit(`XCOMHISTORY.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));
}

private function InitCustomPath()
{
	local PrecomputedPathData PathData;

	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_CustomPath');
	CustomPath.UpdateGrenadePathFn = UpdateGrenadePath;

	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	CustomPath.SetupPath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	CustomPath.SetWeaponAndTargetLocation(WeaponVisualizer.GetEntity(), Unit.GetTeam(), TargetLocation, PathData);
	CustomPath.SetHidden(true);
}

private function UpdateGrenadePath()
{
	class'X2TargetingMethod_RifleGrenade'.static.UpdateGrenadePathTarget(CustomPath, LocFiringUnit.Location, AimAtLocation);
}*/
/*
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
*/


function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	super.AddProjectileVolley(NewProjectile);

	// Have to do this on a timer, as the attached meshes are not created immediately.
	self.SetTimer(0.1f, true, nameof(HideAttachedGrenadeMesh));
}

private function HideAttachedGrenadeMesh()
{
	local int i;

	for (i = ProjectileVolleys.Length - 1; i >= 0; i--)
	{
		HideAttachedGrenadeMeshForProjectile(ProjectileVolleys[i]);
	}
}

private function HideAttachedGrenadeMeshForProjectile(X2UnifiedProjectile NewProjectile)
{
	local string strPathName;
	local int i;

	strPathName = PathName(NewProjectile);

	//`LOG("Adding projectile:" @ strPathName,, 'IRITEST');

	if (strPathName != "" && InStr(strPathName, "X2UnifiedProjectile_RifleGrenade") == INDEX_NONE)
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{
			if (NewProjectile.Projectiles[i].TargetAttachActor != none)
			{
				//`LOG("Attach actor:" @ PathName(NewProjectile.Projectiles[i].TargetAttachActor),, 'IRITEST');
				//NewProjectile.Projectiles[i].TargetAttachActor.Destroy();
				SkeletalMeshActor(NewProjectile.Projectiles[i].TargetAttachActor).SkeletalMeshComponent.SetHidden(true);

				NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
				NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
				WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
				NewProjectile.Projectiles[i].ParticleEffectComponent = none;
			}
		}
	}
}