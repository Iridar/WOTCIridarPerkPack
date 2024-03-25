class X2Condition_Concentration extends X2Condition;

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{
	local XComGameState_Unit	SourceUnit;
	//local XComGameState_Unit	TargetUnit;
	//local XComGameStateHistory	History;
	//local XComGameState_Effect	EffectState;
	//local StateObjectReference	EffectRef;
	
	SourceUnit = XComGameState_Unit(kSource);
	if (SourceUnit == none)
		return 'AA_NotAUnit';

	if (!SourceUnit.HasSoldierAbility('IRI_TM_Concentration'))
	{
		return 'AA_AbilityUnavailable';
	}

	// Check if the source unit is already applying this effect to any target
	if (SourceUnit.AppliedEffectNames.Find('IRI_TM_Concentration_Effect') != INDEX_NONE)
	{
		return 'AA_DuplicateEffectIgnored';
	}

	//History = `XCOMHISTORY;
	//foreach SourceUnit.AppliedEffects(EffectRef)
	//{
	//	EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
	//	if (EffectState == none || EffectState.bRemoved)
	//		continue;
	//
	//	if (EffectState.GetX2Effect().EffectName == 'IRI_TM_Concentration_Effect')
	//	{
	//		return 'AA_DuplicateEffectIgnored';
	//	}
	//}

	//TargetUnit = XComGameState_Unit(kTarget);
	//if (TargetUnit == none)
	//	return 'AA_NotAUnit';
	//
	//foreach TargetUnit.AffectedByEffects(EffectRef)
	//{
	//	EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
	//	if (EffectState == none || EffectState.bRemoved)
	//		continue;
	//
	//	if (EffectState.GetX2Effect().EffectName != 'IRI_TM_Concentration_Effect')
	//		continue;
	//
	//	if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == kSource.ObjectID)
	//	{
	//		return 'AA_DuplicateEffectIgnored';
	//	}
	//}

	return 'AA_Success';
}
