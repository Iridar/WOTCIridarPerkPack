class X2Ability_Templar extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_TM_Rend());
	Templates.AddItem(IRI_TM_Volt());
	Templates.AddItem(IRI_TM_SoulShot());
	Templates.AddItem(IRI_TM_TemplarFocus());

	Templates.AddItem(IRI_TM_Amplify()); // TODO: Check if vanilla Amplify has a visual effect?
	Templates.AddItem(IRI_TM_Reflect()); // TODO: Fix the ReflectAttack projectile missing the target and then causing a viz delay
	Templates.AddItem(IRI_TM_Stunstrike()); // TODO: No visible projectile? Because of no damage effect?

	Templates.AddItem(IRI_TM_AstralGrasp());
	Templates.AddItem(IRI_TM_AstralGrasp_Spirit());
	Templates.AddItem(IRI_TM_AstralGrasp_DamageLink());

	return Templates;
}

static private function X2AbilityTemplate IRI_TM_AstralGrasp_DamageLink()
{
	local X2AbilityTemplate Template;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp_DamageLink');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ThunderLance";
	SetHidden(Template);
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	
	// Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	//Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	Template.AddTargetEffect(new class'X2Effect_ApplySpiritLinkDamage');

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;

	return Template;
}

static private function X2AbilityTemplate IRI_TM_AstralGrasp_Spirit()
{
	local X2AbilityTemplate					Template;
	local X2Effect_AstralGraspSpirit		Effect;
	local X2Effect_OverrideDeathAction		DeathActionEffect;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Persistent				PerkEffect;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp_Spirit');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ThunderLance";
	SetHidden(Template);
	
	// Targeting and Triggering

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'OnUnitBeginPlay';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 100;
	Trigger.ListenerData.EventFn = AstralGrasp_SpiritSpawned_Trigger;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// This will make the Astral Grasped unit immune to all damage except mental and psionic
	Effect = new class'X2Effect_AstralGraspSpirit';
	Effect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	//Effect.ImmueTypesAreInclusive = false;
	//Effect.ImmuneTypes.AddItem('Mental');
	//Effect.ImmuneTypes.AddItem('Psi');
	Effect.EffectName = 'IRI_TM_AstralGrasp_Spirit';
	Effect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddShooterEffect(Effect);

	DeathActionEffect = new class'X2Effect_OverrideDeathAction';
	DeathActionEffect.DeathActionClass = class'X2Action_AstralGraspSpiritDeath';
	DeathActionEffect.EffectName = 'IRI_TM_AstralGrasp_Spirit_DeathOverride';
	DeathActionEffect.BuildPersistentEffect(1, true);
	Template.AddShooterEffect(DeathActionEffect);

	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath("IRIAstralGrasp.AS_PsiDeath");
	AnimSetEffect.BuildPersistentEffect(1, true);
	AnimSetEffect.bRemoveWhenTargetDies = false;
	AnimSetEffect.bRemoveWhenSourceDies = false;
	Template.AddShooterEffect(AnimSetEffect);

	PerkEffect = new class'X2Effect_Persistent';
	PerkEffect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	PerkEffect.EffectName = 'IRI_TM_AstralGrasp_PerkEffect';
	Template.AddTargetEffect(PerkEffect);

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;

	return Template;
}

static private function EventListenerReturn AstralGrasp_SpiritSpawned_Trigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Ability	TriggerAbility;
	local UnitValue				UV;

	`AMLOG("Running");

	SpawnedUnit = XComGameState_Unit(EventSource);
	if (SpawnedUnit == none)
		return ELR_NoInterrupt;

	if (!SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	TriggerAbility = XComGameState_Ability(CallbackData);
	if (TriggerAbility == none)
		return ELR_NoInterrupt;

	`AMLOG("Triggering Spirint Spawned ability at:" @ TargetUnit.GetFullName());

	TriggerAbility.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);

	return ELR_NoInterrupt;
}

static private function X2AbilityTemplate IRI_TM_AstralGrasp()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCost_ActionPoints				ActionCost;
	local X2Condition_UnitProperty					TargetCondition;
	local X2Condition_UnitEffects					UnitEffectsCondition;
	local X2Condition_UnitImmunities				MentalImmunityCondition;
	local X2Condition_UnblockedNeighborTile			UnblockedNeighborTileCondition;
	local X2Effect_AstralGrasp						AstralGrasp;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_StunStrike";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Costs
//Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus'); DEBUG ONLY

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// There must be a free tile around the source unit
	UnblockedNeighborTileCondition = new class'X2Condition_UnblockedNeighborTile';
	UnblockedNeighborTileCondition.RequireVisible = true;
	Template.AbilityShooterConditions.AddItem(UnblockedNeighborTileCondition);

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeLargeUnits = false;
	TargetCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	MentalImmunityCondition = new class'X2Condition_UnitImmunities';
	MentalImmunityCondition.ExcludeDamageTypes.AddItem('Mental');
	Template.AbilityTargetConditions.AddItem(MentalImmunityCondition);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect('IRI_TM_AstralGrasp_Effect', 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// Effects
	AstralGrasp = new class'X2Effect_AstralGrasp';
	AstralGrasp.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	AstralGrasp.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(AstralGrasp);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, true));

	// State and Viz
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CinescriptCameraType = "Psionic_FireAtUnit";
	Template.ActivationSpeech = 'StunStrike';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.Hostility = eHostility_Offensive;
	//Template.CustomFireAnim = 'HL_StunStrike';

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.AdditionalAbilities.AddItem('IRI_TM_AstralGrasp_DamageLink');

	return Template;
}

static private function X2AbilityTemplate IRI_TM_Stunstrike()
{
	local X2AbilityTemplate							Template;
	local X2Effect_Knockback						KnockbackEffect;
	//local X2Effect_PersistentStatChange				DisorientEffect;
	local X2AbilityCost_ActionPoints				ActionCost;
	local X2Effect_ApplyWeaponDamage				DamageEffect;
	local X2Effect_TriggerEvent						TriggerEventEffect;
	local X2Condition_UnitProperty					TargetCondition;
	local X2Condition_UnitEffects					UnitEffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Stunstrike');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_StunStrike";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Costs
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus');

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeLargeUnits = true;
	Template.AbilityTargetConditions.AddItem(TargetCondition);
	

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2Ability_Viper'.default.BindSustainedEffectName, 'AA_UnitIsBound');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// Effects
	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	KnockbackEffect.OnlyOnDeath = false; 
	Template.AddTargetEffect(KnockbackEffect);

	TriggerEventEffect = new class'X2Effect_TriggerEvent';
	TriggerEventEffect.TriggerEventName = 'StunStrikeActivated';
	TriggerEventEffect.PassTargetAsSource = true;
	Template.AddTargetEffect(TriggerEventEffect);

	//	this effect is just here for visuals on a miss
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'IRI_TM_Stunstrike';
	//DamageEffect.bBypassShields = true;
	DamageEffect.bIgnoreArmor = true;
	Template.AddTargetEffect(DamageEffect);

	//DisorientEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
	//DisorientEffect.iNumTurns = default.StunStrikeDisorientNumTurns;
	//DisorientEffect.ApplyChanceFn = StunStrikeDisorientApplyChance;
	//Template.AddTargetEffect(DisorientEffect);

	// State and Viz
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CinescriptCameraType = "Psionic_FireAtUnit";
	Template.ActivationSpeech = 'StunStrike';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CustomFireAnim = 'HL_StunStrike';

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}


static private function X2AbilityTemplate IRI_TM_Reflect()
{
	local X2AbilityTemplate				Template;
	local X2Effect_IncrementUnitValue	ParryUnitValue;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Effect_Reflect				Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Reflect');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.OverrideAbilityAvailabilityFn = Reflect_OverrideAbilityAvailability;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Parry";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
 	Template.AddShooterEffectExclusions();

	// Costs
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.Length = 0;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Effects
	ParryUnitValue = new class'X2Effect_IncrementUnitValue';
	ParryUnitValue.NewValueToSet = 1;
	ParryUnitValue.UnitName = 'IRI_TM_Reflect';
	ParryUnitValue.CleanupType = eCleanup_BeginTurn;
	Template.AddShooterEffect(ParryUnitValue);

	Effect = new class'X2Effect_Reflect';
	Effect.BuildPersistentEffect(1, false, false,, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	// State and Viz
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Defensive;
	Template.BuildInterruptGameStateFn = none; // TypicalAbility_BuildInterruptGameState; // Firaxis has Parry as offensive and interruptible, which is asinine

	Template.PrerequisiteAbilities.AddItem('Parry');
	Template.AdditionalAbilities.AddItem('ReflectShot');

	return Template;
}

// Same as Parry, but later
static private function Reflect_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success')
	{
		if (OwnerState.ActionPoints.Length == 1 && OwnerState.ActionPoints[0] == class'X2CharacterTemplateManager'.default.MomentumActionPoint)
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.PARRY_PRIORITY + 2;
	}
}

