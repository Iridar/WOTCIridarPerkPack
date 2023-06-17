class X2Effect_KineticArmor extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState					AttackGameState;
	local XComGameState_Ability			AbilityState;
	local XComGameStateHistory			History;
	local WeaponDamageValue				MinDamage;
	local WeaponDamageValue				MaxDamage;
	local StatChange					NewStatChange;
	local int							AllowShield;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none)
		return;
	
	History = `XCOMHISTORY;

	AttackGameState = History.GetGameStateFromHistory(AbilityContext.DesiredVisualizationBlockIndex);
	if (AttackGameState == none)
		return;

	AbilityContext = XComGameStateContext_Ability(AttackGameState.GetContext());
	if (AbilityContext == none)
		return;

	AbilityState = XComGameState_Ability(AttackGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	AbilityState.GetDamagePreview(ApplyEffectParameters.SourceStateObjectRef, MinDamage, MaxDamage, AllowShield);

	NewStatChange.StatType = eStat_ShieldHP;
	NewStatChange.StatAmount = int(float(MaxDamage.Damage + MinDamage.Damage) / 2.0f);
	NewEffectState.StatChanges.AddItem(NewStatChange);

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_KineticArmor_Effect"
}