class X2Ability_Templar extends X2Ability;

var private localized string strSiphonEffectDesc;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_TM_Rend());
	Templates.AddItem(IRI_TM_Volt()); 
	Templates.AddItem(IRI_TM_Aftershock());
	Templates.AddItem(IRI_TM_SoulShot());
	Templates.AddItem(IRI_TM_TemplarFocus());

	Templates.AddItem(IRI_TM_Amplify());
	Templates.AddItem(IRI_TM_Reflect());
	//Templates.AddItem(IRI_TM_Stunstrike());
	Templates.AddItem(IRI_TM_ReflectShot());
	Templates.AddItem(IRI_TM_Overcharge());
	Templates.AddItem(PurePassive('IRI_TM_Concentration', "img:///IRIPerkPackUI.UIPerk_WitchHunt", false /*cross class*/, 'eAbilitySource_Psionic', true /*display in UI*/)); // TODO: Icon
	
	Templates.AddItem(IRI_TM_SpectralStride());
	Templates.AddItem(IRI_TM_Siphon());
	Templates.AddItem(IRI_TM_Obelisk());
	Templates.AddItem(IRI_TM_Obelisk_Volt()); 

	Templates.AddItem(IRI_TM_AstralGrasp());
	Templates.AddItem(IRI_TM_AstralGrasp_Spirit());
	Templates.AddItem(IRI_TM_AstralGrasp_SpiritStun());
	Templates.AddItem(IRI_TM_AstralGrasp_SpiritDeath());

	return Templates;
}

static function X2AbilityTemplate IRI_TM_Obelisk()
{
	local X2AbilityTemplate				Template;
	local X2AbilityTarget_Cursor		Cursor;
	local X2AbilityMultiTarget_Radius	RadiusMultiTarget;
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2Effect_Obelisk				PillarEffect;
	//local X2AbilityCost_Focus			FocusCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Obelisk');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Pillar";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// TODO: Add visible range requirement
	Template.TargetingMethod = class'X2TargetingMethod_Pillar';

	Cursor = new class'X2AbilityTarget_Cursor';
	Cursor.bRestrictToSquadsightRange = true;
	Template.AbilityTargetStyle = Cursor;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = 0.25; // small amount so it just grabs one tile
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Costs

	// TODO: DEBUG ONLY
//FocusCost = new class'X2AbilityCost_Focus';
//FocusCost.FocusAmount = `GetConfigInt('IRI_TM_Obelisk_FocusCost');
//Template.AbilityCosts.AddItem(FocusCost);
//AddCooldown(Template, `GetConfigInt('IRI_TM_Obelisk_Cooldown'));

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Effects
	PillarEffect = new class'X2Effect_Obelisk';
	// Duration here is irrelevant, it will be overridden
	PillarEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);	
	PillarEffect.DestructibleArchetype = "FX_Templar_Pillar.Pillar_Destructible";
	PillarEffect.bRemoveWhenSourceDies = false; // Effect needs to be there for proper Volt visualization
	PillarEffect.bRemoveWhenTargetDies = false;	// in case Templar is killed by the attack that is visually interrupted by Volt
	Template.AddShooterEffect(PillarEffect);

	// State and Viz
	Template.CustomFireAnim = 'HL_Pillar';
	Template.ActivationSpeech = 'Pillar';
	Template.Hostility = eHostility_Defensive;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ConcealmentRule = eConceal_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_TemplarAbilitySet'.static.Pillar_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	Template.AdditionalAbilities.AddItem('IRI_TM_Obelisk_Volt');

	return Template;
}

