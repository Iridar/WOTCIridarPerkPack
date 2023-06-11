class X2Action_Fire_ThunderLance extends X2Action_Fire;


function Init()
{
	super.Init();

	bUseAnimToSetNotifyTimer = true;
	NotifyTargetTimer += 4;
}

//var private bool locbMainImpactNotify;
//var private Vector locHitLocation;

/*
[0064.49] WOTCIridarPerkPack: Executing Playing animation: 3.0504
[0064.50] WOTCIridarPerkPack: Executing Playing animation: 3.0576
[0064.50] WOTCIridarPerkPack: ProjectileNotifyHit PROJECTILE HIT: True -694.18,1547.28,16.00
[0064.51] WOTCIridarPerkPack: Executing Playing animation: 3.0660
*/

/*
// Delay the hit notification so that the grenade explodes when the grapple is retracted
function ProjectileNotifyHit(bool bMainImpactNotify, Vector HitLocation)
{	
	locbMainImpactNotify = bMainImpactNotify;
	locHitLocation = HitLocation;

	`AMLOG ("PROJECTILE HIT:" @ bMainImpactNotify @ HitLocation);
	
	self.SetTimer(2.0f, false, nameof(DelayedProjectileNotifyHit));
}

private function DelayedProjectileNotifyHit()
{
	ProjectileNotifyHit(locbMainImpactNotify, locHitLocation);
}*/
/*
defaultproperties
{
	NotifyTargetTimer = 2.0f
}*/