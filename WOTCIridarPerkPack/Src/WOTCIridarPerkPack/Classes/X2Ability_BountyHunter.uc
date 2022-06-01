class X2Ability_BountyHunter extends X2Ability;

var private X2Condition_Visibility UnitDoesNotSeeCondition;
var private X2Condition_Visibility GameplayVisibilityAllowSquadsight;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Squaddie
	Templates.AddItem(IRI_BH_Headhunter());
	Templates.AddItem(IRI_BH_FirePistol());
	//Templates.AddItem(IRI_BH_PistolOverwatch());

	Templates.AddItem(IRI_BH_DeadlyShadow());
	Templates.AddItem(IRI_BH_DeadlyShadow_Passive());

	// Corporal
	Templates.AddItem(IRI_BH_ChasingShot());
	Templates.AddItem(IRI_BH_ChasingShot_Attack());
	Templates.AddItem(IRI_BH_Blindside());

	// Sergeant
	Templates.AddItem(IRI_BH_CustomShadowstrike());
	Templates.AddItem(IRI_BH_CustomZeroIn());

	// Lieutenant
	Templates.AddItem(IRI_BH_Folowthrough());
	Templates.AddItem(IRI_BH_Untraceable());
	Templates.AddItem(PurePassive('IRI_BH_Untraceable_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	// Captain
	Templates.AddItem(IRI_BH_WitchHunt());
	Templates.AddItem(PurePassive('IRI_BH_WitchHunt_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(PurePassive('IRI_BH_ToolsOfTheTrade', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	// Major
	Templates.AddItem(IRI_BH_RightInTheEye());
	Templates.AddItem(PurePassive('IRI_BH_RightInTheEye_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(PurePassive('IRI_BH_DeadlierShadow_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(PurePassive('IRI_BH_ShadowRounds_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	// Colonel
	Templates.AddItem(IRI_BH_NamedBullet());
	Templates.AddItem(IRI_BH_BigGameHunter());
	Templates.AddItem(IRI_BH_BigGameHunter_Passive());

	Templates.AddItem(IRI_BH_RoutingVolley());
	Templates.AddItem(IRI_BH_RoutingVolley_Attack());
	Templates.AddItem(IRI_BH_RoutingVolley_Resuppress());

	Templates.AddItem(IRI_BH_ShadowTeleport());
	

	return Templates;
}

static function X2AbilityTemplate IRI_BH_ShadowTeleport()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ShadowTeleport');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	
	// Costs
	ActionPointCost = new class'X2AbilityCost_BountyHunter_ShadowTeleport';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	// Effects
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	//Template.AbilityTargetStyle = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.TargetingMethod = class'X2TargetingMethod_Grapple';
	Template.TargetingMethod = class'X2TargetingMethod_BountyHunter_ShadowTeleport';

	//Template.Hostility = eHostility_Movement;
	Template.Hostility = eHostility_Neutral;
	Template.CinescriptCameraType = "Soldier_Grapple";
	Template.bLimitTargetIcons = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.BuildNewGameStateFn = class'X2Ability_DefaultAbilitySet'.static.Grapple_BuildGameState;
	//Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.Grapple_BuildVisualization;
	Template.BuildVisualizationFn = ShadowTeleport_BuildVisualization;
	Template.ModifyNewContextFn = ShadowTeleport_ModifyActivatedAbilityContext;
	Template.BuildInterruptGameStateFn = none;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;
}
static simulated function ShadowTeleport_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability AbilityContext;
	
	// Move the primary target ID from primary to multi target.
	// We don't want it as primary target, cuz then projectiles will fly to it, and soldier will aim at it.
	// We still need to store it somewhere, so then later we can retrieve target's location for the visulization for the point in time
	// where we do want to aim at the enemy.
	AbilityContext = XComGameStateContext_Ability(Context);

	AbilityContext = XComGameStateContext_Ability(Context);
	AbilityContext.InputContext.MultiTargets.AddItem(AbilityContext.InputContext.PrimaryTarget);
	AbilityContext.InputContext.PrimaryTarget.ObjectID = 0;
}

static private function ShadowTeleport_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference MovingUnitRef;	
	local VisualizationActionMetadata ActionMetadata;
	local VisualizationActionMetadata EmptyTrack;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_EnvironmentDamage EnvironmentDamage;
	local X2Action_PlaySoundAndFlyOver CharSpeechAction;
	local X2Action_BountyHunter_ShadowTeleport GrappleAction;
	local X2Action_ExitCover ExitCoverAction;
	local X2Action_RevealArea RevealAreaAction;
	local X2Action_UpdateFOW FOWUpdateAction;
	
	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	MovingUnitRef = AbilityContext.InputContext.SourceObject;
	
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);

	CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'GrapplingHook', eColor_Good); // TODO: Speech

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	RevealAreaAction.TargetLocation = AbilityContext.InputContext.TargetLocations[0];
	RevealAreaAction.AssociatedObjectID = MovingUnitRef.ObjectID;
	RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
	RevealAreaAction.bDestroyViewer = false;

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	FOWUpdateAction.BeginUpdate = true;

	ExitCoverAction = X2Action_ExitCover(class'X2Action_BountyHunter_ShadowTeleport_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	ExitCoverAction.bUsePreviousGameState = true;

	GrappleAction = X2Action_BountyHunter_ShadowTeleport(class'X2Action_BountyHunter_ShadowTeleport'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	GrappleAction.DesiredLocation = AbilityContext.InputContext.TargetLocations[0];

	`AMLOG("Visualizing target location as:" @ AbilityContext.InputContext.TargetLocations[0]);

	// destroy any windows we flew through
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
	{
		ActionMetadata = EmptyTrack;

		//Don't necessarily have a previous state, so just use the one we know about
		ActionMetadata.StateObject_OldState = EnvironmentDamage;
		ActionMetadata.StateObject_NewState = EnvironmentDamage;
		ActionMetadata.VisualizeActor = History.GetVisualizer(EnvironmentDamage.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext());
	}

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	FOWUpdateAction.EndUpdate = true;

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	RevealAreaAction.AssociatedObjectID = MovingUnitRef.ObjectID;
	RevealAreaAction.bDestroyViewer = true;
}

static function X2AbilityTemplate IRI_BH_ShadowTeleport11()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_GrantActionPoints		GrantActionPoints;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ShadowTeleport');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;	
	
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	
	

	// TODO: Charges

	// Effects
	GrantActionPoints = new class'X2Effect_GrantActionPoints';
	GrantActionPoints.NumActionPoints = 1;
	GrantActionPoints.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddShooterEffect(GrantActionPoints);

	// State and Viz
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.Hostility = eHostility_Neutral;
	//Template.CinescriptCameraType = "StandardSuppression";
	//Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.BuildNewGameStateFn = class'X2Ability_Cyberus'.static.Teleport_BuildGameState;
	//Template.BuildVisualizationFn = class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.static.IcarusJump_BuildVisualization;
	//Template.BuildVisualizationFn = ShadowTeleport_BuildVisualization;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.ModifyNewContextFn = class'X2Ability_Cyberus'.static.Teleport_ModifyActivatedAbilityContext;
	Template.BuildInterruptGameStateFn = none;

	

	return Template;	
}


// This ability is a bit complicated. Desired function:
// You Suppress the target and force it to move, immediately triggering an attack against it.
// The suppression effect should remain on target, allowing further reaction attacks until the target dies, 
// moves out of LoS, or shooter runs out of ammo.
// 
// Here's how this is achieved:
// IRI_BH_RoutingVolley applies the initial suppression effect and forces the target to run. 
// It also applies a unit value which will be used later to make sure that later we retrigger suppression only against this particular target.
// This suppression effect registers for ability activation event, and triggers the IRI_BH_RoutingVolley_Attack,
// which records the Event Chain Start History Index as a unit value on the target and removes the suppression effect from the target.
// If the target is not moving, we resuppress it right away by triggering the IRI_BH_RoutingVolley_Resuppress in that same listener.
// If the target is moving, then we don't do anything.
// The IRI_BH_RoutingVolley_Resuppress has its own event listener trigger, but it will activate only against a unit that activates an ability
// whose Event Chain Start History Index is not the one that we already recoreded on the suppressed unit as a unit value.
// This ensures the event chain fully resolves before we are able to resuppress the target.
// This convoluted process is required mainly to address various issues that occur when the same suppression effect is used for multiple suppression shots on the same moving target:
// 1. After the unit moves, the suppressing unit continues suppressing the unit's original location. 
// This can be addressed by updating the m_SuppressionHistoryIndex on the suppressing unit state.
// 2. Even if the previous issue is addressed, the suppressing unit will still face the target's original location with their lower body, 
// turning only arms and upper torso as much as possible to aim at the new location.
// This can be addressed via custom Build Vis function for the suppression shot which will add X2Action_MoveTurn after the suppression shot goes through.
// 3. Even if previous issues are addressed, the following suppression cosmetic shots will visually hit the target dead center, producing blood splatter, but not hurting the target,
// as the shots are just for the show.
// I couldn't figure out any way to address this other than removing and reapplying the suppression effect from the target after each shot.
// The ressuppressing needs to be handled by a separate ability and not the suppression shot itself to prevent inception.

static function X2AbilityTemplate IRI_BH_RoutingVolley()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_BountyHunter_RoutingVolley	SuppressionEffect;
	local X2Effect_AutoRunBehaviorTree		RunTree;
	local X2Effect_GrantActionPoints		GrantActionPoints;
	local X2Effect_SetUnitValue				UnitValueEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_RoutingVolley');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;	
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityAllowSquadsight);

	// Costs
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// TODO: Charges

	// Effects
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = 'IRI_BH_RoutingVolley_UnitValue_SuppressTarget';
	UnitValueEffect.NewValueToSet = 1.0f;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	Template.AddTargetEffect(UnitValueEffect);

	Template.bIsASuppressionEffect = true;
	SuppressionEffect = new class'X2Effect_BountyHunter_RoutingVolley';
	SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = true;
	//SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionTargetEffectDesc, Template.IconImage);
	SuppressionEffect.SetSourceDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionSourceEffectDesc, Template.IconImage);
	Template.AddTargetEffect(SuppressionEffect);
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());

	GrantActionPoints = new class'X2Effect_GrantActionPoints';
	GrantActionPoints.NumActionPoints = 1;
	GrantActionPoints.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddTargetEffect(GrantActionPoints);

	RunTree = new class'X2Effect_AutoRunBehaviorTree';
	RunTree.BehaviorTree = 'IRI_PP_FlushRoot';
	Template.AddTargetEffect(RunTree);

	// State and Viz
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.Hostility = eHostility_Offensive;
	Template.CinescriptCameraType = "StandardSuppression";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'BountyHunter'.static.SuppressionBuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = class'BountyHunter'.static.SuppressionBuildVisualizationSync;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AdditionalAbilities.AddItem('IRI_BH_RoutingVolley_Attack');
	Template.AdditionalAbilities.AddItem('IRI_BH_RoutingVolley_Resuppress');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_RoutingVolley_Attack()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_Ammo					AmmoCost;
	local X2Effect_RemoveEffects_MatchSource	RemoveSuppression;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_RoutingVolley_Attack', true, false, false);
	SetHidden(Template);

	Template.AbilityTriggers.Length = 0;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	RemoveSuppression = new class'X2Effect_RemoveEffects_MatchSource';
	RemoveSuppression.EffectNamesToRemove.AddItem(class'X2Effect_BountyHunter_RoutingVolley'.default.EffectName);
	Template.AddTargetEffect(RemoveSuppression);
	
	// Need just the ammo cost.
	Template.AbilityCosts.Length = 0;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.bShowActivation = true;

	//don't want to exit cover, we are already in suppression/alert mode.
	Template.bSkipExitCoverWhenFiring = true;

	SetFireAnim(Template, 'FF_FireSuppress');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_RoutingVolley_Resuppress()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_BountyHunter_RoutingVolley	SuppressionEffect;
	local X2AbilityTrigger_EventListener		Trigger;
	local X2AbilityCost_Ammo					AmmoCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_RoutingVolley_Resuppress');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_supression";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetHidden(Template);

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;	
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.Priority = 40;
	Trigger.ListenerData.EventFn = RoutingVolleyTriggerListener_Resuppress;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Costs
	// TODO: Make sure resuppression happens only if ammo is present.
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true; // Check ammo for activation only.
	Template.AbilityCosts.AddItem(AmmoCost);

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityAllowSquadsight);

	// Effects
	Template.bIsASuppressionEffect = true;
	SuppressionEffect = new class'X2Effect_BountyHunter_RoutingVolley';
	SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = true;
	SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionTargetEffectDesc, Template.IconImage);
	SuppressionEffect.SetSourceDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionSourceEffectDesc, Template.IconImage);
	Template.AddTargetEffect(SuppressionEffect);

	// State and Viz
	Template.Hostility = eHostility_Offensive;
	//Template.CinescriptCameraType = "StandardSuppression";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'BountyHunter'.static.SuppressionBuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = class'BountyHunter'.static.SuppressionBuildVisualizationSync;

	Template.AssociatedPlayTiming = SPT_AfterSequential;
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;	
}

static private function EventListenerReturn RoutingVolleyTriggerListener_Resuppress(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			TargetUnit;
	local XComGameStateHistory			History;
	local UnitValue						UV;

	// Process only abilities that involve movement.
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt || AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length == 0)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none || !AbilityState.IsAbilityInputTriggered())
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(EventSource);
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	// Use this value to filter out ability activations from units that we didn't manually suppress previously.
	if (!TargetUnit.GetUnitValue('IRI_BH_RoutingVolley_UnitValue_SuppressTarget', UV))
		return ELR_NoInterrupt;

	`AMLOG("Attempting trigger resuppress by ability:" @ AbilityContext.InputContext.AbilityTemplateName);

	History = `XCOMHISTORY;
	TargetUnit.GetUnitValue('IRI_BH_RoutingVolley_UnitValue', UV);
	if (UV.fValue != History.GetEventChainStartIndex())
	{
		`AMLOG("Routing Volley has not yet responded to this event chain start, exiting.");
		return ELR_NoInterrupt;
	}

	if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1] != TargetUnit.TileLocation)
	{
		`AMLOG("Unit is not yet on final tile of movement, exiting");
		return ELR_NoInterrupt;
	}

	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	`AMLOG("Attempting resuppress");

	if (AbilityState.AbilityTriggerAgainstSingleTarget(TargetUnit.GetReference(), false))
	{
		`AMLOG("resuppress succeess");
	}

	return ELR_NoInterrupt;
}



static function X2AbilityTemplate IRI_BH_CustomZeroIn()
{
	local X2AbilityTemplate						Template;
	local X2Effect_BountyHunter_CustomZeroIn	BonusEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_CustomZeroIn');

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_ZeroIn";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	BonusEffect = new class'X2Effect_BountyHunter_CustomZeroIn';
	BonusEffect.BuildPersistentEffect(1, true, false, false);
	BonusEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(BonusEffect);

	return Template;
}

static function X2AbilityTemplate IRI_BH_CustomShadowstrike()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ToHitModifier                Effect;
	local X2Condition_Visibility                VisCondition;

	// Same as original, but require no cover.

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_CustomShadowstrike');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstrike";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_ToHitModifier';
	Effect.EffectName = 'IRI_BH_CustomShadowstrike';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Effect.AddEffectHitModifier(eHit_Success, `GetConfigInt('IRI_BH_CustomShadowstrike_AimBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, false /*NonFlanked*/);
	Effect.AddEffectHitModifier(eHit_Crit, `GetConfigInt('IRI_BH_CustomShadowstrike_CritBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, false /*NonFlanked*/);
	

	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bExcludeGameplayVisible = true;
	Effect.ToHitConditions.AddItem(VisCondition);

	//VisCondition = new class'X2Condition_Visibility';
	//VisCondition.bRequireNotMatchCoverType = true;
	//VisCondition.TargetCover = CT_None;
	//Effect.ToHitConditions.AddItem(VisCondition);

	Template.AddTargetEffect(Effect);

	return Template;
}

static function X2AbilityTemplate IRI_BH_BigGameHunter()
{
	local X2AbilityTemplate		Template;	
	local X2AbilityCost_Ammo	AmmoCost;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_BigGameHunter', true, false, false);
	SetHidden(Template);

	Template.AbilityTriggers.Length = 0;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	
	// Need just the ammo cost.
	Template.AbilityCosts.Length = 0;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.bShowActivation = true;

	return Template;	
}

static function X2AbilityTemplate IRI_BH_BigGameHunter_Passive()
{
	local X2AbilityTemplate Template;	
	local X2Effect_BountyHunter_BigGameHunter Effect;
	local X2Effect_Persistent PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BigGameHunter_Passive');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstrike";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_BountyHunter_BigGameHunter';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(Effect);

	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(PersistentEffect);

	Template.AdditionalAbilities.AddItem('IRI_BH_BigGameHunter');

	return Template;	
}


static function X2AbilityTemplate IRI_BH_FirePistol()
{
	local X2AbilityTemplate				Template;	
	local X2AbilityCost_ActionPoints	ActionPointCost;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_FirePistol');

	Template.bUseAmmoAsChargesForHUD = true;
	
	Template.AbilityCosts.Length = 0;
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_BHAmmo');

	ActionPointCost = new class'X2AbilityCost_QuickdrawActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	//Template.AdditionalAbilities.AddItem('PistolOverwatchShot');
	//Template.AdditionalAbilities.AddItem('PistolReturnFire');
	Template.AdditionalAbilities.AddItem('HotLoadAmmo');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_NamedBullet()
{
	local X2AbilityTemplate					Template;	
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityMultiTarget_BurstFire	BurstFireMultiTarget;
	local X2Condition_Visibility			VisibilityCondition;
	local X2Condition_UnitProperty			PropertyCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_NamedBullet');

	// Icon
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
	Template.AbilitySourceName = 'eAbilitySource_Perk';   

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	ToHitCalc.bGuaranteedHit = true;
	Template.AbilityToHitCalc = ToHitCalc;

	Template.AbilityTargetConditions.Length = 0;

	VisibilityCondition = new class'X2Condition_Visibility';
	VisibilityCondition.bRequireGameplayVisible = true;
	VisibilityCondition.bRequireBasicVisibility = true;
	VisibilityCondition.bRequireMatchCoverType = true;
	VisibilityCondition.TargetCover = CT_None;
	Template.AbilityTargetConditions.AddItem(VisibilityCondition);

	PropertyCondition = new class'X2Condition_UnitProperty';
	PropertyCondition.ExcludeAlive = false;
	PropertyCondition.ExcludeDead = true;
	PropertyCondition.ExcludeFriendlyToSource = true;
	PropertyCondition.ExcludeHostileToSource = false;
	PropertyCondition.TreatMindControlledSquadmateAsHostile = true;
	PropertyCondition.RequireWithinRange = true;
	PropertyCondition.WithinRange = class'XComWorldData'.const.WORLD_StepSize * `GetConfigInt('IRI_BH_NamedBullet_Distance_Tiles');
	Template.AbilityTargetConditions.AddItem(PropertyCondition);

	BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire';
	BurstFireMultiTarget.NumExtraShots = 2;
	Template.AbilityMultiTargetStyle = BurstFireMultiTarget;
	
	// Needs to be specifically the same effect to visualize damage markers properly. Chalk up another rake stepped on.
	Template.AddMultiTargetEffect(Template.AbilityTargetEffects[0]);
	//Template.AddMultiTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	
	// Reset costs, keep only AP cost.
	Template.AbilityCosts.Length = 0;   

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	AddCharges(Template, `GetConfigInt('IRI_BH_NamedBullet_Charges'));

	Template.ActivationSpeech = 'FanFire';

	// TODO: Fancy animation. Blue muzzle flash, ricochet sound, ricochet pfx.
	//SetFireAnim(Template, 'FF_NamedBullet');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_Untraceable()
{
	local X2AbilityTemplate			Template;
	local X2Effect_ReduceCooldowns	ReduceCooldown;
	local X2Condition_UnitValue		UnitValueCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Untraceable');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_flamethrower";
	SetHidden(Template);

	// Targeting and Triggering
	SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnEnded', ELD_OnStateSubmitted, eFilter_Player, 50);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	UnitValueCondition = new class'X2Condition_UnitValue';
	UnitValueCondition.AddCheckValue('AttacksThisTurn', 0, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(UnitValueCondition);

	ReduceCooldown = new class'X2Effect_ReduceCooldowns';
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_DeadlyShadow');
	Template.AddTargetEffect(ReduceCooldown);

	// State and Viz
	Template.bIsPassive = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;

	Template.AdditionalAbilities.AddItem('IRI_BH_Untraceable_Passive');

	return Template;
}

static function X2AbilityTemplate IRI_BH_RightInTheEye()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_RightInTheEye');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_flamethrower";
	SetHidden(Template);
	
	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityToHitCalc = default.DeadEye;

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 40;
	Trigger.ListenerData.EventFn = class'Help'.static.FollowUpShot_EventListenerTrigger_CritOnly;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityAllowSquadsight);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	// Ability Effects
	Template.bAllowAmmoEffects = false;
	Template.bAllowBonusWeaponEffects = false;
	Template.bAllowFreeFireWeaponUpgrade = false;
	Template.AddTargetEffect(class'X2Effect_Blind'.static.CreateBlindEffect(1, 0));

	// State and Vis
	Template.FrameAbilityCameraType = eCameraFraming_Never; 
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bUsesFiringCamera = false;
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'Help'.static.FollowUpShot_BuildVisualization;
	Template.MergeVisualizationFn = class'Help'.static.FollowUpShot_MergeVisualization;
	Template.BuildInterruptGameStateFn = none;

	Template.AdditionalAbilities.AddItem('IRI_BH_RightInTheEye_Passive');

	return Template;
}

static function X2AbilityTemplate IRI_BH_WitchHunt()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Condition_UnitProperty			UnitProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_WitchHunt');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_flamethrower";
	SetHidden(Template);
	
	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityToHitCalc = default.DeadEye;

	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 40;
	Trigger.ListenerData.EventFn = class'Help'.static.FollowUpShot_EventListenerTrigger_CritOnly;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityAllowSquadsight);

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeAlive = false;
	UnitProperty.ExcludeDead = true;
	UnitProperty.ExcludeFriendlyToSource = true;
	UnitProperty.ExcludeHostileToSource = false;
	UnitProperty.TreatMindControlledSquadmateAsHostile = true;
	UnitProperty.ExcludeNonPsionic = true;
	Template.AbilityTargetConditions.AddItem(UnitProperty);

	// Ability Effects
	Template.bAllowAmmoEffects = false;
	Template.bAllowBonusWeaponEffects = false;
	Template.bAllowFreeFireWeaponUpgrade = false;
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1));

	// State and Vis
	Template.FrameAbilityCameraType = eCameraFraming_Never; 
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bUsesFiringCamera = false;
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'Help'.static.FollowUpShot_BuildVisualization;
	Template.MergeVisualizationFn = class'Help'.static.FollowUpShot_MergeVisualization;
	Template.BuildInterruptGameStateFn = none;

	Template.AdditionalAbilities.AddItem('IRI_BH_WitchHunt_Passive');

	return Template;
}

static function X2AbilityTemplate IRI_BH_Headhunter()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_Headhunter	Headhunter;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Headhunter');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

	SetPassive(Template);

	Headhunter = new class'X2Effect_BountyHunter_Headhunter';
	Headhunter.BuildPersistentEffect(1, true);
	Headhunter.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(Headhunter);
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_DeadlyShadow()
{
	local X2AbilityTemplate						Template;
	local X2Effect_BountyHunter_DeadlyShadow	StealthEffect;
	local X2Effect_AdditionalAnimSets			Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_DeadlyShadow');

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
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_BountyHunter_Stealth'); // Must not be flanked and not in Deadly Shadow
	Template.AddShooterEffectExclusions();

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	AddCooldown(Template, `GetConfigInt('IRI_DeadlyShadow_Cooldown'));
	
	// Effects
	StealthEffect = new class'X2Effect_BountyHunter_DeadlyShadow';
	StealthEffect.BuildPersistentEffect(2, false, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(StealthEffect);

	Template.AddTargetEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	Effect = new class'X2Effect_AdditionalAnimSets';
	Effect.EffectName = 'ShadowAnims';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	Effect.bRemoveWhenTargetConcealmentBroken = true;
	Effect.AddAnimSetWithPath("IRIBountyHunter.Anims.AS_ReaperShadow");
	Effect.EffectName = 'IRI_DeadlyShadow_Effect';
	Template.AddTargetEffect(Effect);

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

	Template.AdditionalAbilities.AddItem('IRI_BH_DeadlyShadow_Passive');
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_DeadlyShadow_Passive()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_CritMagic	CritMagic;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_DeadlyShadow_Passive');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

	SetPassive(Template);
	
	CritMagic = new class'X2Effect_BountyHunter_CritMagic';
	CritMagic.BuildPersistentEffect(1, true);
	CritMagic.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(CritMagic);
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_ChasingShot()
{
	local X2AbilityTemplate		Template;	
	local X2Effect_Persistent	ChasingShotEffect;
	local X2AbilityCost_Ammo	AmmoCost;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ChasingShot');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition); // visible to any ally

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);	

	AmmoCost = new class'X2AbilityCost_BHAmmo';
	AmmoCost.bFreeCost = true; // Require ammo only for activation
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bUseAmmoAsChargesForHUD = true;

	AddCooldown(Template, `GetConfigInt('IRI_BH_ChasingShot_Cooldown'));

	// Effects
	ChasingShotEffect = new class'X2Effect_Persistent';
	ChasingShotEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	ChasingShotEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true); // TODO: Status icon here
	ChasingShotEffect.EffectName = 'IRI_BH_ChasingShot_Effect';
	ChasingShotEffect.DuplicateResponse = eDupe_Allow;
	Template.AddTargetEffect(ChasingShotEffect);

	// State and Viz
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.ConcealmentRule = eConceal_Always;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
	//Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AdditionalAbilities.AddItem('IRI_BH_ChasingShot_Attack');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_ChasingShot_Attack()
{
	local X2AbilityTemplate							Template;	
	local X2AbilityTrigger_EventListener			Trigger;
	local X2Condition_UnitEffectsWithAbilitySource	UnitEffectsCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_ChasingShot_Attack');

	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect('IRI_BH_ChasingShot_Effect', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// Icon
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standard";
	Template.AbilitySourceName = 'eAbilitySource_Perk';   
	SetHidden(Template);	    

	Template.AbilityTriggers.Length = 0;	
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = ChasingShotTriggerListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Reset costs, keep only ammo cost.
	Template.AbilityCosts.Length = 0;   
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_BHAmmo');

	Template.bShowActivation = true;
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	return Template;	
}

static private function EventListenerReturn ChasingShotTriggerListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			UnitState;
	local XComGameState_Ability			ChasingShotState;
	local XComGameState					NewGameState;
	local XComGameStateHistory			History;
	local XComGameState_Effect			EffectState;
	//local XComGameState_Ability			AbilityState;
	//local StateObjectReference			AbilityRef;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none) 
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	ChasingShotState = XComGameState_Ability(CallbackData);
	if (ChasingShotState == none)
		return ELR_NoInterrupt;

	// If triggered ability involves movement, trigger Chasing Shot attack against first available target when the unit is on the final tile of movement.
	if (AbilityContext.InputContext.MovementPaths.Length > 0 && 
        AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length > 0)
    {
        if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1] == UnitState.TileLocation)
		{
			if (ChasingShotState.AbilityTriggerAgainstTargetIndex(0))
			{
				// After activating the ability, remove the Chasing Shot effect from the target.
				// This needs to be done here so that Chasing Shot can properly interact with Followthrough.
				`AMLOG("Removing Chasing Shot Effect");
				History = `XCOMHISTORY;
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove Chase effect");
				foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
				{
					if (EffectState.GetX2Effect().EffectName == 'IRI_BH_ChasingShot_Effect' && EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ChasingShotState.OwnerStateObject.ObjectID)
					{
						EffectState.RemoveEffect(NewGameState, NewGameState, true);
						break;
					}
				}

				

				`GAMERULES.SubmitGameState(NewGameState);
			}
			// Reset cooldown if Chase Shot failed to activate
			// -> but the effect remains on target, you can try again.
			//else
			//{
			//	AbilityRef = UnitState.FindAbility('IRI_BH_ChasingShot', ChasingShotState.SourceWeapon);
			//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
			//	if (AbilityState != none)
			//	{
			//		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Chase Cooldown");
			//		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
			//		AbilityState.iCooldown = 0;
			//		`GAMERULES.SubmitGameState(NewGameState);
			//	}
			//}
		}
	}	

	return ELR_NoInterrupt;
}

static function X2AbilityTemplate IRI_BH_Blindside()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2Effect_Knockback				KnockbackEffect;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Blindside');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	// Targeting and Triggering
	Template.DisplayTargetHitChance = true;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.TargetingMethod = class'X2TargetingMethod_OverTheShoulder';
	Template.AbilityToHitCalc = default.SimpleStandardAim;
	Template.AbilityToHitOwnerOnMissCalc = default.SimpleStandardAim;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.UnitDoesNotSeeCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	
	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);	
	AddCooldown(Template, `GetConfigInt('IRI_BH_Blindside_Cooldown'));

	// Ammo
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_BHAmmo');
	Template.bUseAmmoAsChargesForHUD = true;

	// Effects
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bIgnoreArmor = true;
	Template.AddTargetEffect(WeaponDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;
	Template.bAllowFreeFireWeaponUpgrade = true;

	// State and Viz
	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "StandardGunFiring";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;	
}

static function X2AbilityTemplate IRI_BH_Folowthrough()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_BountyHunter_Folowthrough	Folowthrough;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Folowthrough');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	// Targeting and Triggering
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	
	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);	
	AddCooldown(Template, `GetConfigInt('IRI_BH_Folowthrough_Cooldown'));

	// Effects
	Folowthrough = new class'X2Effect_BountyHunter_Folowthrough';
	Folowthrough.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	Folowthrough.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(Folowthrough);

	// State and Viz
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.ConcealmentRule = eConceal_Always;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;	
	//Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;	
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

defaultproperties
{
	Begin Object Class=X2Condition_Visibility Name=DefaultVisibilityCondition
    bExcludeGameplayVisible = true; //condition will FAIL if there is GameplayVisibility FROM the target TO the source
    End Object
    UnitDoesNotSeeCondition = DefaultVisibilityCondition;

	Begin Object Class=X2Condition_Visibility Name=DefaultGameplayVisibilityAllowSquadsight
	bRequireGameplayVisible = true;
	bAllowSquadsight = true;
    End Object
    GameplayVisibilityAllowSquadsight = DefaultGameplayVisibilityAllowSquadsight;
	
}


/*
static function X2AbilityTemplate IRI_BH_PistolOverwatch()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_ReserveActionPoints      ReserveActionPointsEffect;
	local array<name>                       SkipExclusions;
	local X2Effect_CoveringFire             CoveringFireEffect;
	local X2Condition_AbilityProperty       CoveringFireCondition;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2Effect_SetUnitValue             UnitValueEffect;
	local X2Condition_UnitEffects           SuppressedCondition;
	local X2AbilityCost_Ammo				AmmoCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_PistolOverwatch');
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;   //  this will guarantee the unit has at least 1 action point
	ActionPointCost.bFreeCost = true;           //  ReserveActionPoints effect will take all action points away
	ActionPointCost.DoNotConsumeAllEffects.Length = 0;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.Length = 0;
	ActionPointCost.AllowedTypes.RemoveItem(class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	SuppressedCondition = new class'X2Condition_UnitEffects';
	SuppressedCondition.AddExcludeEffect(class'X2Effect_Suppression'.default.EffectName, 'AA_UnitIsSuppressed');
	SuppressedCondition.AddExcludeEffect(class'X2Effect_SkirmisherInterrupt'.default.EffectName, 'AA_AbilityUnavailable');
	Template.AbilityShooterConditions.AddItem(SuppressedCondition);
	
	ReserveActionPointsEffect = new class'X2Effect_ReserveOverwatchPoints';
	Template.AddTargetEffect(ReserveActionPointsEffect);

	CoveringFireEffect = new class'X2Effect_CoveringFire';
	CoveringFireEffect.AbilityToActivate = 'PistolOverwatchShot';
	CoveringFireEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	CoveringFireCondition = new class'X2Condition_AbilityProperty';
	CoveringFireCondition.OwnerHasSoldierAbilities.AddItem('CoveringFire');
	CoveringFireEffect.TargetConditions.AddItem(CoveringFireCondition);
	Template.AddTargetEffect(CoveringFireEffect);

	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = default.ConcealedOverwatchTurn;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(UnitValueEffect);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_pistoloverwatch";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PISTOL_OVERWATCH_PRIORITY;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.AbilityConfirmSound = "Unreal2DSounds_OverWatch";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = OverwatchAbility_BuildVisualization;
	Template.CinescriptCameraType = "Overwatch";

	Template.Hostility = eHostility_Defensive;

	// Removed
	//Template.DefaultKeyBinding = class'UIUtilities_Input'.const.FXS_KEY_Y;
	//Template.bNoConfirmationWithHotKey = true;

	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	// Added
	Template.bUseAmmoAsChargesForHUD = true;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true; // Require ammo only for activation
	Template.AbilityCosts.AddItem(AmmoCost);

	return Template;
}*/