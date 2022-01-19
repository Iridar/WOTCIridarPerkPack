class X2Ability_Items extends X2Ability_PerkPack;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Supercharge());
	
	Templates.AddItem(Singe());
	Templates.AddItem(PurePassive('IRI_Singe_Passive', "img:///IRIPerkPack_UILibrary.UIPerk_Singe",, 'eAbilitySource_Item', true));

	return Templates;
}

static function X2AbilityTemplate Singe()
{
	local X2AbilityTemplate					Template;
	local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Condition_UnitProperty			LivingTargetProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Singe');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_Singe";
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	
	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityToHitCalc = default.DeadEye;

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 40;
	Trigger.ListenerData.EventFn = FollowUpShot_EventListenerTrigger;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Target Conditions
	// TODO: Visibility condition?

	// Allow friendly fire, if the triggering ability does.
	//Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	LivingTargetProperty = new class'X2Condition_UnitProperty';
	LivingTargetProperty.ExcludeAlive = false;
	LivingTargetProperty.ExcludeDead = true;
	LivingTargetProperty.ExcludeFriendlyToSource = false;
	LivingTargetProperty.ExcludeHostileToSource = false;
	Template.AbilityTargetConditions.AddItem(LivingTargetProperty);
	
	// Ability Effects
	Template.bAllowAmmoEffects = false;
	Template.bAllowBonusWeaponEffects = false;
	Template.bAllowFreeFireWeaponUpgrade = false;

	//	putting the burn effect first so it visualizes correctly
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateBurningStatusEffect(GetConfigInt('IRI_Singe_BurnDamage'), GetConfigInt('IRI_Singe_BurnDamage_Spread')));

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bAllowFreeKill = false;
	WeaponDamageEffect.bAllowWeaponUpgrade = false;
	WeaponDamageEffect.bIgnoreBaseDamage = true;
	WeaponDamageEffect.EffectDamageValue = GetAbilityDamage(Template.DataName);
	Template.AddTargetEffect(WeaponDamageEffect);

	// State and Vis
	Template.FrameAbilityCameraType = eCameraFraming_Never; 
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bUsesFiringCamera = false;
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = FollowUpShot_BuildVisualization;
	Template.MergeVisualizationFn = FollowUpShot_MergeVisualization;
	Template.BuildInterruptGameStateFn = none;

	Template.TriggerChance = GetConfigFloat('IRI_Singe_TriggerChance');

	Template.AdditionalAbilities.AddItem('IRI_Singe_Passive');
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;

	Template.bCrossClassEligible = GetConfigBool('IRI_Singe_bCrossClassEligible');

	return Template;
}

static function X2AbilityTemplate Supercharge()
{
	local X2AbilityTemplate				Template;
	local X2Effect_Items_Supercharge	SuperchargeEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Supercharge');

	SetPassive(Template);

	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_Supercharge";
	Template.AbilitySourceName = 'eAbilitySource_Item';

	SuperchargeEffect = new class'X2Effect_Items_Supercharge';
	SuperchargeEffect.BuildPersistentEffect(1, true);
	SuperchargeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	SuperchargeEffect.ExtraArmorPiercing = GetConfigArrayInt('IRI_Supercharge_ExtraArmorPiercing');
	SuperchargeEffect.ExtraCritChance = GetConfigArrayInt('IRI_Supercharge_ExtraCritChance');
	Template.AddTargetEffect(SuperchargeEffect);

	Template.bCrossClassEligible = GetConfigBool('IRI_Supercharge_bCrossClassEligible');

	return Template;
}