static function X2AbilityTemplate IRI_TM_Obelisk_Volt()
{
	local X2AbilityTemplate							Template;
	local X2Condition_UnitProperty					TargetCondition;
	local X2Effect_ApplyWeaponDamage				DamageEffect;
	local X2Effect_ToHitModifier					HitModEffect;
	local X2Condition_AbilityProperty				AbilityCondition;
	local X2AbilityTag								AbilityTag;
	local X2Condition_ObeliskVolt					ObeliskCondition;
	local X2Effect_Persistent						BladestormTargetEffect;
	local X2Condition_UnitEffectsWithAbilitySource	BladestormTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Obelisk_Volt');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_volt";
	SetHidden(Template);

	// Targeting and Triggering
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Volt'; // Custom calc to force crits against Psionics for cosmetic effect.
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.TargetingMethod = none;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder'); // Triggered from X2Effect_Obelisk

	// Shooter Conditions
	//EffectsCondition = new class'X2Condition_UnitEffects';
	//EffectsCondition.AddRequireEffect(class'X2Effect_Obelisk'.default.EffectName, 'AA_MissingRequiredEffect');
	//Template.AbilityShooterConditions.AddItem(EffectsCondition);

	// Target Conditions
	ObeliskCondition = new class'X2Condition_ObeliskVolt';
	ObeliskCondition.DistanceTiles = `GetConfigInt("IRI_TM_Obelisk_Volt_Distance_Tiles");
	Template.AbilityTargetConditions.AddItem(ObeliskCondition);

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeCivilian = true;
	TargetCondition.ExcludeCosmetic = true;
	TargetCondition.ExcludeRobotic = false;
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	BladestormTargetCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	BladestormTargetCondition.AddExcludeEffect('IRI_TM_Obelisk_Volt_Target', 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(BladestormTargetCondition);

	//Template.AbilityTargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());

	BladestormTargetEffect = new class'X2Effect_Persistent';
	BladestormTargetEffect.BuildPersistentEffect(1, false, true, true, eGameRule_PlayerTurnEnd);
	BladestormTargetEffect.EffectName = 'IRI_TM_Obelisk_Volt_Target';
	BladestormTargetEffect.bApplyOnMiss = true;
	Template.AddTargetEffect(BladestormTargetEffect);

	// Effect - non-psionic
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludePsionic = true;
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'IRI_TM_Volt';
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.TargetConditions.AddItem(TargetCondition);
	Template.AddTargetEffect(DamageEffect);

	// Effect - psionic
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeNonPsionic = true;
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'IRI_TM_Volt_Psi';
	DamageEffect.bIgnoreArmor = true;
	DamageEffect.TargetConditions.AddItem(TargetCondition);
	Template.AddTargetEffect(DamageEffect);

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
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('IRI_TM_Aftershock');
	HitModEffect.TargetConditions.AddItem(default.LivingTargetOnlyProperty);
	HitModEffect.TargetConditions.AddItem(AbilityCondition);

	HitModEffect.EffectName = 'IRI_TM_Aftershock_Effect';
	HitModEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(HitModEffect);

	// State and Viz
	Template.ActionFireClass = class'X2Action_Fire_ObeliskVolt';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ObeliskVolt_BuildVisualization;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildInterruptGameStateFn = none;	// Not interruptible
	Template.Hostility = eHostility_Neutral;	// Not controllable by the player, so should be neutral
	Template.bSkipExitCoverWhenFiring = true;	// bugs out visualization if set to true.

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NormalChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

// Insert a flyover above the Obelisk when Volt activates and play some FX that are normally played by Volt animation.
static private function ObeliskVolt_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr		VisMgr;
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_PlayFlyover				FlyoverAction;
	local XComGameStateContext_Ability		AbilityContext;
	local XComGameState_Ability				AbilityState;
	local X2AbilityTemplate					AbilityTemplate;
	local XComGameState_Unit				SourceUnit;
	local XComGameState_Effect				ObeliskEffect;
	local XComGameState_Destructible		ObeliskState;
	local TTile								ObeliskFiringTile;
	local vector							ObeliskFiringLocation;
	local bool								bGoodAbility;
	local X2Action_PlayEffect				PlayEffect;
	local X2Action_PlayAkEvent				PlayAkEvent;
	local X2Action_TimedWait				TimedWait;
	local X2Action							ExitCover;
	local array<X2Action>					CommonParents;
	local X2Action_MarkerNamed				ReplaceAction;
	local X2Action							FindAction;
	local array<X2Action>					FindActions;

	// Custom X2Action_ExitCover without animation on the shooter
	ObeliskVoltStage1_BuildVisualization(VisualizeGameState);

	VisMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	SourceUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (SourceUnit == none)
		return;

	ExitCover = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_ExitCover',, SourceUnit.ObjectID);
	if (ExitCover == none)
		return;

	AbilityState = XComGameState_Ability(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return;

	ObeliskEffect = SourceUnit.GetUnitAffectedByEffectState('IRI_TM_Obelisk_Effect');
	if (ObeliskEffect == none)
		return;

	ObeliskState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(ObeliskEffect.CreatedObjectReference.ObjectID));
	if (ObeliskState == none)
		return;

	// TODO: Custom exit cover action
	// TODO: Vold casted twice on an enemy attack that killed the Templar??
	// TODO: Alter Aftershock effect so it doesn't pop in so suddenly. Or maybe that's Projectile Hit effect.

	bGoodAbility = SourceUnit.IsFriendlyToLocalPlayer();

	ActionMetaData.StateObject_OldState = ObeliskState;
	ActionMetaData.StateObject_NewState	= ObeliskState;
	ActionMetaData.VisualizeActor = ObeliskState.GetVisualizer();

	ObeliskFiringTile = ObeliskState.TileLocation;
	ObeliskFiringTile.Z += 3;
	ObeliskFiringLocation = `XWORLD.GetPositionFromTileCoordinates(ObeliskFiringTile);

	CommonParents = ExitCover.ParentActions;

	// Insert above Exit Cover Action to delay it for 0.8 sec
	TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, true,, ExitCover.ParentActions));
	TimedWait.DelayTimeSec = 0.8f;	

	// Boo hoo. Boo hoo hoo. Doesn't work for non-units.
	//FlyoverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, ExitCover.ParentActions));
    //FlyoverAction.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', bGoodAbility ? eColor_Good : eColor_Bad, AbilityTemplate.IconImage);

	// TODO: Figure out why this flyover plays only once.
	FlyoverAction = X2Action_PlayFlyover(class'X2Action_PlayFlyover'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, CommonParents));
	FlyoverAction.ActorRef.ObjectID = SourceUnit.ObjectID; // TODO: Maybe put Obelisk's object ID here.
	FlyoverAction.FlyoverMessage = AbilityTemplate.LocFlyOverText;
	FlyoverAction.FlyoverIcon = AbilityTemplate.IconImage;
	FlyoverAction.FlyoverLocation = ObeliskFiringLocation;
	FlyoverAction.MessageColor = bGoodAbility ? eColor_Good : eColor_Bad;

	ActionMetaData = ExitCover.Metadata; // Use actual unit metadata for other actions.

	PlayAkEvent = X2Action_PlayAkEvent(class'X2Action_PlayAkEvent'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, CommonParents));
	PlayAkEvent.AkEventPath = "XPACK_SoundCharacterFX.Templar_Volt_ChargeUp";
	PlayAkEvent.SoundLocation = ObeliskFiringLocation;

	PlayEffect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, CommonParents));
	PlayEffect.EffectName = "IRIObelisk.PS_Volt_Cast";
	PlayEffect.EffectLocation = ObeliskFiringLocation;

	//	Remove any instances of cinematic camera from the viz tree. Looks janky otherwise.
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_StartCinescriptCamera', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
	foreach FindActions(FindAction)
	{
		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		ReplaceAction.SetName("ReplaceCinescriptCamera");
		VisMgr.ReplaceNode(ReplaceAction, FindAction);
	}

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_EndCinescriptCamera', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
	foreach FindActions(FindAction)
	{
		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		ReplaceAction.SetName("ReplaceCinescriptCamera");
		VisMgr.ReplaceNode(ReplaceAction, FindAction);
	}
}


static private function X2AbilityTemplate IRI_TM_Siphon()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionCost;
	local array<name>					SkipExclusions;
	local X2Effect_Persistent			PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Siphon');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ReflectShot";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	//SkipExclusions.AddItem('Freeze'); // Arguably shouldn't be able to unfreeze themselves
 	Template.AddShooterEffectExclusions(SkipExclusions);

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingTargetUnitOnlyProperty);
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_Siphon');

	// Costs
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus');
	AddCooldown(Template, `GetConfigInt("IRI_TM_Siphon_Cooldown"));

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);

	// Effects
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.EffectName = 'IRI_TM_Siphon_Buff_Effect';
	PersistentEffect.BuildPersistentEffect(1, true);
	PersistentEffect.bRemoveWhenSourceDies = true;
	PersistentEffect.bRemoveWhenTargetDies = true;
	PersistentEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, default.strSiphonEffectDesc, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddShooterEffect(PersistentEffect);

	Template.AddTargetEffect(new class'X2Effect_Siphon');

	// State and Viz
	//Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.bShowActivation = true;
	Template.bSkipFireAction = false;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.CustomFireAnim = 'HL_Siphon';
	Template.CustomSelfFireAnim = 'HL_SiphonSelf';

	return Template;
}

static private function AddSiphonEffects(out X2AbilityTemplate Template)
{
	local X2Effect_RemoveEffects	RemoveEffects;
	local X2Effect_DLC_Day60Freeze	FreezeEffect;
	local X2Effect					Effect;

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('IRI_TM_Siphon_Buff_Effect');
	Template.AddShooterEffect(RemoveEffects);

	// Fire
	Effect = class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1);
	Effect.TargetConditions.AddItem(CreateUnitValueCondition('IRI_TM_Siphon_fire'));
	Template.AddTargetEffect(Effect);

	// Acid
	Effect = class'X2StatusEffects'.static.CreateAcidBurningStatusEffect(2, 1);
	Effect.TargetConditions.AddItem(CreateUnitValueCondition('IRI_TM_Siphon_acid'));
	Template.AddTargetEffect(Effect);

	// Poison
	Effect = class'X2StatusEffects'.static.CreatePoisonedStatusEffect();
	Effect.TargetConditions.AddItem(CreateUnitValueCondition('IRI_TM_Siphon_poison'));
	Template.AddTargetEffect(Effect);

	// Freeze
	if (`GetConfigBool("IRI_TM_Siphon_AllowFreeze"))
	{
		FreezeEffect = class'X2Effect_DLC_Day60Freeze'.static.CreateFreezeEffect(class'X2Item_DLC_Day60Grenades'.default.FROSTBOMB_MIN_RULER_FREEZE_DURATION, class'X2Item_DLC_Day60Grenades'.default.FROSTBOMB_MAX_RULER_FREEZE_DURATION);
		FreezeEffect.bApplyRulerModifiers = true;
		FreezeEffect.TargetConditions.AddItem(CreateUnitValueCondition('IRI_TM_Siphon_Frost'));
		Template.AddTargetEffect(FreezeEffect);

		Effect = class'X2Effect_DLC_Day60Freeze'.static.CreateFreezeRemoveEffects();
		Effect.TargetConditions.AddItem(CreateUnitValueCondition('IRI_TM_Siphon_Frost'));
		Template.AddTargetEffect(Effect);

		Template.AddTargetEffect(CreateClearUnitValueEffect('IRI_TM_Siphon_Frost'));
	}

	// Cleanse all values - use target effects array, cuz shooter effects seem to be processed before target effects
	// preventing unit value conditions from passing
	Template.AddTargetEffect(CreateClearUnitValueEffect('IRI_TM_Siphon_fire'));
	Template.AddTargetEffect(CreateClearUnitValueEffect('IRI_TM_Siphon_poison'));
	Template.AddTargetEffect(CreateClearUnitValueEffect('IRI_TM_Siphon_acid'));
}

