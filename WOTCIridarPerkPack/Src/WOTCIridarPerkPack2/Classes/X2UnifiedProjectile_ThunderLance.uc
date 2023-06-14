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
}

private function DoMainImpactDelayed()
{
	super.DoMainImpact(LocIndex, LocfDeltaT, LocbShowImpactEffects);

	`XEVENTMGR.TriggerEvent('IRI_ThunderLanceImpactEvent');
}

function UpdateProjectileDistances(int Index, float fDeltaT)
{
	super.UpdateProjectileDistances(Index, fDeltaT);

	`XEVENTMGR.TriggerEvent('IRI_ThunderLanceUpdateEvent');
}