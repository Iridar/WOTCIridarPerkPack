class X2Effect_Siphon extends X2Effect_RemoveEffects;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	SourceUnit;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Effect	EffectState;
	local array<XComGameState_Effect>	EffectStates;
	local X2Effect_Persistent	PersistentEffect;
	local StateObjectReference	EffectRef;
	local XComGameStateHistory	History;
	local bool					bRemoveEffect;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return;

	History = `XCOMHISTORY;
	foreach TargetUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState == none || EffectState.bRemoved)
			continue;

		PersistentEffect = EffectState.GetX2Effect();
		if (PersistentEffect == none)
			continue;

		bRemoveEffect = false;
		if (`GetConfigBool("IRI_TM_Siphon_AllowFreeze"))
		{
			if (PersistentEffect.DamageTypes.Find('Frost') != INDEX_NONE)
			{
				SourceUnit.SetUnitFloatValue('IRI_TM_Siphon_Frost', 1, eCleanup_BeginTactical);
				bRemoveEffect = true;
			}
		}
		if (PersistentEffect.DamageTypes.Find('fire') != INDEX_NONE)
		{
			SourceUnit.SetUnitFloatValue('IRI_TM_Siphon_fire', 1, eCleanup_BeginTactical);
			bRemoveEffect = true;
		}
		if (PersistentEffect.DamageTypes.Find('poison') != INDEX_NONE)
		{
			SourceUnit.SetUnitFloatValue('IRI_TM_Siphon_poison', 1, eCleanup_BeginTactical);
			bRemoveEffect = true;
		}
		if (PersistentEffect.DamageTypes.Find(class'X2Effect_ParthenogenicPoison'.default.ParthenogenicPoisonType) != INDEX_NONE)
		{
			SourceUnit.SetUnitFloatValue('IRI_TM_Siphon_poison', 1, eCleanup_BeginTactical);
			bRemoveEffect = true;
		}
		if (PersistentEffect.DamageTypes.Find('acid') != INDEX_NONE)
		{
			SourceUnit.SetUnitFloatValue('IRI_TM_Siphon_acid', 1, eCleanup_BeginTactical);
			bRemoveEffect = true;
		}
		if (bRemoveEffect)
		{
			EffectStates.AddItem(EffectState);

			// For some bizarre reason this stops the iterator.
			// Addendum: presumably because this removes a member from the AffectedByEffects array.
			// In the future if you need to iterate over an array of applied effects and remove some,
			// try using for() from the end.
			//EffectState.RemoveEffect(NewGameState, NewGameState, true);
		}
	}

	foreach EffectStates(EffectState)
	{
		EffectState.RemoveEffect(NewGameState, NewGameState, true);
	}
}
