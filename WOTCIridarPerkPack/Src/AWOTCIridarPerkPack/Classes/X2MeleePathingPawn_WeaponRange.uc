class X2MeleePathingPawn_WeaponRange extends X2MeleePathingPawn;

var private XGUnit			Visualizer;
var private XComWorldData	World;
var private float			SightRangeUnits;

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState, X2TargetingMethod_MeleePath InTargetingMethod)
{
	super.Init(InUnitState, InAbilityState, InTargetingMethod);

	Visualizer = XGUnit(UnitState.GetVisualizer());
	World = `XWORLD;
	SightRangeUnits = `METERSTOUNITS(UnitState.GetCurrentStat(eStat_SightRadius));
}

// ScootAndShoot not finished: This needs to get the reachable tile cache, then filter out tiles from where the enemy cannot be seen.
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

	// Iridar: use a custom function for this.
	if(SelectAttackTile(UnitState, Target, AbilityTemplate, PossibleTiles))
	{
		// Start Issue #1084
		// The native `class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile` function
		// gives only one possible attack tile for adjacent targets, so we use our own
		// script logic to add more possible attack tiles for adjacent targets.
		// If there's only one possible melee attack tile and the unit is standing on it,
		// then the target is directly adjacent.
		if (UnitState.UnitSize == 1 && PossibleTiles.Length == 1 && UnitState.TileLocation == PossibleTiles[0])
		{
			UpdatePossibleTilesForAdjacentTarget(Target);
		}
		// End Issue #1084

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

private function bool SelectAttackTile(XComGameState_Unit ChasingUnitState, 
														   XComGameState_BaseObject TargetState, 
														   X2AbilityTemplate MeleeAbilityTemplate,
														   optional out array<TTile> SortedPossibleTiles, // index 0 is the best option.
														   optional out TTile IdealTile, // If this tile is available, will just return it
														   optional bool Unsorted = false)
{
	local array<TTile>							ReachableTiles;
	local TTile									ReachableTile;
	local array<GameRulesCache_VisibilityInfo>	AllVisibleToSource;
	local GameRulesCache_VisibilityInfo			OneVisibleToSource;
	local X2GameRulesetVisibilityManager		VisibilityMgr;
	local array<X2Condition>					Conditions;
	local XComGameState_Unit					TargetUnit;

	TargetUnit = XComGameState_Unit(TargetState);
	if (TargetUnit == none)
		return false;
		
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	Visualizer.m_kReachableTilesCache.GetAllPathableTiles(ReachableTiles);

	//`AMLOG("Got this many reachable tiles:" @ ReachableTiles.Length);
	Conditions.AddItem(class'X2TacticalVisibilityHelpers'.default.GameplayVisibilityCondition);

	foreach ReachableTiles(ReachableTile)
	{
		AllVisibleToSource.Length = 0;
		VisibilityMgr.GetAllVisibleUnitsToSource_Remote(UnitState.ObjectID, ReachableTile, AllVisibleToSource,, Conditions, TargetUnit.GetTeam());

		//`AMLOG("Testing tile:" @ ReachableTile.X @ ReachableTile.Y @ ReachableTile.Z @ "num visible enemies:" @ AllVisibleToSource.Length);

		foreach AllVisibleToSource(OneVisibleToSource)
		{
			if (OneVisibleToSource.TargetID == TargetState.ObjectID)
			{
				//`AMLOG("Can see target, adding tile.");
				SortedPossibleTiles.AddItem(ReachableTile);
			}
		}
	}

	return SortedPossibleTiles.Length > 0;
}
