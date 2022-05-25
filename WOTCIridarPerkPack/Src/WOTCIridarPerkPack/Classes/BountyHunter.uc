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
		return false;

	if (AbilityTemplate.Hostility != eHostility_Offensive)
		return false;

	if (X2AbilityTarget_Single(AbilityTemplate.AbilityTargetStyle) == none)
		return false;

	return true;
}
