class X2Effect_DeadlyShadow extends X2Effect_Persistent;

// Start Issue #923
/// HL-Docs: feature:ExtraDamageModifierHooks; issue:923; tags:tactical,compatibility
/// The base game does not work well with certain types of damage-modifier
/// effects. In particular, attempts to implement multiplicative,
/// percentage-based damage modifiers are hindered by the fact that the
/// overall calculated damage depends on the order in which such effects
/// are applied to a unit.
///
/// The following hooks solve the problem by applying configured damage
/// modifiers either before or after the "default" behaviour, which
/// is where normal flat damage is added or subtracted. As long as all
/// the effects using these hooks are commutative with one another, the
/// final damage result will be independent of the order in which effects
/// are applied.
///
/// In summary: use these hooks to apply multiplicative damage modifiers
/// such as percent-based increases and reductions. The pre-default hooks
/// are for multipliers that should apply to just the calculated base
/// damage, while the post-default hooks apply modifiers to the calculated
/// damage after all the additive modifiers have been applied.
///
/// **Important** Your implementations of these functions should return the
/// amount of damage your effect is adding or subtracting, **not** the overall
/// damage. The value you return will be added to `CurrentDamage`.
///
/// ## Pre-default hooks
/// The "pre-default" hooks are applied immediately after the base damage
/// has been calculated.
/// This allows mods to apply damage modifiers based on the base damage
/// before any flat damage modifiers are applied.
///
/// The following hook is used for effects that are applied to the
/// attacker:
/// ```unrealscript
/// float GetPreDefaultAttackingDamageModifier_CH(
///         XComGameState_Effect EffectState,
///         XComGameState_Unit SourceUnit,
///         Damageable Target,
///         XComGameState_Ability AbilityState,
///         const out EffectAppliedData ApplyEffectParameters,
///         float CurrentDamage,
///         XComGameState NewGameState)
/// ```
/// This next one is used for effects that are applied to the target
/// (the "defender"):
/// ```unrealscript
/// float GetPreDefaultDefendingDamageModifier_CH(
///         XComGameState_Effect EffectState,
///         XComGameState_Unit SourceUnit,
///         XComGameState_Unit TargetUnit,
///         XComGameState_Ability AbilityState,
///         const out EffectAppliedData ApplyEffectParameters,
///         float CurrentDamage,
///         XComGameState NewGameState)
/// ```
/// The arguments are largely self explanatory, but note that `CurrentDamage`
/// is a float, as is the return value. `CurrentDamage` is the current total
/// damage, which is the base damage with any preceding damage modifiers
/// already applied.
///
/// ## Post-default hooks
/// Once the pre-default modifiers have been applied, the traditional (flat)
/// damage modifiers are processed as per existing base game behaviour. When
/// that has finished, the "post-default" hooks are applied. This allows mods
/// to apply damage modifiers to the total damage including any bonus flat
/// damage.
///
/// The following hook is used for effects that are applied to the
/// attacker:
/// ```unrealscript
/// float GetPostDefaultAttackingDamageModifier_CH(
///         XComGameState_Effect EffectState,
///         XComGameState_Unit SourceUnit,
///         Damageable Target,
///         XComGameState_Ability AbilityState,
///         const out EffectAppliedData ApplyEffectParameters,
///         float CurrentDamage,
///         XComGameState NewGameState)
/// ```
/// This next one is used for effects that are applied to the target
/// (the "defender"):
/// ```unrealscript
/// float GetPostDefaultDefendingDamageModifier_CH(
///         XComGameState_Effect EffectState,
///         XComGameState_Unit SourceUnit,
///         XComGameState_Unit TargetUnit,
///         XComGameState_Ability AbilityState,
///         const out EffectAppliedData ApplyEffectParameters,
///         float CurrentDamage,
///         XComGameState NewGameState)
/// ```
/// The arguments are largely self explanatory, but note that `CurrentDamage`
/// is a float, as is the return value. `CurrentDamage` is the current total
/// damage.
///
/// ## Compatibility
/// If you implement any of these functions in your own effects, they will do
/// nothing unless the game is using version 1.22.0+ of the Community
/// Highlander.
///
/// Do note that these are applied along with any traditional damage modifiers
/// your effect has, so if you want your effects to work with older versions
/// of the Community Highlander and setups without any Community Highlander at
/// all, then you should guard the old damage modifier functions with a
/// check for these new functions, e.g.
/// ```unrealscript
/// function int GetAttackingDamageModifier(...)
/// {
///     if (Function'XComGame.X2Effect_Persistent.GetPreDefaultAttackingDamageModifier_CH' != none)
///     {
///         // Using the new hooks, so skip the old implementation
///         return 0;
///     }
///
///     // Continue with old implementation here
///     ...
/// }
/// ```
function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{
	local float DamageMod;

	if (SourceUnit.IsConcealed())
	{
		DamageMod += CurrentDamage * 0.5f;
	}
	return DamageMod; 
}
