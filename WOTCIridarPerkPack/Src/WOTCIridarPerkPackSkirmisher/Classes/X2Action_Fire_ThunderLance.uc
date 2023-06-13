class X2Action_Fire_ThunderLance extends X2Action_Fire;

//var private bool locbMainImpactNotify;
//var private Vector locHitLocation;
//var private bool bProcessingDelay;

var private XComPrecomputedPath_ThunderLance CustomPath;

const ImpactDelay = 2.0f; // # Impact Delay # 

function Init()
{
	//local XComGameState_Ability AbilityState;	
	//local XGUnit FiringUnit;
	//local XComGameState_Item WeaponItem;
//	//local X2WeaponTemplate WeaponTemplate;
	////local XComWeapon Entity, WeaponEntity;
	//local XComGameState_Item Item;
	//local XGWeapon AmmoWeapon;

	super.Init();

	//AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	//FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
	//WeaponItem = AbilityState.GetSourceWeapon();
	//if (WeaponItem != none)
	//{
	//	WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
	//	WeaponEntity = WeaponVisualizer.GetEntity();
	//}
	//if (FiringUnit.CurrentPerkAction != none)
	//{
	//	WeaponEntity = FiringUnit.CurrentPerkAction.GetPerkWeapon();
	//}

	UpdatePrimaryTargetLocation();
	//bUseKillAnim = false;
	InitCustomPath();
}

private function UpdatePrimaryTargetLocation()
{
	local XComWorldData					World;
	local TTile							TileLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local XComGameState_Unit			PrimaryTargetState;
	local XGUnit						PrimaryTargetGameUnit;

	World = `XWORLD;

	World.GetFloorTileForPosition(TargetLocation, TileLocation);

	TargetsOnTile = World.GetUnitsOnTile(TileLocation);

	if (TargetsOnTile.Length > 0)
	{
		PrimaryTargetState = XComGameState_Unit(History.GetGameStateForObjectID(TargetsOnTile[0].ObjectID));
		if (PrimaryTargetState != none)
		{
			PrimaryTargetGameUnit = XGUnit(PrimaryTargetState.GetVisualizer());
			if (PrimaryTargetGameUnit != none)
			{
				TargetLocation = TargetUnit.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
			}
		}		
	}

	UnitPawn.TargetLoc = TargetLocation;
}

private function InitCustomPath()
{
	local PrecomputedPathData PathData;

	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_ThunderLance');
	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	CustomPath.SetupPath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	CustomPath.SetWeaponAndTargetLocation(WeaponVisualizer.GetEntity(), Unit.GetTeam(), TargetLocation, PathData);
	CustomPath.SetHidden(true);
}

/*
function CompleteAction()
{
	//CustomPath.Destroy();

	super.CompleteAction();
}*/

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{	
	local Object EventObj;
	local int i;

	if (NewProjectile != none)
	{

		`AMLOG("Adding new volley:" @ NewProjectile.Class.Name @ "with this many projectile elements:" @ NewProjectile.Projectiles.Length);
		

		//if (X2UnifiedProjectile_ThunderLance(NewProjectile) == none)
		//{
			//NewProjectile.AbilityContextTargetLocation = TargetLocation;

			for (i = 0; i < NewProjectile.Projectiles.Length; i++)
			{
				
				//NewProjectile.Projectiles[i].GrenadePath = CustomPath;

				`AMLOG("Projectile element exists:" @ NewProjectile.Projectiles[i].ProjectileElement != none);

				EventObj = self;
				`XEVENTMGR.RegisterForEvent(EventObj, 'OnProjectileFireSound', OnProjectileFired, ELD_Immediate,, NewProjectile.Projectiles[i].ProjectileElement,, NewProjectile.Projectiles[i].ProjectileElement);
				
			}
		//}
	}
	super.AddProjectileVolley(NewProjectile);
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


	foreach ProjectileVolleys(Projectile)
	{
		for (i = 0; i < Projectile.Projectiles.Length; i++)
		{
			if (Projectile.Projectiles[i].ProjectileElement != ProjectileElement)
				continue;

			`AMLOG("Found projectile element."); 

			UpdateGrenadePath();

			Projectile.Projectiles[i].EndTime = Projectile.Projectiles[i].StartTime + ImpactDelay; // So that the explosion is delayed by the exact amount
			Projectile.Projectiles[i].GrenadePath = CustomPath; // So that X2UnifiedProjectile::StructTarget() always returns false
			Projectile.Projectiles[i].InitialTargetLocation = TargetLocation; // So that grenade explosion visually happens on the target
			//Projectile.Projectiles[i].InitialTargetDistance = VSize(TargetLocation - Projectile.Projectiles[i].InitialSourceLocation);
			//Projectile.Projectiles[i].InitialTravelDirection = TargetLocation - Projectile.Projectiles[i].InitialSourceLocation;
			//Projectile.Projectiles[i].InitialTargetNormal = -Projectile.Projectiles[i].InitialTravelDirection;

		}
	}

	return ELR_NoInterrupt;
}


private function UpdateGrenadePath()
{
	local float		iKeyframes;
	local vector	PathEndLocation;
	local float		i;
	local TTile PathEndTile;
	
	PathEndLocation = TargetLocation;

	PathEndTile = `XWORLD.GetTileCoordinatesFromPosition(PathEndLocation);

	`AMLOG("Setting path end tile:" @ PathEndTile.X @ PathEndTile.Y @ PathEndTile.Z);

	CustomPath.bUseOverrideTargetLocation = true;
	CustomPath.OverrideTargetLocation = PathEndLocation;

	CustomPath.UpdateTrajectory();
	iKeyframes = CustomPath.iNumKeyframes;

	CustomPath.akKeyframes[0].fTime = 0.0f;

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		CustomPath.akKeyframes[i].vLoc = PathEndLocation + vect(2, 2, 2) * i / iKeyframes;
		CustomPath.akKeyframes[i].fTime = ImpactDelay + 0.05f * i / iKeyframes; 
	}

	CustomPath.akKeyframes[iKeyframes - 1].vLoc = PathEndLocation;
}
