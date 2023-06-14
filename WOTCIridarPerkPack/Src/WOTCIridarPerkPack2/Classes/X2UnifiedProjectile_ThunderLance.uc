class X2UnifiedProjectile_ThunderLance extends X2UnifiedProjectile;

/* Order of calling functions in X2UnifiedProjectile:
ConfigureNewProjectile
SetupVolley
AddProjectileVolley Adding new volley: X2UnifiedProjectile_ThunderLance
Tick BEGIN TICKING
FireProjectileInstance Running 0
*/

var private int		LocIndex;
var private float	LocfDeltaT;
var private bool	LocbShowImpactEffects;

const ImpactDelay = 2.0f; // # Impact Delay # 

function DoMainImpact(int Index, float fDeltaT, bool bShowImpactEffects)
{
	LocIndex = Index;
	LocfDeltaT = fDeltaT;
	LocbShowImpactEffects = bShowImpactEffects;

	SetTimer(ImpactDelay, false, nameof(DoMainImpactDelayed));
	SetTimer(1.0f, false, nameof(PlayGrenadePullSound));

	Projectiles[0].TargetAttachActor.PlayAkEvent(AkEvent(`CONTENT.RequestGameArchetype("XPACK_SoundCharacterFX.Skirmisher_Whiplash_Impact")), , , , Projectiles[0].InitialTargetLocation);
}

private function PlayGrenadePullSound()
{
	Projectiles[0].TargetAttachActor.PlayAkEvent(AkEvent(`CONTENT.RequestGameArchetype("SoundX2CharacterFX.Granade_Pull")), , , , Projectiles[0].InitialTargetLocation);
}

private function DoMainImpactDelayed()
{
	super.DoMainImpact(LocIndex, LocfDeltaT, LocbShowImpactEffects);

	// This will detonate the grenade projectiles.
	`XEVENTMGR.TriggerEvent('IRI_ThunderLanceImpactEvent');
}