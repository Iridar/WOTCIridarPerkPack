class BountyHunter extends Object abstract;

static final function bool IsAbilityValidForDeadlierShadow(const XComGameState_Ability AbilityState)
{
	local X2AbilityTemplate Template;

	Template = AbilityState.GetMyTemplate();

	return Template.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) && Template.Hostility == eHostility_Offensive;
}

static final function bool IsAbilityValidForFollowthrough(const XComGameState_Ability AbilityState)
{
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return false;

	if (!AbilityTemplate.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it doesn't deal damage.");
		return false;
	}
	if (AbilityTemplate.Hostility != eHostility_Offensive)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it's not offensive.");
		return false;
	}
	if (X2AbilityTarget_Single(AbilityTemplate.AbilityTargetStyle) == none)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it's not single target style.");
		return false;
	}
	return true;
}