static private function X2AbilityTemplate IRI_TM_Amplify()
{
	local X2AbilityTemplate				Template;
	local X2Effect_Amplify				AmplifyEffect;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2AbilityTag					AbilityTag;
	local X2Condition_UnitEffects		EffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Amplify');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Amplify";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddExcludeEffect(class'X2Effect_Amplify'.default.EffectName, 'AA_AlreadyAmplified');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	// Effects
	AmplifyEffect = new class'X2Effect_IRI_Amplify';
	AmplifyEffect.BuildPersistentEffect(1, true, true);
	AmplifyEffect.bRemoveWhenTargetDies = true;
	AmplifyEffect.BonusDamageMult = class'X2Ability_TemplarAbilitySet'.default.AmplifyBonusDamageMult;
	AmplifyEffect.MinBonusDamage = class'X2Ability_TemplarAbilitySet'.default.AmplifyMinBonusDamage;
	
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = AmplifyEffect;
	AmplifyEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2Ability_TemplarAbilitySet'.default.AmplifyEffectName, `XEXPAND.ExpandString(class'X2Ability_TemplarAbilitySet'.default.AmplifyEffectDesc), Template.IconImage, true, , Template.AbilitySourceName);
	AbilityTag.ParseObj = none; // bsg-dforrest (7.27.17): need to clear out ParseObject

	Template.AddTargetEffect(AmplifyEffect);

	// State and Viz
	Template.bShowActivation = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_Lens';
	Template.ActivationSpeech = 'Amplify';
	Template.Hostility = eHostility_Offensive;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}

static private function X2AbilityTemplate IRI_TM_Volt()
{
	local X2AbilityTemplate				Template;
	local X2Condition_UnitProperty		TargetCondition;
	local X2Effect_ApplyWeaponDamage	DamageEffect;
	local X2Effect_ToHitModifier		HitModEffect;
	local X2Condition_AbilityProperty	AbilityCondition;
	local X2AbilityTag                  AbilityTag;
	local X2AbilityCost_ActionPoints	ActionCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Volt');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_volt";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_Volt';
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Volt'; // Custom calc to force crits against Psionics for cosmetic effect.
	Template.TargetingMethod = class'X2TargetingMethod_Volt';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	// Costs
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus');

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	//	NOTE: visibility is NOT required for multi targets as it is required between each target (handled by multi target class)

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeCivilian = true;
	TargetCondition.ExcludeCosmetic = true;
	TargetCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(TargetCondition);
	Template.AbilityMultiTargetConditions.AddItem(TargetCondition);

	// Effect - non-psionic
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludePsionic = true;
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'IRI_TM_Volt';
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.TargetConditions.AddItem(TargetCondition);
	Template.AddTargetEffect(DamageEffect);
	Template.AddMultiTargetEffect(DamageEffect);

	// Effect - psionic
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeNonPsionic = true;
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'IRI_TM_Volt_Psi';
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.TargetConditions.AddItem(TargetCondition);
	Template.AddTargetEffect(DamageEffect);
	Template.AddMultiTargetEffect(DamageEffect);

	// Effect - Aftershock
	HitModEffect = new class'X2Effect_ToHitModifier';
	HitModEffect.BuildPersistentEffect(2, , , , eGameRule_PlayerTurnBegin);
	HitModEffect.AddEffectHitModifier(eHit_Success, class'X2Ability_TemplarAbilitySet'.default.VoltHitMod, class'X2Ability_TemplarAbilitySet'.default.RecoilEffectName);
	HitModEffect.bApplyAsTarget = true;
	HitModEffect.bRemoveWhenTargetDies = true;
	HitModEffect.bUseSourcePlayerState = true;
	
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = HitModEffect;
	HitModEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2Ability_TemplarAbilitySet'.default.RecoilEffectName, `XEXPAND.ExpandString(class'X2Ability_TemplarAbilitySet'.default.RecoilEffectDesc), "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Recoil");

	AbilityTag.ParseObj = none;
	
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('Reverberation');
	HitModEffect.TargetConditions.AddItem(default.LivingTargetOnlyProperty);
	HitModEffect.TargetConditions.AddItem(AbilityCondition);
	Template.AddTargetEffect(HitModEffect);
	Template.AddMultiTargetEffect(HitModEffect);

	// State and Viz
	Template.CustomFireAnim = 'HL_Volt';
	Template.ActivationSpeech = 'Volt';
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActionFireClass = class'X2Action_Fire_Volt';
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState; // Interruptible, unlike original Volt

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.DamagePreviewFn = class'X2Ability_TemplarAbilitySet'.static.VoltDamagePreview;

	return Template;
}

