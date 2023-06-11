class X2Action_Fire_ThunderLance extends X2Action_Fire;

var private bool locbMainImpactNotify;
var private Vector locHitLocation;
var private bool bProcessingDelay;

var private XComPrecomputedPath_ThunderLance CustomPath;

const ImpactDelay = 1.95f; // # Impact Delay # 

function Init()
{
	local XComGameState_Ability AbilityState;	
	local XGUnit FiringUnit;
	local XComGameState_Item WeaponItem;
	local X2WeaponTemplate WeaponTemplate;
	local XComWeapon Entity, WeaponEntity;
	local XComGameState_Item Item;
	local XGWeapon AmmoWeapon;

	super.Init();

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	FiringUnit = XGUnit(History.GetVisualizer(AbilityState.OwnerStateObject.ObjectID));
		
	WeaponItem = AbilityState.GetSourceWeapon();
	if (WeaponItem != none)
	{
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
		WeaponEntity = WeaponVisualizer.GetEntity();
	}
	else if (FiringUnit.CurrentPerkAction != none)
	{
		WeaponEntity = FiringUnit.CurrentPerkAction.GetPerkWeapon();
	}

	// grenade tosses hide the weapon
	if( AbilityTemplate.bHideWeaponDuringFire)
	{
		WeaponEntity.Mesh.SetHidden( false );						// unhide the grenade that was hidden after the last one fired
	}
	else if( AbilityTemplate.bHideAmmoWeaponDuringFire)
	{
		Item = XComGameState_Item( History.GetGameStateForObjectID( AbilityState.SourceAmmo.ObjectID ) );
		AmmoWeapon = XGWeapon( Item.GetVisualizer( ) );
		Entity = XComWeapon( AmmoWeapon.m_kEntity );
		Entity.Mesh.SetHidden( true );
	}

	InitCustomPath();
}

private function InitCustomPath()
{
	local PrecomputedPathData PathData;

	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_ThunderLance');
	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	CustomPath.SetupPath(WeaponVisualizer.GetEntity(), Unit.GetTeam(), PathData);
	CustomPath.SetWeaponAndTargetLocation(WeaponVisualizer.GetEntity(), Unit.GetTeam(), GetPathEndLocation(), PathData);
	CustomPath.SetHidden(true);
}


function CompleteAction()
{
	CustomPath.Destroy();

	super.CompleteAction();
}

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{	
	local int i;

	if (NewProjectile != none)
	{

		`AMLOG("Adding new volley:" @ NewProjectile.Class.Name);


		if (X2UnifiedProjectile_ThunderLance(NewProjectile) == none)
		{
			UpdateGrenadePath();

			for (i = 0; i < NewProjectile.Projectiles.Length; i++)
			{
				NewProjectile.Projectiles[i].GrenadePath = CustomPath;
			}
		}
	}
	super.AddProjectileVolley(NewProjectile);
}

private function vector GetPathEndLocation()
{
	if (TargetUnit != none)
	{
		return TargetUnit.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
	}
	else
	{
		return TargetLocation;
	}
}

private function UpdateGrenadePath()
{
	local float		iKeyframes;
	local vector	PathEndLocation;
	local float		i;
	
	PathEndLocation = GetPathEndLocation();

	`AMLOG("Setting path end location:" @ PathEndLocation);

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
}
