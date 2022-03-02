class X2AbilityCooldown_Shared extends X2AbilityCooldown;

var array<name> GlobalCooldownAbilities;
var int SharedCooldown;

simulated function ApplyCooldown(XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameStateContext_Ability	AbilityContext;

	super.ApplyCooldown(kAbility, AffectState, AffectWeapon, NewGameState);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext != None)
	{
		ApplyCooldownToSquadmates(AbilityContext.InputContext.AbilityTemplateName, kAbility.iCooldown, AffectState.ObjectID, NewGameState);
	}
}

// When an officer uses an officer ability, all other instances of this ability for other officers go on the same cooldown.
simulated final function ApplyCooldownToSquadmates(const name AbilityName, const int Cooldown, const int ExcludeUnitState, XComGameState NewGameState)
{	
	local XComGameState_Unit		UnitState;
	local StateObjectReference		UnitRef;
	local StateObjectReference		AbilityRef;
	local XComGameState_Ability		AbilityState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory		History;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;
	foreach XComHQ.Squad(UnitRef)
	{
		if (UnitRef.ObjectID == ExcludeUnitState)
			continue;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState == none)
			continue;

		AbilityRef = UnitState.FindAbility(AbilityName);
		if (AbilityRef.ObjectID > 0)
		{
			AbilityState = GetAbilityState(AbilityRef.ObjectID, NewGameState);
			if (AbilityState != none)
			{
				AbilityState.iCooldown = Cooldown;
			}
		}
	}
}

simulated final function XComGameState_Ability GetAbilityState(int ObjectID, XComGameState NewGameState)
{
	local XComGameState_Ability AbilityState;
	
	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ObjectID));
	if (AbilityState != none)
		return AbilityState;

	return XComGameState_Ability(NewGameState.ModifyStateObject(class'XComGameState_Ability', ObjectID));
}