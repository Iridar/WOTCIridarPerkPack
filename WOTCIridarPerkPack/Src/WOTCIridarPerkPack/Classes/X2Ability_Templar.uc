class X2Ability_Templar extends X2Ability_PerkPack;

// TODO: Randomize SoulShot effect rotation? Ahh probably not possible without rotating the socket. Rotate the socket randomly maybe?

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(TemplarShield());
	Templates.AddItem(SoulShot());
	Templates.AddItem(Apotheosis());

	return Templates;
}

static function X2AbilityTemplate Apotheosis()
{
	local X2AbilityTemplate			 Template;
	local X2Effect_TemplarApotheosis PersistentEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Apotheosis');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_holywarrior";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
 	Template.AddShooterEffectExclusions();

	// Triggering and Targeting
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	AddCooldown(Template, GetConfigInt('IRI_Apotheosis_Cooldown'));

	// Effects
	PersistentEffect = new class'X2Effect_TemplarApotheosis';
	PersistentEffect.BuildPersistentEffect(GetConfigInt('IRI_Apotheosis_Duration'), false, true,, eGameRule_PlayerTurnBegin);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	// State and Viz
	Template.Hostility = eHostility_Neutral;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	//Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.bShowActivation = false; // Don't show flyover, it obscures the fancy animation.
	Template.CustomSelfFireAnim = 'HL_Apotheosis';
	Template.CustomFireAnim = 'HL_Apotheosis';
	Template.CinescriptCameraType = "Templar_Ghost";
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = false;

	return Template;
}

static function X2AbilityTemplate TemplarShield()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2Effect_TemplarShieldAnimations	AnimSetEffect;
	local X2Effect_TemplarShield			ShieldedEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TemplarShield');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_TemplarShield";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
 	Template.AddShooterEffectExclusions();

	// Triggering and Targeting
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.AddItem('Momentum');
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Effects
	AnimSetEffect = new class'X2Effect_TemplarShieldAnimations';
	AnimSetEffect.BuildPersistentEffect(1, false, true,, eGameRule_PlayerTurnBegin);
	AnimSetEffect.AddAnimSetWithPath("IRIParryReworkAnims.Anims.AS_BallisticShield");
	AnimSetEffect.AddAnimSetWithPath("IRIParryReworkAnims.Anims.AS_TemplarShield");
	Template.AddTargetEffect(AnimSetEffect);

	ShieldedEffect = new class'X2Effect_TemplarShield';
	ShieldedEffect.BuildPersistentEffect(1, false, true,, eGameRule_PlayerTurnBegin);
	ShieldedEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	ShieldedEffect.EffectName = class'X2Effect_TemplarShield'.default.EffectName;
	Template.AddTargetEffect(ShieldedEffect);

	// State and Viz
	Template.Hostility = eHostility_Defensive;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.bShowActivation = false; // Don't show flyover, it obscures the fancy animation.
	Template.CustomSelfFireAnim = 'HL_Shield_Extend';
	Template.CustomFireAnim = 'HL_Shield_Extend';
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = false;
	Template.OverrideAbilityAvailabilityFn = TemplarShield_OverrideAbilityAvailability;

	Template.OverrideAbilities.AddItem('ParryActivate');
	Template.OverrideAbilities.AddItem('Parry');
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;

	return Template;
}

private static function TemplarShield_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success')
	{
		if (OwnerState.ActionPoints.Length == 1 && OwnerState.ActionPoints[0] == 'Momentum')
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.PARRY_PRIORITY;
	}
}

static function X2AbilityTemplate SoulShot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          TargetProperty;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2AbilityCooldown                 Cooldown;
	local X2Condition_Visibility            TargetVisibilityCondition;

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

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	AddCooldown(Template, GetConfigInt('IRI_SoulShot_Cooldown'));

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

