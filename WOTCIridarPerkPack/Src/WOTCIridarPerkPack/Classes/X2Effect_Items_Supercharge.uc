class X2Effect_Items_Supercharge extends X2Effect_Persistent;

var array<int> ExtraArmorPiercing;
var array<int> ExtraCritChance;

function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData)
{
	local XComGameState_Unit			TargetUnit;
	local XComGameState_Destructible	Destructible;
	local int							Tiles;

	if (ExtraArmorPiercing.Length > 0 &&
		AbilityState.SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		TargetUnit = XComGameState_Unit(TargetDamageable);
		if (TargetUnit != none)
		{
			Tiles = Attacker.TileDistanceBetween(TargetUnit);
			if (Tiles > ExtraArmorPiercing.Length)
			{
				Tiles = ExtraArmorPiercing.Length - 1;
			}
			return ExtraArmorPiercing[Tiles]; 
		}
		else
		{
			Destructible = XComGameState_Destructible(TargetDamageable);
			if (Destructible == none)
				return 0;

			Tiles = class'Help'.static.TileDistanceBetweenUnitAndTile(Attacker, Destructible.TileLocation);
			if (Tiles > ExtraArmorPiercing.Length)
			{
				Tiles = ExtraArmorPiercing.Length - 1;
			}
			return ExtraArmorPiercing[Tiles]; 
		}
	}
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo	ShotInfo;
	local int				Tiles;

	if (ExtraCritChance.Length > 0 &&
		AbilityState.SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		Tiles = Attacker.TileDistanceBetween(Target);
		if (Tiles > ExtraCritChance.Length)
		{
			Tiles = ExtraCritChance.Length - 1;
		}
		ShotInfo.Value = ExtraCritChance[Tiles]; 
		
		if (ShotInfo.Value != 0)
		{
			ShotInfo.ModType = eHit_Crit;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);
		}
	}
}
