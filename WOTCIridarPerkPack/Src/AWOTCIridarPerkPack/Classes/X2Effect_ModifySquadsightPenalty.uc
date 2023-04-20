class X2Effect_ModifySquadsightPenalty extends X2Effect_Persistent;

// Double squadsight penalties for specified abilities. If no abilities are specified, applies to all abilities.

var array<name> AbilityNames;

var float fAimModifier;
var float fCritModifier;

var float iAimFlatModifier;
var float iCritFlatModifier;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo	ShotMod;
	local int				Tiles;

	if (AbilityNames.Length != 0 && AbilityNames.Find(AbilityState.GetMyTemplateName()) == INDEX_NONE)
		return;

	//  Calculate how far into Squadsight range are we.
	Tiles = Attacker.TileDistanceBetween(Target);
	Tiles -= Attacker.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;

	if (Tiles > 0)
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = fAimModifier * float(class'X2AbilityToHitCalc_StandardAim'.default.SQUADSIGHT_DISTANCE_MOD * Tiles) + iAimFlatModifier; // SQUADSIGHT_DISTANCE_MOD is already negative
		ShotMod.Reason = FriendlyName;
		if (ShotMod.Value != 0)
		{
			ShotModifiers.AddItem(ShotMod);
		}

		ShotMod.ModType = eHit_Crit;
		ShotMod.Value = fCritModifier * float(class'X2AbilityToHitCalc_StandardAim'.default.SQUADSIGHT_CRIT_MOD) + iCritFlatModifier;
		ShotMod.Reason = FriendlyName;
		if (ShotMod.Value != 0)
		{
			ShotModifiers.AddItem(ShotMod);
		}
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Allow
}