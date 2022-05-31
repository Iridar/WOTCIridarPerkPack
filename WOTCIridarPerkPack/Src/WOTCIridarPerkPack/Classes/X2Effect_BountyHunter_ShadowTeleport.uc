//	Just like GetOverHere effect except the source jumps to the target
class X2Effect_BountyHunter_ShadowTeleport extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnitState;
	local TTile TeleportToTile;
	local vector Destination;
	local X2EventManager EventManager;

	SourceUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnitState == none)
		SourceUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	Destination = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	TeleportToTile = `XWORLD.GetTileCoordinatesFromPosition(Destination);

	SourceUnitState.SetVisibilityLocation(TeleportToTile);

	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('ObjectMoved', SourceUnitState, SourceUnitState, NewGameState);
	EventManager.TriggerEvent('UnitMoveFinished', SourceUnitState, SourceUnitState, NewGameState);
}

simulated function AddX2ActionsForVisualizationSource(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_GetOverThere GetOverThereAction;
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	Destination = ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	TeleportToTile = `XWORLD.GetTileCoordinatesFromPosition(Destination);

	GetOverThereAction = X2Action_GetOverThere(class'X2Action_GetOverThere'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));//auto-parent to damage initiating action
	GetOverThereAction.Destination = `XWORLD.GetPositionFromTileCoordinates(TeleportToTile);
	
}