class X2Ability_Skirmisher extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_SK_PredatorStrike());
	Templates.AddItem(IRI_SK_PredatorStrike_RevealNearestEnemy());

	Templates.AddItem(IRI_SK_ThunderLance());

	return Templates;
}

/*
Another Iridar-tier complicated ability. This is essentially a copy of LaunchGrenade, with the following changes:

1. Instead of using a grenade launcher weapon, we're using a PerkContent with a PerkWeapon, 
based on the Whiplash perk. The only difference from Whiplash weapon is that ours uses a custom Projectile,
the X2UnifiedProjectile_ThunderLance, which has a delay on its main impact, accomplished via simple Timer.

2. Custom TargetingMethod, based on Rocket Launcher's, but with a custom XComPrecomputedPath_ThunderLance.
*/
static private function X2AbilityTemplate IRI_SK_ThunderLance()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_AbilitySourceWeapon   GrenadeCondition, ProximityMineCondition;
	local X2Effect_ProximityMine            ProximityMineEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SK_ThunderLance');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_grenade_launcher";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	
	// Targeting and Triggering
	Template.TargetingMethod = class'X2TargetingMethod_ThunderLance';

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	CursorTarget = new class'X2AbilityTarget_Cursor';
	//CursorTarget.bRestrictToWeaponRange = true;
	//CursorTarget.IncreaseWeaponRange = 4;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;  
	RadiusMultiTarget.bUseWeaponBlockingCoverFlag = true;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Costs
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	AmmoCost.UseLoadedAmmo = true;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Salvo');
	ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('TotalCombat');
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Shooder Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	GrenadeCondition = new class'X2Condition_AbilitySourceWeapon';
	GrenadeCondition.CheckGrenadeFriendlyFire = true;
	Template.AbilityMultiTargetConditions.AddItem(GrenadeCondition);

	// Effects
	Template.bRecordValidTiles = true;
	Template.bUseLaunchedGrenadeEffects = true;
	Template.bHideAmmoWeaponDuringFire = false; // TODO: This flag causes grenade explosion to not play sometimes?

	ProximityMineEffect = new class'X2Effect_ProximityMine';
	ProximityMineEffect.BuildPersistentEffect(1, true, false, false);
	ProximityMineCondition = new class'X2Condition_AbilitySourceWeapon';
	ProximityMineCondition.MatchGrenadeType = 'ProximityMine';
	ProximityMineEffect.TargetConditions.AddItem(ProximityMineCondition);
	Template.AddShooterEffect(ProximityMineEffect);

	// Viz and State
	Template.ActionFireClass = class'X2Action_Fire_ThunderLance';
	Template.CustomFireAnim = 'HL_ThunderLance';
	Template.ActivationSpeech = 'ThrowGrenade';

	Template.DamagePreviewFn = class'X2Ability_Grenades'.static.GrenadeDamagePreview;

	//Template.CinescriptCameraType = "Grenadier_GrenadeLauncher";

	Template.bOverrideAim = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.ModifyNewContextFn = ThunderLance_ModifyActivatedAbilityContext;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

