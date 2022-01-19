class X2Ability_Items extends X2Ability_PerkPack;


var config WeaponDamageValue SLAG_BONUS_DAMAGE;
var config int SLAG_TRIGGER_CHANCE;
var config int SLAG_BURN_DAMAGE_PER_TICK;
var config int SLAG_BURN_DAMAGE_PER_TICK_SPREAD;

var config array<int> MELTA_BONUS_PIERCE;
var config array<int> MELTA_BONUS_CRIT;

var config bool SLAG_IS_CROSS_CLASS_COMPATIBLE;
var config bool MELTA_IS_CROSS_CLASS_COMPATIBLE;

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
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	//	putting the burn effect first so it visualizes correctly
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1)); // TODO: Configurable damage

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bIgnoreBaseDamage = true;
	WeaponDamageEffect.bAllowFreeKill = false;
	WeaponDamageEffect.bAllowWeaponUpgrade = false;
	WeaponDamageEffect.EffectDamageValue.Damage = 1; // TODO: Configurable damage
	Template.AddTargetEffect(WeaponDamageEffect);

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

	Template.AdditionalAbilities.AddItem('IRI_Singe_Passive');

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
	Template.AddTargetEffect(SuperchargeEffect);

	return Template;
}
