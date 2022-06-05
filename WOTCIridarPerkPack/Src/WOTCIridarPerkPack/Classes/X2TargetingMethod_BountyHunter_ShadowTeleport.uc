class X2TargetingMethod_BountyHunter_ShadowTeleport extends X2TargetingMethod_MeleePath;

//var private X2GrapplePuck GrapplePuck;

var private X2AbilityTemplate			AbilityTemplate;
var private XComPresentationLayer		Pres;
var private UITacticalHUD				TacticalHud;
var private XComGameStateHistory		History;
var private XComGameState_Unit			TargetUnitState;
//var private X2Camera_LookAtActorTimed	LookAtCamera;
//var private XCom3DCursor				Cursor;
var private XGUnit						TargetGameUnit;
var private XComWorldData				World;
var private TTile						LastSelectedTile;
var private array<TTile>				PossibleTiles;
var private X2BountyHunter_ShadowTeleport_PuckActor PuckActor;

const ChasingShotTileDistance = 6;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	
	super(X2TargetingMethod).Init(InAction, NewTargetIndex);

	History = `XCOMHISTORY;
	Pres = `PRES;
	Cursor = `CURSOR;
	Cursor.CursorSetLocation(Cursor.GetCursorFeetLocation(), false, true); 
	World = `XWORLD;
	TacticalHud = Pres.GetTacticalHUD();
	AbilityTemplate = Ability.GetMyTemplate();
	
	PuckActor = Cursor.Spawn(class'X2BountyHunter_ShadowTeleport_PuckActor', Cursor);
	PuckActor.SetVisible(true);

	IconManager = Pres.GetActionIconMgr();
	IconManager.ShowIcons(true);
	IconManager.UpdateCursorLocation(true);

	PuckActor.World = World;
	PuckActor.AbilityTemplate = AbilityTemplate;
	PuckActor.CachePuckMeshes();

	DirectSelectNearestTarget();
}


function Canceled()
{
	PuckActor.Destroy();
	IconManager.ShowIcons(false);

	if(LookAtCamera != none && LookAtCamera.LookAtDuration < 0)
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
	}

	super(X2TargetingMethod).Canceled();
}

function Update(float DeltaTime)
{
	local vector NewTargetLocation;

	NewTargetLocation = Cursor.GetCursorFeetLocation();
	if (CachedTargetLocation != NewTargetLocation)
	{
		CachedTargetLocation = NewTargetLocation;
	
		LastSelectedTile = World.GetTileCoordinatesFromPosition(NewTargetLocation);

		`AMLOG("Cursor position:" @ NewTargetLocation);

		//if (class'Helpers'.static.FindTileInList(LastSelectedTile, PossibleTiles) == INDEX_NONE)
		//{
		//	LastSelectedTile = GetClosestPossibleTile(LastSelectedTile);
		//	`AMLOG("Tile not possible, selected tile:" @ LastSelectedTile.X @ LastSelectedTile.Y @ LastSelectedTile.Z);
		//}
		PuckActor.UpdatePuckVisuals(LastSelectedTile, TargetGameUnit);
	}
	IconManager.UpdateCursorLocation();
	super(X2TargetingMethod).Update(DeltaTime);
}





private function TTile GetClosestPossibleTile(const TTile GivenTile)
{
	local TTile ClosestTile;
	local float ClosestDistance;
	local float Distance;
	local TTile PossibleTile;

	ClosestDistance = 40;
	foreach PossibleTiles(PossibleTile)
	{
		Distance = class'Helpers'.static.DistanceBetweenTiles(LastSelectedTile, PossibleTile);
		if (Distance < ClosestDistance)
		{
			ClosestTile = PossibleTile;
			ClosestDistance = Distance;
		}
	}
	return ClosestTile;
}

