class X2Condition_EffectGrantsThisTurn_MatchSource extends X2Condition;

struct CheckValue
{
	var name            EffectName;
	var CheckConfig     ConfigValue;
	var name            OptionalOverrideFalureCode;
};
var() array<CheckValue> m_aCheckValues;

function AddCheckValue(name EffectName, int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0, optional name OptionalOverrideFalureCode='')
{
	local CheckValue AddValue;
	AddValue.EffectName = EffectName;
	AddValue.ConfigValue.CheckType = CheckType;
	AddValue.ConfigValue.Value = Value;
	AddValue.ConfigValue.ValueMin = ValueMin;
	AddValue.ConfigValue.ValueMax = ValueMax;
	AddValue.OptionalOverrideFalureCode = OptionalOverrideFalureCode;
	m_aCheckValues.AddItem(AddValue);
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{
	local XComGameState_Unit	TargetUnit, SourceUnit;
	local XComGameState_Effect	EffectState;
	local name RetCode;
	local int i;
	
	TargetUnit = XComGameState_Unit(kTarget);
	SourceUnit = XComGameState_Unit(kSource);
	if (TargetUnit != none && SourceUnit != none)
	{
		RetCode = 'AA_Success';

		`AMLOG("X2Condition_EffectGrantsThisTurn_MatchSource: begin value check for effect: " @ m_aCheckValues[0].EffectName @ "on unit: " @ TargetUnit.GetFullName() @ "applied by:" @ SourceUnit.GetFullName());

		for (i = 0; i < m_aCheckValues.Length; i++)
		{
			for (i = 0; (i < m_aCheckValues.Length) && (RetCode == 'AA_Success'); i++)
			{
				EffectState = GetEffectState_MatchSource(TargetUnit, SourceUnit.ObjectID, m_aCheckValues[i].EffectName);
				if (EffectState == none)
				{
					`AMLOG("X2Condition_EffectGrantsThisTurn_MatchSource: effect is not present, exiting.");
					return 'AA_MissingRequiredEffect';
				}
				else
				{
					RetCode = PerformValueCheck(EffectState.GrantsThisTurn, m_aCheckValues[i].ConfigValue);

					`AMLOG("X2Condition_EffectGrantsThisTurn_MatchSource: found effect, current value: " @ EffectState.GrantsThisTurn @ "check value:" @ m_aCheckValues[i].ConfigValue.Value @ "check result:" @ RetCode);

					if (RetCode != 'AA_Success' && m_aCheckValues[i].OptionalOverrideFalureCode != '')
					{
						RetCode = m_aCheckValues[i].OptionalOverrideFalureCode;
					}
				}
			}
		}	

	}
	else return 'AA_NotAUnit';
	
	return RetCode;
}

private function XComGameState_Effect GetEffectState_MatchSource(const XComGameState_Unit TargetUnit, const int SourceUnitID, const name FindEffectName)
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