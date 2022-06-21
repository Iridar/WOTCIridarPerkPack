class X2MeleePathingPawn_BountyHunter_ShadowTeleport extends X2MeleePathingPawn;

var int AroundTargetTileDistance;

// ---------------------------------------------------------
// Override some of the original functions to allow selecting any tile we want, not just those the unit has enough mobility to reach.

simulated function bool IsDashing()
{
	return false;
}
simulated function bool IsOutOfRange(TTile Tile)
{
	return false;
}
simulated function vector GetPathDestinationLimitedByCost()
{
	return `XWORLD.GetPositionFromTileCoordinates(LastDestinationTile);
}
simulated function AddOrRemoveWaypoint(Vector Destination)
{
}

private function DoUpdatePuckVisuals_BH(TTile PathDestination, Actor TargetActor, X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComGameState_Unit ActiveUnitState;

	ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));

	UpdatePuckVisuals_BH(ActiveUnitState, PathDestination, TargetActor, MeleeAbilityTemplate);
}

private function UpdatePuckVisuals_BH(XComGameState_Unit ActiveUnitState, 
												const out TTile PathDestination, 
												Actor TargetActor,
												X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComWorldData WorldData;
	local XGUnit Unit;
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;
	local float UnitSize;

	WorldData = `XWORLD;

	// determine target puck size and location
	MeshTranslation = TargetActor.Location;

	Unit = XGUnit(TargetActor);
	if(Unit != none)
	{
		UnitSize = Unit.GetVisualizedGameState().UnitSize;
		MeshTranslation = Unit.GetPawn().CollisionComponent.Bounds.Origin;
	}
	else
	{
		UnitSize = 1.0f;
	}

	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	OutOfRangeMeshComponent.SetHidden(true);
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	FromTargetTile = WorldData.GetPositionFromTileCoordinates(PathDestination) - MeshTranslation; 
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
	SlashingMeshComponent.SetRotation(MeshRotation);
	SlashingMeshComponent.SetScale(UnitSize);
	
	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetHidden(false);
	PuckMeshCircleComponent.SetStaticMesh(GetMeleePuckMeshForAbility(MeleeAbilityTemplate));
	//</workshop>
	if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
		
	// CHANGED BY IRIDAR - Use the final tile under the cursor, not the end of the visual path.
	MeshTranslation = GetPathDestinationLimitedByCost(); // make sure we line up perfectly with the end of the path ribbon
	// END OF CHANGED

	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
	PuckMeshComponent.SetTranslation(MeshTranslation);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetTranslation(MeshTranslation);
	//</workshop>

	MeshScale.X = ActiveUnitState.UnitSize;
	MeshScale.Y = ActiveUnitState.UnitSize;
	MeshScale.Z = 1.0f;
	PuckMeshComponent.SetScale3D(MeshScale);
	//<workshop> SMOOTH_TACTICAL_CURSOR AMS 2016/01/22
	//INS:
	PuckMeshCircleComponent.SetScale3D(MeshScale);
	//</workshop>
}