static private function X2AbilityTemplate IRI_TM_TemplarFocus()
{
	local X2AbilityTemplate		Template;
	local X2Effect_TemplarFocus	FocusEffect;
	local array<StatChange>		StatChanges;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_TemplarFocus');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_InnerFocus";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Effects
	FocusEffect = new class'X2Effect_TemplarFocus';
	FocusEffect.BuildPersistentEffect(1, true, false);
	FocusEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, false, , Template.AbilitySourceName);
	FocusEffect.EffectSyncVisualizationFn = class'X2Ability_TemplarAbilitySet'.static.FocusEffectVisualization;
	FocusEffect.VisualizationFn = class'X2Ability_TemplarAbilitySet'.static.FocusEffectVisualization;
	FocusEffect.bDisplayInSpecialDamageMessageUI = false;

	//	focus 0
	StatChanges.Length = 0; // Settle down, compiler
	FocusEffect.AddNextFocusLevel(StatChanges, 0, 0);
	//	focus 1
	FocusEffect.AddNextFocusLevel(StatChanges, 0, 0);
	//	focus 2
	FocusEffect.AddNextFocusLevel(StatChanges, 0, 0);

	Template.AddTargetEffect(FocusEffect);

	Template.AdditionalAbilities.AddItem('FocusKillTracker');

	Template.bIsPassive = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	return Template;
}

static private function X2AbilityTemplate IRI_TM_Rend()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;
	local X2AbilityToHitCalc_StandardMelee  StandardMelee;

	Template = class'X2Ability_TemplarAbilitySet'.static.Rend('IRI_TM_Rend');

	StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
	StandardMelee.bGuaranteedHit = true;
	StandardMelee.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardMelee;
	
	Template.AbilityCosts.Length = 0;
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTargetEffects.Length = 0;
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.DamageTypes.AddItem('Melee');
	Template.AddTargetEffect(WeaponDamageEffect);

	return Template;
}


