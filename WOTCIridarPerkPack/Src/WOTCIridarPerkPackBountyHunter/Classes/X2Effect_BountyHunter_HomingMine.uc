class X2Effect_BountyHunter_HomingMine extends X2Effect_HomingMine;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local XComGameState_Unit SourceUnit;
	local ShotModifierInfo ShotMod;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	if (SourceUnit != none && SourceUnit.GetTeam() == Attacker.GetTeam()) // guarantee shot for squadmates only
	{
		ShotMod.ModType = eHit_Success;
		ShotMod.Value = 100;
		ShotMod.Reason = FriendlyName;

		ShotModifiers.AddItem(ShotMod);
	}
}
