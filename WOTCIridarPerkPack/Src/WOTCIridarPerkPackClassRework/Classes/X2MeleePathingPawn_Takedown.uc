class X2MeleePathingPawn_Takedown extends X2MeleePathingPawn;

// Same as original, but allow only selecting tiles the target will be flanked from (have no cover from).

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

	if(Target == none)
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
	local array<TTile>               DirectlyAdjacentTiles;
	local TTile                      AdjacentTile;
	local XComGameState_Unit         TargetUnit;
	local bool						 bCheckForFlanks;

	local X2GameRulesetVisibilityManager	VisibilityMgr;
	local GameRulesCache_VisibilityInfo		VisibilityInfo;
	local XComWorldData						World;

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

	GatherTilesAdjacentToTiles_BH(TargetTiles, DirectlyAdjacentTiles, 1.5f);

	World = `XWORLD;

	foreach DirectlyAdjacentTiles(AdjacentTile)
	{
		if (class'Helpers'.static.FindTileInList(AdjacentTile, SortedPossibleTiles) != INDEX_NONE)
			continue;		

		if (!World.CanUnitsEnterTile(AdjacentTile) || !World.IsFloorTileAndValidDestination(AdjacentTile, ChasingUnitState))
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
