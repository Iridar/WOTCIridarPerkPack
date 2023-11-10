class X2Ability_Templar extends X2Ability;

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

	Templates.AddItem(IRI_TM_AstralGrasp());
	Templates.AddItem(IRI_TM_AstralGrasp_Spirit());
	Templates.AddItem(IRI_TM_AstralGrasp_SpiritStun());
	Templates.AddItem(IRI_TM_AstralGrasp_SpiritDeath());

	return Templates;
}



static private function X2AbilityTemplate IRI_TM_SpectralStride()
{
	local X2AbilityTemplate				Template;
	local X2Condition_UnitEffects		EffectsCondition;
	local X2Condition_UnitProperty		UnitPropertyCondition;
	local X2AbilityCost_ActionPoints	ActionCost;
	local X2Effect_PersistentTraversalChange SpectralStride;

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
	SpectralStride = new class'X2Effect_PersistentTraversalChange';
	SpectralStride.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnEnd);
	SpectralStride.AddTraversalChange( eTraversal_Phasing, true );
	SpectralStride.AddTraversalChange( eTraversal_JumpUp, true );
	SpectralStride.bRemoveWhenTargetDies = true;
	SpectralStride.EffectName = 'IRI_TM_SpectralStride_Effect';
	SpectralStride.DuplicateResponse = eDupe_Ignore;
	SpectralStride.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(SpectralStride);

	// State and Viz
	Template.bShowActivation = true;
	Template.CinescriptCameraType = "Templar_Ghost";
	Template.bFrameEvenWhenUnitIsHidden = true;
	SetFireAnim(Template, 'HL_SpectralStride');
	Template.ActivationSpeech = 'Amplify'; // TODO: Speech
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
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('IRI_TM_Aftershock');
	HitModEffect.TargetConditions.AddItem(default.LivingTargetOnlyProperty);
	HitModEffect.TargetConditions.AddItem(AbilityCondition);

	HitModEffect.EffectName = 'IRI_TM_Aftershock_Effect';
	HitModEffect.DuplicateResponse = eDupe_Ignore;

	HitModEffect.VFXTemplateName = "IRIVolt.PS_Aftershock";
	HitModEffect.VFXSocket = 'FX_Chest'; // FX_Head
	HitModEffect.VFXSocketsArrayName = 'BoneSocketActor';

	// Disspates Aftershock FX upon target death/duration
	HitModEffect.EffectRemovedVisualizationFn = AftershockEffectRemovedVisualization;

	// TODO: Dissipate the effect on target death // orbit -30%, pieces -30-50%

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

	Template.AddTargetEffect(CreateConcentrationEffect());
	
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