class X2Ability_ClassRework extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Sharpshooter
	Templates.AddItem(IRI_SH_SteadyHands());
	Templates.AddItem(PurePassive('IRI_SH_SteadyHands_Passive', "img:///UILibrary_PerkIcons.UIPerk_steadyhands", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_SH_Standoff());
	Templates.AddItem(IRI_SH_Standoff_Shot());
	Templates.AddItem(IRI_SH_ScootAndShoot());
	

	// Ranger
	Templates.AddItem(IRI_RN_ZephyrStrike());
	Templates.AddItem(IRI_RN_TacticalAdvance());
	Templates.AddItem(PurePassive('IRI_RN_TacticalAdvance_Passive', "img:///IRIPerkPackUI.UIPerk_TacticalAdvance", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_RN_Intercept());
	Templates.AddItem(IRI_RN_Intercept_Return());
	Templates.AddItem(IRI_RN_Intercept_Attack());

	// Grenadier
	Templates.AddItem(IRI_GN_OrdnancePouch());
	Templates.AddItem(IRI_GN_CollateralDamage());
	Templates.AddItem(IRI_GN_CollateralDamage_Passive());

	// Specialist
	Templates.AddItem(IRI_SP_AutonomousProtocols());
	Templates.AddItem(IRI_SP_Overclock());
	Templates.AddItem(IRI_SP_ScoutingProtocol());
	Templates.AddItem(IRI_SP_ConstantReadiness());

	// AWC
	Templates.AddItem(PurePassive('IRI_AWC_MedicinePouch', "img:///UILibrary_PerkIcons.UIPerk_item_medikit", true /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	
	return Templates;
}

static private function X2AbilityTemplate IRI_SP_ConstantReadiness()
{
	local X2AbilityTemplate					Template;
	local X2Effect_SP_ConstantReadiness		Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SP_ConstantReadiness');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_evervigilant";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_SP_ConstantReadiness';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.PrerequisiteAbilities.AddItem('NOT_EverVigilant');

	return Template;
}

static private function X2AbilityTemplate IRI_SP_ScoutingProtocol()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityMultiTarget_Radius		RadiusMultiTarget;
	local X2Effect_PersistentSquadViewer    ViewerEffect;
	local X2Effect_ScanningProtocol			ScanningEffect;
	local X2Condition_UnitProperty			CivilianProperty;
	local X2AbilityTarget_Cursor			CursorTarget;
	local X2AbilityCost_Charges				ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SP_ScoutingProtocol');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sensorsweep";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	// Targeting and Triggering
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;
	Template.TargetingMethod = class'X2TargetingMethod_GremlinAOE';
	
	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = `GetConfigInt("IRI_SP_ScoutingProtocol_RangeMeters");            //  meters
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = `GetConfigInt("IRI_SP_ScoutingProtocol_Radius");
	//RadiusMultiTarget.bUseWeaponRadius = true;
	RadiusMultiTarget.bIgnoreBlockingCover = true; // skip the cover checks, the squad viewer will handle this once selected
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Costs
	if (`GetConfigInt("IRI_SP_ScoutingProtocol_InitCharges") > 0)
	{
		Template.AbilityCharges = new class'X2AbilityCharges_ScanningProtocol';
		Template.AbilityCharges.InitialCharges = `GetConfigInt("IRI_SP_ScoutingProtocol_InitCharges");

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Template.AbilityCosts.AddItem(ChargeCost);
	}

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.AddItem('IRI_Gremlin_Action_Point');
	Template.AbilityCosts.AddItem(ActionPointCost);

	AddCooldown(Template, `GetConfigInt("IRI_SP_ScoutingProtocol_Cooldown"));

	// Effects
	ScanningEffect = new class'X2Effect_ScanningProtocol';
	ScanningEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	ScanningEffect.TargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	Template.AddMultiTargetEffect(ScanningEffect);

	ScanningEffect = new class'X2Effect_ScanningProtocol';
	ScanningEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	CivilianProperty = new class'X2Condition_UnitProperty';
	CivilianProperty.ExcludeNonCivilian = true;
	CivilianProperty.ExcludeHostileToSource = false;
	CivilianProperty.ExcludeFriendlyToSource = false;
	ScanningEffect.TargetConditions.AddItem(CivilianProperty);
	Template.AddMultiTargetEffect(ScanningEffect);

	ViewerEffect = new class'X2Effect_PersistentSquadViewer';
	ViewerEffect.bUseSourceLocation = false;
	ViewerEffect.bUseWeaponRadius = false;
	ViewerEffect.ViewRadius = `GetConfigInt("IRI_SP_ScoutingProtocol_Radius");
	ViewerEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	Template.AddShooterEffect(ViewerEffect);

	// State and Viz
	Template.bStationaryWeapon = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bSkipPerkActivationActions = true;
	Template.ActivationSpeech = 'ScanningProtocol';
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = class'X2Ability_SpecialistAbilitySet'.static.SendGremlinToLocation_BuildGameState;
	Template.BuildVisualizationFn = ScoutingProtocol_BuildVisualization;
	Template.CinescriptCameraType = "Specialist_ScanningProtocol";
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	return Template;
}

static private function ScoutingProtocol_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			GremlinUnitState;
	local XComGameState_Ability         AbilityState;
	local array<PathPoint> Path;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local VisualizationActionMetadata        ShooterMetadata;
	local X2Action_WaitForAbilityEffect DelayAction;

	local int EffectIndex, MultiTargetIndex;
	local PathingInputData              PathData;
	local PathingResultData				ResultData;
	local X2Action_RevealArea			RevealAreaAction;
	local TTile TargetTile;
	local vector TargetPos;

	local X2Action_PlayAnimation PlayAnimation;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, , VisualizeGameState.HistoryIndex));
	AbilityTemplate = AbilityState.GetMyTemplate();

	GremlinItem = XComGameState_Item(History.GetGameStateForObjectID(Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	GremlinUnitState = XComGameState_Unit(History.GetGameStateForObjectID(GremlinItem.CosmeticUnitRef.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	//Configure the visualization track for the shooter
	//****************************************************************************************

	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	ShooterMetadata = EmptyTrack;
	ShooterMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ShooterMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ShooterMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTree(ShooterMetadata, Context, false, ShooterMetadata.LastActionAdded);

	
	//Configure the visualization track for the gremlin
	//****************************************************************************************
	InteractingUnitRef = GremlinUnitState.GetReference();

	ActionMetadata = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinUnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	ActionMetadata.VisualizeActor = GremlinUnitState.GetVisualizer();

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	// Given the target location, we want to generate the movement data.  
	TargetPos = Context.InputContext.TargetLocations[0];
	TargetTile = `XWORLD.GetTileCoordinatesFromPosition(TargetPos);

	class'X2PathSolver'.static.BuildPath(GremlinUnitState, GremlinUnitState.TileLocation, TargetTile, PathData.MovementTiles);
	class'X2PathSolver'.static.GetPathPointsFromPath(GremlinUnitState, PathData.MovementTiles, Path);
	class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(ActionMetadata.VisualizeActor), Path);
	PathData.MovingUnitRef = GremlinUnitState.GetReference();
	PathData.MovementData = Path;
	Context.InputContext.MovementPaths.AddItem(PathData);
	class'X2TacticalVisibilityHelpers'.static.FillPathTileData(PathData.MovingUnitRef.ObjectID,	PathData.MovementTiles,	ResultData.PathTileData);
	Context.ResultContext.PathResults.AddItem(ResultData);
	class'X2VisualizerHelpers'.static.ParsePath(Context, ActionMetadata);
	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	RevealAreaAction.TargetLocation = TargetPos;
	RevealAreaAction.ScanningRadius = `GetConfigInt("IRI_SP_ScoutingProtocol_Radius");
	
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	PlayAnimation.Params.AnimName = 'NO_ScanningProtocol';

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));
	}
	
	DelayAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	DelayAction.ChangeTimeoutLength(class'X2Ability_SpecialistAbilitySet'.default.GREMLIN_PERK_EFFECT_WINDOW);

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[MultiTargetIndex];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		DelayAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		DelayAction.ChangeTimeoutLength(class'X2Ability_SpecialistAbilitySet'.default.GREMLIN_ARRIVAL_TIMEOUT);       //  give the gremlin plenty of time to show up

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityMultiTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, Context.FindMultiTargetEffectApplyResult(AbilityTemplate.AbilityMultiTargetEffects[EffectIndex], MultiTargetIndex));
		}
	}

	//****************************************************************************************
}

