class X2Action_Fire_RifleGrenade extends X2Action_Fire;

// This custom fire action is used for the Rifle Grenade ability.
// It's responsible for hiding the grenade projectile that is launched alongside the rifle grenade projectile,
// which is something that seems to be happening automatically for all "launch grenade" types of abilities.

// TODO: Make rifle grenade visually impact units when targeting them directly.
// TODO: Make rifle grenade explode on impact.

/*
function Init()
{
	super.Init();

}
*/

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	super.AddProjectileVolley(NewProjectile);

	// Have to do this on a timer, as the attached meshes are not created immediately.
	self.SetTimer(0.01f, true, nameof(HideAttachedGrenadeMesh));
}

private function HideAttachedGrenadeMesh()
{
	local int i;

	for (i = ProjectileVolleys.Length - 1; i >= 0; i--)
	{
		HideAttachedGrenadeMeshForProjectile(ProjectileVolleys[i]);
	}
}

// Launching a grenade forcibly launches two projectiles, the one from the grenade launcher, and one from the grenade itself.
// For the purposes of Rifle Grenades, we don't want the launched grenade to be visible, because that's what Rifle Grenade is for. 
// So whenever a unit launches a projectile with this ability, we check if it has a mesh attached to it, and nuke it if it does.
private function HideAttachedGrenadeMeshForProjectile(X2UnifiedProjectile NewProjectile)
{
	local string strPathName;
	local XComAnimNodeBlendDynamic tmpNode;
	local int i;

	strPathName = PathName(NewProjectile);
	//`LOG("Adding projectile:" @ strPathName,, 'IRITEST');

	// I.e. if this projectile anything other than the rifle grenade
	if (strPathName != "" && InStr(strPathName, "X2UnifiedProjectile_RifleGrenade") == INDEX_NONE)
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{
			//`LOG("Attach actor:" @ PathName(NewProjectile.Projectiles[i].TargetAttachActor),, 'IRITEST');
			//NewProjectile.Projectiles[i].TargetAttachActor.Destroy();


			// And actually has a mesh attached to it - it seems to launch a lot of other projectiles that don't, idk what those are. Maybe they don't even exist.
			if (NewProjectile.Projectiles[i].TargetAttachActor != none)
			{
				// Hide the attached mesh, if any.
				SkeletalMeshActor(NewProjectile.Projectiles[i].TargetAttachActor).SkeletalMeshComponent.SetHidden(true);
				
				// Remove the playing particle effect, if any.
				NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
				NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
				WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
				NewProjectile.Projectiles[i].ParticleEffectComponent = none;

				// Assume doing this once is enough, so clear the timer once its done.
				self.ClearTimer(nameof(HideAttachedGrenadeMeshForProjectile));
			}
		}		
	}
}


function CompleteAction()
{
	super.CompleteAction();

	// Clear time once the action completes just in case. It's probably unnecesary. Or not doing it could cause garbage collection crashes. Rather not play Russian Roulette.
	self.ClearTimer(nameof(HideAttachedGrenadeMeshForProjectile));
}
