class X2Ability_BountyHunter extends X2Ability_PerkPack;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_DeadlyShadow());
	Templates.AddItem(IRI_DeadlyShadow_Passive());

	Templates.AddItem(Blind());

	return Templates;
}

static function X2AbilityTemplate IRI_DeadlyShadow()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Shadow                       StealthEffect;
	local X2Effect_PersistentStatChange         StatEffect;
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2AbilityCharges						Charges;
	local X2AbilityCost_Charges					ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_DeadlyShadow');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_Stealth');
	Template.AddShooterEffectExclusions();

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	AddCooldown(Template, GetConfigInt('IRI_DeadlyShadow_Cooldown'));
	
	// Effects
	StealthEffect = new class'X2Effect_Shadow';
	StealthEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	StealthEffect.bRemoveWhenTargetConcealmentBroken = true;
	Template.AddTargetEffect(StealthEffect);

	Template.AddTargetEffect(class'X2Ability_ReaperAbilitySet'.static.ShadowAnimEffect());
	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	// State and Viz
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CustomFireAnim = 'NO_ShadowStart';
	Template.ActivationSpeech = 'Shadow';
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.AdditionalAbilities.AddItem('IRI_DeadlyShadow_Passive');
	
	return Template;
}

static function X2AbilityTemplate IRI_DeadlyShadow_Passive()
{
	local X2AbilityTemplate		Template;
	local X2Effect_DeadlyShadow	StatEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_DeadlyShadow_Passive');

	SetPassive(Template);
	SetHidden(Template);

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

	StatEffect = new class'X2Effect_DeadlyShadow';
	StatEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.bRemoveWhenTargetConcealmentBroken = true;
	StatEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(StatEffect);


	return Template;
}


static function X2AbilityTemplate Blind()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          TargetProperty;
	local X2Condition_Visibility            TargetVisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Blind');

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
	
	//AddCooldown(Template, GetConfigInt('IRI_SoulShot_Cooldown'));

	// Effects
	Template.AddTargetEffect(class'X2Effect_Blind'.static.CreateBlindEffect(2, 0));

	// State and Viz
	Template.bShowActivation = false;

	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'IonicStorm';
	//Template.CinescriptCameraType = "IRI_SoulShot";

	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	
	return Template;
}