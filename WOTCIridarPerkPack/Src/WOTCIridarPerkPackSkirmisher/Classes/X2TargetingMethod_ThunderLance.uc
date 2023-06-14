class X2TargetingMethod_ThunderLance extends X2TargetingMethod_RocketLauncher;

var private XGWeapon WeaponVisualizer;
var private XComPrecomputedPath_ThunderLance CustomPath;
var private UITacticalHUD TacticalHUD;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComGameState_Item		WeaponItem;
	local float						TargetingRange;
	local X2AbilityTarget_Cursor	CursorTarget;
	local PrecomputedPathData		PathData;

	super.Init(InAction, NewTargetIndex);

	// determine our targeting range
	WeaponItem = Ability.GetSourceWeapon();
	TargetingRange = Ability.GetAbilityCursorRangeMeters( );

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;

	// show the grenade path
	WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

	XComWeapon(WeaponVisualizer.m_kEntity).bPreviewAim = true;

	// Updating grenade path in Update() is not often enough, 
	// so have to do it in an Actor, which can do it every Tick()
	CustomPath = `BATTLE.spawn(class'XComPrecomputedPath_ThunderLance');
	CustomPath.UpdateGrenadePathFn = UpdateGrenadePath;

	PathData.InitialPathTime = 0.1f;
	PathData.MaxPathTime = 0.1f;
	PathData.MaxNumberOfBounces = 0;
	CustomPath.ActivatePath(WeaponVisualizer.GetEntity(), FiringUnit.GetTeam(), PathData);

	TacticalHUD = `PRES.GetTacticalHUD();
}