static private function X2Effect CreateClearUnitValueEffect(const name ValueName)
{
	local X2Effect_ClearUnitValue ClearUnitValue;

	ClearUnitValue = new class'X2Effect_ClearUnitValue';
	ClearUnitValue.UnitValueName = ValueName;
	ClearUnitValue.bSource = true;

	return ClearUnitValue;
}
static private function X2Condition CreateUnitValueCondition(const name ValueName)
{
	local X2Condition_UnitValueSource UnitValue;

	UnitValue = new class'X2Condition_UnitValueSource';
	UnitValue.AddCheckValue(ValueName, 1);

	return UnitValue;
}


static private function X2AbilityTemplate IRI_TM_SpectralStride()
{
	local X2AbilityTemplate				Template;
	local X2Condition_UnitEffects		EffectsCondition;
	local X2Condition_UnitProperty		UnitPropertyCondition;
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2Effect_SpectralStride		SpectralStride;
	local X2Effect_AdditionalAnimSets	AnimEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_SpectralStride');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Amplify";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	ActionCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MomentumActionPoint);
	Template.AbilityCosts.AddItem(ActionCost);
	
//Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus'); // TODO DEBUG ONLY

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	//UnitPropertyCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddExcludeEffect(class'X2Effect_SpectralStride'.default.EffectName, 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	// Effects
	SpectralStride = new class'X2Effect_SpectralStride';
	SpectralStride.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnEnd);
	SpectralStride.AddTraversalChange( eTraversal_Phasing, true );
	SpectralStride.AddTraversalChange( eTraversal_JumpUp, true );
	SpectralStride.bRemoveWhenTargetDies = true;
	SpectralStride.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(SpectralStride);

	AnimEffect = new class'X2Effect_AdditionalAnimSets';
	AnimEffect.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnEnd);
	AnimEffect.AddAnimSetWithPath("IRISpectralStride.AS_SpectralStride_Target");
	AnimEffect.bRemoveWhenTargetDies = true;
	Template.AddTargetEffect(AnimEffect);

	// State and Viz
	Template.bShowActivation = true;
	Template.CinescriptCameraType = "IRI_TM_SpectralStride";
	Template.bFrameEvenWhenUnitIsHidden = true;
	SetFireAnim(Template, 'HL_SpectralStride');
	Template.ActivationSpeech = 'Exchange';
	Template.Hostility = eHostility_Neutral;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	return Template;
}

static private function X2Effect CreateConcentrationEffect()
{
	local X2Effect_Concentration ConcentrationEffect;

	ConcentrationEffect = new class'X2Effect_Concentration';
	ConcentrationEffect.BuildPersistentEffect(1, true);
	// TODO: Icon
	ConcentrationEffect.SetDisplayInfo(ePerkBuff_Penalty, `GetLocalizedString("IRI_TM_Concentration_EffectTitle"), `GetLocalizedString("IRI_TM_Concentration_EffectDesc"), "img:///IRIPerkPackUI.UIPerk_WitchHunt", true,, 'eAbilitySource_Psionic');

	ConcentrationEffect.TargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);

	// Can't apply the effect if we're already applying it to any unit
	// Can't apply the effect if we're missing the Concentration ability
	ConcentrationEffect.TargetConditions.AddItem(new class'X2Condition_Concentration');

	ConcentrationEffect.VFXTemplateName = "IRIVolt.PS_Concentration_Persistent";
	ConcentrationEffect.VFXSocket = 'FX_Chest'; // FX_Head
	ConcentrationEffect.VFXSocketsArrayName = 'BoneSocketActor';

	return ConcentrationEffect;
}


static private function X2AbilityTemplate IRI_TM_Aftershock()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('IRI_TM_Aftershock', "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Recoil", false /*cross class*/, 'eAbilitySource_Psionic', true /*display in UI*/);

	// Vanilla Aftershock requires vanilla Volt, lol
	Template.PrerequisiteAbilities.AddItem('IRI_TM_Volt');

	return Template;
}

static private function X2AbilityTemplate IRI_TM_Overcharge()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Overcharge	Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Overcharge');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Overcharge";

	SetPassive(Template);
	SetHidden(Template);
	Template.bUniqueSource = true;

	Effect = new class'X2Effect_Overcharge';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	return Template;
}


// Somewhat complicated ability. Explained in steps:
// 1. Use Astral Grasp on the target organic.
// 2. X2Effect_AstralGrasp will spawn a copy of the enemy unit (spirit/ghost) on a tile near the shooter,
// the spirit will visibly spawn standing right inside the target.
// Astral Grasp skips fire action in typical visualization,
// instead its fire action is created in X2Effect_AstralGrasp visualization,
// because the fire action needs to visualize against the spirit,
// pulling it out of the target's body, Skirmisher's Justice style.
// Perk content is used for the fire action visualization.
// 3. X2Effect_AstralGrasp will trigger an event when the spirit's unit state is created,
// which will trigger IRI_TM_AstralGrasp_Spirit ability.
// Perk content is used to create a "mind control"-like tether to the spirit's body.
// To make the tether visible when the spirit is getting pulled by Astral Grasp, 
// a MergeVis function is used to insert this ability's visualization tree
// after the spirit spawns inside the target's body, but before it is pulled out by Astral Grasp.
// 4. The effect used by Perk Content for tether is also used to track the connection 
// between the spirit and the body.
// If the spirit is killed, IRI_TM_AstralGrasp_SpiritDeath is triggered,
// which kills the unit who has this effect, Holy Warrior style.
// 5. X2Effect_AstralGraspSpirit is put on the Spirit by the IRI_TM_AstralGrasp_Spirit ability.
// It ensures the spirit can't dodge and other similarly reasonable stuff.
// The effect has the same duration as X2Effect_AstralGrasp, and when it expires, it despawns the spirit.
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

