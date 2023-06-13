class X2ThunderLanceEventHolder extends Actor;

var private X2Action_Fire_ThunderLance FireAction;

static final function RegisterProjectile(X2Action_Fire_ThunderLance RegFireAction, X2UnifiedProjectileElement ProjectileElement)
{
	local X2EventManager EventMgr;
	local X2ThunderLanceEventHolder NewEventHolder;
	local Object EventObj;

	NewEventHolder = RegFireAction.Spawn(class'X2ThunderLanceEventHolder', RegFireAction);
	NewEventHolder.FireAction = RegFireAction;

	EventMgr = `XEVENTMGR;
	EventObj = NewEventHolder;
	EventMgr.RegisterForEvent(EventObj, 'OnProjectileFireSound', NewEventHolder.OnProjectileFired, ELD_Immediate,, ProjectileElement,, ProjectileElement);
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

	`AMLOG("Running for projectile:" @ PathName(ProjectileElement));

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			`AMLOG("Found projectile element."); 

			FireAction.UpdateGrenadePath();

			Projectile.Projectiles[i].EndTime = Projectile.Projectiles[i].StartTime + 10; // Delay the explosion by whatever amount, actual detonation will happen earlier than that on main projectile impact
			Projectile.Projectiles[i].GrenadePath = FireAction.CustomPath; // So that X2UnifiedProjectile::StructTarget() always returns false
			Projectile.Projectiles[i].InitialTargetLocation = FireAction.TargetLocation; // So that grenade explosion visually happens on the target
			//Projectile.Projectiles[i].InitialTargetDistance = VSize(TargetLocation - Projectile.Projectiles[i].InitialSourceLocation);
			//Projectile.Projectiles[i].InitialTravelDirection = TargetLocation - Projectile.Projectiles[i].InitialSourceLocation;
			//Projectile.Projectiles[i].InitialTargetNormal = -Projectile.Projectiles[i].InitialTravelDirection;

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

	`AMLOG("Running for projectile:" @ PathName(ProjectileElement));

	foreach FireAction.ProjectileVolleys(Projectile)
	{
		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			`AMLOG("Found projectile element."); 

			// That should make the projectile explode next tick
			Projectile.Projectiles[i].EndTime = WorldInfo.TimeSeconds;

		}
	}

	return ELR_NoInterrupt;
}