// Improved Rocket Targeting baked in.
function Update(float DeltaTime)
{
	local XComWorldData World;
	local VoxelRaytraceCheckResult Raytrace;
	local array<Actor> CurrentlyMarkedTargets;
	local int Direction, CanSeeFromDefault;
	local UnitPeekSide PeekSide;
	local int OutRequiresLean;
	local TTile BlockedTile, PeekTile, UnitTile;
	local TTile TargetTile;   // Single variable for Issue #617
	local bool GoodView;
	local CachedCoverAndPeekData PeekData;
	local array<TTile> Tiles;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;

	// Easier targeting
	local vector ShootFromLocation;

	NewTargetLocation = Cursor.GetCursorFeetLocation();
	NewTargetLocation.Z = GetOptimalZForTile(NewTargetLocation);

	if( NewTargetLocation != CachedTargetLocation )
	{
		// Easier targeting
		ShootFromLocation = FiringUnit.Location;
		ShootFromLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;

		World = `XWORLD;
		GoodView = false;
		if( World.VoxelRaytrace_Locations(ShootFromLocation, NewTargetLocation, Raytrace) )
		{
			BlockedTile = Raytrace.BlockedTile; 
			//  check left and right peeks
			FiringUnit.GetDirectionInfoForPosition(NewTargetLocation, OutVisibilityInfo, Direction, PeekSide, CanSeeFromDefault, OutRequiresLean, true);

			if (PeekSide != eNoPeek)
			{
				UnitTile = World.GetTileCoordinatesFromPosition(FiringUnit.Location);
				PeekData = World.GetCachedCoverAndPeekData(UnitTile);
				if (PeekSide == ePeekLeft)
					PeekTile = PeekData.CoverDirectionInfo[Direction].LeftPeek.PeekTile;
				else
					PeekTile = PeekData.CoverDirectionInfo[Direction].RightPeek.PeekTile;

				// Start Issue #617
				/// HL-Docs: ref:Bugfixes; issue:617
				/// Ray trace from the peek tile to the target, not from the unit tile to the peek tile.
				TargetTile = World.GetTileCoordinatesFromPosition(NewTargetLocation);
				if (!World.VoxelRaytrace_Tiles(PeekTile, TargetTile, Raytrace))
					GoodView = true;
				else
					BlockedTile = Raytrace.BlockedTile;
				// End Issue #617
			}				
		}		
		else
		{
			GoodView = true;
		}

		if( !GoodView )
		{
			NewTargetLocation = World.GetPositionFromTileCoordinates(BlockedTile);
		}

		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawSplashRadius();
		DrawAOETiles(Tiles);
	}

	super.UpdateTargetLocation(DeltaTime);	
}

// Iridar: Fake the path graphics here.
private function UpdateGrenadePath()
{
	UpdateGrenadePathTarget(NewTargetLocation);
}

private function UpdateGrenadePathTarget(const vector PathEndLocation)
{
	local vector	PathStartLocation;
	local float		iKeyframes;
	local float		i;

	PathStartLocation = FiringUnit.Location;

	iKeyframes = CustomPath.iNumKeyframes;

	CustomPath.bUseOverrideSourceLocation = true;
	CustomPath.OverrideSourceLocation = PathStartLocation;

	CustomPath.bUseOverrideTargetLocation = true;
	CustomPath.OverrideTargetLocation = PathEndLocation;

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		CustomPath.akKeyframes[i].vLoc = PathStartLocation + (PathEndLocation - PathStartLocation) * i / iKeyframes;
	}
}


// super.Committed() calls Canceled() too.
function Canceled()
{
	super.Canceled();

	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	CustomPath.ClearPathGraphics();
	XComWeapon(WeaponVisualizer.m_kEntity).bPreviewAim = false;

	CustomPath.Destroy();
}

// Easier targeting
function int GetOptimalZForTile(const vector VectorLocation)
{
	local XComWorldData					World;
	local TTile							TileLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local array<Actor>					ActorsOnTile;
	local XGUnit						GameUnitOnTile;
	local XComGameState_Unit			UnitOnTile;

	World = `XWORLD;

	TileLocation = World.GetTileCoordinatesFromPosition(VectorLocation);
	TargetsOnTile = World.GetUnitsOnTile(TileLocation);

	if (TargetsOnTile.Length > 0)
	{
		UnitOnTile = GetLivingUnitFromHistory(TargetsOnTile);
		if (UnitOnTile != none)
		{
			GameUnitOnTile = XGUnit(UnitOnTile.GetVisualizer());
			if (GameUnitOnTile != none)
			{
				TacticalHUD.m_kTargetReticle.SetTarget(GameUnitOnTile);
				TacticalHUD.m_kTargetReticle.SetMode(eUIReticle_Advent);
				TacticalHUD.m_kTargetReticle.SetVisible(true);
			}
		}
	}
	else
	{
		TacticalHUD.m_kTargetReticle.SetTarget();
		TacticalHUD.m_kTargetReticle.SetVisible(false);
	}

	//	If there's a unit on the tile, or the tile contains a high cover object
	if (TargetsOnTile.Length > 0 || World.IsLocationHighCover(VectorLocation))
	{
		//	then we aim at a point a floor above the tile (around soldier's waist-chest level)
		return World.GetFloorZForPosition(VectorLocation) + class'XComWorldData'.const.WORLD_FloorHeight;
	}
	else
	{
		//	if the tile contains low cover object, then we aim slightly above the floor
		if (World.IsLocationLowCover(VectorLocation))
		{
			return class'XComWorldData'.const.WORLD_HalfFloorHeight;
		}
		else
		{
			//	otherwise we aim at floor
			return World.GetFloorZForPosition(VectorLocation);
		}
	}
}

static private function XComGameState_Unit GetLivingUnitFromHistory(array<StateObjectReference>	TargetsOnTile)
{
	local XComGameStateHistory	History;
	local StateObjectReference	UnitRef;
	local XComGameState_Unit	UnitState;

	History = `XCOMHISTORY;
	foreach TargetsOnTile(UnitRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState == none)
			continue;

		if (UnitState.IsDead())
			continue;

		if (UnitState.GetMyTemplate().bIsCosmetic)
			continue;

		return UnitState;
	}
	return none;
}

defaultproperties
{
	SnapToTile = true; // Doesn't seem to do anything
	ProjectileTimingStyle=""
	OrdnanceTypeName="" // Can't set anything here, or else X2UnifiedProjectile::FireProjectileInstance()
		// will override the custom path with `PRECOMPUTEDPATH.
}