simulated event Tick(float DeltaTime)
{
	local XCom3DCursor Cursor;
	local XComWorldData WorldData;
	local vector CursorLocation;
	local TTile PossibleTile;
	local TTile CursorTile;
	local TTile ClosestTile;
	local X2AbilityTemplate AbilityTemplate;
	local float ClosestTileDistance;
	local float TileDistance;

	local TTile InvalidTile;
	InvalidTile.X = -1;
	InvalidTile.Y = -1;
	InvalidTile.Z = -1;
	
	if(TargetVisualizer == none) 
	{
		return;
	}

	Cursor = `CURSOR;
	WorldData = `XWORLD;
	CursorLocation = Cursor.GetCursorFeetLocation();
	CursorTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);

	// mouse needs to actually highlight a specific tile, controller tabs through them
	if(`ISCONTROLLERACTIVE)
	{
		ClosestTileDistance = -1;

		if(VSizeSq2D(CursorLocation - TargetVisualizer.Location) > 0.1f)
		{
			CursorLocation = TargetVisualizer.Location + (Normal(Cursor.Location - TargetVisualizer.Location) * class'XComWorldData'.const.WORLD_StepSize);
			foreach PossibleTiles(PossibleTile)
			{
				TileDistance = VSizeSq(WorldData.GetPositionFromTileCoordinates(PossibleTile) - CursorLocation);
				if(ClosestTileDistance < 0 || TileDistance < ClosestTileDistance)
				{
					ClosestTile = PossibleTile;
					ClosestTileDistance = TileDistance;
				}
			}

			if(ClosestTile != LastDestinationTile)
			{
				AbilityTemplate = AbilityState.GetMyTemplate();
				RebuildPathingInformation_BH(ClosestTile, TargetVisualizer, AbilityTemplate, InvalidTile);
				DoUpdatePuckVisuals_BH(ClosestTile, TargetVisualizer, AbilityTemplate);
				LastDestinationTile = ClosestTile;
				TargetingMethod.TickUpdatedDestinationTile(LastDestinationTile);
			}

			// put the cursor back on the unit
			Cursor.CursorSetLocation(TargetVisualizer.Location, true);
		}
	}
	else
	{
		if(CursorTile != LastDestinationTile)
		{
			foreach PossibleTiles(PossibleTile)
			{
				if(PossibleTile == CursorTile)
				{
					//`AMLOG("Rebuilding pathing information for tile:" @ CursorTile.X @ CursorTile.Y @ CursorTile.Z);
					AbilityTemplate = AbilityState.GetMyTemplate();
					RebuildPathingInformation_BH(CursorTile, TargetVisualizer, AbilityTemplate, InvalidTile);
					LastDestinationTile = CursorTile;
					TargetingMethod.TickUpdatedDestinationTile(LastDestinationTile);
					break;
				}
			}
		}
	}
}

