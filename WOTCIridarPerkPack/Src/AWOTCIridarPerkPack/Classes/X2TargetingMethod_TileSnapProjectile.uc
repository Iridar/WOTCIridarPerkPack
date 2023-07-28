class X2TargetingMethod_TileSnapProjectile extends X2TargetingMethod_Grenade;

var private vector FiringLocation;
var private vector NewTargetLocation;
var private XComWorldData World;
var private TTile SourceTile;

static function bool UseGrenadePath() { return false; }

function Init(AvailableAction InAction, int NewTargetIndex)
{
	super.Init(InAction, NewTargetIndex);

	World = `XWORLD;
	SourceTile = UnitState.TileLocation;
	FiringLocation = World.GetPositionFromTileCoordinates(SourceTile);
	FiringLocation.Z += World.WORLD_FloorHeight;
}

function Update(float DeltaTime)
{
	local GameRulesCache_VisibilityInfo	OutVisibilityInfo;
	local VoxelRaytraceCheckResult		Raytrace;
	local array<Actor>					CurrentlyMarkedTargets;
	local int						Direction;
	local int						CanSeeFromDefault;
	local int						OutRequiresLean;
	local UnitPeekSide				PeekSide;
	local CachedCoverAndPeekData	PeekData;
	local TTile						PeekTile;
	local TTile						BlockedTile;
	local TTile						TargetTile;
	local array<TTile>				Tiles;

	NewTargetLocation = Cursor.GetCursorFeetLocation();

	if (NewTargetLocation != CachedTargetLocation)
	{
		TargetTile = World.GetTileCoordinatesFromPosition(NewTargetLocation);
		
		World.CanSeeTileToTile(SourceTile, TargetTile, OutVisibilityInfo);			
		
		if (!OutVisibilityInfo.bClearLOS)
		{
			//  check left and right peeks
			FiringUnit.GetDirectionInfoForPosition(NewTargetLocation, OutVisibilityInfo, Direction, PeekSide, CanSeeFromDefault, OutRequiresLean, true);

			if (PeekSide == eNoPeek)
			{
				if (World.VoxelRaytrace_Tiles(SourceTile, TargetTile, Raytrace))
				{
					BlockedTile = Raytrace.BlockedTile;
					NewTargetLocation = World.GetPositionFromTileCoordinates(BlockedTile);
				}
			}
			else
			{
				PeekData = World.GetCachedCoverAndPeekData(SourceTile);
				if (PeekSide == ePeekLeft)
					PeekTile = PeekData.CoverDirectionInfo[Direction].LeftPeek.PeekTile;
				else
					PeekTile = PeekData.CoverDirectionInfo[Direction].RightPeek.PeekTile;

				if (World.VoxelRaytrace_Tiles(PeekTile, TargetTile, Raytrace))
				{
					BlockedTile = Raytrace.BlockedTile;
					NewTargetLocation = World.GetPositionFromTileCoordinates(BlockedTile);
				}
			}				
		}	

		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawSplashRadius();
		DrawAOETiles(Tiles);
	}

	super.UpdateTargetLocation(DeltaTime);
}

simulated protected function Vector GetSplashRadiusCenter( bool SkipTileSnap = false )
{
	local vector Center;
	local TTile SnapTile;

	Center = NewTargetLocation;

	if (SnapToTile && !SkipTileSnap)
	{
		SnapTile = `XWORLD.GetTileCoordinatesFromPosition( Center );
		
		// keep moving down until we find a floor tile.
		while ((SnapTile.Z >= 0) && !`XWORLD.GetFloorPositionForTile( SnapTile, Center ))
		{
			--SnapTile.Z;
		}
	}

	return Center;
}