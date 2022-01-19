class X2Effect_Items_Singe extends X2Effect_Persistent;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	return 0; 
}

DefaultProperties
{
    EffectName="IRI_Singe_Effect"
    DuplicateResponse=eDupe_Allow
}