function DirectSetTarget(int TargetIndex)
{
	// advance the target counter
	LastTarget = TargetIndex % Action.AvailableTargets.Length;
	if (LastTarget < 0)
	{
		LastTarget = Action.AvailableTargets.Length + TargetIndex;
	}

	// put the targeting reticle on the new target
	TacticalHud.TargetEnemy(GetTargetedObjectID());

	// have the idle state machine look at the new target
	FiringUnit.IdleStateMachine.CheckForStanceUpdate();

	// have the pathing pawn draw a path to the target
	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Action.AvailableTargets[LastTarget].PrimaryTarget.ObjectID));
	TargetGameUnit = XGUnit(TargetUnitState.GetVisualizer());

	PuckActor.UnitSize = TargetUnitState.UnitSize;

	UpdateMeleeTarget();
		
	if (LookAtCamera != none)
	{
		`CAMERASTACK.RemoveCamera(LookAtCamera);
	}
	LookAtCamera = new class'X2Camera_LookAtActorTimed';
	LookAtCamera.LookAtDuration = `ISCONTROLLERACTIVE ? -1.0f : 0.0f;
	LookAtCamera.ActorToFollow = TargetUnit != none ? TargetGameUnit.GetPawn() : TargetUnitState.GetVisualizer();
	`CAMERASTACK.AddCamera(LookAtCamera);
}
/*
function bool GetPreAbilityPath(out array<TTile> PathTiles)
{

	return PathTiles.Length > 1;
}
*/
private function UpdateMeleeTarget()
{
	local vector TileLocation;

	SelectAttackTile();
	// build a path to the default (best) tile
	// TODO: Draw Grapple Puck here

	// and update the tiles to reflect the new target options
	//UpdatePossibleTilesVisuals();
	DrawAOETiles(PossibleTiles);

	if(`ISCONTROLLERACTIVE)
	{
		// move the 3D cursor to the new target
		if(`XWORLD.GetFloorPositionForTile(PossibleTiles[0], TileLocation))
		{
			// Single Line for #520
			/// HL-Docs: ref:Bugfixes; issue:520
			/// Controller input now allows choosing melee attack destination tile despite floor differences
			Cursor.m_iRequestedFloor = `CURSOR.WorldZToFloor(TargetGameUnit.Location);
			Cursor.CursorSetLocation(TileLocation, true, true);
		}
	}
	//DoUpdatePuckVisuals(PossibleTiles[0], Target.GetVisualizer(), AbilityTemplate);
}

// Finds the melee tiles available to the unit, if any are available to the source unit. If IdealTile is specified,
// it will select the closest valid attack tile to the ideal (and will simply return the ideal if it is valid). If no array us provided for
// PossibleTiles, will simply return true or false based on whether or not a tile is available
//simulated static native function bool SelectAttackTile(XComGameState_Unit UnitState, 
//														   XComGameState_BaseObject TargetUnitState, 
//														   X2AbilityTemplate AbilityTemplate,
//														   optional out array<TTile> PossibleTiles, // index 0 is the best option.
//														   optional out TTile IdealTile, // If this tile is available, will just return it
//														   optional bool Unsorted = false) const; // if unsorted is true, just returns the list of possible tiles

private function bool SelectAttackTile()
{
	local array<TTile>               TargetTiles; // Array of tiles occupied by the target; these tiles can be attacked by melee.
	local TTile                      TargetTile;
	local array<TTile>               AdjacentTiles;	// Array of tiles adjacent to Target Tiles; the attacking unit can move to these tiles to attack.
	local TTile                      AdjacentTile;
	local bool						 bCheckForFlanks;

	local X2GameRulesetVisibilityManager	VisibilityMgr;
	local GameRulesCache_VisibilityInfo		VisibilityInfo;

	local vector							FiringLocation;
	//local VoxelRaytraceCheckResult			Raytrace;
	//local vector							AdjacentLocation;
	//local GameRulesCache_VisibilityInfo		OutVisibilityInfo;
	//local int								Direction;
	//local int								CanSeeFromDefault;
	//local UnitPeekSide						PeekSide;
	//local int								OutRequiresLean;
	//local CachedCoverAndPeekData			PeekData;
	//local TTile								PeekTile;

	GatherTilesOccupiedByUnit_BH(TargetTiles);
		
	// Only gather flanking tiles if the target can take cover.
	if (TargetUnitState.CanTakeCover())
	{
		bCheckForFlanks = true;
		VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	}

	// Collect non-duplicate tiles around every Target Tile to see which tiles we can attack from.
	GatherTilesAdjacentToTiles_BH(TargetTiles, AdjacentTiles);
	
	FiringLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);

	foreach TargetTiles(TargetTile)
	{
		foreach AdjacentTiles(AdjacentTile)
		{
			if (class'Helpers'.static.FindTileInList(AdjacentTile, PossibleTiles) != INDEX_NONE)
				continue;		

			//if (!ActiveCache.IsTileReachable(AdjacentTile))
			//	continue;
			if (!World.CanUnitsEnterTile(AdjacentTile) || !World.IsFloorTileAndValidDestination(AdjacentTile, UnitState))
				continue;

			//AdjacentLocation = World.GetPositionFromTileCoordinates(AdjacentTile);
			//World.VoxelRaytrace_Locations(FiringLocation, AdjacentLocation, Raytrace); // Presumably returns true if the raytrace path is blocked.
			//if (Raytrace.BlockedFlag != 0x0)
			//{
			//	// Edit: this should not be target game unit
			//	TargetGameUnit.GetDirectionInfoForPosition(AdjacentLocation, OutVisibilityInfo, Direction, PeekSide, CanSeeFromDefault, OutRequiresLean, true);
			//	if (PeekSide != eNoPeek)
			//	{
			//		PeekData = World.GetCachedCoverAndPeekData(UnitState.TileLocation);
			//		if (PeekSide == ePeekLeft)
			//			PeekTile = PeekData.CoverDirectionInfo[Direction].LeftPeek.PeekTile;
			//		else
			//			PeekTile = PeekData.CoverDirectionInfo[Direction].RightPeek.PeekTile;
			//
			//		World.VoxelRaytrace_Tiles(PeekTile, AdjacentTile, Raytrace);
			//
			//		if (Raytrace.BlockedFlag != 0x0)
			//			continue;
			//	}		
			//}

			if (bCheckForFlanks)
			{
				if (VisibilityMgr.GetVisibilityInfoFromRemoteLocation(UnitState.ObjectID, AdjacentTile, TargetUnitState.ObjectID, VisibilityInfo))
				{
					if (VisibilityInfo.TargetCover != CT_None)
						continue; // Skip tile if it provides cover against adjacent tile.
				}
				else continue; // skip tile cuz source unit can't see target unit from there.
			}
				
			PossibleTiles.AddItem(AdjacentTile);
		}
	}

	return PossibleTiles.Length > 0;
}

