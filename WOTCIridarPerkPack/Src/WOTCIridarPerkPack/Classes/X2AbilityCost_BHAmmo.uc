class X2AbilityCost_BHAmmo extends X2AbilityCost_Ammo;

simulated function int CalcAmmoCost(XComGameState_Ability Ability, XComGameState_Item ItemState, XComGameState_BaseObject TargetState)
{
	local XComGameState_Unit SourceUnit;
	
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Ability.OwnerStateObject.ObjectID));
	if (SourceUnit != none && SourceUnit.IsConcealed() && SourceUnit.HasSoldierAbility('IRI_BH_ShadowRounds_Passive'))
	{
		//`AMLOG("Returning 0 ammo cost because unit is concealed");
		return 0;
	}
	//`AMLOG("Unit is not concealed, returning ammo cost:" @ super.CalcAmmoCost(Ability, ItemState, TargetState));
	return super.CalcAmmoCost(Ability, ItemState, TargetState);
}

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
	if (ActivatingUnit.IsConcealed() && ActivatingUnit.HasSoldierAbility('IRI_BH_ShadowRounds_Passive'))
	{
		//`AMLOG("Unit is concealed, can afford by default");
		return 'AA_Success';
	}
	//`AMLOG("Unit is not concealed, can afford:" @ super.CanAfford(kAbility, ActivatingUnit));
	return super.CanAfford(kAbility, ActivatingUnit);
}

defaultproperties
{
	iAmmo = 1
}