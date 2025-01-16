class X2AbilityTarget_IncreaseGrenadeRange extends X2AbilityTarget_Cursor;

var int IncreasedRangeTiles;

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Item SourceWeapon;
	local int RangeInTiles;
	local float RangeInMeters;

	`AMLOG("Running" @ AbilityState.GetMyTemplateName());

	if (bRestrictToWeaponRange)
	{
		SourceWeapon = AbilityState.GetSourceAmmo(); //AbilityState.GetSourceWeapon(); - use grenade range instead of weapon

		`AMLOG("SourceWeapon" @ SourceWeapon.GetMyTemplateName());

		if (SourceWeapon != none)
		{
			`AMLOG("Range" @ SourceWeapon.GetItemRange(AbilityState));

			RangeInTiles = SourceWeapon.GetItemRange(AbilityState) + IncreasedRangeTiles;

			`AMLOG("Total range" @ RangeInTiles);

			if( RangeInTiles == 0 )
			{
				// This is melee range
				RangeInMeters = class'XComWorldData'.const.WORLD_Melee_Range_Meters;
			}
			else
			{
				RangeInMeters = `UNITSTOMETERS(`TILESTOUNITS(RangeInTiles));
			}

			`AMLOG("Returning range in meters" @ RangeInMeters);

			return RangeInMeters;
		}
	}
	return FixedAbilityRange;
}