static private function X2AbilityTemplate IRI_SP_Overclock()
{
	local X2AbilityTemplate				Template;
	local X2Effect_GrantActionPoints    ActionPointEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SP_Overclock');

	// Icon Properties
	Template.DisplayTargetHitChance = false;
	Template.AbilitySourceName = 'eAbilitySource_Perk';                                       // color of the icon
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Overclock";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;
	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	// Costs
	AddCooldown(Template, `GetConfigInt("IRI_SP_Overclock_Cooldown"));
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SelfTarget;	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = default.DeadEye;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Effects
	ActionPointEffect = new class'X2Effect_GrantActionPoints';
	ActionPointEffect.NumActionPoints = 1;
	ActionPointEffect.PointType = 'IRI_Gremlin_Action_Point';
	Template.AddTargetEffect(ActionPointEffect);

	// State and Viz
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	//Template.ActivationSpeech = 'RunAndGun';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bCrossClassEligible = false;

	return Template;
}

static private function X2AbilityTemplate IRI_SP_AutonomousProtocols()
{
	local X2AbilityTemplate					Template;
	local X2Effect_SP_AutonomousProtocols	Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SP_AutonomousProtocols');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_defensiveprotocol";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_SP_AutonomousProtocols';
	Effect.ProtocolAbilities = `GetConfigArrayName("IRI_SP_AutonomousProtocols_Abilities");
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	return Template;
}

// ========================================================
//							GRENADIER
// --------------------------------------------------------

static private function X2AbilityTemplate IRI_GN_CollateralDamage_Passive()
{
	local X2AbilityTemplate				Template;
	local X2Effect_GN_CollateralDamage	Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_GN_CollateralDamage_Passive');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_CollateralDamage";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_GN_CollateralDamage';
	Effect.DamageMod = `GetConfigFloat("IRI_GN_CollateralDamage_DamageMod");
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, false,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	return Template;
}

static private function X2AbilityTemplate IRI_GN_CollateralDamage()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_Ammo					AmmoCost;
	local X2AbilityTarget_Cursor				CursorTarget;
	local X2AbilityMultiTarget_Radius			RadiusMultiTarget;
	local X2AbilityCooldown						Cooldown;
	local X2Effect_ReliableWorldDamage			WorldDamage;
	local X2AbilityToHitCalc_StandardAim		StandardAim;
	local X2Condition_Visibility				Visibility;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_GN_CollateralDamage');

	// Icon Setup
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_CollateralDamage";

	// Targeting and Triggering
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bGuaranteedHit = true;
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;
	Template.DisplayTargetHitChance = false;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = `TILESTOMETERS(`GetConfigFloat("IRI_GN_CollateralDamage_TileDistance"));
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponBlockingCoverFlag = false;
	RadiusMultiTarget.bIgnoreBlockingCover = true;
	RadiusMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	RadiusMultiTarget.bAddPrimaryTargetAsMultiTarget = true;
	RadiusMultiTarget.fTargetRadius = `TILESTOMETERS(`GetConfigFloat("IRI_GN_CollateralDamage_TileRadius"));
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'X2TargetingMethod_TileSnapProjectile';

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Visibility = new class'X2Condition_Visibility';
	Visibility.bRequireGameplayVisible = true;
	Visibility.bRequireBasicVisibility = true;
	Visibility.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(Visibility);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	// Costs
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = `GetConfigInt("IRI_GN_CollateralDamage_AmmoCost");
	Template.AbilityCosts.AddItem(AmmoCost);
	
	Template.AbilityCosts.AddItem(default.WeaponActionTurnEnding);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = `GetConfigInt("IRI_GN_CollateralDamage_Cooldown");
	Template.AbilityCooldown = Cooldown;
	
	// Effects
	Template.AddMultiTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');

	Template.AddMultiTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	WorldDamage = new class'X2Effect_ReliableWorldDamage';
	WorldDamage.DamageAmount = `GetConfigInt("IRI_GN_CollateralDamage_EnvDamage");
	WorldDamage.bSkipGroundTiles = true;
	Template.AddShooterEffect(WorldDamage);
	Template.bRecordValidTiles = true; // For the world damage effect

	// State and Viz	
	Template.bOverrideAim = true;
	Template.ActionFireClass = class'X2Action_Fire_CollateralDamage';

	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.CinescriptCameraType = "Grenadier_SaturationFire";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.Hostility = eHostility_Offensive;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AdditionalAbilities.AddItem('IRI_GN_CollateralDamage_Passive');

	return Template;	
}

static private function X2AbilityTemplate IRI_GN_OrdnancePouch()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('IRI_GN_OrdnancePouch', "img:///UILibrary_PerkIcons.UIPerk_steadyhands", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/);

	Template.SoldierAbilityPurchasedFn = OrdnancePouchPurchased;

	return Template;
}

static private function OrdnancePouchPurchased(XComGameState NewGameState, XComGameState_Unit UnitState)
{
	local X2ItemTemplate FreeItem;
	local XComGameState_Item ItemState;

	// Cargo cult
	if (UnitState.IsMPCharacter())
		return;

	FreeItem = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Ability_GrenadierAbilitySet'.default.FreeGrenadeForPocket);
	if (FreeItem == none)
	{
		`RedScreen("Free grenade '" $ class'X2Ability_GrenadierAbilitySet'.default.FreeGrenadeForPocket $ "' is not a valid item template.");
		return;
	}
	ItemState = FreeItem.CreateInstanceFromTemplate(NewGameState);
	if (!UnitState.AddItemToInventory(ItemState, class'OrdnanceInventorySlot'.default.UseSlot, NewGameState))
	{
		`RedScreen("Unable to add free grenade to unit's inventory. Sadness." @ UnitState.ToString());
		return;
	}
}

// ========================================================
//							SHARPSHOOTER
// --------------------------------------------------------


static private function X2AbilityTemplate IRI_SH_ScootAndShoot()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2Effect_Knockback						KnockbackEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SH_ScootAndShoot');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_quickdraw";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Targeting and Triggering
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//Template.AbilityTargetStyle = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	//Template.TargetingMethod = class'X2TargetingMethod_MeleePath';
	Template.TargetingMethod = class'AWOTCIridarPerkPack.X2TargetingMethod_MeleePath_WeaponRange';	

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty); // Units only.
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	
	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = false;
	ActionPointCost.bMoveCost = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AddCooldown(Template, `GetConfigInt("IRI_SH_ScootAndShoot_Cooldown"));
	
	// Effects
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;   

	// State and Viz
	Template.Hostility = eHostility_Neutral;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.bSkipMoveStop = false;
	Template.bSkipExitCoverWhenFiring = false;
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = ScootAndShoot_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AdditionalAbilities.AddItem('Quickdraw');

	return Template;
}

static private function ScootAndShoot_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory				History;
	local XComGameStateContext_Ability		AbilityContext;
	local StateObjectReference				InteractingUnitRef;
	local VisualizationActionMetadata		EmptyTrack;
	local VisualizationActionMetadata		ActionMetadata;	
	local VisualizationActionMetadata		SourceMetadata;
	local X2VisualizerInterface				TargetVisualizerInterface;
	local XComGameState_EnvironmentDamage	DamageEventStateObject;
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action_MarkerNamed				JoinActions;
	local Array<X2Action>					FoundActions;
	local X2Action_Fire						FireAction;
	local X2Action_ExitCover				ExitCoverAction;
	local XGUnit							SourceVisualizer;
	local int i, j;

	History = `XCOMHISTORY;
	VisMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	SourceVisualizer = XGUnit(History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));

	SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(SourceVisualizer.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceVisualizer.ObjectID);
	SourceMetadata.StateObjectRef = AbilityContext.InputContext.SourceObject;
	SourceMetadata.VisualizeActor = SourceVisualizer;

	if( AbilityContext.InputContext.MovementPaths.Length > 0 )
	{
		class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, SourceMetadata);
	}

	ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover_ScootAndShoot'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, SourceMetadata.LastActionAdded));
	FireAction = X2Action_Fire(class'X2Action_Fire'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, ExitCoverAction));
	class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceMetadata, AbilityContext, false, FireAction);

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for( i = 0; i < AbilityContext.InputContext.MultiTargets.Length; ++i )
	{
		InteractingUnitRef = AbilityContext.InputContext.MultiTargets[i];
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		ActionMetadata.LastActionAdded = FireAction; //We want these applied effects to trigger off of the bombard action
		for( j = 0; j < AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, AbilityContext.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, ActionMetadata);
		}
	}
	//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	// add visualization of environment damage
	foreach VisualizeGameState.IterateByClassType( class'XComGameState_EnvironmentDamage', DamageEventStateObject )
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = DamageEventStateObject;
		ActionMetadata.StateObject_NewState = DamageEventStateObject;
		ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer(DamageEventStateObject.ObjectID);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction);
	}
	//****************************************************************************************

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, FoundActions);

	if( VisMgr.BuildVisTree.ChildActions.Length > 0 )
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, none, FoundActions));
		JoinActions.SetName("Join");
	}
}
static private function X2AbilityTemplate IRI_SH_Standoff()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityMultiTarget_Radius		MultiTarget;
	local X2Effect_ReserveActionPoints		ReservePointsEffect;
	local X2Condition_UnitEffects           SuppressedCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SH_Standoff');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_killzone";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	// Targetind and Triggering
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'AWOTCIridarPerkPack.X2TargetingMethod_TopDown_NoCameraLock';

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.bUseWeaponBlockingCoverFlag = false;
	MultiTarget.bIgnoreBlockingCover = true;
	MultiTarget.fTargetRadius = `TILESTOMETERS(`GetConfigFloat("IRI_SH_Standoff_Radius_Tiles"));
	Template.AbilityMultiTargetStyle = MultiTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	// Costs

	// Ammo cost - just in case.
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	AddCooldown(Template, `GetConfigInt("IRI_SH_Standoff_Cooldown"));

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Effects
	ReservePointsEffect = new class'X2Effect_ReserveActionPoints';
	ReservePointsEffect.ReserveType = 'IRI_SH_Standoff';
	Template.AddShooterEffect(ReservePointsEffect);
	
	// State and Viz
	Template.Hostility = eHostility_Defensive;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";
	Template.ActivationSpeech = 'KillZone';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	
	Template.AdditionalAbilities.AddItem('IRI_SH_Standoff_Shot');
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	
	return Template;
}

static private function X2AbilityTemplate IRI_SH_Standoff_Shot()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityCost_ReserveActionPoints ReserveActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Persistent               KillZoneEffect;
	local X2Condition_UnitEffectsWithAbilitySource  KillZoneCondition;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2Condition_UnitProperty          ShooterCondition;
	local X2Condition_UnitProperty			TargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SH_Standoff_Shot');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	SetHidden(Template);

	// Targeting and Triggering
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bReactionFire = true;
	Template.AbilityToHitCalc = StandardAim;

	//Trigger on movement - interrupt the move
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'ObjectMoved';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalOverwatchListener;
	Template.AbilityTriggers.AddItem(Trigger);
	//  trigger on an attack
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.TypicalAttackListener;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeConcealed = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);
	Template.AddShooterEffectExclusions();

	// Costs

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ReserveActionPointCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveActionPointCost.iNumPoints = 1;
	ReserveActionPointCost.bFreeCost = true;
	ReserveActionPointCost.AllowedTypes.AddItem('IRI_SH_Standoff');
	Template.AbilityCosts.AddItem(ReserveActionPointCost);

	// Target Conditions
	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.TreatMindControlledSquadmateAsHostile = false;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.RequireWithinRange = true;
	TargetCondition.WithinRange = `TILESTOUNITS(`GetConfigFloat("IRI_SH_Standoff_Radius_Tiles"));
	Template.AbilityTargetConditions.AddItem(TargetCondition);

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bDisablePeeksOnMovement = false;
	TargetVisibilityCondition.bAllowSquadsight = false;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(class'X2Ability_DefaultAbilitySet'.static.OverwatchTargetEffectsCondition());

	//  Do not shoot targets that were already hit by this unit this turn with this ability
	KillZoneCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	KillZoneCondition.AddExcludeEffect('IRI_SH_Standoff_Shot_Effect', 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(KillZoneCondition);

	// Target Effects
	
	//  Mark the target as shot by this unit so it cannot be shot again this turn
	KillZoneEffect = new class'X2Effect_Persistent';
	KillZoneEffect.EffectName = 'IRI_SH_Standoff_Shot_Effect';
	KillZoneEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	KillZoneEffect.SetupEffectOnShotContextResult(true, true);      //  mark them regardless of whether the shot hit or missed
	Template.AddTargetEffect(KillZoneEffect);

	//  Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;

	// State and Viz
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static private function X2AbilityTemplate IRI_SH_SteadyHands()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_PersistentStatChange		StatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SH_SteadyHands');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_steadyhands";
	SetHidden(Template);

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Trigger when using Hunker Down
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 50;
	Trigger.ListenerData.EventFn = OnHunkerDown_TriggerEventListener;
	Template.AbilityTriggers.AddItem(Trigger);

	// Trigger at the end of turn if we didn't move last turn
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'PlayerTurnEnded';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.Priority = 50;
	Trigger.ListenerData.EventFn = SteadyHands_TriggerEventListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Shooter Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingShooterProperty);

	// Effects
	StatChangeEffect = new class'X2Effect_PersistentStatChange';
	StatChangeEffect.EffectName = 'SteadyHandsStatBoost';
	StatChangeEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnBegin);
	StatChangeEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true);
	StatChangeEffect.AddPersistentStatChange(eStat_Offense, class'X2Ability_SharpshooterAbilitySet'.default.STEADYHANDS_AIM_BONUS);
	StatChangeEffect.AddPersistentStatChange(eStat_CritChance, class'X2Ability_SharpshooterAbilitySet'.default.STEADYHANDS_CRIT_BONUS);
	Template.AddTargetEffect(StatChangeEffect);

	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.AdditionalAbilities.AddItem('IRI_SH_SteadyHands_Passive');

	return Template;
}

static private function EventListenerReturn SteadyHands_TriggerEventListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit	UnitState;
    local XComGameState_Ability	AbilityState;
	local UnitValue				UV;

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (UnitState == none)
		return ELR_NoInterrupt;

	UnitState.GetUnitValue('MovesThisTurn', UV);

	if (UV.fValue == 0)
	{
		AbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false);
	}
	return ELR_NoInterrupt;
}

// ========================================================
//							RANGER
// --------------------------------------------------------

static private function X2AbilityTemplate IRI_RN_Intercept()
{
	local X2AbilityTemplate				Template;
	local X2Effect_RN_Intercept			InterceptEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2Condition_UnitEffects       SuppressedCondition;
	local X2Condition_UnitProperty      ConcealedCondition;
	local X2Effect_SetUnitValue         UnitValueEffect;
	local array<name>                   SkipExclusions;
	local X2Effect_ReserveOverwatchPoints	ReserveOverwatchPoints;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_Intercept');

	// Icon Properties
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_RN_Intercept";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY + 5;	//	After Sword Slice but before Corporal abilities.
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	//Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;
	//Template.bNoConfirmationWithHotKey = true;
	
	//	Targeting and Triggering
	Template.TargetingMethod = class'X2TargetingMethod_RN_Intercept';
	Template.AbilityToHitCalc = default.DeadEye;
	Template.DisplayTargetHitChance = false;
	Template.AbilityTargetStyle = default.SelfTarget;	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//	Ability Cost
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true; // Reserve AP effect will take away all action points anyway
	Template.AbilityCosts.AddItem(ActionPointCost);

	//	Shooter Conditions
	//	Cannot be used while Suppressed, just like regular Overwatch.
	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);

	//	Can be used while disoriented, just like regular overwatch.
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	//	Ability Effects
	ReserveOverwatchPoints = new class'X2Effect_ReserveOverwatchPoints';
	ReserveOverwatchPoints.ReserveType = 'iri_intercept_ap';
	Template.AddShooterEffect(ReserveOverwatchPoints);

	InterceptEffect = new class'X2Effect_RN_Intercept';
	InterceptEffect.TriggerEventName = 'AbilityActivated';
	InterceptEffect.bAllowCoveringFire = true;
	InterceptEffect.bInterceptMovementOnly = true;
	InterceptEffect.bAllowInterrupt = true;
	InterceptEffect.bAllowNonInterrupt_IfNonInterruptible = true; // First place to check if there are ANY issues with this ability.
	InterceptEffect.bMoveAfterAttack = true;
	InterceptEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	InterceptEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(InterceptEffect);

	//	If the Intercepting unit is concealed, mark it as such.
	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = class'X2Ability_DefaultAbilitySet'.default.ConcealedOverwatchTurn;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);

	//	Game State and Viz	
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.ActivationSpeech = 'Overwatch';
	Template.Hostility = eHostility_Defensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.OverwatchAbility_BuildVisualization;

	Template.AdditionalAbilities.AddItem('IRI_RN_Intercept_Return');
	Template.AdditionalAbilities.AddItem('IRI_RN_Intercept_Attack');

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentNormalLoss;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.NormalLostSpawnIncreasePerUse;

	return Template;
}


static private function X2AbilityTemplate IRI_RN_Intercept_Return()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitValue				IsNotImmobilized;
	local X2Condition_UnitStatCheck         UnitStatCheckCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_Intercept_Return');

	//	Icon
	SetHidden(Template);
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	
	//	Shooter Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeCosmetic = false; //Cosmetic units are allowed movement
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	IsNotImmobilized = new class'X2Condition_UnitValue';
	IsNotImmobilized.AddCheckValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 0);
	Template.AbilityShooterConditions.AddItem(IsNotImmobilized);

	// Unit might not be mobilized but have zero mobility
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_Mobility, 0, eCheck_GreaterThan);
	Template.AbilityShooterConditions.AddItem(UnitStatCheckCondition);

	//	Cost
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bMoveCost = true;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	//	Targeting and Triggering
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Path';
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');	//	Triggered from X2Effect_InterceptAbility

	Template.Hostility = eHostility_Movement;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildVisualization;
	Template.MergeVisualizationFn = Intercept_MoveReturn_MergeVisualization;
	Template.BuildInterruptGameStateFn = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildInterruptGameState;

	//	We set SPT when triggering this ability.
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentMoveLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.MoveChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MoveLostSpawnIncreasePerUse;

	return Template;
}

static private function Intercept_MoveReturn_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action							EnterCover;
	local X2Action							InterruptEnd;
	local X2Action							MarkerStart, MarkerEnd;
	local array<X2Action>					FindActions;
	local XComGameStateContext_Ability		InterceptContext;
	
	// ## Init
	VisMgr = `XCOMVISUALIZATIONMGR;	
	InterceptContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	
	//	Get all the actions we'll need. 
	
	//InterruptEnd = VisMgr.GetNodeOfType(VisualizationTree, class'X2Action_MarkerTreeInsertEnd');

	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerInterruptEnd', FindActions,, InterceptContext.InputContext.PrimaryTarget.ObjectID);

	`LOG("Looking for Interrupt End Action with index closest to:" @ InterceptContext.DesiredVisualizationBlockIndex,, 'IRI_RIDER_VIZ');

	InterruptEnd = FindActionWithClosestHistoryIndex(FindActions, InterceptContext.DesiredVisualizationBlockIndex);

	EnterCover  = VisMgr.GetNodeOfType(VisualizationTree, class'X2Action_EnterCover',, InterceptContext.InputContext.SourceObject.ObjectID);
	MarkerStart = VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin');
	MarkerEnd = VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd');

	//	Fallback
	if (InterruptEnd == none || EnterCover == none || MarkerStart == none || MarkerEnd == none)
	{
		`LOG("Intercept_MoveReturn_MergeVisualization: ERROR! Merge failed!" @ InterruptEnd == none @ EnterCover == none @ MarkerStart == none @ MarkerEnd == none,, 'IRI_RIDER_VIZ');
		XComGameStateContext_Ability(BuildTree.StateChangeContext).SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
		return;
	}

	//	Insert the whole Interception visualization between the Interrupt Action pair
	VisMgr.ConnectAction(MarkerStart, VisualizationTree, false, EnterCover);
	VisMgr.ConnectAction(InterruptEnd, VisualizationTree, false, MarkerEnd);

	`LOG("Intercept_MoveReturn_MergeVisualization: Merge complete.", class'Help'.default.bLog, 'IRI_RIDER_VIZ');
}


static private function X2AbilityTemplate IRI_RN_Intercept_Attack()
{
	local X2AbilityTemplate					Template;
	local X2AbilityToHitCalc_StandardMelee  StandardMelee;
	local X2AbilityCost_ReserveActionPoints	ReserveAPCost;
	
	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility('IRI_RN_Intercept_Attack');
	ResetMeleeShooterConditions(Template);

	//	Remove the end-of-move trigger to fix the bug where it would override Sword Slice's sometimes.
	Template.AbilityTriggers.Length = 0;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_RN_Intercept";
	SetHidden(Template);

	//Template.AbilityCosts.Length = 0;
	ReserveAPCost = new class'X2AbilityCost_ReserveActionPoints';
	ReserveAPCost.iNumPoints = 1;
	ReserveAPCost.AllowedTypes.AddItem('iri_intercept_ap');
	Template.AbilityCosts.AddItem(ReserveAPCost);

	//	Suffers reaction fire penalties.
	//	ToHicCalc will automatically remove the penalty if we Intercept while concealed.
	StandardMelee = new class'X2AbilityToHitCalc_StandardMelee';
	StandardMelee.bReactionFire = true;
	Template.AbilityToHitCalc = StandardMelee;

	//	Remove cinematic camera, it looks super bad when target is moving.
	Template.CinescriptCameraType = "";

	Template.bUniqueSource = true;

	//	Must be interruptible, otherwise will deal damage even if the intercepting unit is killed by enemy reaction fire.
	//Template.BuildInterruptGameStateFn = none;

	return Template;
}

static private function ResetMeleeShooterConditions(out X2AbilityTemplate Template)
{
	local array<name> SkipExclusions;

	//	 X2Ability_RangerAbilitySet::AddSwordSliceAbility() generates ability that cannot be used while Disoriented, which is a problem for a melee-only class.
	Template.AbilityShooterConditions.Length = 0;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);
}

static private function X2Action FindActionWithClosestHistoryIndex(const array<X2Action> FindActions, const int DesiredHistoryIndex)
{
	local X2Action FindAction;
	local X2Action BestAction;
	local int	   HistoryIndexDelta;

	if (FindActions.Length == 1)
		return FindActions[0];

	foreach FindActions(FindAction)
	{
		if (FindAction.StateChangeContext.AssociatedState.HistoryIndex == DesiredHistoryIndex)
		{
			return FindAction;
		}

		if (DesiredHistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex < HistoryIndexDelta)
		{	
			HistoryIndexDelta = DesiredHistoryIndex - FindAction.StateChangeContext.AssociatedState.HistoryIndex;
			BestAction = FindAction;

			//	No break on purpose! We want the cycle to sift through all Fire Actions in the tree.
		}
	}
	return BestAction;
}


static private function X2AbilityTemplate IRI_RN_TacticalAdvance()
{
	local X2AbilityTemplate					Template;
	local X2Effect_TacticalAdvance			Effect;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_TacticalAdvance');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_TacticalAdvance";
	
	SetHidden(Template);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 50;
	Trigger.ListenerData.EventFn = OnHunkerDown_TriggerEventListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	Effect = new class'X2Effect_TacticalAdvance';
	Effect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.AdditionalAbilities.AddItem('IRI_RN_TacticalAdvance_Passive');

	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static private function EventListenerReturn OnHunkerDown_TriggerEventListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Unit	NewUnitState;
	local XComGameState_Unit	OldUnitState;
    local XComGameState_Ability	AbilityState;

	if (GameState.GetContext() == none || GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	NewUnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(UnitState.ObjectID));
	if (NewUnitState == none)
		return ELR_NoInterrupt;

	OldUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ObjectID,, GameState.HistoryIndex - 1));
	if (OldUnitState == none)
		return ELR_NoInterrupt;

	`AMLOG(UnitState.GetFullName() @ "was hunkered:" @ OldUnitState.IsHunkeredDown() @ "is hunkered:" @ NewUnitState.IsHunkeredDown());

	if (!OldUnitState.IsHunkeredDown() && NewUnitState.IsHunkeredDown())
	{
		AbilityState = XComGameState_Ability(CallbackData);
		if (AbilityState != none)
		{
			`AMLOG("Triggering");
			AbilityState.AbilityTriggerAgainstSingleTarget(UnitState.GetReference(), false);
		}
	}

	return ELR_NoInterrupt;
}

static private function X2AbilityTemplate IRI_RN_ZephyrStrike()
{
	local X2AbilityTemplate						Template;
	local X2AbilityMultiTarget_Radius           MultiTargetRadius;
	local X2AbilityCost_ActionPoints			ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_ZephyrStrike');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ceramicblade";
	
	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AddCooldown(Template, `GetConfigInt("IRI_RN_ZephyrStrike_Cooldown"));

	// Targeting and Triggering
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Cursor';
	Template.TargetingMethod = class'X2TargetingMethod_PathTarget';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	MultiTargetRadius = new class'X2AbilityMultiTarget_Radius';
	MultiTargetRadius.fTargetRadius = `TILESTOMETERS(`GetConfigFloat("IRI_RN_ZephyrStrike_Radius_Tiles"));
	MultiTargetRadius.bExcludeSelfAsTargetIfWithinRadius = true;
	MultiTargetRadius.bUseWeaponRadius = false;
	MultiTargetRadius.bIgnoreBlockingCover = true;
	MultiTargetRadius.NumTargetsRequired = 1; //At least someone must be in range
	Template.AbilityMultiTargetStyle = MultiTargetRadius;

	// Shootder conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Multi Target Conditions
	Template.AbilityMultiTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	// Effects
	Template.AddMultiTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	Template.bAllowBonusWeaponEffects = true;

	Template.bFriendlyFireWarning = false;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bSkipExitCoverWhenFiring = false;
	Template.AbilityConfirmSound = "TacticalUI_SwordConfirm";
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = ZephyrStrike_BuildVisualization;

	Template.ActivationSpeech = 'Reaper';

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.MeleeLostSpawnIncreasePerUse;

	return Template;
}

