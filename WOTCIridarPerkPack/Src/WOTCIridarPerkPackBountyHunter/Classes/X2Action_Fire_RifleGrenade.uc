class X2Action_Fire_RifleGrenade extends X2Action_Fire;

var private bool bHasSetTimer;
var private array<int> PatchedProjectileIndices;

// This custom fire action is used for the Rifle Grenade ability.
// It's responsible for hiding the grenade projectile that is launched alongside the rifle grenade projectile,
// which is something that seems to be happening automatically for all "launch grenade" types of abilities.

// TODO: Make rifle grenade visually impact units when targeting them directly. - done this already?
// TODO: Figure out why first explosion happens in the wrong place. Seems not to be caused by targeting method.
// TODO: Female version of animation with female sockets. 
// TODO: Ensure projectile code compat with laser/coil vektor

/*
function Init()
{
	super.Init();

}
*/

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	super.AddProjectileVolley(NewProjectile);

	if (NewProjectile != none && !bHasSetTimer)
	{
		// Have to do this on a timer, as the attached meshes are not created immediately.
		self.SetTimer(0.01f, true, nameof(HideAttachedGrenadeMesh));
		bHasSetTimer = true;
	}
}

private function HideAttachedGrenadeMesh()
{
	local bool bAllVolleySetUp;
	local int i;

	bAllVolleySetUp = true;

	for (i = ProjectileVolleys.Length - 1; i >= 0; i--)
	{
		if (ProjectileVolleys[i] == none)
			continue;

		if (ProjectileVolleys[i].bSetupVolley)
		{
			if (PatchedProjectileIndices.Find(i) == INDEX_NONE)
			{
				if (HideAttachedGrenadeMeshForProjectile(ProjectileVolleys[i]))
				{
					//PatchedProjectileIndices.AddItem(i);
				}
			}
		}
		else
		{
			bAllVolleySetUp = false;
		}
	}

	if (bAllVolleySetUp)
	{
		`LOG("Projectile patching done, clearing timer",, 'IRITEST');
		//self.ClearTimer(nameof(HideAttachedGrenadeMesh));
	}
}

// Launching a grenade forcibly launches two projectiles, the one from the grenade launcher, and one from the grenade itself.
// For the purposes of Rifle Grenades, we don't want the launched grenade to be visible, because that's what Rifle Grenade is for. 
// So whenever a unit launches a projectile with this ability, we check if it has a mesh attached to it, and nuke it if it does.

// There's also a cosmetic fire weapon volley notify for the vektor rifle so there's a shot sound / muzzle flash. Have to remove the actual projectile fired, though.
private function bool HideAttachedGrenadeMeshForProjectile(X2UnifiedProjectile NewProjectile)
{
	local bool bDidSomething;
	local string strPathName;
	local int i;

	// I.e. if this projectile anything other than the rifle grenade
	strPathName = PathName(NewProjectile.ObjectArchetype);
	if (strPathName == "" || strPathName ==  "IRIBountyHunter.Archetypes.PJ_RifleGrenade")
		return true; // Return true here so we don't bother with this projectile again.

	//`LOG("Projectile element comment:" @ NewProjectile.Projectiles[i].ProjectileElement.Comment,, 'IRITEST');

	`LOG("HideAttachedGrenadeMeshForProjectile running for projectile:" @ strPathName @ "Context target location:" @ NewProjectile.AbilityContextTargetLocation,, 'IRITEST');

	if (NewProjectile.VolleyNotify.bCosmeticVolley) // This is the cosmetic vektor rifle shot.
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{
			// Allow Vektor rifle firing to play.
			if (NewProjectile.Projectiles[i].ProjectileElement.FireSound != none)
				continue;

			if (InStr(NewProjectile.Projectiles[i].ProjectileElement.Comment, "Muzzle") != INDEX_NONE)
				continue;

			if (InStr(NewProjectile.Projectiles[i].ProjectileElement.Comment, "Shell") != INDEX_NONE)
				continue;

			if (InStr(NewProjectile.Projectiles[i].ProjectileElement.Comment, "Sound") != INDEX_NONE)
				continue;

			if (!NewProjectile.Projectiles[i].bFired)
				continue;
				
			NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
			NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
			NewProjectile.Projectiles[i].ParticleEffectComponent = none;

			// But kill tracer or bullet distortion.
			NewProjectile.EndProjectileInstance(i, 0);

			bDidSomething = true;
		}
	}
	else
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{
			if (NewProjectile.Projectiles[i].TargetAttachActor == none)
				continue;

			if (!NewProjectile.Projectiles[i].bFired)
				continue;
			
			// Hide the attached mesh, if any.
			SkeletalMeshActor(NewProjectile.Projectiles[i].TargetAttachActor).SkeletalMeshComponent.SetHidden(true);
			//NewProjectile.Projectiles[i].TargetAttachActor.Destroy();
				
			// Remove the playing particle effect, if any. It has the smoke trail and I'd love to leave it, but it also has a small spinny grenade launcher projectile for some reason.
			// Yes, even thrown hand grenades have it. Yes, it's stupid.
			NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
			NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
			NewProjectile.Projectiles[i].ParticleEffectComponent = none;

			NewProjectile.EndProjectileInstance(i, 0);

			bDidSomething = true;
		}
	}

	return bDidSomething;
}


function CompleteAction()
{
	super.CompleteAction();

	// Clear time once the action completes just in case. It's probably unnecesary. Or not doing it could cause garbage collection crashes. Rather not play Russian Roulette.
	self.ClearTimer(nameof(HideAttachedGrenadeMesh));
}
