class X2Action_Fire_RifleGrenade extends X2Action_Fire;

var private bool bHasSetTimer;
var private array<X2UnifiedProjectile> PatchProjectileVolleys;

// This custom fire action is used for the Rifle Grenade ability.
// It's responsible for hiding the grenade projectile that is launched alongside the rifle grenade projectile,
// which is something that seems to be happening automatically for all "launch grenade" types of abilities.
// As well as hiding the projectile fired by the vektor rifle, which is done intentionally to produce muzzle flash / firing sound / shell ejection.

// TODO: Make rifle grenade visually impact units when targeting them directly. - done this already?
// TODO: Ensure projectile code compat with laser/coil vektor


function Init()
{
	super.Init();

	// This will make the grenade explosion happen higher if the grenade impacts a unit.
	class'X2TargetingMethod_RifleGrenade'.static.MaybeUpdateTargetForUnitOnTile(TargetLocation, AbilityContext.InputContext.SourceObject);
	AimAtLocation = TargetLocation;
}


function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	local string strPathName;

	super.AddProjectileVolley(NewProjectile);

	if (NewProjectile == none)
		return;

	strPathName = PathName(NewProjectile.ObjectArchetype);
	//`LOG("Fire Action adding projectile volley:" @ strPathName,, 'IRITEST');
	if (strPathName == "" || strPathName ==  "IRIBountyHunter.Archetypes.PJ_RifleGrenade")
		return;

	PatchProjectileVolleys.AddItem(NewProjectile);

	//`LOG("It's added, current length:" @ PatchProjectileVolleys.Length,, 'IRITEST');

	if (!bHasSetTimer)
	{
		// Start the looped timer when projectiles are added and keep it running until all projectiles are fired and patched.
		// Have to do this on a timer, as the projectiles are not fired immediately, and until they are, attached meshes and PFX don't exist.
		
		self.SetTimer(0.01f, true, nameof(HideAttachedGrenadeMesh));
		bHasSetTimer = true;
	}
}

private function HideAttachedGrenadeMesh()
{
	local X2UnifiedProjectile PatchProjectileVolley;
	local bool bPatchedSomething;

	//`LOG("Iterating over:" @ PatchProjectileVolleys.Length @ "projectile volleys",, 'IRITEST');

	foreach PatchProjectileVolleys(PatchProjectileVolley)
	{
		if (HideAttachedGrenadeMeshForProjectile(PatchProjectileVolley))
		{
			bPatchedSomething = true;
		}
	}

	if (!bPatchedSomething)
	{
		//`LOG("Projectile patching done, clearing timer",, 'IRITEST');

		self.ClearTimer(nameof(HideAttachedGrenadeMesh));
	}
}

// Apparently Fire Weapon Volley Notify, when working with abilities that use GetLoadedAmmo - or something else unique to launching grenades -
// forcibly launches two projectiles, the one from the grenade launcher, and one from the grenade itself.
// For the purposes of Rifle Grenades, we don't want the launched grenade to be visible, because that's what Rifle Grenade is for. 
// So whenever a unit launches a projectile with this ability, we check if it has a mesh attached to it, and nuke it if it does.

// There's also a cosmetic fire weapon volley notify for the vektor rifle so there's a shot sound / muzzle flash. Have to remove the actual projectile fired, though.
private function bool HideAttachedGrenadeMeshForProjectile(X2UnifiedProjectile NewProjectile)
{
	local bool bWaitingForProjectilesToFire;
	local bool bPatchedProjectile;
	local int i;

	//`LOG("Projectile element comment:" @ NewProjectile.Projectiles[i].ProjectileElement.Comment,, 'IRITEST');
	//`LOG("HideAttachedGrenadeMeshForProjectile running for projectile:" @ PathName(NewProjectile.ObjectArchetype) @ "Context target location:" @ NewProjectile.AbilityContextTargetLocation @ "Num projectiles:" @ NewProjectile.Projectiles.Length @ "Has Projectile Element:" @ NewProjectile.Projectiles[0].ProjectileElement != none @ "Setup Volley:" @ NewProjectile.bSetupVolley,, 'IRITEST');
	
	if (NewProjectile.VolleyNotify.bCosmeticVolley) // This is the cosmetic vektor rifle shot.
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{	
			NewProjectile.Projectiles[i].InitialTargetLocation = self.TargetLocation;

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
			{
				bWaitingForProjectilesToFire = true;
				continue;
			}

			if (NewProjectile.Projectiles[i].bWaitingToDie)
				continue;

			if (NewProjectile.Projectiles[i].ParticleEffectComponent != none)
			{
				NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
				NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
				WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
				NewProjectile.Projectiles[i].ParticleEffectComponent = none;
			}

			// But kill tracer or bullet distortion.
			NewProjectile.EndProjectileInstance(i, 0);

			bPatchedProjectile = true;
		}
	}
	else // This is the flying hand grenade projectile.
	{
		for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
		{	
			// Something in the logic bugs out, and the first use of the ability for the soldier has the grenade explosion happen not where it should.
			// Hard set it to the correct vector.
			NewProjectile.Projectiles[i].InitialTargetLocation = self.TargetLocation; 

			if (!NewProjectile.Projectiles[i].bFired)
			{
				bWaitingForProjectilesToFire = true;
				continue;
			}

			if (NewProjectile.Projectiles[i].bWaitingToDie)
				continue;

			if (NewProjectile.Projectiles[i].TargetAttachActor != none)
			{
				// Hide the attached mesh, if any.
				SkeletalMeshActor(NewProjectile.Projectiles[i].TargetAttachActor).SkeletalMeshComponent.SetHidden(true);
				//NewProjectile.Projectiles[i].TargetAttachActor.Destroy();
				
				// Remove the playing particle effect, if any. It has the smoke trail and I'd love to leave it, but it also has a small spinny grenade launcher projectile for some reason.
				// Yes, even thrown hand grenades have it. Yes, it's stupid.
				NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
				NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
				WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
				NewProjectile.Projectiles[i].ParticleEffectComponent = none;

				// NewProjectile.EndProjectileInstance(i, 0);
				bPatchedProjectile = true;
			}
		}
	}

	//`LOG("HideAttachedGrenadeMeshForProjectile running for projectile:" @ `ShowVar(bWaitingForProjectilesToFire) @ `ShowVar(bPatchedProjectile),, 'IRITEST');

	return bWaitingForProjectilesToFire || !bPatchedProjectile;
}


function CompleteAction()
{
	super.CompleteAction();

	//`LOG("Action over",, 'IRITEST');

	if (self.IsTimerActive(nameof(HideAttachedGrenadeMesh)))
	{
		//`LOG("Action over, clearing timer",, 'IRITEST');

		// Clear time once the action completes just in case.
		self.ClearTimer(nameof(HideAttachedGrenadeMesh));
	}
}
