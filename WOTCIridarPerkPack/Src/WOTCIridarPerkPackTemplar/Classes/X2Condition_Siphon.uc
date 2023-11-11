class X2Condition_Siphon extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Effect	EffectState;
	local X2Effect_Persistent	PersistentEffect;
	local StateObjectReference	EffectRef;
	local XComGameStateHistory	History;
	
	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)
		return 'AA_NotAUnit';
	
	History = `XCOMHISTORY;
	foreach UnitState .AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState == none || EffectState.bRemoved)
			continue;

		PersistentEffect = EffectState.GetX2Effect();
		if (PersistentEffect == none)
			continue;

		if (PersistentEffect.DamageTypes.Find('Frost') != INDEX_NONE)
			return 'AA_Success'; 

		if (PersistentEffect.DamageTypes.Find('fire') != INDEX_NONE)
			return 'AA_Success'; 

		if (PersistentEffect.DamageTypes.Find('poison') != INDEX_NONE)
			return 'AA_Success'; 

		if (PersistentEffect.DamageTypes.Find(class'X2Effect_ParthenogenicPoison'.default.ParthenogenicPoisonType) != INDEX_NONE)
			return 'AA_Success'; 

		if (PersistentEffect.DamageTypes.Find('acid') != INDEX_NONE)
			return 'AA_Success'; 
	}

	return 'AA_MissingRequiredEffect'; 
}