// Copypasted from Chimera Squad ability Crowd Control
static private function ZephyrStrike_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory			History;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Unit			MultiTargetUnit, HellionUnitNewState;
	local X2VisualizerInterface			TargetVisualizerInterface;
	local EffectResults					MultiTargetResult;
	local X2Effect                      TargetEffect;
	local name                          ResultName, ApplyResult;
	local bool                          TargetGotAnyEffects;
	local X2Camera_Cinescript           CinescriptCamera;
	local Actor							TargetVisualizer;
	local int							EffectIndex, MultiTargetIndex;
	local TTile							TargetTile, BestTile;
	local array<TTile>					MeleeTiles;
	//local bool							bFinisherAnimation, bAlternateAnimation;

	local VisualizationActionMetadata		EmptyMetadata;
	local VisualizationActionMetadata		SourceMetadata;
	local VisualizationActionMetadata		TargetMetadata;

	local X2Action_PlayAnimation			BeginAnimAction;
	local X2Action_PlayAnimation			SettleAnimAction;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyover;
	local X2Action_ForceUnitVisiblity_CS	UnitVisibilityAction;
	local X2Action_ExitCover				ExitCoverAction;
	local X2Action_EnterCover				EnterCoverAction;
	local X2Action_StartCinescriptCamera	CinescriptStartAction;
	local X2Action_EndCinescriptCamera		CinescriptEndAction;
	local X2Action_Fire_Faceoff_CS			FireFaceoffAction;
	local X2Action_ApplyWeaponDamageToUnit	ApplyWeaponDamageAction;	
	local X2Action_MarkerNamed				JoinActions;
	local array<X2Action>					FoundActions;
	local array<name>						AnimationOverrides;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);
	AbilityTemplate.CinescriptCameraType = "IRI_RN_ZephyrStrike_Camera"; // Iridar:Hack, but Firaxis does it, and we set it back afterwards anyway.

	//Configure the visualization track for the shooter
	InteractingUnitRef = Context.InputContext.SourceObject;
	SourceMetadata = EmptyMetadata;
	SourceMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	SourceMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	HellionUnitNewState = XComGameState_Unit(SourceMetadata.StateObject_NewState);

	if (Context.InputContext.MovementPaths.Length > 0)
	{
		ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceMetadata, Context));
		ExitCoverAction.bSkipExitCoverVisualization = AbilityTemplate.bSkipExitCoverWhenFiring;

		class'X2VisualizerHelpers'.static.ParsePath(Context, SourceMetadata, AbilityTemplate.bSkipMoveStop);
	}

	// Add a Camera Action to the Shooter's Metadata.  Minor hack: To create a CinescriptCamera the AbilityTemplate 
	// must have a camera type.  So manually set one here, use it, then restore.
	CinescriptCamera = class'X2Camera_Cinescript'.static.CreateCinescriptCameraForAbility(Context);
	CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	CinescriptStartAction.CinescriptCamera = CinescriptCamera;

	// Exit Cover
	ExitCoverAction = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	ExitCoverAction.bSkipExitCoverVisualization = true;
	
	//PlayAnimation, start of crowd control
	BeginAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	BeginAnimAction.Params.AnimName = 'FF_ZephyrStrikeStart';
	BeginAnimAction.Params.PlayRate = BeginAnimAction.GetNonCriticalAnimationSpeed();

	//Shooter Effects
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, SourceMetadata, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));
	}

	//Shooter Flyover
	if (AbilityTemplate.ActivationSpeech != '')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.ActivationSpeech, eColor_Good);
	}

	// Add an action to pop the last CinescriptCamera off the camera stack.
	CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	CinescriptEndAction.CinescriptCamera = CinescriptCamera;

	AbilityTemplate.CinescriptCameraType = "IRI_RN_ZephyrStrike_Camera_Target";

	//PerkStart, Wait to start until the soldier tells us to
	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(SourceMetadata, Context, false, BeginAnimAction);

	//Handle each multi-target	
	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		MultiTargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.MultiTargets[MultiTargetIndex].ObjectID));
		if (MultiTargetUnit == None)
			continue;

		MultiTargetResult = Context.ResultContext.MultiTargetEffectResults[MultiTargetIndex];

		//Hellion cant attack itself
		if (MultiTargetUnit.ObjectID == InteractingUnitRef.ObjectID)
			continue;

		//Don't visit targets which got no effect
		TargetGotAnyEffects = false;
		foreach MultiTargetResult.ApplyResults(ResultName)
		{
			if (ResultName == 'AA_Success')
			{
				TargetGotAnyEffects = true;
				break;
			}
		}
		if (!TargetGotAnyEffects)
			continue;

		//bFinisherAnimation = (MultiTargetIndex == Context.InputContext.MultiTargets.Length - 1);
		//bAlternateAnimation = ((MultiTargetIndex % 2) != 0);

		// Target Information
		TargetVisualizer = History.GetVisualizer(MultiTargetUnit.ObjectID);
		TargetMetadata = EmptyMetadata;
		TargetMetadata.StateObject_OldState = History.GetGameStateForObjectID(MultiTargetUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		TargetMetadata.StateObject_NewState = MultiTargetUnit;
		TargetMetadata.VisualizeActor = TargetVisualizer;

		//Find BestTile to stand on for punch
		TargetTile = MultiTargetUnit.TileLocation;		
		class'Helpers'.static.FindAvailableNeighborTile(TargetTile, BestTile);
		class'Helpers'.static.FindTilesForMeleeAttack(MultiTargetUnit, MeleeTiles);
		if (MeleeTiles.Length > 0)
		{
			BestTile = MeleeTiles[0];
		}

		//Teleport to and face target
		UnitVisibilityAction = X2Action_ForceUnitVisiblity_CS(class'X2Action_ForceUnitVisiblity_CS'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		UnitVisibilityAction.bMatchToCustomTile = true;
		UnitVisibilityAction.bMatchFacingToCustom = true;
		UnitVisibilityAction.CustomTileLocation = BestTile;
		UnitVisibilityAction.CustomTileFacingTile = TargetTile;
		UnitVisibilityAction.TargetActor = TargetMetadata.VisualizeActor;

		// Add an action to pop the previous CinescriptCamera off the camera stack.
		//CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		//CinescriptEndAction.CinescriptCamera = CinescriptCamera;
		//CinescriptEndAction.bForceEndImmediately = true;

		// Add an action to push a new CinescriptCamera onto the camera stack.
		CinescriptCamera = class'X2Camera_Cinescript'.static.CreateCinescriptCameraForAbility(Context);
		CinescriptCamera.TargetObjectIdOverride = MultiTargetUnit.ObjectID;
		CinescriptStartAction = X2Action_StartCinescriptCamera(class'X2Action_StartCinescriptCamera'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		CinescriptStartAction.CinescriptCamera = CinescriptCamera;

		// Add a custom Fire action to the shooter Metadata.		
		FireFaceoffAction = X2Action_Fire_Faceoff_CS(class'X2Action_Fire_Faceoff_CS'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		FireFaceoffAction.SetFireParameters(Context.IsResultContextMultiHit(MultiTargetIndex), MultiTargetUnit.ObjectID, false);
		FireFaceoffAction.vTargetLocation = TargetVisualizer.Location;
		FireFaceoffAction.FireAnimBlendTime = 0.0f;
		FireFaceoffAction.bEnableRMATranslation = false;
		FireFaceoffAction.AnimationOverride = ZephyrStrike_GetAnimationOverride(AnimationOverrides);
		
		//Target Effects
		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityMultiTargetEffects.Length; ++EffectIndex)
		{
			TargetEffect = AbilityTemplate.AbilityMultiTargetEffects[EffectIndex];
			ApplyResult = Context.FindMultiTargetEffectApplyResult(TargetEffect, MultiTargetIndex);

			// Target effect visualization
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, TargetMetadata, ApplyResult);

			// Source effect visualization
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualizationSource(VisualizeGameState, SourceMetadata, ApplyResult);
		}

		TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);
		if (TargetVisualizerInterface != none)
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, TargetMetadata);
		}

		ApplyWeaponDamageAction = X2Action_ApplyWeaponDamageToUnit(VisualizationMgr.GetNodeOfType(VisualizationMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', TargetVisualizer));
		if (ApplyWeaponDamageAction != None)
		{
			VisualizationMgr.DisconnectAction(ApplyWeaponDamageAction);
			VisualizationMgr.ConnectAction(ApplyWeaponDamageAction, VisualizationMgr.BuildVisTree, false, FireFaceoffAction);
		}

		// Add an action to pop the last CinescriptCamera off the camera stack.
		CinescriptEndAction = X2Action_EndCinescriptCamera(class'X2Action_EndCinescriptCamera'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
		CinescriptEndAction.CinescriptCamera = CinescriptCamera;
	}
	
	//Teleport to our Starting Location
	UnitVisibilityAction = X2Action_ForceUnitVisiblity_CS(class'X2Action_ForceUnitVisiblity_CS'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	UnitVisibilityAction.bMatchToCustomTile = true;
	UnitVisibilityAction.CustomTileLocation = HellionUnitNewState.TileLocation;
	UnitVisibilityAction.bMatchFacingToCustom = true;
	UnitVisibilityAction.CustomTileFacingTile = TargetTile; // Face the last target

	//PlayAnimation, end of crowd control
	SettleAnimAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	SettleAnimAction.Params.AnimName = 'FF_ZephyrStrikeFinish';
	//SettleAnimAction.Params.StartOffsetTime = 1.3f;
	SettleAnimAction.Params.PlayRate = BeginAnimAction.GetNonCriticalAnimationSpeed();
	SettleAnimAction.Params.BlendTime = 0.0f;
	
	// Perk End
	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded);

	//Enter Cover (but skip animation)
	EnterCoverAction = X2Action_EnterCover(class'X2Action_EnterCover'.static.AddToVisualizationTree(SourceMetadata, Context, false, SourceMetadata.LastActionAdded));
	EnterCoverAction.bSkipEnterCover = true;

	// Join
	VisualizationMgr.GetAllLeafNodes(VisualizationMgr.BuildVisTree, FoundActions);

	if (VisualizationMgr.BuildVisTree.ChildActions.Length > 0)
	{
		JoinActions = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SourceMetadata, Context, false, none, FoundActions));
		JoinActions.SetName("Join");
	}

	AbilityTemplate.CinescriptCameraType = "";
}

