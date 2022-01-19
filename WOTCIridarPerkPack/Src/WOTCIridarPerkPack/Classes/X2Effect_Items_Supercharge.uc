class X2Effect_Items_Supercharge extends X2Effect_Persistent;

/*
function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{
	local XComGameState_Item SourceWeapon;
	local XComGameState_Unit TargetUnit;
	local int Tiles;

	TargetUnit = XComGameState_Unit(TargetDamageable);
	SourceWeapon = AbilityState.GetSourceWeapon();

	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		Tiles = Attacker.TileDistanceBetween(TargetUnit);
		if (Tiles > class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_PIERCE.Length)
		{
			Tiles = class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_PIERCE.Length - 1;
		}

		return class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_PIERCE[Tiles]; 
	}
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local int Tiles;
	local XComGameState_Item SourceWeapon;
	local ShotModifierInfo ShotInfo;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		Tiles = Attacker.TileDistanceBetween(Target);
		if (Tiles > class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_CRIT.Length)
		{
			Tiles = class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_CRIT.Length - 1;
		}
		ShotInfo.Value = class'X2Ability_SlagAndMelta'.default.MELTA_BONUS_CRIT[Tiles];

		ShotInfo.ModType = eHit_Crit;
		ShotInfo.Reason = FriendlyName;
		ShotModifiers.AddItem(ShotInfo);
	}
}*/