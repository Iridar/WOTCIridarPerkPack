class X2Ability_Templar extends X2Ability_PerkPack;


/*
To do: 
compatibility with other perks? 
- Ghost
- Channel 
- Overcharge
*/

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(SoulShot());

	return Templates;
}

static function X2AbilityTemplate SoulShot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          TargetProperty;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2AbilityCooldown                 Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SoulShot');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_soulfire";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	TargetProperty = new class'X2Condition_UnitProperty';
	TargetProperty.ExcludeRobotic = true;
	TargetProperty.FailOnNonUnits = true;
	TargetProperty.TreatMindControlledSquadmateAsHostile = true;
	Template.AbilityTargetConditions.AddItem(TargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 0;
	Template.AbilityCooldown = Cooldown;

	// Effects
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bIgnoreBaseDamage = true;
	WeaponDamageEffect.DamageTag = 'IRI_SoulShot';
	//WeaponDamageEffect.bBypassShields = true;
	//WeaponDamageEffect.bIgnoreArmor = true;
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.AddTargetEffect(new class'X2Effect_SoulShot_ArrowHit');

	// State and Viz
	Template.bShowActivation = false;
	SetFireAnim(Template, 'HL_SoulShot');

	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'IonicStorm';
	//Template.CinescriptCameraType = "Psionic_FireAtUnit"; // TODO: Cinecam
	Template.CinescriptCameraType = "IRI_SoulShot";

	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	
	return Template;
}

