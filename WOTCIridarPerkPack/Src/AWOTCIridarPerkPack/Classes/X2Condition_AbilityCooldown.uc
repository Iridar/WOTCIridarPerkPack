class X2Condition_AbilityCooldown extends X2Condition;

// This condition will check cooldowns of specified abilities.
// By default, passing at least one check is enough for condition to succeed.

var bool bAllChecksMustPass;

struct AbilityCooldownCheckValue
{
	var name            AbilityName;
	var CheckConfig     ConfigValue;
	var name            OptionalOverrideFalureCode;
};
var privatewrite array<AbilityCooldownCheckValue> m_aCheckValues;

function AddCheckValue(name AbilityName, int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0, optional name OptionalOverrideFalureCode='')
{
	local AbilityCooldownCheckValue AddValue;
	AddValue.AbilityName = AbilityName;
	AddValue.ConfigValue.CheckType = CheckType;
	AddValue.ConfigValue.Value = Value;
	AddValue.ConfigValue.ValueMin = ValueMin;
	AddValue.ConfigValue.ValueMax = ValueMax;
	AddValue.OptionalOverrideFalureCode = OptionalOverrideFalureCode;
	m_aCheckValues.AddItem(AddValue);
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Ability	AbilityState;
	local name	RetCode;
	local int	i;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)
		return 'AA_NotAUnit';

	for (i = 0; i < m_aCheckValues.Length; i++)
	{
		AbilityState = GetAbilityFromUnit(UnitState, m_aCheckValues[i].AbilityName);
		
		if (AbilityState != none)
		{
			RetCode = PerformValueCheck(AbilityState.iCooldown, m_aCheckValues[i].ConfigValue);
			if (RetCode == 'AA_Success')
			{
				return 'AA_Success';
			}
			else if (bAllChecksMustPass)
			{
				if (m_aCheckValues[i].OptionalOverrideFalureCode != '')
				{
					return m_aCheckValues[i].OptionalOverrideFalureCode;
				}
				else
				{
					return RetCode;
				}
			}
		}
		else if (bAllChecksMustPass)
		{
			return 'AA_AbilityUnavailable';
		}
	}	

	// If we're here, means that passing at least one check is enough (bAllChecksMustPass is false), 
	// but the unit doesn't have any of the abilities. Or no checks passed.
	return 'AA_AbilityUnavailable';
}

private function XComGameState_Ability GetAbilityFromUnit(const XComGameState_Unit UnitState, const name AbilityName, optional StateObjectReference MatchWeapon, optional XComGameState CheckGameState)
{
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability AbilityState;

	AbilityRef = UnitState.FindAbility(AbilityName, MatchWeapon);
	if (AbilityRef.ObjectID != 0)
	{
		if (CheckGameState != none)
		{
			AbilityState = XComGameState_Ability(CheckGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
		}
		else
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
		}
	}
	return AbilityState;
}