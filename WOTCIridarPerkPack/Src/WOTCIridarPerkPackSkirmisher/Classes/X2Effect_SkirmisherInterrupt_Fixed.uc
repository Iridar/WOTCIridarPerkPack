class X2Effect_SkirmisherInterrupt_Fixed extends X2Effect_SkirmisherInterrupt;

// Interrupts initiative turn; for use only with Forward Operator

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local XComGameStateHistory	History;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_AIGroup	GroupState;

	`AMLOG("Running");

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit == none)
		return;

	`AMLOG("TargetUnit" @ TargetUnit.GetFullName());

	GroupState = TargetUnit.GetGroupMembership();
	if (GroupState == none)
		return;

	`AMLOG("Have group state");

	TargetUnit.SetUnitFloatValue('SkirmisherInterruptOriginalGroup', GroupState.ObjectID, eCleanup_BeginTactical);

	// ---- Start New Code ---
	// Search for other units on the same team also affected by the Interrupt effect,
	// and if there are any, add the TargetUnit to the same group.
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (!UnitState.IsUnitAffectedByEffectName(EffectName))
			continue;

		if (UnitState.IsDead() || !UnitState.IsInPlay())
			continue;

		if (UnitState.GetTeam() != TargetUnit.GetTeam())
			continue;

		GroupState = UnitState.GetGroupMembership();
		if (GroupState == none)
			continue;

		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(GroupState.Class, GroupState.ObjectID));	
		GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);

		`TACTICALRULES.InterruptInitiativeTurn(NewGameState, GroupState.GetReference());
		return;
	}
	// ---- End New Code ---

	`AMLOG("Creating new group state");

	GroupState = XComGameState_AIGroup(NewGameState.CreateNewStateObject(class'XComGameState_AIGroup'));	
	GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
	GroupState.bSummoningSicknessCleared = true;

	`TACTICALRULES.InterruptInitiativeTurn(NewGameState, GroupState.GetReference());
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit	TargetUnit;
	local XComGameState_AIGroup	GroupState;
	local UnitValue				GroupValue;

	`AMLOG("Running");

	TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`AMLOG("TargetUnit" @ TargetUnit.GetFullName());
	if (TargetUnit != none && TargetUnit.GetUnitValue('SkirmisherInterruptOriginalGroup', GroupValue))
	{
		GroupState = TargetUnit.GetGroupMembership();
		if (GroupState.m_arrMembers.Length == 1 && GroupState.m_arrMembers[0].ObjectID == TargetUnit.ObjectID)
		{
			NewGameState.RemoveStateObject(GroupState.ObjectID);
		}

		`AMLOG("Restoring original group");
		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupValue.fValue));
		GroupState.AddUnitToGroup(TargetUnit.ObjectID, NewGameState);
		TargetUnit.ClearUnitValue('SkirmisherInterruptOriginalGroup');
	}
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	local UnitValue				GroupValue;
	local XComGameState_AIGroup	GroupState;

	GroupState = UnitState.GetGroupMembership();
	UnitState.GetUnitValue('SkirmisherInterruptOriginalGroup', GroupValue);

	if (GroupState.ObjectID != GroupValue.fValue && UnitState.IsAbleToAct())
	{
		ActionPoints.Length = 0;
		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	}	
}
