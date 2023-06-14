class X2AbilityCost_Ammo_ThunderLance extends X2AbilityCost_Ammo;

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Item LoadedAmmoState;
	local XComGameStateHistory History;
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit Unit;
	local int Cost;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	// RipJack has infinite ammo lol
	if (bFreeCost || /*AffectWeapon.HasInfiniteAmmo() ||*/ (`CHEATMGR != none && `CHEATMGR.bUnlimitedAmmo && Unit.GetTeam() == eTeam_XCom))	
		return;

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	Cost = CalcAmmoCost(kAbility, AffectWeapon, TargetState);

	kAbility.iAmmoConsumed = Cost;

	//  loaded ammo (aka grenades in a grenade launcher) track their own ammo, and we ignore the launcher's
	if (UseLoadedAmmo)
	{
		LoadedAmmoState = XComGameState_Item(History.GetGameStateForObjectID(kAbility.SourceAmmo.ObjectID));
		`AMLOG("Loaded ammo is:" @ LoadedAmmoState.GetMyTemplateName());
		if (LoadedAmmoState != None)
		{
			LoadedAmmoState = XComGameState_Item(NewGameState.ModifyStateObject(LoadedAmmoState.Class, LoadedAmmoState.ObjectID));
			LoadedAmmoState.Ammo -= Cost;
		}
	}
	else
	{
		AffectWeapon.Ammo -= Cost;
	}
}