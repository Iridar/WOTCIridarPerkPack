class X2GrapplePuck_ThunderLance extends X2GrapplePuck;

function InitForUnitState(XComGameState_Unit InUnitState)
{
	local XComWorldData WorldData;
	local StaticMesh PuckMesh;
	local StaticMesh PuckMeshConfirmed;
	local TTile SelectedTile;

	UnitState = InUnitState;

	InstancedMeshComponent.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Tile.AOETile", class'StaticMesh')));
	InstancedMeshComponent.SetAbsolute(true, true);

	// load the resources for our components
	GrapplePath.SetMaterial(MaterialInterface(DynamicLoadObject(PathMaterialName, class'MaterialInterface')));

	PuckMesh = StaticMesh(DynamicLoadObject(PuckMeshName, class'StaticMesh'));
	PuckMeshConfirmed = StaticMesh(DynamicLoadObject(PuckMeshConfirmedName, class'StaticMesh'));
	GrapplePuck.SetStaticMeshes(PuckMesh, PuckMeshConfirmed);
	OutOfRangeGrapplePuck.SetStaticMeshes(PuckMesh, PuckMeshConfirmed);
	
	WaypointMesh.Init();

	// get all valid grapple location
	HasGrappleLocations(UnitState, GrappleLocations);

	// add tiles for all grapple locations to the grid component
	FillOutGridComponent();

	// and select the default grapple destination (if any)
	if(GrappleLocations.Length > 0)
	{
		//SelectClosestGrappleLocationToUnit();

		// if the controller is active, snap it to the location we just picked
		if(`ISCONTROLLERACTIVE)
		{
			WorldData = `XWORLD;
			SelectedTile = GrappleLocations[SelectedGrappleLocation].Tile;
			Cursor.CursorSetLocation(WorldData.GetPositionFromTileCoordinates(SelectedTile), true);

			// these should probably be added to CursorSetLocation, but in the interests of changing as little
			// as possible for the controller patch, just setting them here.
			Cursor.m_iRequestedFloor = Cursor.WorldZToFloor(Cursor.Location);
			Cursor.m_iLastEffectiveFloorIndex = Cursor.m_iRequestedFloor;
			Cursor.m_bCursorLaunchedInAir = false;
		}
	}
}