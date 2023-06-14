class X2AbilityTarget_ThunderLance extends X2AbilityTarget_Cursor;

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Item SourceWeapon;
	local int RangeInTiles;
	local float RangeInMeters;

	if (bRestrictToWeaponRange)
	{
		SourceWeapon = AbilityState.GetSourceAmmo(); //AbilityState.GetSourceWeapon(); - use grenade range instead of ripjack range
		if (SourceWeapon != none)
		{
			RangeInTiles = SourceWeapon.GetItemRange(AbilityState);

			RangeInTiles += `GetConfigInt("IRI_SK_ThunderLance_RangeIncrase_Tiles");

			if( RangeInTiles == 0 )
			{
				// This is melee range
				RangeInMeters = class'XComWorldData'.const.WORLD_Melee_Range_Meters;
			}
			else
			{
				RangeInMeters = `UNITSTOMETERS(`TILESTOUNITS(RangeInTiles));
			}

			return RangeInMeters;
		}
	}
	return FixedAbilityRange;
}