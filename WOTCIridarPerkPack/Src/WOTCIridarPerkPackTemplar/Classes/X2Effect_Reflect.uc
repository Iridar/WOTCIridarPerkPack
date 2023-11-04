class X2Effect_Reflect extends X2Effect_Persistent;

function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{
	local UnitValue ReflectUnitValue;

	`LOG("X2Effect_Reflect::ChangeHitResultForTarget",, 'XCom_HitRolls');

	//	check for Reflect - if the unit value is set, then a Reflect is guaranteed
	if (TargetUnit.GetUnitValue('IRI_TM_Reflect', ReflectUnitValue) && TargetUnit.IsAbleToAct())
	{
		if (ReflectUnitValue.fValue > 0)
		{
			`LOG("Reflect available - using!",, 'XCom_HitRolls');
			NewHitResult = eHit_Reflect;
			TargetUnit.SetUnitFloatValue('IRI_TM_Reflect', ReflectUnitValue.fValue - 1);
			return true;
		}
	}
	
	`LOG("Reflect not available.",, 'XCom_HitRolls');
	return false;
}
/*
static private function ReflectEffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Effect_TemplarFocus	FocusState;
	local XComGameState_Unit				UnitState;
	local UnitValue							UV;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}
	if (UnitState == none)
		return;

	UnitState.GetUnitValue('IRI_TM_Reflect', UV);
	if (UV.fValue == 0)
		return;

	FocusState = UnitState.GetTemplarFocusEffectState();
	if (FocusState != none)
	{
		FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
		FocusState.SetFocusLevel(FocusState.FocusLevel + UV.fValue, UnitState, NewGameState);		
	}
}*/

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_Reflect"
	//EffectRemovedFn = ReflectEffectRemoved;
}