private function RebuildPathingInformation_BH(TTile PathDestination, Actor TargetActor, X2AbilityTemplate MeleeAbilityTemplate, TTile CursorTile)
{
	local XComWorldData WorldData;
	local XComGameState_Unit ActiveUnitState;
	local array<PathPoint> PathPoints;
	local array<TTile> WaypointTiles;
	local float OriginalOriginZ;
	local XComCoverPoint CoverPoint;
	local bool bCursorOnOriginalUnit;

	local ActorIdentifier ActorID;

	if(LastActiveUnit == none)
	{
		`Redscreen("RebuildPathingInformation(): Unable to update, no unit was set with SetActive()");
		return;
	}

	ActiveUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(LastActiveUnit.ObjectID));
	bCursorOnOriginalUnit = CursorOnOriginalUnit();

	WorldData = `XWORLD;
	// CHANGED BY IRIDAR - Fox the native function, shove the starting and ending tiles into the path directly.
	//UpdatePath(PathDestination, PathTiles);
	PathTiles.Length = 0;
	PathTiles.AddItem(ActiveUnitState.TileLocation);
	PathTiles.AddItem(PathDestination);
	
	// Call the native function so it can fill the ActorId for us.
	// It's gonna cry in the log, but we don't care.
	class'X2PathSolver'.static.GetPathPointsFromPath(ActiveUnitState, PathTiles, PathPoints);
	ActorID = PathPoints[0].ActorId;

	// Disregard the path points set up by X2PathSolver, once again set up only starting and ending points.
	PathPoints.Length = 0;
	PathPoints.Add(2);
	PathPoints[0].Position = WorldData.GetPositionFromTileCoordinates(ActiveUnitState.TileLocation);
	PathPoints[0].Traversal = eTraversal_Teleport;
	PathPoints[0].Phasing = true;
	PathPoints[0].PathTileIndex = 0;
	PathPoints[0].ActorId = ActorID;

	PathPoints[1].Position = WorldData.GetPositionFromTileCoordinates(PathDestination);
	PathPoints[1].Traversal = eTraversal_Teleport;
	PathPoints[1].Phasing = true;
	PathPoints[1].PathTileIndex = 1;
	PathPoints[1].ActorId = ActorID;

	// END OF CHANGED

	// get the path points from the tile path. Path points are a visual representation of the path, for
	// running and drawing the cursor line.
	//class'X2PathSolver'.static.GetPathPointsFromPath(ActiveUnitState, PathTiles, PathPoints);

	// the start of the ribbon should line up with the actor's feet (he may be offset if he's in cover)
	OriginalOriginZ = PathPoints[0].Position.Z;
	PathPoints[0].Position = LastActiveUnit.GetPawn().GetFeetLocation();
	PathPoints[0].Position.Z = OriginalOriginZ;

	// and if the path destination is also in the same tile as the unit, line that up too
	if(PathTiles[PathTiles.Length - 1] == ActiveUnitState.TileLocation)
	{
		PathPoints[PathPoints.Length - 1].Position = PathPoints[0].Position;
	}	
	// If cursor is in bounds, and is not being snapped to a cover shield location,
	// and the cursor is on a valid tile or on the current unit,
	// the path should lead to the exact cursor position.
	if (`ISCONTROLLERACTIVE && 
		`XPROFILESETTINGS.Data.m_bSmoothCursor && 
	    (CursorTile == PathDestination || bCursorOnOriginalUnit))
	{
		
		if(!WorldData.GetCoverPoint(PathPoints[PathPoints.Length - 1].Position, CoverPoint))
		{
			PathPoints[PathPoints.Length - 1].Position.X = `CURSOR.Location.X;
			PathPoints[PathPoints.Length - 1].Position.Y = `CURSOR.Location.Y;
		}
	}

	// pull the points. This smooths the points and removes unneeded angles in the line that result
	// from pathing through discrete tiles
	GetWaypointTiles(WaypointTiles);
	class'XComPath'.static.PerformStringPulling(LastActiveUnit, PathPoints, WaypointTiles);

	VisualPath.SetPathPointsDirect(PathPoints);
	BuildSpline();

	UpdateConcealmentTiles();
	UpdateHazardTileMarkerInfo();
	UpdateLaserScopeMarkers();
	UpdateKillZoneMarkers(ActiveUnitState);
	UpdateObjectiveTiles(ActiveUnitState);
	UpdateBondmateTiles(ActiveUnitState);
	UpdateReviveTiles(ActiveUnitState);
	UpdateHuntersMarkTiles(ActiveUnitState);
	UpdateHazardMarkerInfo(ActiveUnitState);
	UpdateNoiseMarkerInfo(ActiveUnitState);
	UpdatePathMarkers();

	UpdatePathTileData();		
	UpdateRenderablePath(`CAMERASTACK.GetCameraLocationAndOrientation().Location);
	if( `ISCONTROLLERACTIVE )
	{
		RenderablePath.SetHidden(bCursorOnOriginalUnit);
	}

	UpdateTileCacheVisuals();
	UpdateBorderHideHeights();

	if( `ISCONTROLLERACTIVE == FALSE )
		UpdatePuckVisuals(ActiveUnitState, PathDestination, TargetActor, MeleeAbilityTemplate);
	UpdatePuckFlyovers(ActiveUnitState);
	UpdatePuckAudio();
}

// ---------------------------------------------------------
// Override some of the original functions / create new ones to allow selecting any tile around the unit within the specified distance,
// not just tiles directly adjacent to the target.

simulated function UpdateMeleeTarget(XComGameState_BaseObject Target)
{
	local X2AbilityTemplate AbilityTemplate;
	local vector TileLocation;

	//<workshop> Francois' Smooth Cursor AMS 2016/04/07
	//INS:
	local TTile InvalidTile;
	InvalidTile.X = -1;
	InvalidTile.Y = -1;
	InvalidTile.Z = -1;
	//</workshop>

	if (Target == none)
	{
		`Redscreen("X2MeleePathingPawn::UpdateMeleeTarget: Target is none!");
		return;
	}

	TargetVisualizer = Target.GetVisualizer();
	AbilityTemplate = AbilityState.GetMyTemplate();

	PossibleTiles.Length = 0;

	if (SelectAttackTile(UnitState, Target, AbilityTemplate, PossibleTiles))
	{
		// build a path to the default (best) tile
		//<workshop> Francois' Smooth Cursor AMS 2016/04/07
		//WAS:
		//RebuildPathingInformation(PossibleTiles[0], TargetVisualizer, AbilityTemplate);	
		RebuildPathingInformation_BH(PossibleTiles[0], TargetVisualizer, AbilityTemplate, InvalidTile);
		//</workshop>

		// and update the tiles to reflect the new target options
		UpdatePossibleTilesVisuals();

		if(`ISCONTROLLERACTIVE)
		{
			// move the 3D cursor to the new target
			if(`XWORLD.GetFloorPositionForTile(PossibleTiles[0], TileLocation))
			{
				// Single Line for #520
				/// HL-Docs: ref:Bugfixes; issue:520
				/// Controller input now allows choosing melee attack destination tile despite floor differences
				`CURSOR.m_iRequestedFloor = `CURSOR.WorldZToFloor(TargetVisualizer.Location);
				`CURSOR.CursorSetLocation(TileLocation, true, true);
			}
		}
	}
	//<workshop> TACTICAL_CURSOR_PROTOTYPING AMS 2015/12/07
	//INS:
	DoUpdatePuckVisuals_BH(PossibleTiles[0], Target.GetVisualizer(), AbilityTemplate);
	//</workshop>
}

// Finds the melee tiles available to the unit, if any are available to the source unit. If IdealTile is specified,
// it will select the closest valid attack tile to the ideal (and will simply return the ideal if it is valid). If no array us provided for
// SortedPossibleTiles, will simply return true or false based on whether or not a tile is available
//simulated static native function bool SelectAttackTile(XComGameState_Unit UnitState, 
//														   XComGameState_BaseObject TargetState, 
//														   X2AbilityTemplate MeleeAbilityTemplate,
//														   optional out array<TTile> SortedPossibleTiles, // index 0 is the best option.
//														   optional out TTile IdealTile, // If this tile is available, will just return it
//														   optional bool Unsorted = false) const; // if unsorted is true, just returns the list of possible tiles

private function bool SelectAttackTile(XComGameState_Unit ChasingUnitState, 
														   XComGameState_BaseObject TargetState, 
														   X2AbilityTemplate MeleeAbilityTemplate,
														   optional out array<TTile> SortedPossibleTiles, // index 0 is the best option.
														   optional out TTile IdealTile, // If this tile is available, will just return it
														   optional bool Unsorted = false)
{
	local array<TTile>               TargetTiles; // Array of tiles occupied by the target; these tiles can be attacked by melee.
	local TTile                      TargetTile;
	local array<TTile>               AdjacentTiles;	// Array of tiles adjacent to Target Tiles; the attacking unit can move to these tiles to attack.
	local array<TTile>               AllAdjacentTiles;
	local array<TTile>               DirectlyAdjacentTiles;
	local TTile                      AdjacentTile;
	local XComGameState_Unit         TargetUnit;
	local bool						 bCheckForFlanks;

	local X2GameRulesetVisibilityManager	VisibilityMgr;
	local GameRulesCache_VisibilityInfo		VisibilityInfo;
	local XComWorldData						World;
	local float								SightRadiusUnitsSq;

	TargetUnit = XComGameState_Unit(TargetState);
	if (TargetUnit == none)
		return false;

	// Only gather flanking tiles if the target can take cover.
	if (TargetUnit.CanTakeCover())
	{
		bCheckForFlanks = true;
		VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	}

	GatherTilesOccupiedByUnit_BH(TargetUnit, TargetTiles);

	// Collect non-duplicate tiles around every Target Tile to see which tiles we can attack from.
	GatherTilesAdjacentToTiles_BH(TargetTiles, AllAdjacentTiles, AroundTargetTileDistance);

	// Remove from that array tiles that are directly adjacent to the unit, cuz teleporting there would break concealment.
	GatherTilesAdjacentToTiles_BH(TargetTiles, DirectlyAdjacentTiles, 1.5f);
	class'Helpers'.static.RemoveTileSubset(AdjacentTiles, AllAdjacentTiles, DirectlyAdjacentTiles);

	SightRadiusUnitsSq = `METERSTOUNITS(ChasingUnitState.GetVisibilityRadius());
	SightRadiusUnitsSq = SightRadiusUnitsSq * SightRadiusUnitsSq;

	World = `XWORLD;
	foreach TargetTiles(TargetTile)
	{
		foreach AdjacentTiles(AdjacentTile)
		{
			if (class'Helpers'.static.FindTileInList(AdjacentTile, SortedPossibleTiles) != INDEX_NONE)
				continue;		

			if (!World.CanUnitsEnterTile(AdjacentTile) || !World.IsFloorTileAndValidDestination(AdjacentTile, ChasingUnitState))
				continue;

			// Checks for line of sight, but not sight distance.
			if (!World.CanSeeTileToTile(ChasingUnitState.TileLocation, AdjacentTile, VisibilityInfo))
				continue;

			// Skip tile if it's outside unit's sight radius.
			if (SightRadiusUnitsSq < VisibilityInfo.DefaultTargetDist)
				continue;

			// Skip tiles that don't have line of sight to the target unit.
			if (!World.CanSeeTileToTile(AdjacentTile, TargetUnit.TileLocation, VisibilityInfo))
				continue;

			if (bCheckForFlanks)
			{
				if (VisibilityMgr.GetVisibilityInfoFromRemoteLocation(ChasingUnitState.ObjectID, AdjacentTile, TargetUnit.ObjectID, VisibilityInfo))
				{
					if (VisibilityInfo.TargetCover != CT_None)
						continue; // Skip tile if it provides cover against adjacent tile.
				}
				else continue; // skip tile cuz source unit can't see target unit from there.
			}
				
			SortedPossibleTiles.AddItem(AdjacentTile);
		}
	}

	return SortedPossibleTiles.Length > 0;
}

private function GatherTilesAdjacentToTiles_BH(out array<TTile> TargetTiles, out array<TTile> AdjacentTiles, const float TileDistance)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local TTile              TargetTile;
	local vector             TargetLocation;
	
	WorldData = `XWORLD;

	// Collect a 3x3 box of tiles around every target tile, excluding duplicates.
	// Melee attacks can happen diagonally upwards or downwards too,
	// so collecting tiles on the same Z level would not be enough.
	foreach TargetTiles(TargetTile)
	{
		TargetLocation = WorldData.GetPositionFromTileCoordinates(TargetTile);

		WorldData.CollectTilesInSphere(TilePosPairs, TargetLocation, `TILESTOUNITS(TileDistance));

		foreach TilePosPairs(TilePair)
		{
			if (class'Helpers'.static.FindTileInList(TilePair.Tile, AdjacentTiles) != INDEX_NONE)
				continue;

			AdjacentTiles.AddItem(TilePair.Tile);
		}
	}
}

private function GatherTilesOccupiedByUnit_BH(const XComGameState_Unit TargetUnit, out array<TTile> OccupiedTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local Box                VisibilityExtents;

	TargetUnit.GetVisibilityExtents(VisibilityExtents);
	
	WorldData = `XWORLD;
	WorldData.CollectTilesInBox(TilePosPairs, VisibilityExtents.Min, VisibilityExtents.Max);

	foreach TilePosPairs(TilePair)
	{
		OccupiedTiles.AddItem(TilePair.Tile);
	}
}
