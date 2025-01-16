class X2Action_Fire_RifleGrenade extends X2Action_Fire;

var private bool bHasSetTimer;
var private array<X2UnifiedProjectile> PatchProjectileVolleys;

// This custom fire action is used for the Rifle Grenade ability.
// It's responsible for hiding the grenade projectile that is launched alongside the rifle grenade projectile,
// which is something that seems to be happening automatically for all "launch grenade" types of abilities.
// As well as hiding the projectile fired by the vektor rifle, which is done intentionally to produce muzzle flash / firing sound / shell ejection.

function Init()
{
	super.Init();

	// Used to make the grenade explosion happen higher if the grenade impacts a unit,
	// and to make the projectile impact the target rather than target's tile.
	// Incidentally, force assigning this to projectiles also fixes a bug that first grenade launch has the grenade explode in the wrong place for some reason.
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
	if (strPathName == "" || strPathName ==  "IRIBountyHunter.Archetypes.PJ_RifleGrenade")
		return;

	PatchProjectileVolleys.AddItem(NewProjectile);

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

	foreach PatchProjectileVolleys(PatchProjectileVolley)
	{
		if (HideAttachedMesh_AndKillPFX_ForProjectile(PatchProjectileVolley))
		{
			bPatchedSomething = true;
		}
	}

	if (!bPatchedSomething)
	{
		self.ClearTimer(nameof(HideAttachedGrenadeMesh));
	}
}

// Apparently Fire Weapon Volley Notify, when working with abilities that use GetLoadedAmmo - or something else unique to launching grenades -
// forcibly launches two projectiles, the one from the grenade launcher, and one from the grenade itself.
// For the purposes of Rifle Grenades, we don't want the launched grenade to be visible, because that's what Rifle Grenade is for. 
// So whenever a unit launches a projectile with this ability, we check if it has a mesh attached to it, and nuke it if it does.

// There's also a cosmetic fire weapon volley notify for the vektor rifle so there's a shot sound / muzzle flash. Have to remove the actual projectile fired, though.
private function bool HideAttachedMesh_AndKillPFX_ForProjectile(X2UnifiedProjectile NewProjectile)
{
	local bool bWaitingForProjectilesToFire;
	local bool bPatchedProjectile;
	local int i;

	for (i = NewProjectile.Projectiles.Length - 1; i >= 0; i--)
	{	
		NewProjectile.Projectiles[i].InitialTargetLocation = self.TargetLocation;

		if (!NewProjectile.Projectiles[i].bFired)
		{
			bWaitingForProjectilesToFire = true;
			continue;
		}

		if (NewProjectile.Projectiles[i].bWaitingToDie)
			continue;

		// Allow muzzle flash to play
		if (InStr(NewProjectile.Projectiles[i].ProjectileElement.Comment, "Muzzle") != INDEX_NONE)
			continue;

		// Allow shell ejection to play
		if (InStr(NewProjectile.Projectiles[i].ProjectileElement.Comment, "Shell") != INDEX_NONE)
			continue;

		if (NewProjectile.Projectiles[i].ParticleEffectComponent != none)
		{
			NewProjectile.Projectiles[i].ParticleEffectComponent.OnSystemFinished = none;
			NewProjectile.Projectiles[i].ParticleEffectComponent.DeactivateSystem( );
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(NewProjectile.Projectiles[i].ParticleEffectComponent);
			NewProjectile.Projectiles[i].ParticleEffectComponent = none;
		}

		if (NewProjectile.Projectiles[i].TargetAttachActor != none)
		{
			// Hide the attached mesh, if any.
			SkeletalMeshActor(NewProjectile.Projectiles[i].TargetAttachActor).SkeletalMeshComponent.SetHidden(true);
		}

		bPatchedProjectile = true;
	}

	return bWaitingForProjectilesToFire || !bPatchedProjectile;
}


function CompleteAction()
{
	super.CompleteAction();

	if (self.IsTimerActive(nameof(HideAttachedGrenadeMesh)))
	{
		// Clear time once the action completes just in case.
		self.ClearTimer(nameof(HideAttachedGrenadeMesh));
	}
}