private function GatherTilesAdjacentToTiles_BH(out array<TTile> TargetTiles, out array<TTile> AdjacentTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local TTile              TargetTile;
	local vector             Minimum;
	local vector             Maximum;
	
	WorldData = `XWORLD;

	// Collect a 3x3 box of tiles around every target tile, excluding duplicates.
	// Melee attacks can happen diagonally upwards or downwards too,
	// so collecting tiles on the same Z level would not be enough.
	foreach TargetTiles(TargetTile)
	{
		Minimum = WorldData.GetPositionFromTileCoordinates(TargetTile);
		Maximum = Minimum;

		Minimum.X -= WorldData.WORLD_StepSize * ChasingShotTileDistance;
		Minimum.Y -= WorldData.WORLD_StepSize * ChasingShotTileDistance;
		Minimum.Z -= WorldData.WORLD_FloorHeight * ChasingShotTileDistance;

		Maximum.X += WorldData.WORLD_StepSize * ChasingShotTileDistance;
		Maximum.Y += WorldData.WORLD_StepSize * ChasingShotTileDistance;
		Maximum.Z += WorldData.WORLD_FloorHeight * ChasingShotTileDistance;

		WorldData.CollectTilesInBox(TilePosPairs, Minimum, Maximum);

		foreach TilePosPairs(TilePair)
		{
			if (class'Helpers'.static.FindTileInList(TilePair.Tile, AdjacentTiles) != INDEX_NONE)
				continue;

			AdjacentTiles.AddItem(TilePair.Tile);
		}
	}
}

private function GatherTilesOccupiedByUnit_BH(out array<TTile> OccupiedTiles)
{	
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local Box                VisibilityExtents;

	TargetUnitState.GetVisibilityExtents(VisibilityExtents);
	
	World.CollectTilesInBox(TilePosPairs, VisibilityExtents.Min, VisibilityExtents.Max);

	foreach TilePosPairs(TilePair)
	{
		OccupiedTiles.AddItem(TilePair.Tile);
	}
}


/*
function Canceled()
{
	GrapplePuck.Destroy();
	super.Canceled();
}

function Committed()
{
	GrapplePuck.ShowConfirmAndDestroy();
	super.Committed();
}*/
/*
function GetTargetLocations(out array<Vector> TargetLocations)
{
	local Vector TargetLocation;

	TargetLocations.Length = 0;

	if(GrapplePuck.GetGrappleTargetLocation(TargetLocation))
	{
		TargetLocations.AddItem(TargetLocation);
	}
}
*/

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(World.GetPositionFromTileCoordinates(LastSelectedTile));
	`AMLOG("Setting target location as:" @ TargetLocations[0]);
}
function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	return TargetLocations.Length == 1 ? 'AA_Success' : 'AA_NoTargets';
}
defaultproperties
{
	ProvidesPath = false
}