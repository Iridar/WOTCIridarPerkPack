class X2MeleePathingPawn_BountyHunter_ShadowTeleport extends X2MeleePathingPawn;

const ChasingShotTileDistance = 6;

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState, X2TargetingMethod_MeleePath InTargetingMethod)
{
	super.Init(InUnitState, InAbilityState, InTargetingMethod);

	RenderablePath.SetHidden(true);
}


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
		RebuildPathingInformation(PossibleTiles[0], TargetVisualizer, AbilityTemplate, InvalidTile);
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
	DoUpdatePuckVisuals(PossibleTiles[0], Target.GetVisualizer(), AbilityTemplate);
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
	local TTile                      AdjacentTile;
	local XComGameState_Unit         TargetUnit;
	local XComGameState_Destructible TargetObject;
	local XComDestructibleActor      DestructibleActor;
	local bool						 bCheckForFlanks;

	local X2GameRulesetVisibilityManager	VisibilityMgr;
	local GameRulesCache_VisibilityInfo		VisibilityInfo;
	local XComWorldData						World;

	local vector							FiringLocation;
	local VoxelRaytraceCheckResult			Raytrace;
	local vector							AdjacentLocation;
	local GameRulesCache_VisibilityInfo		OutVisibilityInfo;
	local int								Direction;
	local int								CanSeeFromDefault;
	local UnitPeekSide						PeekSide;
	local int								OutRequiresLean;
	local CachedCoverAndPeekData			PeekData;
	local TTile								PeekTile;
	local XGUnit							VisUnit;

	TargetUnit = XComGameState_Unit(TargetState);
	if (TargetUnit != none)
	{
		GatherTilesOccupiedByUnit_BH(TargetUnit, TargetTiles);
		
		// Only gather flanking tiles if the target can take cover.
		if (TargetUnit.CanTakeCover())
		{
			bCheckForFlanks = true;
			VisibilityMgr = `TACTICALRULES.VisibilityMgr;
		}
	}
	else
	{
		TargetObject = XComGameState_Destructible(TargetState);
		if (TargetObject == none)
		{
			`LOG(self.Class.Name @ GetFuncName() @ ":: WARNING, target is not a unit and not a destructible object! Its class is:" @ TargetState.Class.Name @ ", unable to detect additional tiles to melee attack from. Attacking unit:" @ UnitState.GetFullName());
			return false;
		}

		DestructibleActor = XComDestructibleActor(TargetObject.GetVisualizer());
		if (DestructibleActor == none)
		{
			`LOG(self.Class.Name @ GetFuncName() @ ":: WARNING, no visualizer found for destructible object with ID:" @ TargetObject.ObjectID @ ", unable to detect additional tiles to melee attack from. Attacking unit:" @ UnitState.GetFullName());
			return false;
		}

		// AssociatedTiles is the array of tiles occupied by the destructible object.
	    // In theory, every tile from that array can be targeted by a melee attack.
		TargetTiles = DestructibleActor.AssociatedTiles;
	}

	// Collect non-duplicate tiles around every Target Tile to see which tiles we can attack from.
	GatherTilesAdjacentToTiles_BH(TargetTiles, AdjacentTiles);
	World = `XWORLD;
	FiringLocation = World.GetPositionFromTileCoordinates(ChasingUnitState.TileLocation);
	VisUnit = XGUnit(ChasingUnitState.GetVisualizer());
	foreach TargetTiles(TargetTile)
	{
		foreach AdjacentTiles(AdjacentTile)
		{
			if (class'Helpers'.static.FindTileInList(AdjacentTile, SortedPossibleTiles) != INDEX_NONE)
				continue;		

			//if (!ActiveCache.IsTileReachable(AdjacentTile))
			//	continue;
			if (!World.CanUnitsEnterTile(AdjacentTile) || !World.IsFloorTileAndValidDestination(AdjacentTile, ChasingUnitState))
				continue;

			AdjacentLocation = World.GetPositionFromTileCoordinates(AdjacentTile);

			// Presumably returns true if the raytrace path is blocked.
			World.VoxelRaytrace_Locations(FiringLocation, AdjacentLocation, Raytrace);
			if (Raytrace.BlockedFlag != 0x0)
			{
				
				VisUnit.GetDirectionInfoForPosition(AdjacentLocation, OutVisibilityInfo, Direction, PeekSide, CanSeeFromDefault, OutRequiresLean, true);
				if (PeekSide != eNoPeek)
				{
					PeekData = World.GetCachedCoverAndPeekData(ChasingUnitState.TileLocation);
					if (PeekSide == ePeekLeft)
						PeekTile = PeekData.CoverDirectionInfo[Direction].LeftPeek.PeekTile;
					else
						PeekTile = PeekData.CoverDirectionInfo[Direction].RightPeek.PeekTile;

					World.VoxelRaytrace_Tiles(PeekTile, AdjacentTile, Raytrace);

					if (Raytrace.BlockedFlag != 0x0)
						continue;
				}		
			}

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