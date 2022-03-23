class ActorScentTracker extends Actor;

var int CachedUnitObjectID;

var InstancedTileComponent TileComponent;

const TILE_MESH_PATH = "UI_3D.Tile.AOETile_Psy";

var array<int> UnitsWithAbility;
var array<int> UnitsWithoutAbility;

var bool bTilesShown;

event PostBeginPlay()
{
	local XComGameStateHistory History;

	TileComponent = new class'InstancedTileComponent';
	TileComponent.CustomInit();
	TileComponent.SetMesh(StaticMesh(`CONTENT.RequestGameArchetype(TILE_MESH_PATH)));

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Ability', AbilityState)
	{
		//TileComponent.InitFromState(AbilityState);
		TileComponent.SetMockParameters(AbilityState);
		`LOG("Init ability:" @ AbilityState.GetMyTemplateName(),, 'IRIACTOR');
		break;
	}
}

event Destroyed()
{
	TileComponent.Dispose();
	super.Destroyed();
}

event Tick(float DeltaTime)
{
	local XGUnit						ActiveUnit;
	local XComGameState_Unit			UnitState;
	local XComTacticalController		TacticalController;
	local XComGameStateHistory			History;
	local XComGameState_ScentTracking	ScentTracking;
	local array<TTile>					TilesToDraw;
	local XComGameState_Ability			AbilityState;
	local bool							bShouldShowTiles;

	TacticalController = XComTacticalController(GetALocalPlayerController());
	if (TacticalController == none)
		return;

	ActiveUnit = TacticalController.GetActiveUnit();
	if (ActiveUnit == none || UnitsWithoutAbility.Find(ActiveUnit.ObjectID) != INDEX_NONE)
		return;

	History = `XCOMHISTORY;
	ScentTracking = XComGameState_ScentTracking(History.GetSingleGameStateObjectForClass(class'XComGameState_ScentTracking', true));
	if (ScentTracking == none)
		return;
	
	if (UnitsWithAbility.Find(ActiveUnit.ObjectID) == INDEX_NONE)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActiveUnit.ObjectID));
		if (UnitState != none)
		{
			if (UnitState.HasAbilityFromAnySource('IRI_ScentTracking'))
			{
				UnitsWithAbility.AddItem(UnitState.ObjectID);
				bShouldShowTiles = true;
			}
			else
			{
				UnitsWithoutAbility.AddItem(UnitState.ObjectID);
				bShouldShowTiles = false;
			}
		}
		else
		{
			bShouldShowTiles = false;
		}
	}
	else
	{
		bShouldShowTiles = true;
	}
	

	// TODO: This needs to be finished and optimized. Rotate static mesh with footstep texture.
	if (bShouldShowTiles)
	{
		if (bTilesShown)
		{
			if (CachedUnitObjectID == 
			return;
		}
		else
		{
		}
		`LOG("Drawing tiles",, 'IRIACTOR');
		ScentTracking.GetTiles(TilesToDraw);

		`LOG("Drawing united tiles" @ TilesToDraw.Length,, 'IRIACTOR');
		TileComponent.SetVisible(true);
		TileComponent.SetTiles(TilesToDraw);
		TileComponent.SetVisible(true);
	}
	else
	{
		`LOG("Hiding tiles",, 'IRIACTOR');
		TileComponent.SetVisible(false);
	}	
}