// TODO: Handle cases:
// 1. Grasp the spirit and kill the spirit
// 2. Grasp the spirit and kill the body
// 3. Grasp the spirit and let it expire
// 4. Grasping non-humanoid spirits
// 6. Fix camerawork when spirit is killed
// 8. Custom fire/pull animations and projectiles

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

	// Target Conditions - visible organic that's not immune to psi and mental and hasn't been grasped yet
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
	MentalImmunityCondition.ExcludeDamageTypes.AddItem('Psi');
	Template.AbilityTargetConditions.AddItem(MentalImmunityCondition);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect('IRI_X2Effect_AstralGrasp', 'AA_DuplicateEffectIgnored');
	// Can't grasp grasped spirits lol
	UnitEffectsCondition.AddExcludeEffect('IRI_TM_AstralGrasp_SpiritLink', 'AA_DuplicateEffectIgnored'); 
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// Effects
	// Spawns the spirit and visualizes pulling it out of the body
	AstralGrasp = new class'X2Effect_AstralGrasp';
	AstralGrasp.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	AstralGrasp.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(AstralGrasp);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, true));

	// State and Viz
	Template.bSkipFireAction = true; // Fire action is in the X2Effect_AstralGrasp's visualization
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'Justice';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.Hostility = eHostility_Offensive;
	//Template.ActionFireClass = class'XComGame.X2Action_ViperGetOverHere';

	//Template.CinescriptCameraType = "Psionic_FireAtUnit";;
	//Template.BuildVisualizationFn = AstralGrasp_BuildVisualization;
	//Template.BuildVisualizationFn = class'X2Ability_SkirmisherAbilitySet'.static.Justice_BuildVisualization;
	//Template.CustomFireAnim = 'HL_StunStrike';

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.AddTargetEffect(CreateConcentrationEffect());

	return Template;
}

// Main purpose of this ability is to create a visible tether
// between the spirit and the body via Perk Content
static private function X2AbilityTemplate IRI_TM_AstralGrasp_Spirit()
{
	local X2AbilityTemplate					Template;
	local X2Effect_AstralGraspSpirit		Effect;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Persistent				PerkEffect;
	local X2Effect_AdditionalAnimSets		AnimSetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp_Spirit');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ThunderLance";
	SetHidden(Template);
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	//Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger); // idk doesn't work

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'IRI_AstralGrasp_SpiritSpawned'; // Triggered from X2Effect_AstralGrasp
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 100;
	Trigger.ListenerData.EventFn = AstralGrasp_SpiritSpawned_Trigger;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	//Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Effects
	Effect = new class'X2Effect_AstralGraspSpirit';
	Effect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	Effect.EffectName = 'IRI_TM_AstralGrasp_SpiritLink';
	Effect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddShooterEffect(Effect);

	// AnimSet with the death animation
	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath("IRIAstralGrasp.AS_PsiDeath");
	AnimSetEffect.BuildPersistentEffect(1, true);
	AnimSetEffect.bRemoveWhenTargetDies = false;
	AnimSetEffect.bRemoveWhenSourceDies = false;
	Template.AddShooterEffect(AnimSetEffect);

	// Used by Perk Content to create a tether and to kill the original unit when the spirit dies
	PerkEffect = new class'X2Effect_Persistent';
	PerkEffect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnBegin);
	PerkEffect.bRemoveWhenTargetDies = true;	// Remove tether when the body is killed
	PerkEffect.bRemoveWhenSourceDies = false;
	PerkEffect.EffectName = 'IRI_AstralGrasp_SpiritKillEffect';
	Template.AddTargetEffect(PerkEffect);

	// State and Viz
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = AstralGrasp_Spirit_MergeVisualization;
	Template.Hostility = eHostility_Neutral;

	return Template;
}

