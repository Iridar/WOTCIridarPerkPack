class X2Effect_GrantCharges extends X2Effect;

// An effect for granting Charges to the specified ability.
// Base game already has functionality in the Charge Cost to grant additional initial charges if the soldier has a specified ability, 
// but I find that approach more fickle, since I would have to patch that Charge Cost, and there's no guarantee some other mod won't override my changes.

var name	AbilityName;
var int		NumCharges;
var bool	bMatchSourceWeapon;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit		UnitState;
	local XComGameState_Ability		AbilityState;
	local StateObjectReference		AbilityRef;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none)
		return;
		
	if (bMatchSourceWeapon)
	{
		AbilityRef = UnitState.FindAbility(AbilityName, ApplyEffectParameters.ItemStateObjectRef);
	}
	else
	{
		AbilityRef = UnitState.FindAbility(AbilityName);
	}
	if (AbilityRef.ObjectID == 0)
		return;
	
	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState != none)
		{
			AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		}
	}

	if (AbilityState == none)
		return;

	AbilityState.iCharges += NumCharges;
}
