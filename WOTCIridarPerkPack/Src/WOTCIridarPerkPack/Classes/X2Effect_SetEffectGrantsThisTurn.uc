class X2Effect_SetEffectGrantsThisTurn extends X2Effect;

var name EffectName;
var int iValue;
var bool bIncrease;
var bool bReduce;
var bool bSet;
var bool bMatchSource;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Effect	ChangeEffectState;

	UnitState = XComGameState_Unit(kNewTargetState);
	
	if (UnitState != none)
	{
		if (bMatchSource)
		{
			ChangeEffectState = GetEffectState_MatchSource(UnitState, ApplyEffectParameters.SourceStateObjectRef.ObjectID, EffectName);
		}
		else ChangeEffectState = UnitState.GetUnitAffectedByEffectState(EffectName);

		if (ChangeEffectState != none)
		{
			`AMLOG("X2Effect_SetEffectGrantsThisTurn: found effect: " @ EffectName @ "on unit: " @ UnitState.GetFullName() @ "current value: " @ ChangeEffectState.GrantsThisTurn);
			ChangeEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(class'XComGameState_Effect', ChangeEffectState.ObjectID));
			if (bSet)
			{
				ChangeEffectState.GrantsThisTurn = iValue;
			}
			if (bIncrease) 
			{
				ChangeEffectState.GrantsThisTurn++;
			}
			if (bReduce)
			{
				ChangeEffectState.GrantsThisTurn--;
			}

			`AMLOG("X2Effect_SetEffectGrantsThisTurn: new GrantsThisTurn value: " @ ChangeEffectState.GrantsThisTurn);
		}
	}
}

static private function XComGameState_Effect GetEffectState_MatchSource(const XComGameState_Unit TargetUnit, const int SourceUnitID, const name FindEffectName)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach TargetUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none && EffectState.GetX2Effect().EffectName == FindEffectName && EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == SourceUnitID)
		{
			return EffectState;
		}
	}

	return none;
}

defaultproperties
{
	
}