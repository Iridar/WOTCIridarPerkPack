class X2Effect_AdditionalAbilityDamagePreview extends X2Effect;

// When attached to an ability, this effect will add the damage of *another* specified ability into its damage preview.

var name AbilityName;
var bool bMatchSourceWeapon;

simulated function GetDamagePreview(StateObjectReference TargetRef, XComGameState_Ability AbilityState, bool bAsPrimaryTarget, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameState_Unit	AbilityOwner;
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability AdditionalAbilityState;
	local XComGameStateHistory	History;

	History = `XCOMHISTORY;
	AbilityOwner = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (AbilityOwner != none)
	{
		if (bMatchSourceWeapon)
		{
			AbilityRef = AbilityOwner.FindAbility(AbilityName, AbilityState.SourceWeapon);
		}
		else
		{
			AbilityRef = AbilityOwner.FindAbility(AbilityName);
		}
			
		if (AbilityRef.ObjectID != 0)
		{
			AdditionalAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AdditionalAbilityState != none)
			{
				AdditionalAbilityState.NormalDamagePreview(TargetRef, MinDamagePreview, MaxDamagePreview, AllowsShield);
			}
		}
	}
}


