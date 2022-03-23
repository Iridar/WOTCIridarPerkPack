class XComGameState_ScentTracking extends XComGameState_BaseObject;

var array<XComGameStateContext_Ability>	ContextVault;

const MAX_CONTEXT_PER_UNIT = 3;

final static function XComGameState_ScentTracking GetOrCreate(out XComGameState NewGameState)
{
	local XComGameStateHistory			History;
	local XComGameState_ScentTracking	StateObject;

	History = `XCOMHISTORY;

	StateObject = XComGameState_ScentTracking(History.GetSingleGameStateObjectForClass(class'XComGameState_ScentTracking', true));

	if (StateObject == none)
	{
		StateObject = XComGameState_ScentTracking(NewGameState.CreateNewStateObject(class'XComGameState_ScentTracking'));
	}
	else 
	{
		StateObject = XComGameState_ScentTracking(NewGameState.ModifyStateObject(class'XComGameState_ScentTracking', StateObject.ObjectID));		
	}
	return StateObject; 
}

final function AddContext(XComGameStateContext_Ability AbilityContext)
{	
	`LOG("Adding context for ability" @ AbilityContext.InputContext.AbilityTemplateName @ "with move tiles:" @ AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length,, 'IRITEST');
	ContextVault.AddItem(AbilityContext);
}

final function GetTiles(out array<TTile> TilesToDraw)
{
	local XComGameStateContext_Ability AbilityContext;
	local array<TTile> MovementTiles;

	foreach ContextVault(AbilityContext)
	{
		`LOG("--Merging tiles" @ AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length,, 'IRIACTOR');
		MovementTiles = AbilityContext.InputContext.MovementPaths[0].MovementTiles;
		class'Helpers'.static.GetTileUnion(TilesToDraw, TilesToDraw, MovementTiles, false);
	}
}