static private function X2AbilityTemplate IRI_TM_SoulShot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2AbilityToHitCalc_StandardAim	StandardAim;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_SoulShot');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_SoulShot";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;

	// Targeting and Triggering
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	AddCooldown(Template, `GetConfigInt('IRI_TM_SoulShot_Cooldown'));

	// Effects
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bIgnoreBaseDamage = true;
	WeaponDamageEffect.DamageTag = 'IRI_TM_SoulShot';
	//WeaponDamageEffect.bBypassShields = true;
	//WeaponDamageEffect.bIgnoreArmor = true;
	Template.AddTargetEffect(WeaponDamageEffect);
	Template.AddTargetEffect(new class'X2Effect_Templar_SoulShot_ArrowHit');

	// State and Viz
	Template.bShowActivation = false;
	SetFireAnim(Template, 'HL_SoulShot');

	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'IonicStorm';
	Template.CinescriptCameraType = "IRI_TM_SoulShot";

	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	// Trigger Momentum
	Template.PostActivationEvents.AddItem('RendActivated');
	
	return Template;
}




//	========================================
//				COMMON CODE
//	========================================

static private function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static private function AddCharges(out X2AbilityTemplate Template, int InitialCharges)
{
	local X2AbilityCharges		Charges;
	local X2AbilityCost_Charges	ChargeCost;

	if (InitialCharges > 0)
	{
		Charges = new class'X2AbilityCharges';
		Charges.InitialCharges = InitialCharges;
		Template.AbilityCharges = Charges;

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Template.AbilityCosts.AddItem(ChargeCost);
	}
}

static private function AddFreeCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}

static private function RemoveVoiceLines(out X2AbilityTemplate Template)
{
	Template.ActivationSpeech = '';
	Template.SourceHitSpeech = '';
	Template.TargetHitSpeech = '';
	Template.SourceMissSpeech = '';
	Template.TargetMissSpeech = '';
	Template.TargetKilledByAlienSpeech = '';
	Template.TargetKilledByXComSpeech = '';
	Template.MultiTargetsKilledByAlienSpeech = '';
	Template.MultiTargetsKilledByXComSpeech = '';
	Template.TargetWingedSpeech = '';
	Template.TargetArmorHitSpeech = '';
	Template.TargetMissedSpeech = '';
}

static private function SetFireAnim(out X2AbilityTemplate Template, name Anim)
{
	Template.CustomFireAnim = Anim;
	Template.CustomFireKillAnim = Anim;
	Template.CustomMovingFireAnim = Anim;
	Template.CustomMovingFireKillAnim = Anim;
	Template.CustomMovingTurnLeftFireAnim = Anim;
	Template.CustomMovingTurnLeftFireKillAnim = Anim;
	Template.CustomMovingTurnRightFireAnim = Anim;
	Template.CustomMovingTurnRightFireKillAnim = Anim;
}

static private function SetHidden(out X2AbilityTemplate Template)
{
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	
	//TacticalText is for mainly for item-granted abilities (e.g. to hide the ability that gives the armour stats)
	Template.bDisplayInUITacticalText = false;
	
	//	bDisplayInUITooltip isn't actually used in the base game, it should be for whether to show it in the enemy tooltip, 
	//	but showing enemy abilities didn't make it into the final game. Extended Information resurrected the feature  in its enhanced enemy tooltip, 
	//	and uses that flag as part of it's heuristic for what abilities to show, but doesn't rely solely on it since it's not set consistently even on base game abilities. 
	//	Anyway, the most sane setting for it is to match 'bDisplayInUITacticalText'. (c) MrNice
	Template.bDisplayInUITooltip = false;
	
	//Ability Summary is the list in the armoury when you're looking at a soldier.
	Template.bDontDisplayInAbilitySummary = true;
	Template.bHideOnClassUnlock = true;
}

static private function X2AbilityTemplate Create_AnimSet_Passive(name TemplateName, string AnimSetPath)
{
	local X2AbilityTemplate                 Template;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.bDontDisplayInAbilitySummary = true;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	
	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath(AnimSetPath);
	AnimSetEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSetEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static private function SetPassive(out X2AbilityTemplate Template)
{
	Template.bIsPassive = true;

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.bDisplayInUITacticalText = true;
	Template.bDisplayInUITooltip = true;
	Template.bDontDisplayInAbilitySummary = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
}

static private function X2AbilityTemplate HiddenPurePassive(name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true)
{
	local X2AbilityTemplate	Template;
	
	Template = PurePassive(TemplateName, TemplateIconImage, bCrossClassEligible, AbilitySourceName, bDisplayInUI);
	SetHidden(Template);
	
	return Template;
}

//	Use: SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnBegun',, eFilter_Player);
static private function	SetSelfTarget_WithEventTrigger(out X2AbilityTemplate Template, name EventID, optional EventListenerDeferral Deferral = ELD_OnStateSubmitted, optional AbilityEventFilter Filter = eFilter_None, optional int Priority = 50)
{
	local X2AbilityTrigger_EventListener Trigger;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = EventID;
	Trigger.ListenerData.Deferral = Deferral;
	Trigger.ListenerData.Filter = Filter;
	Trigger.ListenerData.Priority = Priority;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);
}

static private function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;

	`LOG("Action layer: " @ iLayer @ ": " @ Action.Class.Name @ Action.StateChangeContext.AssociatedState.HistoryIndex,, 'IRIPISTOLVIZ'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}