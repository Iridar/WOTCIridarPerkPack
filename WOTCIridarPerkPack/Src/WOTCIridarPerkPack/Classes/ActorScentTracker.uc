class ActorScentTracker extends Actor;

//var int CachedUnitObjectID;

event Tick(float DeltaTime)
{
	local XGUnit						ActiveUnit;
	local XComGameState_Unit			UnitState;
	local XComTacticalController		TacticalController;
	local XComGameStateHistory			History;
	local XComGameState_ScentTracking	ScentTracking;

	TacticalController = XComTacticalController(GetALocalPlayerController());
	if (TacticalController == none)
		return;

	ActiveUnit = TacticalController.GetActiveUnit();
	if (ActiveUnit == none /*|| ActiveUnit.ObjectID == CachedUnitObjectID*/)
		return;

	History = `XCOMHISTORY;
	//CachedUnitObjectID = ActiveUnit.ObjectID;

	ScentTracking = XComGameState_ScentTracking(History.GetSingleGameStateObjectForClass(class'XComGameState_ScentTracking', true));
	`LOG(GetFuncName() @ "Got Scent Tracking:" @ ScentTracking != none,, 'IRIACTOR');
	if (ScentTracking == none)
		return;
	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActiveUnit.ObjectID));
	`LOG(GetFuncName() @ "Active Unit:" @ UnitState.GetFullName() @ "has ability:" @ UnitState.HasAbilityFromAnySource('IRI_ScentTracking'),, 'IRIACTOR');
	if (UnitState != none && UnitState.HasAbilityFromAnySource('IRI_ScentTracking'))
	{
		`LOG("Drawing tiles",, 'IRIACTOR');
		ScentTracking.DrawTiles();
	}
	else
	{
		`LOG("Hiding tiles",, 'IRIACTOR');
		ScentTracking.HideTiles();
	}	
}
