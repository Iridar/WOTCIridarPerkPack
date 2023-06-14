class X2ThunderLanceEventHolder extends Actor;

var private X2Action_Fire_ThunderLance FireAction;
var private bool bHadNoFireSound;

static final function RegisterProjectile(X2Action_Fire_ThunderLance RegFireAction, X2UnifiedProjectileElement ProjectileElement)
{
	local X2EventManager EventMgr;
	local X2ThunderLanceEventHolder NewEventHolder;
	local Object EventObj;

	NewEventHolder = RegFireAction.Spawn(class'X2ThunderLanceEventHolder', RegFireAction);
	NewEventHolder.FireAction = RegFireAction;

	// Insert a placeholder projectile fire sound if the projectile doesn't have any
	// just need to have *something* there for OnProjectileFireSound to trigger.
	if (ProjectileElement.FireSound == none)
	{
		NewEventHolder.bHadNoFireSound = true;
		ProjectileElement.FireSound = new class'AkEvent';
	}

	EventMgr = `XEVENTMGR;
	EventObj = NewEventHolder;
	EventMgr.RegisterForEvent(EventObj, 'OnProjectileFireSound', NewEventHolder.OnProjectileFired, ELD_Immediate,, ProjectileElement,, ProjectileElement);
	EventMgr.RegisterForEvent(EventObj, 'IRI_ThunderLanceUpdateEvent', NewEventHolder.OnMainProjectileMoved, ELD_Immediate,, none,, ProjectileElement);
	EventMgr.RegisterForEvent(EventObj, 'IRI_ThunderLanceImpactEvent', NewEventHolder.OnMainProjectileImpact, ELD_Immediate,, none,, ProjectileElement);
	
}

private function EventListenerReturn OnProjectileFired(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{	
	local X2UnifiedProjectile		 Projectile;
	local X2UnifiedProjectileElement ProjectileElement;
	local int i;

	ProjectileElement = X2UnifiedProjectileElement(CallbackData);
	if (ProjectileElement == none)
		return ELR_NoInterrupt;

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			FireAction.UpdateGrenadePath();

			Projectile.Projectiles[i].EndTime = Projectile.Projectiles[i].StartTime + 10;	// Delay the explosion by whatever amount, actual detonation will happen earlier than that on main projectile impact
			Projectile.Projectiles[i].GrenadePath = FireAction.CustomPath;					// So that X2UnifiedProjectile::StruckTarget() always returns false
			Projectile.Projectiles[i].InitialTargetLocation = FireAction.TargetLocation;	// So that grenade explosion visually happens on the target
		}
	}

	return ELR_NoInterrupt;
}

private function EventListenerReturn OnMainProjectileMoved(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{	
	local X2UnifiedProjectile_ThunderLance	MainProjectile;
	local X2UnifiedProjectile				Projectile;
	local X2UnifiedProjectileElement		ProjectileElement;
	local int i;

	ProjectileElement = X2UnifiedProjectileElement(CallbackData);
	if (ProjectileElement == none)
		return ELR_NoInterrupt;

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		MainProjectile = X2UnifiedProjectile_ThunderLance(Projectile);
		if (MainProjectile != none)
			break;
	}

	if (MainProjectile == none || MainProjectile.Projectiles.Length == 0 || MainProjectile.Projectiles[0].TargetAttachActor == none)
	{
		`AMLOG("Failed to find main projectile");
		return ELR_NoInterrupt;
	}

	`AMLOG("Found main projectile");

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		MainProjectile = X2UnifiedProjectile_ThunderLance(Projectile);
		if (MainProjectile != none)
			break;

		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			if (Projectile.Projectiles[i].TargetAttachActor != none)
			{
				Projectile.Projectiles[i].TargetAttachActor.SetLocation( MainProjectile.Projectiles[0].TargetAttachActor.Location );
			}
		}
	}

	return ELR_NoInterrupt;
}

private function EventListenerReturn OnMainProjectileImpact(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{	
	local X2UnifiedProjectile		 Projectile;
	local X2UnifiedProjectileElement ProjectileElement;
	local int i;

	ProjectileElement = X2UnifiedProjectileElement(CallbackData);
	if (ProjectileElement == none)
		return ELR_NoInterrupt;

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			// That should make the projectile explode next tick.
			Projectile.Projectiles[i].EndTime = WorldInfo.TimeSeconds;

			if (bHadNoFireSound)
			{
				// Reset it back to nothing if we used a placeholder.
				Projectile.Projectiles[i].ProjectileElement.FireSound = none;
			}

			CommitSudoku();
		}
	}

	return ELR_NoInterrupt;
}

private function CommitSudoku()
{
	local X2EventManager	EventMgr;
	local Object			EventObj;

	EventMgr = `XEVENTMGR;
	EventObj = self;
			
	EventMgr.UnRegisterFromEvent(EventObj, 'OnProjectileFireSound');
	EventMgr.UnRegisterFromEvent(EventObj, 'IRI_ThunderLanceImpactEvent');
	
	Destroy();
}
