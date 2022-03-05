class XComGameState_ScentTracking extends XComGameState_BaseObject;

var array<XComGameStateContext_Ability>	ContextVault;
var InstancedTileComponent				TileComponent;

const MAX_CONTEXT_PER_UNIT = 3;
const TILE_MESH_PATH = "UI_3D.Tile.AOETile_Psy";
//const TILE_MESH_PATH = "TicketMachine_A.Meshes.Turnstile_A_2x";

final static function XComGameState_ScentTracking GetOrCreate(out XComGameState NewGameState)
{
	local XComGameStateHistory			History;
	local XComGameState_ScentTracking	StateObject;

	History = `XCOMHISTORY;

	StateObject = XComGameState_ScentTracking(History.GetSingleGameStateObjectForClass(class'XComGameState_ScentTracking', true));

	if (StateObject == none)
	{
		StateObject = XComGameState_ScentTracking(NewGameState.CreateNewStateObject(class'XComGameState_ScentTracking'));
		StateObject.Init();
	}
	else 
	{
		StateObject = XComGameState_ScentTracking(NewGameState.ModifyStateObject(class'XComGameState_ScentTracking', StateObject.ObjectID));		
	}
	return StateObject; 
}


final function Init()
{
	`LOG("Custom object init, have mesh:" @ StaticMesh(`CONTENT.RequestGameArchetype(TILE_MESH_PATH)) != none,, 'IRITEST');
	TileComponent = new class'InstancedTileComponent';
	TileComponent.SetMesh(StaticMesh(`CONTENT.RequestGameArchetype(TILE_MESH_PATH)));
	TileComponent.CustomInit();
}

final function Cleanup()
{
	TileComponent.Dispose();
}

final function AddContext(XComGameStateContext_Ability AbilityContext, XComGameState_Ability AbilityState)
{	
	if (ContextVault.Length == 0 && TileComponent != none)
	{
		`LOG("Setting mock ability",, 'IRITEST');
		TileComponent.SetMockParameters(AbilityState);
		TileComponent.InitFromState(AbilityState);
	}

	`LOG("Adding context for ability" @ AbilityContext.InputContext.AbilityTemplateName @ "with move tiles:" @ AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length,, 'IRITEST');
	ContextVault.AddItem(AbilityContext);
}

final function DrawTiles()
{
	local XComGameStateContext_Ability AbilityContext;
	//local array<TTile> TilesToUnite;
	local array<TTile> TilesToDraw;
	local array<TTile> MovementTiles;

	foreach ContextVault(AbilityContext)
	{
		
		`LOG("--Merging tiles" @ AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length,, 'IRIACTOR');
		MovementTiles = AbilityContext.InputContext.MovementPaths[0].MovementTiles;
		class'Helpers'.static.GetTileUnion(TilesToDraw, TilesToDraw, MovementTiles, false);

	}
	`LOG("Drawing united tiles" @ TilesToDraw.Length,, 'IRIACTOR');
	TileComponent.DrawAOETiles(TilesToDraw);
	TileComponent.SetVisible(true);
}

final function HideTiles()
{
	TileComponent.SetVisible(false);
}
