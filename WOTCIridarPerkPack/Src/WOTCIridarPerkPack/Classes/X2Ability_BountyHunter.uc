class X2Ability_BountyHunter extends X2Ability;

var private X2Condition_Visibility UnitDoesNotSeeCondition;
var private X2Condition_Visibility GameplayVisibilityAllowSquadsight;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Squaddie
	Templates.AddItem(IRI_BH_Headhunter());
	Templates.AddItem(IRI_BH_FirePistol());
	Templates.AddItem(SetTreePosition(IRI_BH_Nightfall(), 0));
	Templates.AddItem(IRI_BH_Nightfall_Passive());

		// Corporal
	Templates.AddItem(SetTreePosition(IRI_BH_DramaticEntrance(), 1));
	Templates.AddItem(IRI_BH_DarkNight_Passive());

		// Sergeant
	Templates.AddItem(SetTreePosition(IRI_BH_ShadowTeleport(), 2)); // Night Dive
	Templates.AddItem(IRI_BH_Nightmare());

		// Lieutenant
	Templates.AddItem(IRI_BH_DoublePayload());
	Templates.AddItem(IRI_BH_NothingPersonal());
	Templates.AddItem(SetTreePosition(IRI_BH_BurstFire(), 3));
	Templates.AddItem(IRI_BH_BurstFire_Passive());

		// Captain
	Templates.AddItem(IRI_BH_BombRaider());
	Templates.AddItem(IRI_BH_NightRounds());
	Templates.AddItem(IRI_BH_UnrelentingPressure());

		// Major
	Templates.AddItem(IRI_BH_WitchHunt());
	Templates.AddItem(PurePassive('IRI_BH_WitchHunt_Passive', "img:///IRIPerkPackUI.UIPerk_WitchHunt", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(PurePassive('IRI_BH_FeelingLucky_Passive', "img:///IRIPerkPackUI.UIPerk_FeelingLucky", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_BH_BigGameHunter());

		// Colonel
	Templates.AddItem(IRI_BH_BlindingFire());
	Templates.AddItem(PurePassive('IRI_BH_BlindingFire_Passive', "img:///IRIPerkPackUI.UIperk_BlindingFire", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(SetTreePosition(IRI_BH_NamedBullet(), 6));
	Templates.AddItem(Create_AnimSet_Passive('IRI_BH_NamedBullet_AnimPassive', "IRIBountyHunter.Anims.AS_NamedShot"));
	Templates.AddItem(SetTreePosition(IRI_BH_Terminate(), 6));
	Templates.AddItem(IRI_BH_Terminate_Attack());
	Templates.AddItem(IRI_BH_Terminate_Resuppress());

	// GTS
	Templates.AddItem(IRI_BH_Untraceable());
	Templates.AddItem(PurePassive('IRI_BH_Untraceable_Passive', "img:///IRIPerkPackUI.UIPerk_Untraceable", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	// Unused
	Templates.AddItem(IRI_BH_ChasingShot());
	Templates.AddItem(IRI_BH_ChasingShot_Attack());
	Templates.AddItem(IRI_BH_Blindside());
	Templates.AddItem(IRI_BH_Folowthrough());
	Templates.AddItem(IRI_BH_BigGameHunter_Alt());
	Templates.AddItem(IRI_BH_BigGameHunter_Alt_Passive());

	return Templates;
}

static private function X2AbilityTemplate SetTreePosition(X2AbilityTemplate Template, int iRank)
{
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY + 10 * iRank;

	return Template;
}

static function X2AbilityTemplate IRI_BH_NightRounds()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_NightRounds	NightRounds;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_NightRounds');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ToolsOfTheTrade";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	NightRounds = new class'X2Effect_BountyHunter_NightRounds';
	NightRounds.BuildPersistentEffect(1, true);
	NightRounds.BonusCritDamage = `GetConfigInt('IRI_BH_NightRounds_BonusCritDamage');
	NightRounds.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(NightRounds);

	return Template;
}

static function X2AbilityTemplate IRI_BH_UnrelentingPressure()
{
	local X2AbilityTemplate							Template;
	local X2Effect_BountyHunter_UnrelentingPressure	ReduceCooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_UnrelentingPressure');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_UnrelentingPressure";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	ReduceCooldown = new class'X2Effect_BountyHunter_UnrelentingPressure';
	ReduceCooldown.BuildPersistentEffect(1, true, true, true);
	ReduceCooldown.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(ReduceCooldown);
	
	Template.PrerequisiteAbilities.AddItem('IRI_BH_BurstFire');

	return Template;
}

static function X2AbilityTemplate IRI_BH_BombRaider()
{
	local X2AbilityTemplate		Template;
	local X2Effect_BiggestBooms	BiggestBoomsEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BombRaider');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BombRaider";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	BiggestBoomsEffect = new class'X2Effect_BiggestBooms';
	BiggestBoomsEffect.BuildPersistentEffect(1, true, true, true);
	BiggestBoomsEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(BiggestBoomsEffect);

	return Template;
}

static function X2AbilityTemplate IRI_BH_BurstFire()
{
	local X2AbilityTemplate					Template;	
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityMultiTarget_BurstFire	BurstFireMultiTarget;
	local int								NumExtraShots;

	// No ammo cost, no using while burning or disoriented
	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_BurstFire', true, false, false);

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BurstFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = `GetConfigInt('IRI_BH_BurstFire_AmmoCost');
	Template.AbilityCosts.AddItem(AmmoCost);

	AddCooldown(Template, `GetConfigInt('IRI_BH_BurstFire_Cooldown'));

	NumExtraShots = `GetConfigInt('IRI_BH_BurstFire_NumShots') - 1;
	if (NumExtraShots > 0)
	{
		BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire';
		BurstFireMultiTarget.NumExtraShots = NumExtraShots;
		Template.AbilityMultiTargetStyle = BurstFireMultiTarget;
	}
	Template.AddMultiTargetEffect(Template.AbilityTargetEffects[2]); // Just the damage effect.

	// Placebo, actual firing animation is set by Template Master in BountyHunter\XComTemplateEditor.ini
	SetFireAnim(Template, 'FF_FireSuppress');

	Template.AdditionalAbilities.AddItem('IRI_BH_BurstFire_Passive');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_BurstFire_Passive()
{
	local X2AbilityTemplate							Template;
	local X2Effect_ModifySquadsightPenalty			BurstFireAimPenalty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BurstFire_Passive');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BurstFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);
	SetHidden(Template);

	BurstFireAimPenalty = new class'X2Effect_ModifySquadsightPenalty';
	BurstFireAimPenalty.AbilityNames.AddItem('IRI_BH_BurstFire');
	BurstFireAimPenalty.fModifier = `GetConfigFloat('IRI_BH_BurstFire_SquadSightPenaltyModifier');
	BurstFireAimPenalty.BuildPersistentEffect(1, true);
	BurstFireAimPenalty.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false,,Template.AbilitySourceName);
	Template.AddTargetEffect(BurstFireAimPenalty);

	return Template;
}

static function X2AbilityTemplate IRI_BH_NothingPersonal()
{
	local X2AbilityTemplate					Template;	
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_ApplyWeaponDamage		WeaponDamageEffect;
	local X2Effect_Knockback				KnockbackEffect;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_NothingPersonal');

	// Icon
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_NothingPersonal";
	Template.AbilitySourceName = 'eAbilitySource_Perk';   
	SetHidden(Template);	    

	// Trigger
	Template.AbilityTriggers.Length = 0;	
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'IRI_BH_ShadowTeleport';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = NothingPersonalTriggerListener;
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Costs
	Template.AbilityCosts.Length = 0;   
	
	// Effects
	Template.AbilityTargetEffects.Length = 0;
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.DamageTag = 'IRI_BH_NothingPersonal';
	WeaponDamageEffect.bIgnoreArmor = false;
	WeaponDamageEffect.bIgnoreBaseDamage = true;
	Template.AddTargetEffect(WeaponDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bShowActivation = true;

	SetFireAnim(Template, 'FF_NothingPersonal');
	//Template.AssociatedPlayTiming = SPT_AfterSequential;

	Template.BuildVisualizationFn = NothingPersonal_BuildVisualization;

	Template.PrerequisiteAbilities.AddItem('IRI_BH_ShadowTeleport');

	return Template;
}

static private function NothingPersonal_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local StateObjectReference MovingUnitRef;	
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateContext_Ability AbilityContext;
	local X2Action_PlaySoundAndFlyOver Flyover;
	local XComGameState_Unit UnitState;
	local XComGameStateVisualizationMgr VisMgr;
	local array<X2Action> LeafNodes;
	
	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	MovingUnitRef = AbilityContext.InputContext.SourceObject;

	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (UnitState.HasSoldierAbility('IRI_BH_FeelingLucky_Passive'))
	{
		Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
		Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString('IRI_BH_FeelingLucky_Flyover_Added'), '', eColor_Good);
	}

	TypicalAbility_BuildVisualization(VisualizeGameState);

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);
	Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,, Flyover, LeafNodes));
	Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString('NightDiveActionAvailable'), '', eColor_Good);
}

static private function EventListenerReturn NothingPersonalTriggerListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			NothingPersonalState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none) 
		return ELR_NoInterrupt;

	NothingPersonalState = XComGameState_Ability(CallbackData);
	if (NothingPersonalState == none || AbilityContext.InputContext.MultiTargets.Length == 0 || AbilityContext.InputContext.MultiTargets[0].ObjectID == 0)
		return ELR_NoInterrupt;

	NothingPersonalState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.MultiTargets[0], false);
	
	return ELR_NoInterrupt;
}

static function X2AbilityTemplate IRI_BH_DoublePayload()
{
	local X2AbilityTemplate			Template;
	local X2Effect_GrantCharges		GrantCharges;
	local X2Effect_BaseDamageBonus	BaseDamageBonus;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_DoublePayload');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_DoublePayload";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	GrantCharges = new class'X2Effect_GrantCharges';
	GrantCharges.AbilityName = 'HomingMine';
	GrantCharges.NumCharges = `GetConfigInt('IRI_BH_DoublePayload_NumBonusCharges');
	Template.AddTargetEffect(GrantCharges);

	BaseDamageBonus = new class'X2Effect_BaseDamageBonus';
	BaseDamageBonus.AbilityName = 'HomingMineDetonation';
	BaseDamageBonus.DamageMod = `GetConfigFloat('IRI_BH_DoublePayload_BonusDamage');
	BaseDamageBonus.bOnlyPrimaryTarget = true;
	BaseDamageBonus.BuildPersistentEffect(1, true);
	BaseDamageBonus.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	BaseDamageBonus.EffectName = 'IRI_BH_DoublePayload_BonusDamageEffect';
	Template.AddTargetEffect(BaseDamageBonus);

	Template.PrerequisiteAbilities.AddItem('HomingMine');
	
	return Template;
}




static function X2AbilityTemplate IRI_BH_DramaticEntrance()
{
	local X2AbilityTemplate							Template;
	local X2Effect_BountyHunter_DramaticEntrance	DramaticEntrance;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_DramaticEntrance');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_DramaticEntrance";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	DramaticEntrance = new class'X2Effect_BountyHunter_DramaticEntrance';
	DramaticEntrance.BuildPersistentEffect(1, true);
	DramaticEntrance.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(DramaticEntrance);

	Template.PrerequisiteAbilities.AddItem('NOT_IRI_BH_DarkNight_Passive');
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_DarkNight_Passive()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('IRI_BH_DarkNight_Passive', "img:///IRIPerkPackUI.UIPerk_DarkNight", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/);

	Template.PrerequisiteAbilities.AddItem('NOT_IRI_BH_DramaticEntrance');
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_ShadowTeleport()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCooldown							Cooldown;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2Effect_AdditionalAbilityDamagePreview	DamagePreview;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ShadowTeleport');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ShadowTeleport";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	
	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = `GetConfigInt('IRI_BH_ShadowTeleport_Cooldown');
	Cooldown.AditionalAbilityCooldowns.Add(1);
	Cooldown.AditionalAbilityCooldowns[0].AbilityName = 'IRI_BH_Nightfall';
	Cooldown.AditionalAbilityCooldowns[0].NumTurns = Cooldown.iNumTurns;
	Template.AbilityCooldown = Cooldown;

	AddCharges(Template, `GetConfigInt('IRI_BH_ShadowTeleport_Charges'));
	
	// Effects
	AddNightfallShooterEffects(Template);

	DamagePreview = new class'X2Effect_AdditionalAbilityDamagePreview';
	DamagePreview.AbilityName = 'IRI_BH_NothingPersonal';
	DamagePreview.bMatchSourceWeapon = true;
	Template.AddTargetEffect(DamagePreview);
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.TargetingMethod = class'X2TargetingMethod_BountyHunter_ShadowTeleport';	
	//X2AbilityTarget_MovingMelee(Template.AbilityTargetStyle).MovementRangeAdjustment = -99; // Only works towards reduction, apparently.

	Template.Hostility = eHostility_Neutral;
	//Template.bLimitTargetIcons = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.bUsesFiringCamera = true;
	Template.CinescriptCameraType = "Gremlin_Hack_Soldier";
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = ShadowTeleport_BuildGameState;
	Template.BuildVisualizationFn = ShadowTeleport_BuildVisualization;
	Template.ModifyNewContextFn = ShadowTeleport_ModifyActivatedAbilityContext;
	Template.BuildInterruptGameStateFn = none;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.PostActivationEvents.AddItem('IRI_BH_ShadowTeleport');

	return Template;
}

static private function XComGameState ShadowTeleport_BuildGameState(XComGameStateContext Context)
{
	local XComWorldData						WorldData;
	local XComGameState						NewGameState;
	local XComGameState_Unit				MovingUnitState;
	local XComGameStateContext_Ability		AbilityContext;
	local TTile								UnitTile;
	local TTile								PrevUnitTile;
	local Vector							TilePos;
	local Vector							PrevTilePos;
	local Vector							TilePosDiff;

	NewGameState = TypicalAbility_BuildGameState(Context);	

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	MovingUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	WorldData = `XWORLD;
	TilePos = AbilityContext.InputContext.TargetLocations[0];
	UnitTile = WorldData.GetTileCoordinatesFromPosition(TilePos);

	//Set the unit's new location
	PrevUnitTile = MovingUnitState.TileLocation;
	MovingUnitState.SetVisibilityLocation(UnitTile);

	if (UnitTile != PrevUnitTile)
	{
		TilePos = WorldData.GetPositionFromTileCoordinates( UnitTile );
		PrevTilePos = WorldData.GetPositionFromTileCoordinates( PrevUnitTile );
		TilePosDiff = TilePos - PrevTilePos;
		TilePosDiff.Z = 0;

		MovingUnitState.MoveOrientation = Rotator( TilePosDiff );
	}
	
	`XEVENTMGR.TriggerEvent( 'ObjectMoved', MovingUnitState, MovingUnitState, NewGameState );
	`XEVENTMGR.TriggerEvent( 'UnitMoveFinished', MovingUnitState, MovingUnitState, NewGameState );

	// Action point cost has consumed all AP at this point, so grant an extra AP.
	MovingUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);

	return NewGameState;	
}

static simulated function ShadowTeleport_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability AbilityContext;
	
	// Move the primary target ID from primary to multi target.
	// We don't want it as primary target, cuz then projectiles will fly to it, and soldier will aim at it.
	// We still need to store it somewhere, so then later we can retrieve target's location for the visulization for the point in time
	// where we do want to aim at the enemy.
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
	local X2Action_PlaySoundAndFlyOver Flyover;
	local X2Action_BountyHunter_ShadowTeleport GrappleAction;
	local X2Action_BountyHunter_ShadowTeleport_ExitCover ExitCoverAction;
	local X2Action_RevealArea RevealAreaAction;
	local X2Action_UpdateFOW FOWUpdateAction;
	local X2Action_MoveTurn MoveTurn;
	local X2Action_CameraFrameAbility CameraFrame;
	local XComGameState_Unit UnitState;
	local XComGameStateVisualizationMgr VisMgr;
	local array<X2Action> LeafNodes;
	
	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	MovingUnitRef = AbilityContext.InputContext.SourceObject;
	
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(MovingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(MovingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(MovingUnitRef.ObjectID);

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'RunAndGun', eColor_Good);

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	RevealAreaAction.TargetLocation = AbilityContext.InputContext.TargetLocations[0];
	RevealAreaAction.AssociatedObjectID = MovingUnitRef.ObjectID;
	RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 4;
	RevealAreaAction.bDestroyViewer = false;

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	FOWUpdateAction.BeginUpdate = true;

	CameraFrame = X2Action_CameraFrameAbility(class'X2Action_CameraFrameAbility'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	CameraFrame.AbilitiesToFrame.AddItem(AbilityContext);
	CameraFrame.CameraTag = 'AbilityFraming';

	MoveTurn = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	MoveTurn.m_vFacePoint = AbilityContext.InputContext.TargetLocations[0];

	ExitCoverAction = X2Action_BountyHunter_ShadowTeleport_ExitCover(class'X2Action_BountyHunter_ShadowTeleport_ExitCover'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, MoveTurn));
	ExitCoverAction.bUsePreviousGameState = true;

	GrappleAction = X2Action_BountyHunter_ShadowTeleport(class'X2Action_BountyHunter_ShadowTeleport'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ExitCoverAction));
	GrappleAction.DesiredLocation = AbilityContext.InputContext.TargetLocations[0];
	GrappleAction.SetFireParameters(true);

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

	// Don't show these flyovers if Nothing Personal is present and we have enough ammo for it.
	if (UnitState.HasSoldierAbility('IRI_BH_NothingPersonal') && (GetSecondaryWeaponAmmo(UnitState, VisualizeGameState) > 0 || UnitState.HasSoldierAbility('IRI_BH_FeelingLucky_Passive')))
		return;

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);
	if (UnitState.HasSoldierAbility('IRI_BH_FeelingLucky_Passive'))
	{
		Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, LeafNodes));
		Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString('IRI_BH_FeelingLucky_Flyover_Added'), '', eColor_Good);
	}

	Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,, Flyover, LeafNodes));
	Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString('NightDiveActionAvailable'), '', eColor_Good);
}

