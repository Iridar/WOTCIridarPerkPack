class X2Effect_BountyHunter_BurstFireAimPenalty extends X2Effect_Persistent;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo	ShotMod;
	local int				Tiles;

	if (AbilityState.GetMyTemplateName() != 'IRI_BH_BurstFire')
		return;

	//  Calculate how far into Squadsight range are we.
	Tiles = Attacker.TileDistanceBetween(Target);
	Tiles -= Attacker.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;

	if (Tiles > 0)
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = class'X2AbilityToHitCalc_StandardAim'.default.SQUADSIGHT_DISTANCE_MOD * Tiles; // SQUADSIGHT_DISTANCE_MOD is already negative
		ShotMod.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotMod);
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_BountyHunter_BurstFireAimPenalty_Effect"
}