// If targeted tile has any units, smuggle the first one as the primary target of the ability
// so that the TriggerHitReact notify in the firing animation has a target to work with
static private function ThunderLance_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComWorldData					World;
	local TTile							TileLocation;
	local vector						TargetLocation;
	local array<StateObjectReference>	TargetsOnTile;

	World = `XWORLD;
	
	AbilityContext = XComGameStateContext_Ability(Context);

	TargetLocation = AbilityContext.InputContext.TargetLocations[0];

	World.GetFloorTileForPosition(TargetLocation, TileLocation);

	TargetsOnTile = World.GetUnitsOnTile(TileLocation);

	if (TargetsOnTile.Length > 0)
	{
		AbilityContext.InputContext.PrimaryTarget = TargetsOnTile[0];
	}
}


static private function X2AbilityTemplate IRI_SK_PredatorStrike()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Effect_OverrideDeathAction		OverrideDeathAction;
	local X2Condition_PredatorStrike		HealthCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SK_PredatorStrike');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.Shiremct_perk_SkirmisherStrike";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_MAJOR_PRIORITY;

	// Targeting and triggering
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityTargetStyle = default.SimpleSingleMeleeTarget;

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);
	AddCooldown(Template, `GetConfigInt("IRI_SK_PredatorStrike_Cooldown"));

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeNonHumanoidAliens = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	HealthCondition = new class'X2Condition_PredatorStrike';
	HealthCondition.BelowHealthPercent = `GetConfigFloat("IRI_SK_PredatorStrike_HealthPercent");
	Template.AbilityTargetConditions.AddItem(HealthCondition);
	
	// Effects
	// Use custom Fire and Death actions to play synced on-kill animations.
	Template.ActionFireClass = class'X2Action_PredatorStrike';
	OverrideDeathAction = new class'X2Effect_OverrideDeathAction';
	OverrideDeathAction.DeathActionClass = class'X2Action_PredatorStrike_Death';
	OverrideDeathAction.EffectName = 'IRI_SK_PredatorStrike_DeathActionEffect';
	Template.AddTargetEffect(OverrideDeathAction);

	Template.AddTargetEffect(new class'X2Effect_PredatorStrike');

	// State and Viz
	Template.CinescriptCameraType = "IRI_PredatorStrike_Camera";
	Template.bOverrideMeleeDeath = false;
	
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = PredatorStrike_BuildVisualization;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AdditionalAbilities.AddItem('IRI_SK_PredatorStrike_RevealNearestEnemy');

	return Template;
}

static private function PredatorStrike_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action						FireAction;
	local XComGameStateContext_Ability	AbilityContext;
	local X2Action_MoveTurn				MoveTurnAction;
	local VisualizationActionMetadata   ActionMetadata;
	local VisualizationActionMetadata   EmptyTrack;
	local XComGameStateHistory			History;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local X2Action_PlayAnimation		PlayAnimation;
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2Action						DeathAction;
	local TTile							TurnTileLocation;

	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

	History = `XCOMHISTORY;
	VisMgr = `XCOMVISUALIZATIONMGR;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	TargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none)
		return;
	SourceUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (SourceUnit == none)
		return;

	FireAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_PredatorStrike',, AbilityContext.InputContext.SourceObject.ObjectID);
	if (FireAction == none)
		return;

	//	Make the shooter rotate towards the target. This doesn't always happen automatically in time.
	ActionMetadata = FireAction.Metadata;
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true, FireAction.ParentActions[0]));
	MoveTurnAction.m_vFacePoint =  `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
	MoveTurnAction.UpdateAimTarget = true;

	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(TargetUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = TargetUnit;
	ActionMetadata.VisualizeActor = History.GetVisualizer(TargetUnit.ObjectID);
		
	// Make target rotate towards the shooter, but on the same Z as the target, for better animation alignment.
	TurnTileLocation = SourceUnit.TileLocation;
	TurnTileLocation.Z = TargetUnit.TileLocation.Z;

	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction.ParentActions[0]));
	MoveTurnAction.m_vFacePoint =  `XWORLD.GetPositionFromTileCoordinates(TurnTileLocation);
	MoveTurnAction.UpdateAimTarget = true;

	//	Make the target play its idle animation to prevent it from turning back to their original facing direction right away.
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, MoveTurnAction));
	PlayAnimation.Params.AnimName = 'HL_Idle';
	PlayAnimation.Params.BlendTime = 0.3f;		

	if (AbilityContext.IsResultContextMiss())
	{
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction.ParentActions[0]));
		PlayAnimation.Params.AnimName = 'FF_SkulljackedMiss';
		return;
	}

	DeathAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_PredatorStrike_Death',, TargetUnit.ObjectID);
	if (DeathAction != none)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, DeathAction));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2Effect_Executed'.default.UnitExecutedFlyover, '', eColor_Bad);
	}
}

static private function X2AbilityTemplate IRI_SK_PredatorStrike_RevealNearestEnemy()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PredatorStrikeReveal		Effect;
	local X2AbilityTrigger_EventListener	AbilityTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_SK_PredatorStrike_RevealNearestEnemy');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.Shiremct_perk_SkirmisherStrike";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetHidden(Template);

	// Targeting and triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	AbilityTrigger = new class'X2AbilityTrigger_EventListener';
	AbilityTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	AbilityTrigger.ListenerData.EventID = 'IRI_SK_PredatorStrike_Activated';
	AbilityTrigger.ListenerData.Filter = eFilter_Unit;
	AbilityTrigger.ListenerData.EventFn = RevealNearestEnemy_Trigger;
	Template.AbilityTriggers.AddItem(AbilityTrigger);
	
	// Effects
	Effect = new class'X2Effect_PredatorStrikeReveal';
	Effect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	// State and Viz
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	//Template.AssociatedPlayTiming = SPT_AfterSequential;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}

static private function EventListenerReturn RevealNearestEnemy_Trigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;

	`AMLOG("Running");

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityState == none || AbilityContext.IsResultContextMiss())
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	`AMLOG("Looking for enemies");

	TargetUnit = FindNearestAdventUnit(SourceUnit);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	if (AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false))
	{
		`AMLOG("Revealing enemy:" @ TargetUnit.GetFullName());
	}
	else
	{	
		`AMLOG("Could not Revealing enemy:" @ TargetUnit.GetFullName());
	}

	return ELR_NoInterrupt;
}

// Look for the ADVENT unit on the Alien team closest to the given Unit.
// Look for those not on red alert first, if none found, fall back to a unit not visible to XCOM.
static private function XComGameState_Unit FindNearestAdventUnit(const XComGameState_Unit SourceUnit)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Unit	ClosestUnit;
	local XComGameStateHistory	History;
	local int					ShortestTileDistance;
	local int					TileDistance;

	History = `XCOMHISTORY;

	ShortestTileDistance = const.MaxInt;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		`AMLOG("Looking at:" @ UnitState.GetFullName());

		if (UnitState.IsDead())
			continue;

		`AMLOG("Alive");

		if (!UnitState.IsInPlay())
			continue;

		`AMLOG("In Play");

		if (UnitState.GetTeam() != eTeam_Alien)
			continue;

		`AMLOG("On alien team");

		if (!UnitState.GetMyTemplate().bIsAdvent)
			continue;

		if (class'X2TacticalVisibilityHelpers'.static.CanXComSquadSeeTarget(UnitState.ObjectID))
			continue;

		TileDistance = SourceUnit.TileDistanceBetween(UnitState);

		`AMLOG("Not visible. Tile Distance:" @ TileDistance);

		if (TileDistance < ShortestTileDistance)
		{
			ShortestTileDistance = TileDistance;
			ClosestUnit = UnitState;

			`AMLOG("This is now closest unit:" @ TileDistance);
		}

		return ClosestUnit;
	}
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

static function X2AbilityTemplate Create_AnimSet_Passive(name TemplateName, string AnimSetPath)
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

static function X2AbilityTemplate HiddenPurePassive(name TemplateName, optional string TemplateIconImage="img:///UILibrary_PerkIcons.UIPerk_standard", optional bool bCrossClassEligible=false, optional Name AbilitySourceName='eAbilitySource_Perk', optional bool bDisplayInUI=true)
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