static private function EventListenerReturn AstralGrasp_SpiritSpawned_Trigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Ability	TriggerAbility;

	SpawnedUnit = XComGameState_Unit(EventSource);
	if (SpawnedUnit == none)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventData);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	TriggerAbility = XComGameState_Ability(CallbackData);
	if (TriggerAbility == none)
		return ELR_NoInterrupt;

	`AMLOG("Triggering Spirint Spawned ability at:" @ TargetUnit.GetFullName());

	TriggerAbility.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);

	return ELR_NoInterrupt;
}

// Use a custom Merge Vis function to make this ability visualize (create a tether between body and spirit) 
// after the spirit has been spawned but before it's been pulled out of the body
static private function AstralGrasp_Spirit_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	class'Help'.static.InsertAfterMarker_MergeVisualization(BuildTree, VisualizationTree, 'IRI_AstralGrasp_MarkerStart');
}


// Stun the spirit. Moved to the separate ability for visualization purposes.
static private function X2AbilityTemplate IRI_TM_AstralGrasp_SpiritStun()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Persistent				StunnedEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp_SpiritStun');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ThunderLance";
	SetHidden(Template);
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'IRI_AstralGrasp_SpiritSpawned'; // Triggered from X2Effect_AstralGrasp
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 100;
	Trigger.ListenerData.EventFn = AstralGrasp_SpiritSpawned_Trigger;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Stun the spirit
	StunnedEffect = class'X2Effect_Stunned_AstralGrasp'.static.CreateStunnedStatusEffect(2, 100);
	StunnedEffect.DamageTypes.Length = 0;
	StunnedEffect.DamageTypes.AddItem('Psi');
	StunnedEffect.bRemoveWhenTargetDies = true;
	Template.AddShooterEffect(StunnedEffect);

	// State and Viz
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.bUniqueSource = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = AstralGrasp_SpiritStun_MergeVisualization;
	Template.Hostility = eHostility_Neutral;

	return Template;
}

// Use a custom Merge Vis function to make this ability visualize (stun the spawned unit) 
// after the spirit has been pulled out of the body
static private function AstralGrasp_SpiritStun_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	class'Help'.static.InsertAfterMarker_MergeVisualization(BuildTree, VisualizationTree, 'IRI_AstralGrasp_UnitSpawned_MarkerStart');
}

// Copy of the HolyWarriorDeath ability.
static private function X2AbilityTemplate IRI_TM_AstralGrasp_SpiritDeath()
{
	local X2AbilityTemplate								Template;
	local X2AbilityTrigger_EventListener				DeathEventListener;
	local X2Condition_UnitEffectsWithAbilitySource		TargetEffectCondition;
	local X2Effect_HolyWarriorDeath						HolyWarriorDeathEffect;
	local X2Effect_RemoveEffects						RemoveEffects;
	local X2Effect_AstralGrasp_OverrideDeathAction		DeathActionEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_AstralGrasp_SpiritDeath');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ThunderLance";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	SetHidden(Template);

	// Targetind and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// This ability fires when the owner dies
	DeathEventListener = new class'X2AbilityTrigger_EventListener';
	DeathEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DeathEventListener.ListenerData.EventID = 'UnitDied';
	DeathEventListener.ListenerData.Filter = eFilter_Unit;
	DeathEventListener.ListenerData.EventFn = AstralGrasp_SpiritDeath_EventListenerTrigger;
	Template.AbilityTriggers.AddItem(DeathEventListener);

	// Target Conditions
	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect('IRI_AstralGrasp_SpiritKillEffect', 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);

	// Effects
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.StunnedName);
	Template.AddShooterEffect(RemoveEffects);

	DeathActionEffect = new class'X2Effect_AstralGrasp_OverrideDeathAction';
	DeathActionEffect.DeathActionClass = class'X2Action_AstralGraspSpiritDeath';
	DeathActionEffect.EffectName = 'IRI_SpiritDeathActionEffect';
	Template.AddShooterEffect(DeathActionEffect);

	HolyWarriorDeathEffect = new class'X2Effect_HolyWarriorDeath';
	HolyWarriorDeathEffect.DelayTimeS = 2.0f; // For visualization purposes
	Template.AddTargetEffect(HolyWarriorDeathEffect);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('IRI_AstralGrasp_SpiritKillEffect');
	Template.AddTargetEffect(RemoveEffects);

	// State and Viz
	Template.Hostility = eHostility_Neutral;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.CinescriptCameraType = "HolyWarrior_Death";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.MergeVisualizationFn = class'X2Ability_AdvPriest'.static.HolyWarriorDeath_MergeVisualization;

	return Template;
}

static private function EventListenerReturn AstralGrasp_SpiritDeath_EventListenerTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Unit	TargetUnit;
	local UnitValue				UV;

	SpawnedUnit = XComGameState_Unit(EventSource);
	if (SpawnedUnit == none)
		return ELR_NoInterrupt;

	if (!SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false);

	return ELR_NoInterrupt;
}


static private function X2AbilityTemplate IRI_TM_Reflect()
{
	local X2AbilityTemplate				Template;
	local X2Effect_IncrementUnitValue	ParryUnitValue;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Effect_Reflect				Effect;
	local X2AbilityCost_Focus			FocusCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_Reflect');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.OverrideAbilityAvailabilityFn = Reflect_OverrideAbilityAvailability;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ReflectShot";

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
 	Template.AddShooterEffectExclusions();

	// Costs
	FocusCost = new class'X2AbilityCost_Focus';
	FocusCost.bFreeCost = true; // Actual Focus cost is applied by Reflect Shot.
	Template.AbilityCosts.AddItem(FocusCost);

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

	Effect = new class'X2Effect_Reflect'; // Not a Firaxis class
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
	Template.AdditionalAbilities.AddItem('IRI_TM_ReflectShot');

	return Template;
}

// Same as Parry, but later
static private function Reflect_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success' || // Focus is checked before Action Points, so have to check Action Points explicitly
		Action.AvailableCode == 'AA_CannotAfford_Focus' && OwnerState.ActionPoints.Find(class'X2CharacterTemplateManager'.default.MomentumActionPoint) != INDEX_NONE)
	{
		Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.PARRY_PRIORITY + 2;
		Action.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	}
	else
	{
		Action.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	}
}

static private function X2AbilityTemplate IRI_TM_ReflectShot()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTrigger_EventListener		EventListener;
	local X2Effect_ApplyReflectDamage			DamageEffect;
	local X2AbilityToHitCalc_StandardAim		StandardAim;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TM_ReflectShot');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ReflectShot";
	SetHidden(Template);

	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIgnoreCoverBonus = true;
	Template.AbilityToHitCalc = StandardAim;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.EventID = 'AbilityActivated';
	EventListener.ListenerData.Filter = eFilter_None;
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.TemplarReflectListener;
	Template.AbilityTriggers.AddItem(EventListener);

	// Costs
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Focus');

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	
	DamageEffect = new class'X2Effect_ApplyReflectDamage';
	DamageEffect.EffectDamageValue.DamageType = 'Psi';
	Template.AddTargetEffect(DamageEffect);

	// State and Viz
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.CustomFireAnim = 'HL_IRI_ReflectFire';
	Template.CustomFireKillAnim = 'HL_IRI_ReflectFire';
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.MergeVisualizationFn = class'X2Ability_TemplarAbilitySet'.static.ReflectShotMergeVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	//Template.AddTargetEffect(CreateConcentrationEffect());

	return Template;
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

	Template.AddTargetEffect(CreateConcentrationEffect());

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
	TargetCondition.TreatMindControlledSquadmateAsHostile = true;
	TargetCondition.FailOnNonUnits = false;
	TargetCondition.ExcludeCivilian = true;
	TargetCondition.ExcludeCosmetic = true;
	TargetCondition.ExcludeRobotic = false;
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
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('IRI_TM_Aftershock');
	HitModEffect.TargetConditions.AddItem(default.LivingTargetOnlyProperty);
	HitModEffect.TargetConditions.AddItem(AbilityCondition);

	HitModEffect.EffectName = 'IRI_TM_Aftershock_Effect';
	HitModEffect.DuplicateResponse = eDupe_Ignore;

	//HitModEffect.VFXTemplateName = "IRIVolt.PS_Aftershock";
	//HitModEffect.VFXSocket = 'FX_Chest'; // FX_Head
	//HitModEffect.VFXSocketsArrayName = 'BoneSocketActor';
	// Disspates Aftershock FX upon target death/duration
	//HitModEffect.EffectRemovedVisualizationFn = AftershockEffectRemovedVisualization;

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

	//Template.AddTargetEffect(CreateConcentrationEffect());
	//Template.AddMultiTargetEffect(CreateConcentrationEffect());

	return Template;
}

static private function AftershockEffectRemovedVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayDeathEffect	EffectAction;
	local XGUnit					VisualizeUnit;
	local XComUnitPawn				UnitPawn;

	VisualizeUnit = XGUnit(ActionMetadata.VisualizeActor);
	if (VisualizeUnit == none)
		return;

	UnitPawn = VisualizeUnit.GetPawn();
	if (UnitPawn == none || UnitPawn.Mesh == none)
		return;

	// Use a custom effect that will get the effect location from the pawn mesh when running, not when building visualization.
	EffectAction = X2Action_PlayDeathEffect(class'X2Action_PlayDeathEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	EffectAction.EffectName = "IRIVolt.PS_Aftershock_Dissipate";
	EffectAction.PawnMesh = UnitPawn.Mesh;
	EffectAction.AttachToSocketName = 'FX_Chest';
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

	Template.AddTargetEffect(CreateConcentrationEffect());
	AddSiphonEffects(Template);

	return Template;
}


static private function X2AbilityTemplate IRI_TM_SoulShot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2AbilityToHitCalc_StandardAim	StandardAim;

	local X2AbilityMultiTarget_Cone			ConeMultiTarget;

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

	Template.AddTargetEffect(CreateConcentrationEffect());
	AddSiphonEffects(Template);

	ConeMultiTarget = new class'X2AbilityMultiTarget_Cone';
	ConeMultiTarget.ConeEndDiameter = class'X2Ability_TemplarAbilitySet'.default.ArcWaveConeEndDiameterTiles * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.ConeLength = class'X2Ability_TemplarAbilitySet'.default.ArcWaveConeLengthTiles * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.fTargetRadius = Sqrt(Square(ConeMultiTarget.ConeEndDiameter / 2) + Square(ConeMultiTarget.ConeLength)) * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	ConeMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	ConeMultiTarget.bLockShooterZ = true;
	Template.AbilityMultiTargetStyle = ConeMultiTarget;
	Template.TargetingMethod = class'X2TargetingMethod_ArcWave';
	Template.ActionFireClass = class'X2Action_Fire_Wave';
	Template.AddMultiTargetEffect(WeaponDamageEffect);
	
	return Template;
}



// Unfinished and unused
// No visible projectile? Because of no damage effect?
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
	TargetCondition.TreatMindControlledSquadmateAsHostile = true;
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


static private function ObeliskVoltStage1_BuildVisualization(XComGameState VisualizeGameState)
{	
	//general
	local XComGameStateHistory	History;
	local XComGameStateVisualizationMgr VisualizationMgr;

	//visualizers
	local Actor	TargetVisualizer, ShooterVisualizer;

	//actions
	local X2Action							AddedAction;
	local X2Action							FireAction;
	local X2Action_MoveTurn					MoveTurnAction;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyover;
	local X2Action_ExitCover				ExitCoverAction;
	local X2Action_MoveTeleport				TeleportMoveAction;
	local X2Action_Delay					MoveDelay;
	local X2Action_MoveEnd					MoveEnd;
	local X2Action_MarkerNamed				JoinActions;
	local array<X2Action>					LeafNodes;
	local X2Action_WaitForAnotherAction		WaitForFireAction;

	//state objects
	local XComGameState_Ability				AbilityState;
	local XComGameState_EnvironmentDamage	EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_InteractiveObject	InteractiveObject;
	local XComGameState_BaseObject			TargetStateObject;
	local XComGameState_Item				SourceWeapon;
	local StateObjectReference				ShootingUnitRef;

	//interfaces
	local X2VisualizerInterface			TargetVisualizerInterface, ShooterVisualizerInterface;

	//contexts
	local XComGameStateContext_Ability	Context;
	local AbilityInputContext			AbilityContext;

	//templates
	local X2AbilityTemplate	AbilityTemplate;
	local X2AmmoTemplate	AmmoTemplate;
	local X2WeaponTemplate	WeaponTemplate;
	local array<X2Effect>	MultiTargetEffects;

	//Tree metadata
	local VisualizationActionMetadata   InitData;
	local VisualizationActionMetadata   BuildData;
	local VisualizationActionMetadata   SourceData, InterruptTrack;

	local XComGameState_Unit TargetUnitState;	
	local name         ApplyResult;

	//indices
	local int	EffectIndex, TargetIndex;
	local int	TrackIndex;
	local int	WindowBreakTouchIndex;

	//flags
	local bool	bSourceIsAlsoTarget;
	local bool	bMultiSourceIsAlsoTarget;
	local bool  bPlayedAttackResultNarrative;
			
	// good/bad determination
	local bool bGoodAbility;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityContext = Context.InputContext;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.AbilityRef.ObjectID));
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.AbilityTemplateName);
	ShootingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter, part I. We split this into two parts since
	//in some situations the shooter can also be a target
	//****************************************************************************************
	ShooterVisualizer = History.GetVisualizer(ShootingUnitRef.ObjectID);
	ShooterVisualizerInterface = X2VisualizerInterface(ShooterVisualizer);

	SourceData = InitData;
	SourceData.StateObject_OldState = History.GetGameStateForObjectID(ShootingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceData.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(ShootingUnitRef.ObjectID);
	if (SourceData.StateObject_NewState == none)
		SourceData.StateObject_NewState = SourceData.StateObject_OldState;
	SourceData.VisualizeActor = ShooterVisualizer;	

	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.ItemObject.ObjectID));
	if (SourceWeapon != None)
	{
		WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
		AmmoTemplate = X2AmmoTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState));
	}

	bGoodAbility = XComGameState_Unit(SourceData.StateObject_NewState).IsFriendlyToLocalPlayer();

	if( Context.IsResultContextMiss() && AbilityTemplate.SourceMissSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceMissSpeech, bGoodAbility ? eColor_Bad : eColor_Good);
	}
	else if( Context.IsResultContextHit() && AbilityTemplate.SourceHitSpeech != '' )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceHitSpeech, bGoodAbility ? eColor_Good : eColor_Bad);
	}

	if( !AbilityTemplate.bSkipFireAction || Context.InputContext.MovementPaths.Length > 0 )
	{
		ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover_ObeliskVolt'.static.AddToVisualizationTree(SourceData, Context));
		ExitCoverAction.bSkipExitCoverVisualization = AbilityTemplate.bSkipExitCoverWhenFiring;

		// if this ability has a built in move, do it right before we do the fire action
		if(Context.InputContext.MovementPaths.Length > 0)
		{			
			// note that we skip the stop animation since we'll be doing our own stop with the end of move attack
			class'X2VisualizerHelpers'.static.ParsePath(Context, SourceData, AbilityTemplate.bSkipMoveStop);

			//  add paths for other units moving with us (e.g. gremlins moving with a move+attack ability)
			if (Context.InputContext.MovementPaths.Length > 1)
			{
				for (TrackIndex = 1; TrackIndex < Context.InputContext.MovementPaths.Length; ++TrackIndex)
				{
					BuildData = InitData;
					BuildData.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
					BuildData.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(Context.InputContext.MovementPaths[TrackIndex].MovingUnitRef.ObjectID);
					MoveDelay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(BuildData, Context));
					MoveDelay.Duration = class'X2Ability_DefaultAbilitySet'.default.TypicalMoveDelay;
					class'X2VisualizerHelpers'.static.ParsePath(Context, BuildData, AbilityTemplate.bSkipMoveStop);	
				}
			}

			if( !AbilityTemplate.bSkipFireAction )
			{
				MoveEnd = X2Action_MoveEnd(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveEnd', SourceData.VisualizeActor));				

				if (MoveEnd != none)
				{
					// add the fire action as a child of the node immediately prior to the move end
					AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, none, MoveEnd.ParentActions);

					// reconnect the move end action as a child of the fire action, as a special end of move animation will be performed for this move + attack ability
					VisualizationMgr.DisconnectAction(MoveEnd);
					VisualizationMgr.ConnectAction(MoveEnd, VisualizationMgr.BuildVisTree, false, AddedAction);
				}
				else
				{
					//See if this is a teleport. If so, don't perform exit cover visuals
					TeleportMoveAction = X2Action_MoveTeleport(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_MoveTeleport', SourceData.VisualizeActor));
					if (TeleportMoveAction != none)
					{
						//Skip the FOW Reveal ( at the start of the path ). Let the fire take care of it ( end of the path )
						ExitCoverAction.bSkipFOWReveal = true;
					}

					AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, SourceData.LastActionAdded);
				}
			}
		}
		else
		{
			//If we were interrupted, insert a marker node for the interrupting visualization code to use. In the move path version above, it is expected for interrupts to be 
			//done during the move.
			if (Context.InterruptionStatus != eInterruptionStatus_None)
			{
				//Insert markers for the subsequent interrupt to insert into
				class'X2Action'.static.AddInterruptMarkerPair(SourceData, Context, ExitCoverAction);
			}

			if (!AbilityTemplate.bSkipFireAction)
			{
				// no move, just add the fire action. Parent is exit cover action if we have one
				AddedAction = AbilityTemplate.ActionFireClass.static.AddToVisualizationTree(SourceData, Context, false, SourceData.LastActionAdded);
			}			
		}

		if( !AbilityTemplate.bSkipFireAction )
		{
			FireAction = AddedAction;

			class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackBegin', FireAction.ParentActions[0]);

			if( AbilityTemplate.AbilityToHitCalc != None )
			{
				X2Action_Fire(AddedAction).SetFireParameters(Context.IsResultContextHit());
			}
		}
	}

	//If there are effects added to the shooter, add the visualizer actions for them
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, SourceData, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));		
	}
	//****************************************************************************************

	//Configure the visualization track for the target(s). This functionality uses the context primarily
	//since the game state may not include state objects for misses.
	//****************************************************************************************	
	bSourceIsAlsoTarget = AbilityContext.PrimaryTarget.ObjectID == AbilityContext.SourceObject.ObjectID; //The shooter is the primary target
	if (AbilityTemplate.AbilityTargetEffects.Length > 0 &&			//There are effects to apply
		AbilityContext.PrimaryTarget.ObjectID > 0)				//There is a primary target
	{
		TargetVisualizer = History.GetVisualizer(AbilityContext.PrimaryTarget.ObjectID);
		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

		if( bSourceIsAlsoTarget )
		{
			BuildData = SourceData;
		}
		else
		{
			BuildData = InterruptTrack;        //  interrupt track will either be empty or filled out correctly
		}

		BuildData.VisualizeActor = TargetVisualizer;

		TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
		if( TargetStateObject != none )
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.PrimaryTarget.ObjectID, 
															   BuildData.StateObject_OldState, BuildData.StateObject_NewState,
															   eReturnType_Reference,
															   VisualizeGameState.HistoryIndex);
			`assert(BuildData.StateObject_NewState == TargetStateObject);
		}
		else
		{
			//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
			//and show no change.
			BuildData.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.PrimaryTarget.ObjectID);
			BuildData.StateObject_NewState = BuildData.StateObject_OldState;
		}

		// if this is a melee attack, make sure the target is facing the location he will be melee'd from
		if(!AbilityTemplate.bSkipFireAction 
			&& !bSourceIsAlsoTarget 
			&& AbilityContext.MovementPaths.Length > 0
			&& AbilityContext.MovementPaths[0].MovementData.Length > 0
			&& XGUnit(TargetVisualizer) != none)
		{
			MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(BuildData, Context, false, ExitCoverAction));
			MoveTurnAction.m_vFacePoint = AbilityContext.MovementPaths[0].MovementData[AbilityContext.MovementPaths[0].MovementData.Length - 1].Position;
			MoveTurnAction.m_vFacePoint.Z = TargetVisualizerInterface.GetTargetingFocusLocation().Z;
			MoveTurnAction.UpdateAimTarget = true;

			// Jwats: Add a wait for ability effect so the idle state machine doesn't process!
			WaitForFireAction = X2Action_WaitForAnotherAction(class'X2Action_WaitForAnotherAction'.static.AddToVisualizationTree(BuildData, Context, false, MoveTurnAction));
			WaitForFireAction.ActionToWaitFor = FireAction;
		}

		//Pass in AddedAction (Fire Action) as the LastActionAdded if we have one. Important! As this is automatically used as the parent in the effect application sub functions below.
		if (AddedAction != none && AddedAction.IsA('X2Action_Fire'))
		{
			BuildData.LastActionAdded = AddedAction;
		}
		
		//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
		//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
		//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			ApplyResult = Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]);

			// Target effect visualization
			if( !Context.bSkipAdditionalVisualizationSteps )
			{
				AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
			}

			// Source effect visualization
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
		}

		//the following is used to handle Rupture flyover text
		TargetUnitState = XComGameState_Unit(BuildData.StateObject_OldState);
		if (TargetUnitState != none &&
			XComGameState_Unit(BuildData.StateObject_OldState).GetRupturedValue() == 0 &&
			XComGameState_Unit(BuildData.StateObject_NewState).GetRupturedValue() > 0)
		{
			//this is the frame that we realized we've been ruptured!
			class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildData);
		}

		if (AbilityTemplate.bAllowAmmoEffects && AmmoTemplate != None)
		{
			for (EffectIndex = 0; EffectIndex < AmmoTemplate.TargetEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(AmmoTemplate.TargetEffects[EffectIndex]);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
				AmmoTemplate.TargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}
		}
		if (AbilityTemplate.bAllowBonusWeaponEffects && WeaponTemplate != none)
		{
			for (EffectIndex = 0; EffectIndex < WeaponTemplate.BonusWeaponEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindTargetEffectApplyResult(WeaponTemplate.BonusWeaponEffects[EffectIndex]);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);
				WeaponTemplate.BonusWeaponEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}
		}

		if (Context.IsResultContextMiss() && (AbilityTemplate.LocMissMessage != "" || AbilityTemplate.TargetMissSpeech != ''))
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context, false, BuildData.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, AbilityTemplate.TargetMissSpeech, bGoodAbility ? eColor_Bad : eColor_Good);
		}
		else if( Context.IsResultContextHit() && (AbilityTemplate.LocHitMessage != "" || AbilityTemplate.TargetHitSpeech != '') )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(BuildData, Context, false, BuildData.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocHitMessage, AbilityTemplate.TargetHitSpeech, bGoodAbility ? eColor_Good : eColor_Bad);
		}

		if (!bPlayedAttackResultNarrative)
		{
			class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackResult');
			bPlayedAttackResultNarrative = true;
		}

		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildData);
		}

		if( bSourceIsAlsoTarget )
		{
			SourceData = BuildData;
		}
	}

	if (AbilityTemplate.bUseLaunchedGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState)).LaunchedGrenadeEffects;
	}
	else if (AbilityTemplate.bUseThrownGrenadeEffects)
	{
		MultiTargetEffects = X2GrenadeTemplate(SourceWeapon.GetMyTemplate()).ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
	}

	//  Apply effects to multi targets - don't show multi effects for burst fire as we just want the first time to visualize
	if( MultiTargetEffects.Length > 0 && AbilityContext.MultiTargets.Length > 0 && X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle) == none)
	{
		for( TargetIndex = 0; TargetIndex < AbilityContext.MultiTargets.Length; ++TargetIndex )
		{	
			bMultiSourceIsAlsoTarget = false;
			if( AbilityContext.MultiTargets[TargetIndex].ObjectID == AbilityContext.SourceObject.ObjectID )
			{
				bMultiSourceIsAlsoTarget = true;
				bSourceIsAlsoTarget = bMultiSourceIsAlsoTarget;				
			}

			TargetVisualizer = History.GetVisualizer(AbilityContext.MultiTargets[TargetIndex].ObjectID);
			TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

			if( bMultiSourceIsAlsoTarget )
			{
				BuildData = SourceData;
			}
			else
			{
				BuildData = InitData;
			}
			BuildData.VisualizeActor = TargetVisualizer;

			// if the ability involved a fire action and we don't have already have a potential parent,
			// all the target visualizations should probably be parented to the fire action and not rely on the auto placement.
			if( (BuildData.LastActionAdded == none) && (FireAction != none) )
				BuildData.LastActionAdded = FireAction;

			TargetStateObject = VisualizeGameState.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
			if( TargetStateObject != none )
			{
				History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID, 
																	BuildData.StateObject_OldState, BuildData.StateObject_NewState,
																	eReturnType_Reference,
																	VisualizeGameState.HistoryIndex);
				`assert(BuildData.StateObject_NewState == TargetStateObject);
			}			
			else
			{
				//If TargetStateObject is none, it means that the visualize game state does not contain an entry for the primary target. Use the history version
				//and show no change.
				BuildData.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.MultiTargets[TargetIndex].ObjectID);
				BuildData.StateObject_NewState = BuildData.StateObject_OldState;
			}
		
			//Add any X2Actions that are specific to this effect being applied. These actions would typically be instantaneous, showing UI world messages
			//playing any effect specific audio, starting effect specific effects, etc. However, they can also potentially perform animations on the 
			//track actor, so the design of effect actions must consider how they will look/play in sequence with other effects.
			for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
			{
				ApplyResult = Context.FindMultiTargetEffectApplyResult(MultiTargetEffects[EffectIndex], TargetIndex);

				// Target effect visualization
				MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, ApplyResult);

				// Source effect visualization
				MultiTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceData, ApplyResult);
			}			

			//the following is used to handle Rupture flyover text
			TargetUnitState = XComGameState_Unit(BuildData.StateObject_OldState);
			if (TargetUnitState != none && 
				XComGameState_Unit(BuildData.StateObject_OldState).GetRupturedValue() == 0 &&
				XComGameState_Unit(BuildData.StateObject_NewState).GetRupturedValue() > 0)
			{
				//this is the frame that we realized we've been ruptured!
				class 'X2StatusEffects'.static.RuptureVisualization(VisualizeGameState, BuildData);
			}
			
			if (!bPlayedAttackResultNarrative)
			{
				class'XComGameState_NarrativeManager'.static.BuildVisualizationForDynamicNarrative(VisualizeGameState, false, 'AttackResult');
				bPlayedAttackResultNarrative = true;
			}

			if( TargetVisualizerInterface != none )
			{
				//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
				TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildData);
			}

			if( bMultiSourceIsAlsoTarget )
			{
				SourceData = BuildData;
			}			
		}
	}
	//****************************************************************************************

	//Finish adding the shooter's track
	//****************************************************************************************
	if( !bSourceIsAlsoTarget && ShooterVisualizerInterface != none)
	{
		ShooterVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, SourceData);				
	}	

	//  Handle redirect visualization
	TypicalAbility_AddEffectRedirects(VisualizeGameState, SourceData);

	//****************************************************************************************

	//Configure the visualization tracks for the environment
	//****************************************************************************************

	if (ExitCoverAction != none)
	{
		ExitCoverAction.ShouldBreakWindowBeforeFiring( Context, WindowBreakTouchIndex );
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		BuildData = InitData;
		BuildData.VisualizeActor = none;
		BuildData.StateObject_NewState = EnvironmentDamageEvent;
		BuildData.StateObject_OldState = EnvironmentDamageEvent;

		// if this is the damage associated with the exit cover action, we need to force the parenting within the tree
		// otherwise LastActionAdded with be 'none' and actions will auto-parent.
		if ((ExitCoverAction != none) && (WindowBreakTouchIndex > -1))
		{
			if (EnvironmentDamageEvent.HitLocation == AbilityContext.ProjectileEvents[WindowBreakTouchIndex].HitLocation)
			{
				BuildData.LastActionAdded = ExitCoverAction;
			}
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');	
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		BuildData = InitData;
		BuildData.VisualizeActor = none;
		BuildData.StateObject_NewState = WorldDataUpdate;
		BuildData.StateObject_OldState = WorldDataUpdate;

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');		
		}

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');
		}

		for (EffectIndex = 0; EffectIndex < MultiTargetEffects.Length; ++EffectIndex)
		{
			MultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildData, 'AA_Success');	
		}
	}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification. 
		// Move logic is taken from MoveAbility_BuildVisualization, which only has special case handling for AI patrol movement ( which wouldn't happen here )
		if ( Context.InputContext.MovementPaths.Length > 0 || (InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim()) ) //Is this a closed door?
		{
			BuildData = InitData;
			//Don't necessarily have a previous state, so just use the one we know about
			BuildData.StateObject_OldState = InteractiveObject;
			BuildData.StateObject_NewState = InteractiveObject;
			BuildData.VisualizeActor = History.GetVisualizer(InteractiveObject.ObjectID);

			class'X2Action_BreakInteractActor'.static.AddToVisualizationTree(BuildData, Context);
		}
	}
	
	//Add a join so that all hit reactions and other actions will complete before the visualization sequence moves on. In the case
	// of fire but no enter cover then we need to make sure to wait for the fire since it isn't a leaf node
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, LeafNodes);

	if (!AbilityTemplate.bSkipFireAction)
	{
		if (!AbilityTemplate.bSkipExitCoverWhenFiring)
		{			
			LeafNodes.AddItem(class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceData, Context, false, FireAction));
		}
		else
		{
			LeafNodes.AddItem(FireAction);
		}
	}
	
	if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0)
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceData, Context, false, none, LeafNodes));
		JoinActions.SetName("Join");
	}
}