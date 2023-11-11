class X2Effect_ClearUnitValue extends X2Effect;

var name UnitValueName;
var bool bSource;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	if (bSource)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}
	else
	{
		UnitState = XComGameState_Unit(kNewTargetState);
	}

	if (UnitState != none)
	{
		UnitState.ClearUnitValue(UnitValueName);
	}
}