static private function name ZephyrStrike_GetAnimationOverride(out array<name> AnimationOverrides)
{
	local name OverrideAnimation;

	if (AnimationOverrides.Length == 0)
	{
		//AnimationOverrides.AddItem('FF_ZephyrStrikeA'); // Same stab as B, but without a step-in.
		AnimationOverrides.AddItem('FF_ZephyrStrikeB');
		AnimationOverrides.AddItem('FF_ZephyrStrikeC');
		AnimationOverrides.AddItem('FF_ZephyrStrikeD');
		AnimationOverrides.AddItem('FF_ZephyrStrikeE');
		AnimationOverrides.AddItem('FF_ZephyrStrikeF');
		//AnimationOverrides.AddItem('FF_ZephyrStrikeG'); // Rising part of the Cross Strike doesn't look too good
	}

	OverrideAnimation = AnimationOverrides[Rand(AnimationOverrides.Length)];

	AnimationOverrides.RemoveItem(OverrideAnimation);

	return OverrideAnimation;
}


//	========================================
//				COMMON CODE
//	========================================

static function AddCooldown(out X2AbilityTemplate Template, int Cooldown)
{
	local X2AbilityCooldown AbilityCooldown;

	if (Cooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown';
		AbilityCooldown.iNumTurns = Cooldown;
		Template.AbilityCooldown = AbilityCooldown;
	}
}

static function AddCharges(out X2AbilityTemplate Template, int InitialCharges)
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

static function AddFreeCost(out X2AbilityTemplate Template)
{
	local X2AbilityCost_ActionPoints ActionPointCost;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
}

static function RemoveVoiceLines(out X2AbilityTemplate Template)
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

static function SetFireAnim(out X2AbilityTemplate Template, name Anim)
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

static function SetHidden(out X2AbilityTemplate Template)
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

static function SetPassive(out X2AbilityTemplate Template)
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
static function	SetSelfTarget_WithEventTrigger(out X2AbilityTemplate Template, name EventID, optional EventListenerDeferral Deferral = ELD_OnStateSubmitted, optional AbilityEventFilter Filter = eFilter_None, optional int Priority = 50)
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

static function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;

	`LOG("Action layer: " @ iLayer @ ": " @ Action.Class.Name @ Action.StateChangeContext.AssociatedState.HistoryIndex,, 'IRIPISTOLVIZ'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}