class X2Ability_ClassRework extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_RN_ZephyrStrike());
	Templates.AddItem(IRI_RN_TacticalAdvance());
	Templates.AddItem(PurePassive('IRI_RN_TacticalAdvance_Passive', "img:///UILibrary_XPACK_Common.UIPerk_bond_brotherskeeper", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_RN_Intercept());
	Templates.AddItem(IRI_RN_Intercept_Return());
	Templates.AddItem(IRI_RN_Intercept_Attack());
	
	return Templates;
}

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
	Template.IconImage = "img:///IRIBrawler.UI.UIPerk_Intercept";
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
	
	Template.IconImage = "img:///IRIBrawler.UI.UIPerk_Intercept";
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


static function X2AbilityTemplate IRI_RN_TacticalAdvance()
{
	local X2AbilityTemplate					Template;
	local X2Effect_TacticalAdvance			Effect;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_TacticalAdvance');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_IonicStorm";
	
	SetHidden(Template);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Trigger = new class'X2AbilityTrigger_EventListener';	
	Trigger.ListenerData.EventID = 'AbilityActivated';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.Priority = 50;
	Trigger.ListenerData.EventFn = TacticalAdvance_TriggerEventListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	Effect = new class'X2Effect_TacticalAdvance';
	Effect.BuildPersistentEffect(2, false,,, eGameRule_PlayerTurnEnd);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	Template.AdditionalAbilities.AddItem('IRI_RN_TacticalAdvance_Passive');

	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static private function EventListenerReturn TacticalAdvance_TriggerEventListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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

static function X2AbilityTemplate IRI_RN_ZephyrStrike()
{
	local X2AbilityTemplate						Template;
	local X2AbilityMultiTarget_Radius           MultiTargetRadius;
	local X2AbilityCost_ActionPoints			ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_RN_ZephyrStrike');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_IonicStorm";
	
	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Targeting and Triggering
	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Cursor';
	Template.TargetingMethod = class'X2TargetingMethod_PathTarget';

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	MultiTargetRadius = new class'X2AbilityMultiTarget_Radius';
	MultiTargetRadius.fTargetRadius = `TILESTOMETERS(3);
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
	//Template.CinescriptCameraType = "IRI_RN_ZephyrStrike_Camera";
	//SetFireAnim(Template, 'FF_ZephyrStrike');
	//Template.DamagePreviewFn = IonicStormDamagePreview;

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