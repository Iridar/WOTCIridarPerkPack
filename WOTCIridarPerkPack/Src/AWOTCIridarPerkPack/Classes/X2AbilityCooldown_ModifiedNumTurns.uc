class X2AbilityCooldown_ModifiedNumTurns extends X2AbilityCooldown;

/*
struct AdditionalCooldownInfo
{
	var() name AbilityName;
	var() int NumTurns;
};*/

var array<AdditionalCooldownInfo> ModifyCooldownAbilities;

simulated function int GetNumTurns(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit		UnitState;
	local AdditionalCooldownInfo	ModifyCooldownAbility;
	local int						ModifiedNumTurns;

	ModifiedNumTurns = iNumTurns;
	UnitState = XComGameState_Unit(AffectState);
	if (UnitState != none)
	{
		foreach ModifyCooldownAbilities(ModifyCooldownAbility)
		{
			if (UnitState.HasAbilityFromAnySource(ModifyCooldownAbility.AbilityName))
			{
				ModifiedNumTurns -= ModifyCooldownAbility.NumTurns;
			}
		}
	}
	if (ModifiedNumTurns < 0)
		ModifiedNumTurns = 0;

	return ModifiedNumTurns;
}