static private function int GetSecondaryWeaponAmmo(const XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	local XComGameState_Item ItemState;

	if (UnitState != none)
	{
		ItemState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState);
		if (ItemState != none)
		{
			return ItemState.Ammo;
		}
	}

	return 0;
}

// This ability is a bit complicated. Desired function:
// You Suppress the target and force it to move, immediately triggering an attack against it.
// The suppression effect should remain on target, allowing further reaction attacks until the target dies, 
// moves out of LoS, or shooter runs out of ammo.
// 
// Here's how this is achieved:
// IRI_BH_Terminate applies the initial suppression effect and forces the target to run. 
// It also applies a unit value which will be used later to make sure that later we retrigger suppression only against this particular target.
// This suppression effect registers for ability activation event, and triggers the IRI_BH_Terminate_Attack,
// which records the Event Chain Start History Index as a unit value on the target and removes the suppression effect from the target.
// If the target is not moving, we resuppress it right away by triggering the IRI_BH_Terminate_Resuppress in that same listener.
// If the target is moving, then we don't do anything.
// The IRI_BH_Terminate_Resuppress has its own event listener trigger, but it will activate only against a unit that activates an ability
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

static function X2AbilityTemplate IRI_BH_Terminate()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Effect_BountyHunter_RoutingVolley	SuppressionEffect;
	local X2Effect_AutoRunBehaviorTree		RunTree;
	local X2Effect_GrantActionPoints		GrantActionPoints;
	local X2Effect_SetUnitValue				UnitValueEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Terminate');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Terminate";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

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

	AddCharges(Template, `GetConfigInt('IRI_BH_Terminate_Charges'));

	// Effects
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = 'IRI_BH_Terminate_UnitValue_SuppressTarget';
	UnitValueEffect.NewValueToSet = 1.0f;
	UnitValueEffect.CleanupType = eCleanup_BeginTurn;
	Template.AddTargetEffect(UnitValueEffect);

	Template.bIsASuppressionEffect = true;
	SuppressionEffect = new class'X2Effect_BountyHunter_RoutingVolley';
	SuppressionEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	SuppressionEffect.bRemoveWhenTargetDies = true;
	SuppressionEffect.bRemoveWhenSourceDamaged = true;
	//SuppressionEffect.bBringRemoveVisualizationForward = true;
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionTargetEffectDesc, Template.IconImage,,,Template.AbilitySourceName);
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
	Template.AdditionalAbilities.AddItem('IRI_BH_Terminate_Attack');
	Template.AdditionalAbilities.AddItem('IRI_BH_Terminate_Resuppress');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_Terminate_Attack()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_Ammo					AmmoCost;
	local X2Effect_RemoveEffects_MatchSource	RemoveSuppression;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_Terminate_Attack', true, false, false);
	SetHidden(Template);

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Terminate";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

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

	// Placebo, actual firing animation is set by Template Master in BountyHunter\XComTemplateEditor.ini
	SetFireAnim(Template, 'FF_FireSuppress');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_Terminate_Resuppress()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_BountyHunter_RoutingVolley	SuppressionEffect;
	local X2AbilityTrigger_EventListener		Trigger;
	local X2AbilityCost_Ammo					AmmoCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Terminate_Resuppress');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Terminate";
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
	Trigger.ListenerData.EventFn = TerminateTriggerListener_Resuppress;
	Template.AbilityTriggers.AddItem(Trigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Costs
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
	SuppressionEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, class'X2Ability_GrenadierAbilitySet'.default.SuppressionTargetEffectDesc, Template.IconImage,,,Template.AbilitySourceName);
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

static private function EventListenerReturn TerminateTriggerListener_Resuppress(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
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
	if (!TargetUnit.GetUnitValue('IRI_BH_Terminate_UnitValue_SuppressTarget', UV))
		return ELR_NoInterrupt;

	`AMLOG("Attempting trigger resuppress by ability:" @ AbilityContext.InputContext.AbilityTemplateName);

	History = `XCOMHISTORY;
	TargetUnit.GetUnitValue('IRI_BH_Terminate_UnitValue', UV);
	if (UV.fValue != History.GetEventChainStartIndex())
	{
		`AMLOG("Terminate has not yet responded to this event chain start, exiting.");
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



static function X2AbilityTemplate IRI_BH_BigGameHunter()
{
	local X2AbilityTemplate						Template;
	local X2Effect_BountyHunter_CustomZeroIn	BonusEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BigGameHunter');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BigGameHunter";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	BonusEffect = new class'X2Effect_BountyHunter_CustomZeroIn';
	BonusEffect.BuildPersistentEffect(1, true, false, false);
	BonusEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(BonusEffect);

	return Template;
}

static function X2AbilityTemplate IRI_BH_Nightmare()
{
	local X2AbilityTemplate			Template;
	local X2Effect_ToHitModifier	Effect;
	local X2Condition_Visibility	VisCondition;

	// Same as original, but require no cover.

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Nightmare');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Nightmare";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_ToHitModifier';
	Effect.EffectName = 'IRI_BH_Nightmare';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,,Template.AbilitySourceName);
	Effect.AddEffectHitModifier(eHit_Success, `GetConfigInt('IRI_BH_Nightmare_AimBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, false /*NonFlanked*/);
	Effect.AddEffectHitModifier(eHit_Crit, `GetConfigInt('IRI_BH_Nightmare_CritBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, false /*NonFlanked*/);
	
	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bExcludeGameplayVisible = true;
	Effect.ToHitConditions.AddItem(VisCondition);

	Template.AddTargetEffect(Effect);

	return Template;
}

static function X2AbilityTemplate IRI_BH_BigGameHunter_Alt()
{
	local X2AbilityTemplate		Template;	
	local X2AbilityCost_Ammo	AmmoCost;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_BigGameHunter_Alt', true, false, false);
	SetHidden(Template);
	Template.AbilitySourceName = 'eAbilitySource_Perk';
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

static function X2AbilityTemplate IRI_BH_BigGameHunter_Alt_Passive()
{
	local X2AbilityTemplate Template;	
	local X2Effect_BountyHunter_BigGameHunter Effect;
	local X2Effect_Persistent PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BigGameHunter_Alt_Passive');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstrike";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_BountyHunter_BigGameHunter';
	Effect.BuildPersistentEffect(1, true);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, true);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(PersistentEffect);

	Template.AdditionalAbilities.AddItem('IRI_BH_BigGameHunter_Alt');

	return Template;	
}


static function X2AbilityTemplate IRI_BH_FirePistol()
{
	local X2AbilityTemplate Template;	

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_FirePistol');

	Template.bUseAmmoAsChargesForHUD = true;

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_HandCannon";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;
	
	//Template.AdditionalAbilities.AddItem('PistolOverwatchShot');
	//Template.AdditionalAbilities.AddItem('PistolReturnFire');
	Template.AdditionalAbilities.AddItem('HotLoadAmmo');

	return Template;	
}

static function X2AbilityTemplate IRI_BH_NamedBullet()
{
	local X2AbilityTemplate					Template;	
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityMultiTarget_BurstFire	BurstFireMultiTarget;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_NamedBullet');

	// Icon
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_NamedBullet";
	Template.AbilitySourceName = 'eAbilitySource_Perk';   
	
	BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire';
	BurstFireMultiTarget.NumExtraShots = 2;
	Template.AbilityMultiTargetStyle = BurstFireMultiTarget;
	
	// Needs to be specifically the same effect to visualize damage markers properly. Chalk up another rake stepped on.
	//Template.AddMultiTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	Template.AddMultiTargetEffect(Template.AbilityTargetEffects[0]);

	// Allow targeting only visible units.
	Template.AbilityTargetConditions.Length = 0;
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	// Reset costs, keep only AP cost.
	Template.AbilityCosts.Length = 0;   

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);	

	AddCharges(Template, `GetConfigInt('IRI_BH_NamedBullet_Charges'));

	// State and Viz
	Template.ActivationSpeech = 'FanFire';

	Template.AdditionalAbilities.AddItem('IRI_BH_NamedBullet_AnimPassive');
	Template.BuildVisualizationFn = NamedBullet_BuildVisualization;
	Template.ModifyNewContextFn = NamedBullet_ModifyContext;

	return Template;	
}

static simulated function NamedBullet_ModifyContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability	AbilityContext;
	//local EffectResults				DamageEffectHitResult;
	//local int j;
	local int i;
	
	// For this ability, we want all three instances of damage to hit or miss together,
	// so we assign ability's target effect/hit results to multi targets.

	AbilityContext = XComGameStateContext_Ability(Context);

	for (i = 0; i < AbilityContext.ResultContext.MultiTargetHitResults.Length; i++)
	{
		//`AMLOG(i @ "Patched multi target hit result to:" @ AbilityContext.ResultContext.HitResult);

		AbilityContext.ResultContext.MultiTargetHitResults[i] = AbilityContext.ResultContext.HitResult;
	}

	// Doesn't seem to be necessary.
	//DamageEffectHitResult = AbilityContext.ResultContext.TargetEffectResults;
	//
	//for (i = 0; i < DamageEffectHitResult.Effects.Length; i++)
	//{
	//	for (i = 0; j < AbilityContext.ResultContext.MultiTargetEffectResults.Length; j++)
	//	{
	//		if (AbilityContext.ResultContext.MultiTargetEffectResults[j].Effects[0] == DamageEffectHitResult.Effects[i])
	//		{
	//			`AMLOG(i @ j @ "Patched multi target effect result.");
	//
	//			AbilityContext.ResultContext.MultiTargetEffectResults[j].ApplyResults[0] = DamageEffectHitResult.ApplyResults[i];
	//		}
	//	}
	//}
}

static private function NamedBullet_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action							FireAction;
	local XComGameStateContext_Ability		AbilityContext;
	local VisualizationActionMetadata		ActionMetadata;
	local VisualizationActionMetadata		TargetMetadata;
	local X2Action_TimedWait				TimedWaitOne;
	local X2Action_TimedWait				TimedWaitTwo;
	local array<X2Action>					ParentActions;
	local X2Action_SetGlobalTimeDilation	TimeDilation;
	local array<X2Action>					UnitTakeDamageActions;
	local X2Action_PlayEffect				PlayEffect;
	local X2Action_WaitForAbilityEffect		WaitAction;
	local X2Action_PlaySoundAndFlyOver		PlaySound;
	local XComGameState_Unit				TargetUnit;
	local SoundCue							ImpactSoundCue;

	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

	VisMgr = `XCOMVISUALIZATIONMGR;

	FireAction = VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_Fire');
	if (FireAction == none)
		return;

	AbilityContext = XComGameStateContext_Ability(FireAction.StateChangeContext);
	if (AbilityContext == none || !AbilityContext.IsResultContextHit())
		return;

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', UnitTakeDamageActions,, AbilityContext.InputContext.PrimaryTarget.ObjectID);
	if (UnitTakeDamageActions.Length == 0)
		return;

	ActionMetaData = FireAction.Metadata;
	TargetMetadata = UnitTakeDamageActions[0].Metadata;
	TargetUnit = XComGameState_Unit(TargetMetadata.StateObject_NewState);

	// This action will run when the projectile connects with the target.
	WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, FireAction));

	// (Also play a particle effect on the target when projectile connects)
	PlayEffect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(TargetMetadata, AbilityContext, false, WaitAction));
	PlayEffect.EffectName = "IRIBountyHunter.PS_NamedShot_Impact";
	PlayEffect.AttachToUnit = true;
	PlayEffect.AttachToSocketName = 'FX_Chest';
	PlayEffect.AttachToSocketsArrayName	 = 'BoneSocketActor';

	// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// Also play different impact sounds depending on target type.
	if (TargetUnit.GetMyTemplateGroupName() == 'Cyberus')
	{
		ImpactSoundCue = SoundCue(`CONTENT.RequestGameArchetype("IRIBountyHunter.NamedShot_Impact_Cue"));
	}
	else if (TargetUnit.IsRobotic())
	{
		ImpactSoundCue = SoundCue(`CONTENT.RequestGameArchetype("SoundAmbience.BulletImpactsMetalCue"));
	}
	else
	{
		ImpactSoundCue = SoundCue(`CONTENT.RequestGameArchetype("SoundAmbience.BulletImpactsFleshCue"));
	}

	PlaySound = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(TargetMetadata, AbilityContext, false, WaitAction));
	PlaySound.SetSoundAndFlyOverParameters(ImpactSoundCue, "", '', eColor_Xcom);
	PlaySound.BlockUntilFinished = true;
	PlaySound.DelayDuration = 0.15f;

	PlaySound = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(TargetMetadata, AbilityContext, false, PlaySound));
	PlaySound.SetSoundAndFlyOverParameters(ImpactSoundCue, "", '', eColor_Xcom);
	PlaySound.BlockUntilFinished = true;
	PlaySound.DelayDuration = 0.15f;

	PlaySound = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(TargetMetadata, AbilityContext, false, PlaySound));
	PlaySound.SetSoundAndFlyOverParameters(ImpactSoundCue, "", '', eColor_Xcom);
	// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	// Wait for a second there. This will be our first parallel branch.
	TimedWaitOne = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, WaitAction));
	TimedWaitOne.DelayTimeSec = 1.0f;

	// Begin second parallel branch. Gradually slow down the time.

	PlaySound = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, FireAction.ParentActions));
	PlaySound.SetSoundAndFlyOverParameters(SoundCue(`CONTENT.RequestGameArchetype("IRIBountyHunter.NamedShotClicks_Cue")), "", '', eColor_Xcom);

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, FireAction.ParentActions));
	TimeDilation.TimeDilation = 0.9f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.1f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.8f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.1f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.7f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.1f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.6f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.1f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.5f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.1f;

	//	Then restore normal speed.
	ParentActions.AddItem(TimedWaitOne);
	ParentActions.AddItem(TimedWaitTwo);
	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, ParentActions));
	TimeDilation.TimeDilation = 1.0f;

	// Do it again at the very end of the tree as a failsafe.
	ParentActions.Length = 0;
	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, ParentActions);
	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, ParentActions));
	TimeDilation.TimeDilation = 1.0f;
}

static function X2AbilityTemplate IRI_BH_Untraceable()
{
	local X2AbilityTemplate				Template;
	local X2Effect_ReduceCooldowns		ReduceCooldown;
	local X2Condition_UnitValue			UnitValueCondition;
	local X2Condition_AbilityCooldown	AbilityCooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Untraceable');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Untraceable";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	// Targeting and Triggering
	SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnEnded', ELD_OnStateSubmitted, eFilter_Player, 50);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	UnitValueCondition = new class'X2Condition_UnitValue';
	UnitValueCondition.AddCheckValue('AttacksThisTurn', 0, eCheck_Exact);
	Template.AbilityShooterConditions.AddItem(UnitValueCondition);

	// Trigger this ability only if one of these abilities has cooldown above 1. 
	// Ability triggers at the end of turn, so no need to trigger it if cooldown is 1, it will expire naturally.
	AbilityCooldown = new class'X2Condition_AbilityCooldown';
	AbilityCooldown.AddCheckValue('IRI_BH_Nightfall', 1, eCheck_GreaterThan, 1);
	AbilityCooldown.AddCheckValue('IRI_BH_ShadowTeleport', 1, eCheck_GreaterThan, 1);
	Template.AbilityShooterConditions.AddItem(AbilityCooldown);

	ReduceCooldown = new class'X2Effect_ReduceCooldowns';
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_Nightfall');
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_ShadowTeleport');
	ReduceCooldown.Amount = `GetConfigInt('IRI_BH_Untraceable_CooldownReduction');
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

static function X2AbilityTemplate IRI_BH_BlindingFire()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BlindingFire');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIperk_BlindingFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
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
	Template.AddTargetEffect(class'X2Effect_Blind'.static.CreateBlindEffect(`GetConfigInt('IRI_BH_BlindingFire_DurationTurns'), 0));

	// State and Vis
	Template.FrameAbilityCameraType = eCameraFraming_Never; 
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bUsesFiringCamera = false;
	Template.Hostility = eHostility_Neutral;

	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = class'Help'.static.FollowUpShot_BuildVisualization;
	Template.MergeVisualizationFn = class'Help'.static.FollowUpShot_MergeVisualization;
	Template.BuildInterruptGameStateFn = none;

	Template.AdditionalAbilities.AddItem('IRI_BH_BlindingFire_Passive');

	return Template;
}

static function X2AbilityTemplate IRI_BH_WitchHunt()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Condition_UnitProperty			UnitProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_WitchHunt');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_WitchHunt";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
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
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_HeadHunter";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	Headhunter = new class'X2Effect_BountyHunter_Headhunter';
	Headhunter.BuildPersistentEffect(1, true);
	Headhunter.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Headhunter);
	
	return Template;
}

static function X2AbilityTemplate IRI_BH_Nightfall()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCooldown						Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Nightfall');

	// Icon Setup
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Nightfall";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

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

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = `GetConfigInt('IRI_BH_Nightfall_Cooldown');
	Cooldown.AditionalAbilityCooldowns.Add(1);
	Cooldown.AditionalAbilityCooldowns[0].AbilityName = 'IRI_BH_ShadowTeleport';
	Cooldown.AditionalAbilityCooldowns[0].NumTurns = Cooldown.iNumTurns;
	Template.AbilityCooldown = Cooldown;
	
	// Effects
	AddNightfallShooterEffects(Template);

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

	//Template.AdditionalAbilities.AddItem('IRI_BH_Nightfall_Passive');
	
	return Template;
}

static private function AddNightfallShooterEffects(out X2AbilityTemplate Template)
{
	local X2Effect_BountyHunter_DeadlyShadow	StealthEffect;
	local X2Effect_AdditionalAnimSets			AnimEffect;
	local X2Effect_BountyHunter_GrantAmmo		GrantAmmo;
	local X2Condition_AbilityProperty			AbilityCondition;
		
	StealthEffect = new class'X2Effect_BountyHunter_DeadlyShadow';
	StealthEffect.BuildPersistentEffect(`GetConfigInt('IRI_BH_Nightfall_Duration'), false, true, false, eGameRule_PlayerTurnEnd);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, `GetLocalizedString("IRI_BH_Nightfall_EffectName"), `GetLocalizedString("IRI_BH_Nightfall_EffectDesc"), "img:///IRIPerkPackUI.UIPerk_Nightfall", true,,Template.AbilitySourceName);
	Template.AddShooterEffect(StealthEffect);

	Template.AddShooterEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	AnimEffect = new class'X2Effect_AdditionalAnimSets';
	AnimEffect.DuplicateResponse = eDupe_Ignore;
	AnimEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	AnimEffect.bRemoveWhenTargetConcealmentBroken = true;
	AnimEffect.AddAnimSetWithPath("IRIBountyHunter.Anims.AS_ReaperShadow");
	AnimEffect.EffectName = 'IRI_BH_Nightfall_Anim_Effect';
	Template.AddShooterEffect(AnimEffect);
	
	GrantAmmo = new class'X2Effect_BountyHunter_GrantAmmo';
	GrantAmmo.BuildPersistentEffect(1, true);
	GrantAmmo.bRemoveWhenTargetConcealmentBroken = true;
	GrantAmmo.SetDisplayInfo(ePerkBuff_Bonus, `GetLocalizedString("IRI_BH_Nightfall_EffectName"), `GetLocalizedString("IRI_BH_Nightfall_EffectDesc"), "img:///IRIPerkPackUI.UIPerk_FeelingLucky", true,,Template.AbilitySourceName);

	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('IRI_BH_FeelingLucky_Passive');
	GrantAmmo.TargetConditions.AddItem(AbilityCondition);

	Template.AddShooterEffect(GrantAmmo);
}



static function X2AbilityTemplate IRI_BH_Nightfall_Passive()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_CritMagic	CritMagic;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Nightfall_Passive');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_DeadOfNight";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	CritMagic = new class'X2Effect_BountyHunter_CritMagic';
	CritMagic.BuildPersistentEffect(1, true);
	CritMagic.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
	CritMagic.BonusCritChance = `GetConfigInt('IRI_BH_Nightfall_CritChanceBonusWhenUnseen');
	CritMagic.GrantCritDamageForCritChanceOverflow = `GetConfigInt('IRI_BH_Nightfall_CritDamageBonusPerCritChanceOverflow');
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
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

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

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.bFreeCost = true; // Require ammo only for activation
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bUseAmmoAsChargesForHUD = true;

	AddCooldown(Template, `GetConfigInt('IRI_BH_ChasingShot_Cooldown'));

	// Effects
	ChasingShotEffect = new class'X2Effect_Persistent';
	ChasingShotEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	ChasingShotEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName); // TODO: Status icon here
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
	local X2AbilityCost_Ammo						AmmoCost;

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
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

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
				// EDIT: Followthrough has been cut, but I kept this logic here cuz one way or another the effect needs to be removed
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
	local X2AbilityCost_Ammo				AmmoCost;

	// Macro to do localisation and stuffs
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Blindside');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_standardpistol";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

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
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);
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
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

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
	Folowthrough.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true,,Template.AbilitySourceName);
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

	SetHidden(Template);
	SetPassive(Template);
	
	AnimSetEffect = new class'X2Effect_AdditionalAnimSets';
	AnimSetEffect.AddAnimSetWithPath(AnimSetPath);
	AnimSetEffect.BuildPersistentEffect(1, true, false, false);
	Template.AddTargetEffect(AnimSetEffect);

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