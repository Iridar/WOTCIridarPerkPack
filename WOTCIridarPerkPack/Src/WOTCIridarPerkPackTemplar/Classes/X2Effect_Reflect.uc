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

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_Reflect"
}
