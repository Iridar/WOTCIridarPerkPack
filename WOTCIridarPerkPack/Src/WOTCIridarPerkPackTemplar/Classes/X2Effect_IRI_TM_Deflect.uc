class X2Effect_IRI_TM_Deflect extends X2Effect_Persistent;

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	local UnitValue UV;

	return TargetUnit.GetUnitValue('IRI_TM_Deflect', UV); 
}

function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult)
{
	local UnitValue UV;

	`LOG("X2Effect_IRI_TM_Deflect::ChangeHitResultForTarget",, 'XCom_HitRolls');

	//	Don't Deflect attacks that will be Reflected.
	if (TargetUnit.GetUnitValue('IRI_TM_Reflect', UV))
		return false;

	//	Don't Deflect attacks that will be Parried.
	if (TargetUnit.GetUnitValue('Parry', UV))
		return false;
		
	// Don't Deflect if Templar is discombombulated.
	if (!TargetUnit.IsAbleToAct())
		return false;
	
	// Don't Deflect if Deflect isn't primed.
	if (!TargetUnit.GetUnitValue('IRI_TM_Deflect', UV))
	{
		`LOG("Deflect not available.",, 'XCom_HitRolls');
		return false;
	}

	`LOG("Deflect available - using!",, 'XCom_HitRolls');
	NewHitResult = eHit_Deflect;
	TargetUnit.ClearUnitValue('IRI_TM_Deflect');

	return true;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_IRI_TM_Deflect_Effect"
}
