class X2TargetingMethod_BountyHunter_ShadowTeleport extends X2TargetingMethod_MeleePath;

var private X2GrapplePuck GrapplePuck;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComPresentationLayer Pres;

	super(X2TargetingMethod).Init(InAction, NewTargetIndex);

	Pres = `PRES;

	Cursor = `CURSOR;
	PathingPawn = Cursor.Spawn(class'X2MeleePathingPawn_BountyHunter_ShadowTeleport', Cursor); // Use custom pathing pawn. Otherwise the same.
	PathingPawn.SetVisible(true);
	PathingPawn.Init(UnitState, Ability, self);
	IconManager = Pres.GetActionIconMgr();
	LevelBorderManager = Pres.GetLevelBorderMgr();

	// force the initial updates
	IconManager.ShowIcons(true);
	LevelBorderManager.ShowBorder(true);
	IconManager.UpdateCursorLocation(true);
	LevelBorderManager.UpdateCursorLocation(Cursor.Location, true);

	DirectSelectNearestTarget();

	//GrapplePuck = `CURSOR.Spawn(class'X2GrapplePuck', `CURSOR);
	//GrapplePuck.InitForUnitState(UnitState);
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	local array<TTile> PathTiles;
	local TTile FinalTile;

	TargetLocations.Length = 0;

	GetPreAbilityPath(PathTiles);
	if (PathTiles.Length > 0)
	{	
		FinalTile = PathTiles[PathTiles.Length - 1];
		TargetLocations.AddItem(`XWORLD.GetPositionFromTileCoordinates(FinalTile));

		`AMLOG("Setting target location as:" @ TargetLocations[0]);
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
function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	return TargetLocations.Length == 1 ? 'AA_Success' : 'AA_NoTargets';
}