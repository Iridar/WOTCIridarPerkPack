class InstancedTileComponent extends X2TargetingMethod;

final function CustomInit()
{
    AOEMeshActor = `XWORLDINFO.Spawn(class'InstancedMeshActor');
}
 
final function SetMesh(StaticMesh Mesh)
{
    AOEMeshActor.InstancedMeshComponent.SetStaticMesh(Mesh);
}

// X2TargetingMethod requires that Ability is set. Do it with this function.
final function SetMockParameters(XComGameState_Ability AbilityState)
{
	Ability = AbilityState;
}

final function SetTiles(const out array<TTile> Tiles)
{
    DrawAOETiles(Tiles);
}
 
final function Dispose()
{
    AOEMeshActor.Destroy();
}

final function SetVisible(bool Visible)
{
	AOEMeshActor.SetVisible(Visible);
}

final function bool IsFullyInit()
{
	return Ability != none;
}