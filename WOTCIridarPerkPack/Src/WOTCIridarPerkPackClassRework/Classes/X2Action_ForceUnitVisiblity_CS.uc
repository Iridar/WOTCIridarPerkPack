class X2Action_ForceUnitVisiblity_CS extends X2Action;

// Copied from Chimera Squad

var() EForceVisibilitySetting ForcedVisible;
var() bool bMatchToGameStateLoc;
var() bool bMatchToCustomTile;		// Should we move the unit to the custom specified tile
var() bool bMatchFacingToCustom;	// Should the units rotation be updated to custom directions
var() TTile CustomTileLocation;		// Location to move the unit
var() TTile CustomTileFacingTile;	// Target tile to face
var() vector CustomTileFacingVector;	// Vector to align with for custom facing

var private vector UpdatedLocation;

//------------------------------------------------------------------------------------------------

function Init()
{
	local XComGameState_Unit UnitState;
	local XComWorldData World;
	local vector DesiredFacingVector;

	super.Init();

	if( bMatchToGameStateLoc )
	{
		World = `XWORLD;

		UnitState = XComGameState_Unit(Metadata.StateObject_NewState);
		UpdatedLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);
		UpdatedLocation.Z = Unit.GetDesiredZForLocation(UpdatedLocation);

		UnitPawn.SetLocation(UpdatedLocation);
	}
	else if (bMatchToCustomTile)
	{
		World = `XWORLD;

		UnitState = XComGameState_Unit(Metadata.StateObject_NewState);
		UpdatedLocation = World.GetPositionFromTileCoordinates(CustomTileLocation);
		UpdatedLocation.Z = Unit.GetDesiredZForLocation(UpdatedLocation);

		UnitPawn.SetLocation(UpdatedLocation);

		if (bMatchFacingToCustom)
		{
			if (VSizeSq(CustomTileFacingVector) > 0)
			{
				DesiredFacingVector = CustomTileFacingVector;
				DesiredFacingVector.Z = 0.0f;
			}
			else
			{
				DesiredFacingVector = World.GetPositionFromTileCoordinates(CustomTileFacingTile) - World.GetPositionFromTileCoordinates(CustomTileLocation);
				DesiredFacingVector.Z = 0.0f;
			}
			UnitPawn.SetRotation(Rotator(DesiredFacingVector));
		}
	}

}

simulated state Executing
{
Begin:
	Unit.SetForceVisibility(ForcedVisible);
	Unit.GetPawn().UpdatePawnVisibility();
	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

defaultproperties
{
	bMatchToGameStateLoc=false
}