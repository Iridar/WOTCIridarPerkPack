class X2BountyHunter_ShadowTeleport_PuckActor extends Actor;

var X2AbilityTemplate AbilityTemplate;
var XComWorldData World;

var float UnitSize;

var protected X2FadingStaticMeshComponent	SlashingMeshComponent;
var protected X2FadingStaticMeshComponent	PuckMeshComponent;
var protected X2FadingStaticMeshComponent	PuckMeshCircleComponent;

var protected StaticMesh					PuckMeshSlashing;
var protected StaticMesh					PuckMeshConfirmedSlashing;
var protected StaticMesh					PuckMeshNormal;
var protected StaticMesh					PuckMeshConfirmed;
var protected StaticMesh					PuckMeshCircle; 
var protected StaticMesh					PuckMeshCircleDashing;

final function UpdatePuckVisuals(const out TTile LastSelectedTile, XGUnit TargetGameUnit)
{
	local vector	MeshTranslation;
	local Rotator	MeshRotation;	
	local vector	MeshScale;
	local vector	FromTargetTile;

	MeshTranslation = TargetGameUnit.GetPawn().CollisionComponent.Bounds.Origin;
	MeshTranslation.Z = World.GetFloorZForPosition(MeshTranslation);

	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	//OutOfRangeMeshComponent.SetHidden(true);
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	`AMLOG("Moving melee puck to:" @ MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	FromTargetTile = World.GetPositionFromTileCoordinates(LastSelectedTile) - MeshTranslation; 
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
	SlashingMeshComponent.SetRotation(MeshRotation);
	SlashingMeshComponent.SetScale(UnitSize);
	
	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	
	MeshTranslation = World.GetPositionFromTileCoordinates(LastSelectedTile); // make sure we line up perfectly with the end of the path ribbon
	MeshTranslation.Z = World.GetFloorZForPosition(MeshTranslation);
	PuckMeshComponent.SetTranslation(MeshTranslation);

	MeshScale.X = UnitSize; // Should use casting unit unit size?
	MeshScale.Y = UnitSize; // Should use casting unit unit size?
	MeshScale.Z = 1.0f;
	PuckMeshComponent.SetScale3D(MeshScale);

	if(`ISCONTROLLERACTIVE)
	{
		PuckMeshCircleComponent.SetHidden(false);
		
		PuckMeshCircleComponent.SetTranslation(MeshTranslation);
		PuckMeshCircleComponent.SetScale3D(MeshScale);
	}
}

private function StaticMesh GetMeleePuckMeshForAbility() 
{
	local StaticMesh PuckMesh;
	local string PuckMeshPath;

	if (AbilityTemplate == none || AbilityTemplate.MeleePuckMeshPath == "")
	{
		PuckMeshPath = "UI_3D.CursorSet.S_MovePuck_Slash";
	}
	else
	{
		PuckMeshPath = AbilityTemplate.MeleePuckMeshPath;
	}

	PuckMesh = StaticMesh(DynamicLoadObject(PuckMeshPath, class'StaticMesh'));
	if(PuckMesh == none)
	{
		`Redscreen("Could not load melee puck mesh for ability " $ AbilityTemplate.DataName);
		PuckMesh = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuck_Slash", class'StaticMesh'));
	}

	return PuckMesh;
}

final function CachePuckMeshes()
{
	PuckMeshSlashing = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.CoverChargeAndSlash", class'StaticMesh'));
	PuckMeshConfirmedSlashing = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.CoverChargeAndSlash_Confirm", class'StaticMesh'));
	SlashingMeshComponent.SetStaticMeshes(PuckMeshSlashing, PuckMeshConfirmedSlashing);

	PuckMeshNormal = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuck", class'StaticMesh'));
	PuckMeshConfirmed = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuck_Confirm", class'StaticMesh'));
	PuckMeshComponent.SetStaticMeshes(PuckMeshNormal, PuckMeshConfirmed);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(), PuckMeshConfirmed);

	if(`ISCONTROLLERACTIVE)
	{
		PuckMeshCircle = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuckCircle", class'StaticMesh'));
		PuckMeshCircleDashing = StaticMesh(DynamicLoadObject("UI_3D.CursorSet.S_MovePuckCircle_Dashing", class'StaticMesh'));
		PuckMeshCircleComponent.SetStaticMesh(PuckMeshCircle);
		PuckMeshCircleComponent.SetStaticMesh(GetMeleePuckMeshForAbility());
	}
}