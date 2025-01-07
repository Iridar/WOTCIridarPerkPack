class X2AbilityTarget_IncreaseGrenadeRange extends X2AbilityTarget_Cursor;

var int IncreasedRangeTiles;

simulated function float GetCursorRangeMeters(XComGameState_Ability AbilityState)
{
	local XComGameState_Item SourceWeapon;
	local int RangeInTiles;
	local float RangeInMeters;

	`LOG("Running" @ AbilityState.GetMyTemplateName(),, 'IRITEST');

	if (bRestrictToWeaponRange)
	{
		SourceWeapon = AbilityState.GetSourceAmmo(); //AbilityState.GetSourceWeapon(); - use grenade range instead of weapon

		`LOG("SourceWeapon" @ SourceWeapon.GetMyTemplateName(),, 'IRITEST');

		if (SourceWeapon != none)
		{
			`LOG("Range" @ SourceWeapon.GetItemRange(AbilityState),, 'IRITEST');

			RangeInTiles = SourceWeapon.GetItemRange(AbilityState) + IncreasedRangeTiles;

			`LOG("Total range" @ RangeInTiles,, 'IRITEST');

			if( RangeInTiles == 0 )
			{
				// This is melee range
				RangeInMeters = class'XComWorldData'.const.WORLD_Melee_Range_Meters;
			}
			else
			{
				RangeInMeters = `UNITSTOMETERS(`TILESTOUNITS(RangeInTiles));
			}

			`LOG("Returning range in meters" @ RangeInMeters,, 'IRITEST');

			return RangeInMeters;
		}
	}
	return FixedAbilityRange;
}