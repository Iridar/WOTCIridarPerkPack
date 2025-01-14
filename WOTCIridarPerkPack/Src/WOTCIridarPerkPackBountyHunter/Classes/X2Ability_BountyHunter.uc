class X2Ability_BountyHunter extends X2Ability;

var private X2Condition_Visibility UnitDoesNotSeeCondition;
var private X2Condition_Visibility GameplayVisibilityAllowSquadsight;

var config array<name> CrossClassAbilities;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Squaddie
	Templates.AddItem(IRI_BH_Headhunter());
	Templates.AddItem(IRI_BH_FirePistol());
	Templates.AddItem(SetTreePosition(IRI_BH_Nightfall(), 0));
	Templates.AddItem(IRI_BH_Nightfall_Passive());

	// Corporal
	Templates.AddItem(SetTreePosition(IRI_BH_ExplosiveAction(), 1));
	Templates.AddItem(IRI_BH_DarkNight_Passive());
	Templates.AddItem(IRI_BH_NightWatch());

	// Sergeant
	Templates.AddItem(SetTreePosition(IRI_BH_HomingMine(), 2)); // Sabotage Charge
	Templates.AddItem(IRI_BH_HomingMineDetonation());
	Templates.AddItem(SetTreePosition(IRI_BH_ShadowTeleport(), 2)); // Night Dive
	Templates.AddItem(IRI_BH_Nightmare());

	// Lieutenant
	Templates.AddItem(IRI_BH_DoublePayload());
	Templates.AddItem(IRI_BH_NothingPersonal());
	Templates.AddItem(IRI_BH_NothingPersonal_Passive());
	Templates.AddItem(SetTreePosition(IRI_BH_BurstFire(), 3));
	Templates.AddItem(IRI_BH_BurstFire_Passive());
	Templates.AddItem(IRI_BH_BurstFire_Anim_Passive());

	// Captain
	Templates.AddItem(IRI_BH_BombRaider());
	Templates.AddItem(IRI_BH_NightRounds());
	Templates.AddItem(IRI_BH_UnrelentingPressure());

	// Major
	Templates.AddItem(SetTreePosition(IRI_BH_RifleGrenade(), 5));
	Templates.AddItem(IRI_BH_RifleGrenade_Passive());
	Templates.AddItem(PurePassive('IRI_BH_FeelingLucky_Passive', "img:///IRIPerkPackUI.UIPerk_FeelingLucky", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(IRI_BH_BigGameHunter());

	// Colonel
	Templates.AddItem(IRI_BH_BlindingFire());
	Templates.AddItem(PurePassive('IRI_BH_BlindingFire_Passive', "img:///IRIPerkPackUI.UIperk_BlindingFire", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	Templates.AddItem(SetTreePosition(IRI_BH_NamedBullet(), 6));
	Templates.AddItem(SetTreePosition(IRI_BH_Terminate(), 6));
	Templates.AddItem(IRI_BH_Terminate_ExtraShot());
	Templates.AddItem(IRI_BH_Terminate_ExtraShot_SkipFireAction());

	// GTS
	Templates.AddItem(IRI_BH_Untraceable());
	Templates.AddItem(PurePassive('IRI_BH_Untraceable_Passive', "img:///IRIPerkPackUI.UIPerk_Untraceable", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	// Extra
	Templates.AddItem(IRI_BH_WitchHunt());
	Templates.AddItem(PurePassive('IRI_BH_WitchHunt_Passive', "img:///IRIPerkPackUI.UIPerk_WitchHunt", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));

	return Templates;
}

static private function X2AbilityTemplate SetTreePosition(X2AbilityTemplate Template, int iRank)
{
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY + 10 * iRank;

	return Template;
}

static private function SetCrossClass(out X2AbilityTemplate Template)
{
	if (default.CrossClassAbilities.Find(Template.DataName) != INDEX_NONE)
	{
		Template.bCrossClassEligible = true;
	}
}


/*
Based on Thunder Lance, but with significant changes.

So we're using a Perk Weapon - which is an invisible vektor rifle - as a grenade launcher.
The ability itself doesn't need to be attached to the vektor rifle,
existing game's logic automatically pulls relevant stats from grenades.

The custom targeting method has a custom grenade path which updates the end of the path
based on whether there's a unit on the targeted tile or not,
and also marks the target with a crosshair icon to denote a "direct hit", which deals more damage.

Custom Fire Action has a lot of logic to override the behavior of the launched projectiles.
It appears that when a grenade launching ability fires any volley in its animation,
in addition to the launcher's projectile, the game also launches the projectile of the grenade weapon,
and they fly in parallel.

I don't need that projectile to be visible, so it is hidden via override logic in the fire action. 
I still need the projectile to exist to produce the grenade explosion, so it is just hidden.

Rifle Grenade also has a passive with a custom X2Effect with a bunch of event listeners.

There is also a second "fire weapon volley" notify in the animation which produces a cosmetic shot from the vektor rifle
to add weapon's firing sound and muzzle flash to the rifle grenade launch.

That notify *also* spawns the grenade projectile, the second one now. This one is not needed at all,
so the event listener in the effect kills it before it can even spawn.

Another listener in the effect is responsible for updating positions of sockets that are used by the animation to attach the rifle grenade's model
as the soldier pulls it out and puts it on the rifle. Since different vektor rifles will have different barrel lengths,
and soldiers of different genders will have weapons of different scales, and there are mods that can rescale weapons,
the position of the sockets used in the animation must be dynamic, so the event listener updates their positions
based on the position of the weapon's gun_fire socket.

The ability also uses a custom X2UnifiedProjectile to override the grenade's trajectory so it doesn't bounce and rotates in flight the way I wanted.

The custom animation is also super complicated, where the actual vector rifle is juggled between soldier's right and left hands
as they put the grenade on the rifle's barrel, which is just a cosmetic spawned mesh that gets hidden at the moment of the shot.

The actual vektor rifle plays its fire weapon animation (which doesn't work) and a cosmetic fire weapon volley, 
but the real weapon used by the ability is the invisible perk weapon vektor rifle,
which is also used for the left hand IK purposes.
*/
static private function X2AbilityTemplate IRI_BH_RifleGrenade()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_Ammo                AmmoCost;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2AbilityTarget_Cursor			CursorTarget;
	local X2AbilityMultiTarget_Radius       RadiusMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_AbilitySourceWeapon   GrenadeCondition, ProximityMineCondition;
	local X2Effect_ProximityMine            ProximityMineEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_RifleGrenade');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_AmmoCost');
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_RifleGrenade";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;
	Template.bUseAmmoAsChargesForHUD = true;
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;

	// TODO: Fix left hand in the animation.
	// TODO: Check logs
	// TODO: Check all persisten effects for (1, true)

	// Targeting and Triggering
	Template.TargetingMethod = class'X2TargetingMethod_RifleGrenade';

	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	StandardAim.bIndirectFire = true;
	StandardAim.bGuaranteedHit = true;
	StandardAim.bAllowCrit = false;
	Template.AbilityToHitCalc = StandardAim;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
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

	// So it costs Vektor Rifle ammo too.
	AmmoCost = new class'X2AbilityCost_Ammo_WeaponSlot';	
	AmmoCost.iAmmo = 1;
	AmmoCost.UseLoadedAmmo = false;
	X2AbilityCost_Ammo_WeaponSlot(AmmoCost).InvSlot = eInvSlot_PrimaryWeapon;
	Template.AbilityCosts.AddItem(AmmoCost);
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('Salvo');
	//ActionPointCost.DoNotConsumeAllSoldierAbilities.AddItem('TotalCombat');
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
	Template.bHideAmmoWeaponDuringFire = true;

	ProximityMineEffect = new class'X2Effect_ProximityMine';
	ProximityMineEffect.BuildPersistentEffect(1, true, false, false);
	ProximityMineCondition = new class'X2Condition_AbilitySourceWeapon';
	ProximityMineCondition.MatchGrenadeType = 'ProximityMine';
	ProximityMineEffect.TargetConditions.AddItem(ProximityMineCondition);
	Template.AddShooterEffect(ProximityMineEffect);

	// Viz and State
	Template.ActionFireClass = class'X2Action_Fire_RifleGrenade';
	SetFireAnim(Template, 'FF_FireRifleGrenade');
	Template.ActivationSpeech = 'ThrowGrenade';

	Template.DamagePreviewFn = class'X2Ability_Grenades'.static.GrenadeDamagePreview;
	Template.CinescriptCameraType = "Grenadier_GrenadeLauncher";

	Template.bOverrideAim = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.ModifyNewContextFn = RifleGrenade_ModifyActivatedAbilityContext;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;
	Template.bFrameEvenWhenUnitIsHidden = true;

	Template.AdditionalAbilities.AddItem('IRI_BH_RifleGrenade_Passive');

	return Template;
}

// If targeted tile has any units, smuggle the first one as the primary target of the ability
// so that the TriggerHitReact notify in the firing animation has a target to work with
static private function RifleGrenade_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComWorldData					World;
	local TTile							TileLocation;
	local vector						TargetLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local array<Actor>					ActorsOnTile;
	local array<TilePosPair>			TilePairs;
	local TilePosPair					TilePair;
	local array<XComDestructibleActor>	Destructibles;

	AbilityContext = XComGameStateContext_Ability(Context);
	if (AbilityContext == none)
		return;

	TargetLocation = AbilityContext.InputContext.TargetLocations[0];

	World = `XWORLD;
	World.GetFloorTileForPosition(TargetLocation, TileLocation);

	TargetsOnTile = World.GetUnitsOnTile(TileLocation);
	if (TargetsOnTile.Length > 0)
	{
		AbilityContext.InputContext.PrimaryTarget = TargetsOnTile[0];
	}
	else
	{
		TilePair.Tile = TileLocation;
		TilePair.WorldPos = TargetLocation;
		TilePairs.AddItem(TilePair);

		World.CollectDestructiblesInTiles(TilePairs, Destructibles);
		if (Destructibles.Length > 0)
		{
			AbilityContext.InputContext.PrimaryTarget.ObjectID = Destructibles[0].ObjectID;
		}
	}
}
static private function X2AbilityTemplate IRI_BH_RifleGrenade_Passive()
{
	local X2AbilityTemplate Template;
	local X2Effect_RifleGrenade	Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_RifleGrenade_Passive');

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_RifleGrenade";

	SetPassive(Template);
	SetHidden(Template);
	Template.bUniqueSource = true;

	Effect = new class'X2Effect_RifleGrenade';
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,, Template.AbilitySourceName);
	Template.AddTargetEffect(Effect);

	return Template;
}



static private function X2AbilityTemplate IRI_BH_Terminate()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_Terminate	TargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Terminate');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Terminate";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	AddCharges(Template, `GetConfigInt('IRI_BH_Terminate_Charges'));

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityAllowSquadsight);

	TargetEffect = new class'X2Effect_BountyHunter_Terminate';
	TargetEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnEnd);
	TargetEffect.bRemoveWhenTargetDies = true;
	TargetEffect.SetDisplayInfo(ePerkBuff_Penalty, `GetLocalizedString("IRI_BH_Terminate_EffectTitle"), `GetLocalizedString("IRI_BH_Terminate_EffectText"), Template.IconImage, true, "img:///IRIPerkPackUI.status_Terminate", Template.AbilitySourceName);
	Template.AddTargetEffect(TargetEffect);
	
	// State and Viz
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;
	Template.bShowActivation = false;
	Template.bSkipFireAction = false;
	SetFireAnim(Template, 'FF_IRI_BH_Terminate');

	// This one is triggered as a followup to abilities that don't come from the vektor,
	// or unsupported abilities. It visualizes as a bog standard primary weapon attack, like RapidFire2.
	Template.AdditionalAbilities.AddItem('IRI_BH_Terminate_ExtraShot');

	// This one is triggered when we want the triggering ability to visualize as burst fire, which is done in
	// X2Effect_Terminate PostBuildVis. 
	// This attack doesn't have its own visualization, and is simply inserted after the triggering ability's fire action.

	// Having two separate abilities for this is technically bad for performance,
	// but it's so, sooooo much easier to set up in terms of visualization. Don't you people have powerful CPUs?
	Template.AdditionalAbilities.AddItem('IRI_BH_Terminate_ExtraShot_SkipFireAction');
	Template.AdditionalAbilities.AddItem('IRI_BH_BurstFire_Anim_Passive');

	return Template;
}

static private function X2AbilityTemplate IRI_BH_Terminate_ExtraShot()
{
	local X2AbilityTemplate		Template;
	local X2AbilityCost_Ammo	AmmoCost;
	local X2Condition_UnitEffectsWithAbilitySource	TargetEffectCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_Terminate_ExtraShot', false, true, true);

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BurstFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetHidden(Template);

	// Targeting and Triggering
	// Triggered from X2Effect_BountyHunter_Terminate
	Template.AbilityTriggers.Length = 0;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(class'X2Effect_BountyHunter_Terminate'.default.EffectName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);

	// Costs
	Template.AbilityCosts.Length = 0;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	// State and Viz
	Template.bShowActivation = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildInterruptGameStateFn = none;

	return Template;
}

static private function X2AbilityTemplate IRI_BH_Terminate_ExtraShot_SkipFireAction()
{
	local X2AbilityTemplate		Template;
	local X2AbilityCost_Ammo	AmmoCost;
	local X2Condition_UnitEffectsWithAbilitySource	TargetEffectCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_Terminate_ExtraShot_SkipFireAction', false, true, true);

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BurstFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetHidden(Template);

	// Targeting and Triggering
	// Triggered from X2Effect_BountyHunter_Terminate
	Template.AbilityTriggers.Length = 0;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(class'X2Effect_BountyHunter_Terminate'.default.EffectName, 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);

	// Costs
	Template.AbilityCosts.Length = 0;
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	// State and Viz
	Template.FrameAbilityCameraType = eCameraFraming_Never; 
	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.bSkipExitCoverWhenFiring = true;
	Template.bUsesFiringCamera = false;
	Template.Hostility = eHostility_Neutral;
	Template.BuildVisualizationFn = class'Help'.static.FollowUpShot_BuildVisualization;
	Template.MergeVisualizationFn = class'Help'.static.FollowUpShot_MergeVisualization;
	Template.BuildInterruptGameStateFn = none;

	return Template;
}

static private function X2AbilityTemplate IRI_BH_BurstFire_Anim_Passive()
{
	local X2AbilityTemplate Template;

	Template = Create_AnimSet_Passive('IRI_BH_BurstFire_Anim_Passive', "IRIBountyHunter.Anims.AS_RoutingVolley");
	Template.bUniqueSource = true;

	return Template;
}

static private function X2AbilityTemplate IRI_BH_NightWatch()
{
	local X2AbilityTemplate					Template;
	local X2Effect_ModifySquadsightPenalty	NightWatch;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_NightWatch');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_NightWatch";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	NightWatch = new class'X2Effect_ModifySquadsightPenalty';
	NightWatch.iCritFlatModifier = -class'X2AbilityToHitCalc_StandardAim'.default.SQUADSIGHT_CRIT_MOD;
	NightWatch.BuildPersistentEffect(1, true);
	NightWatch.EffectName = 'IRI_BH_NightWatch_Effect';
	NightWatch.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, false,,Template.AbilitySourceName);
	Template.AddTargetEffect(NightWatch);

	Template.AdditionalAbilities.AddItem('Squadsight');

	return Template;
}

static private function X2AbilityTemplate IRI_BH_NightRounds()
{
	local X2AbilityTemplate			Template;
	local X2Effect_ToHitModifier	Effect;
	local X2Condition_Visibility	VisCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_NightRounds');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_ToolsOfTheTrade";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	Effect = new class'X2Effect_ToHitModifier';
	Effect.EffectName = 'IRI_BH_Nightmare';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Effect.AddEffectHitModifier(eHit_Crit, `GetConfigInt('IRI_BH_NightRounds_CritBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, false /*Flanked*/, true /*NonFlanked*/);

	// Require that target does not see us and has no cover, but we're not flanking. 
	// This should make sure the bonus is ever applied only against enemies that don't take cover.
	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bExcludeGameplayVisible = true;
	VisCondition.bRequireMatchCoverType = true;
	VisCondition.TargetCover = CT_None;
	Effect.ToHitConditions.AddItem(VisCondition);

	Template.AddTargetEffect(Effect);

	return Template;
}

static private function X2AbilityTemplate IRI_BH_UnrelentingPressure()
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
	ReduceCooldown.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(ReduceCooldown);
	
	Template.PrerequisiteAbilities.AddItem('IRI_BH_BurstFire');

	return Template;
}

static private function X2AbilityTemplate IRI_BH_BombRaider()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_BombRaider	BiggestBoomsEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BombRaider');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BombRaider";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	BiggestBoomsEffect = new class'X2Effect_BountyHunter_BombRaider';
	BiggestBoomsEffect.BuildPersistentEffect(1, true, true, true);
	BiggestBoomsEffect.BonusCritChanceWhenUnseen = `GetConfigInt('IRI_BH_Nightfall_CritChanceBonusWhenUnseen');
	BiggestBoomsEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(BiggestBoomsEffect);

	return Template;
}

static private function X2AbilityTemplate IRI_BH_BurstFire()
{
	local X2AbilityTemplate						Template;	
	local X2AbilityCost_Ammo					AmmoCost;
	local X2AbilityMultiTarget_BurstFire		BurstFireMultiTarget;
	local int									NumExtraShots;
	local int									iCooldown;
	local X2AbilityCooldown_ModifiedNumTurns	AbilityCooldown;

	// No ammo cost, no using while burning or disoriented
	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot('IRI_BH_BurstFire', true, false, false);

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BurstFire";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	
	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = `GetConfigInt('IRI_BH_BurstFire_AmmoCost');
	Template.AbilityCosts.AddItem(AmmoCost);

	iCooldown = `GetConfigInt('IRI_BH_BurstFire_Cooldown');
	if (iCooldown > 0)
	{
		AbilityCooldown = new class'X2AbilityCooldown_ModifiedNumTurns';
		AbilityCooldown.iNumTurns = iCooldown;
		AbilityCooldown.ModifyCooldownAbilities.Add(1);
		AbilityCooldown.ModifyCooldownAbilities[0].AbilityName = 'IRI_BH_UnrelentingPressure';
		AbilityCooldown.ModifyCooldownAbilities[0].NumTurns = `GetConfigInt('IRI_BH_UnrelentingPressure_CooldownReductionPassive');
		Template.AbilityCooldown = AbilityCooldown;
	}

	NumExtraShots = `GetConfigInt('IRI_BH_BurstFire_NumShots') - 1;
	if (NumExtraShots > 0)
	{
		BurstFireMultiTarget = new class'X2AbilityMultiTarget_BurstFire';
		BurstFireMultiTarget.NumExtraShots = NumExtraShots;
		Template.AbilityMultiTargetStyle = BurstFireMultiTarget;
	}
	Template.AddMultiTargetEffect(Template.AbilityTargetEffects[2]); // Just the damage effect.

	SetFireAnim(Template, 'FF_IRI_BH_BurstFire');

	Template.AdditionalAbilities.AddItem('IRI_BH_BurstFire_Passive');
	Template.AdditionalAbilities.AddItem('IRI_BH_BurstFire_Anim_Passive');

	Template.ActivationSpeech = 'BulletShred'; // Rupture voiceilne

	return Template;	
}

static private function X2AbilityTemplate IRI_BH_BurstFire_Passive()
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
	BurstFireAimPenalty.fAimModifier = `GetConfigFloat('IRI_BH_BurstFire_SquadSightPenaltyModifier');
	BurstFireAimPenalty.BuildPersistentEffect(1, true);
	BurstFireAimPenalty.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, false,,Template.AbilitySourceName);
	BurstFireAimPenalty.EffectName = 'IRI_BH_BurstFire_SquadsightPenalty_Effect';
	Template.AddTargetEffect(BurstFireAimPenalty);

	return Template;
}

static private function X2AbilityTemplate IRI_BH_NothingPersonal_Passive()
{
	local X2AbilityTemplate Template;	

	Template = PurePassive('IRI_BH_NothingPersonal_Passive', "img:///IRIPerkPackUI.UIPerk_NothingPersonal", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/);

	Template.PrerequisiteAbilities.AddItem('IRI_BH_ShadowTeleport');
	Template.AdditionalAbilities.AddItem('IRI_BH_NothingPersonal');

	return Template;
}

// This ability is a bit funky. We use perk content with a perk weapon to fire a psionic projectile with special impact FX,
// and the Fire Other Weapon notify to fire the pistol projectile for pistol's sounds.
static private function X2AbilityTemplate IRI_BH_NothingPersonal()
{
	local X2AbilityTemplate							Template;	
	local X2Effect_ApplyWeaponDamage				WeaponDamageEffect;
	local X2Effect_Knockback						KnockbackEffect;
	local X2Condition_UnitEffectsWithAbilitySource	TargetEffectCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_NothingPersonal');

	// Icon
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_NothingPersonal";
	Template.AbilitySourceName = 'eAbilitySource_Perk';   
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.bUseAmmoAsChargesForHUD = true;
	
	// Costs
	AddCooldown(Template, `GetConfigInt('IRI_BH_ShadowTeleport_Cooldown'));

	// Target Conditions
	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect('IRI_BH_NothingPersonal_Effect', 'AA_MissingRequiredEffect');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);
	
	// Effects
	Template.AbilityTargetEffects.Length = 0;
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.DamageTag = 'IRI_BH_NothingPersonal';
	WeaponDamageEffect.bIgnoreArmor = false;
	WeaponDamageEffect.bIgnoreBaseDamage = false;
	//WeaponDamageEffect.DamageTypes.AddItem('Psi');
	Template.AddTargetEffect(WeaponDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 2;
	Template.AddTargetEffect(KnockbackEffect);

	Template.bShowActivation = true;

	SetFireAnim(Template, 'FF_NothingPersonal');
	Template.ActivationSpeech = 'LightningHands';

	return Template;
}

static private function X2AbilityTemplate IRI_BH_DoublePayload()
{
	local X2AbilityTemplate			Template;
	local X2Effect_BaseDamageBonus	BaseDamageBonus;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_DoublePayload');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_DoublePayload";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	BaseDamageBonus = new class'X2Effect_BaseDamageBonus';
	BaseDamageBonus.AbilityName = 'IRI_BH_HomingMineDetonation';
	BaseDamageBonus.DamageMod = `GetConfigFloat('IRI_BH_DoublePayload_BonusDamage');
	BaseDamageBonus.bOnlyPrimaryTarget = true;
	BaseDamageBonus.BuildPersistentEffect(1, true);
	BaseDamageBonus.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,,Template.AbilitySourceName);
	BaseDamageBonus.EffectName = 'IRI_BH_DoublePayload_BonusDamageEffect';
	Template.AddTargetEffect(BaseDamageBonus);

	Template.PrerequisiteAbilities.AddItem('IRI_BH_HomingMine');
	
	return Template;
}




static private function X2AbilityTemplate IRI_BH_ExplosiveAction()
{
	local X2AbilityTemplate							Template;
	local X2Effect_BountyHunter_DramaticEntrance	ExplosiveAction;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ExplosiveAction');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_ExplosiveAction";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	ExplosiveAction = new class'X2Effect_BountyHunter_DramaticEntrance';
	ExplosiveAction.BuildPersistentEffect(1, true);
	ExplosiveAction.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(ExplosiveAction);

	Template.PrerequisiteAbilities.AddItem('NOT_IRI_BH_DarkNight_Passive');
	
	return Template;
}

static private function X2AbilityTemplate IRI_BH_DarkNight_Passive()
{
	local X2AbilityTemplate Template;

	Template = PurePassive('IRI_BH_DarkNight_Passive', "img:///IRIPerkPackUI.UIPerk_DarkNight", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/);

	Template.PrerequisiteAbilities.AddItem('NOT_IRI_BH_ExplosiveAction');
	
	return Template;
}

static private function X2AbilityTemplate IRI_BH_ShadowTeleport()
{
	local X2AbilityTemplate							Template;
	local X2AbilityCooldown							Cooldown;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2Effect_Persistent						PersistentEffect;
	local X2Condition_AbilityProperty				AbilityProperty;	
	local X2Condition_UnitEffects					ExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_ShadowTeleport');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_ShadowTeleport";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target conditions
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitDisallowMindControlProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Can't teleport to levitating units.
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect('IcarusDropGrabberEffect', 'AA_UnitIsImmune');
	ExcludeEffects.AddExcludeEffect(class'X2Ability_Archon'.default.BlazingPinionsStage1EffectName, 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);
	
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

	// Enables use of Nothing Personal against this target.
	// Done as a multi-target effect, because this ability ModifyContextFn moves primary target to multi target for the purposes of visualization
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.EffectName = 'IRI_BH_NothingPersonal_Effect';
	PersistentEffect.DuplicateResponse = eDupe_Allow;
	PersistentEffect.BuildPersistentEffect(1, false, true, true, eGameRule_PlayerTurnEnd);

	// Apply this effect only if the shooter has nothing personal.
	AbilityProperty = new class'X2Condition_AbilityProperty';
	AbilityProperty.OwnerHasSoldierAbilities.AddItem('IRI_BH_NothingPersonal');
	PersistentEffect.TargetConditions.AddItem(AbilityProperty);

	Template.AddMultiTargetEffect(PersistentEffect);
	
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
	//local X2Action_PlaySoundAndFlyOver CharSpeechAction;
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

	//CharSpeechAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
	//CharSpeechAction.SetSoundAndFlyOverParameters(None, "", 'RunAndGun', eColor_Good);

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

	VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);
	if (UnitState.HasSoldierAbility('IRI_BH_FeelingLucky_Passive'))
	{
		Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, LeafNodes));
		Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString("IRI_BH_FeelingLucky_Flyover_Added"), '', eColor_Good);
	}

	Flyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,, Flyover, LeafNodes));
	Flyover.SetSoundAndFlyOverParameters(None, `GetLocalizedString("NightDiveActionAvailable"), '', eColor_Good);
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




static private function X2AbilityTemplate IRI_BH_BigGameHunter()
{
	local X2AbilityTemplate						Template;
	local X2Effect_BountyHunter_CustomZeroIn	BonusEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_BigGameHunter');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Mitzruti_BigGameHunter";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	BonusEffect = new class'X2Effect_BountyHunter_CustomZeroIn';
	BonusEffect.BuildPersistentEffect(1, true, false, false);
	BonusEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(BonusEffect);

	return Template;
}

static private function X2AbilityTemplate IRI_BH_Nightmare()
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
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true,,Template.AbilitySourceName);
	Effect.AddEffectHitModifier(eHit_Success, `GetConfigInt('IRI_BH_Nightmare_AimBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, true /*NonFlanked*/);
	Effect.AddEffectHitModifier(eHit_Crit, `GetConfigInt('IRI_BH_Nightmare_CritBonus'), Template.LocFriendlyName, /*ToHitCalClass*/,,, true /*Flanked*/, true /*NonFlanked*/);

	// Require that target does not see us and has no cover.
	// Units that don't take cover in principle should pass as well.
	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bExcludeGameplayVisible = true;
	VisCondition.bRequireMatchCoverType = true;
	VisCondition.TargetCover = CT_None;
	Effect.ToHitConditions.AddItem(VisCondition);

	Template.AddTargetEffect(Effect);

	return Template;
}

static private function X2AbilityTemplate IRI_BH_FirePistol()
{
	local X2AbilityTemplate Template;	
	local X2Condition_UnitEffectsWithAbilitySource TargetEffectCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_PistolStandardShot('IRI_BH_FirePistol');

	Template.bUseAmmoAsChargesForHUD = true;

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_HandCannon";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_PISTOL_SHOT_PRIORITY;

	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddExcludeEffect('IRI_BH_NothingPersonal_Effect', 'AA_DuplicateEffectIgnored');
	Template.AbilityTargetConditions.AddItem(TargetEffectCondition);
	
	//Template.AdditionalAbilities.AddItem('PistolOverwatchShot');
	//Template.AdditionalAbilities.AddItem('PistolReturnFire');
	///Template.AdditionalAbilities.AddItem('HotLoadAmmo');

	Template.OverrideAbilities.AddItem('PistolStandardShot');

	return Template;	
}

static private function X2AbilityTemplate IRI_BH_NamedBullet()
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

	Template.BuildVisualizationFn = NamedBullet_BuildVisualization;
	Template.ModifyNewContextFn = NamedBullet_ModifyContext;

	SetFireAnim(Template, 'FF_NamedShot');

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
	TimedWaitOne.DelayTimeSec = 0.75f;

	// Begin second parallel branch. Gradually slow down the time.

	//PlaySound = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false,, FireAction.ParentActions));
	//PlaySound.SetSoundAndFlyOverParameters(SoundCue(`CONTENT.RequestGameArchetype("IRIBountyHunter.NamedShotClicks_Cue")), "", '', eColor_Xcom);

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, FireAction.ParentActions));
	TimeDilation.TimeDilation = 0.9f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.2f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.8f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.2f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.7f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.2f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.6f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.2f;

	TimeDilation = X2Action_SetGlobalTimeDilation(class'X2Action_SetGlobalTimeDilation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimedWaitTwo));
	TimeDilation.TimeDilation = 0.5f;

	TimedWaitTwo = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, TimeDilation));
	TimedWaitTwo.DelayTimeSec = 0.2f;

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

static private function X2AbilityTemplate IRI_BH_Untraceable()
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
	AbilityCooldown.AddCheckValue('IRI_BH_NothingPersonal', 1, eCheck_GreaterThan, 1);
	Template.AbilityShooterConditions.AddItem(AbilityCooldown);

	ReduceCooldown = new class'X2Effect_ReduceCooldowns';
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_Nightfall');
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_ShadowTeleport');
	ReduceCooldown.AbilitiesToTick.AddItem('IRI_BH_NothingPersonal');
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

static private function X2AbilityTemplate IRI_BH_BlindingFire()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;
	local X2Effect_Blind					BlindEffect;

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
	BlindEffect = class'X2Effect_Blind'.static.CreateBlindEffect(`GetConfigInt('IRI_BH_BlindingFire_DurationTurns'), 0);
	BlindEffect.WatchRule = eGameRule_PlayerTurnEnd; // So the Watch Rule is about the player who owns the unit, not the player who applied the unit...
	Template.AddTargetEffect(BlindEffect);

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

static private function X2AbilityTemplate IRI_BH_WitchHunt()
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

static private function X2AbilityTemplate IRI_BH_Headhunter()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_Headhunter	Headhunter;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Headhunter');

	// Icon Setup
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_HeadHunter";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	SetPassive(Template);

	// Let Nightfall be the ability in the popup.
	Template.bHideOnClassUnlock = true;

	Headhunter = new class'X2Effect_BountyHunter_Headhunter';
	Headhunter.iCritBonus = `GetConfigInt('IRI_BH_Headhunter_CritBonus');
	Headhunter.BuildPersistentEffect(1, true);
	Headhunter.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,,Template.AbilitySourceName);
	Template.AddTargetEffect(Headhunter);

	// This ability needs to be attached to some kind of weapon to work.
	// Bounty hunters apply it to secondary, but we put primary slot in case the perk is used for other purposes.
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;
	Template.bUniqueSource = true; // Just in case for RPGO
	
	return Template;
}

static private function X2AbilityTemplate IRI_BH_Nightfall()
{
	local X2AbilityTemplate						Template;
	local X2AbilityCooldown						Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Nightfall');

	// Icon Setup
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	
	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_Nightfall";
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.bHideOnClassUnlock = false;

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
	//Template.ActivationSpeech = 'Shadow';
	Template.ActivationSpeech = 'ActivateConcealment'; // Use regular soldier voiceline, since we're not using Reaper character template.
	
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.NonAggressiveChosenActivationIncreasePerUse;

	//Template.AdditionalAbilities.AddItem('IRI_BH_Nightfall_Passive');

	Template.bUniqueSource = true;
	
	return Template;
}

static private function AddNightfallShooterEffects(out X2AbilityTemplate Template)
{
	local X2Effect_BountyHunter_DeadlyShadow	StealthEffect;
	local X2Effect_AdditionalAnimSets			AnimEffect;
	local X2Effect_BountyHunter_GrantAmmo		GrantAmmo;
	local X2Condition_AbilityProperty			AbilityCondition;
	local float									DetectionMod;
	local X2Effect_PersistentStatChange			StatChange;

	// LWOTC removes Super Concealment as a mechanic by disabling it on all missions, 
	// so we can longer rely on it to ensure minimum detection radius.
	// And the regular concealment is all we have to work with.
	// Here I apply a detection modifier to make detection radius for bounty hunters very smol.
	// The default value of the modifier is the same as for the LWOTC Reapers.
	// Often it's enough to stand right next to enemies and be undetected,
	// especially if there's any other detection modifier at play.
	// For the record, I think that's uberdumb, but nothing for me to do about.
	if (class'Help'.static.IsModActive('LongWarOfTheChosen'))
	{	
		DetectionMod = `GetConfigFloat('IRI_BH_Nightfall_LWOTC_DetectionModifier');
		if (DetectionMod != 0)
		{
			StatChange = new class'X2Effect_PersistentStatChange';
			StatChange.BuildPersistentEffect(1, true, true, false);
			StatChange.bRemoveWhenTargetConcealmentBroken = true;
			StatChange.AddPersistentStatChange(eStat_DetectionModifier, DetectionMod);
			Template.AddShooterEffect(StatChange);
		}
	}
		
	StealthEffect = new class'X2Effect_BountyHunter_DeadlyShadow';
	StealthEffect.BuildPersistentEffect(`GetConfigInt('IRI_BH_Nightfall_Duration'), false, true, false, eGameRule_PlayerTurnBegin);
	StealthEffect.SetDisplayInfo(ePerkBuff_Bonus, `GetLocalizedString("IRI_BH_Nightfall_EffectName"), `GetLocalizedString("IRI_BH_Nightfall_EffectDesc"), "img:///IRIPerkPackUI.UIPerk_Nightfall", true,,Template.AbilitySourceName);
	Template.AddShooterEffect(StealthEffect);

	Template.AddShooterEffect(class'X2Effect_Spotted'.static.CreateUnspottedEffect());

	AnimEffect = new class'X2Effect_AdditionalAnimSets';
	AnimEffect.DuplicateResponse = eDupe_Ignore;
	AnimEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	//AnimEffect.bRemoveWhenTargetConcealmentBroken = true; // Removed by Nightfall effect.
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



static private function X2AbilityTemplate IRI_BH_Nightfall_Passive()
{
	local X2AbilityTemplate					Template;
	local X2Effect_BountyHunter_CritMagic	CritMagic;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_Nightfall_Passive');

	Template.IconImage = "img:///IRIPerkPackUI.UIPerk_DeadOfNight";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	SetPassive(Template);

	CritMagic = new class'X2Effect_BountyHunter_CritMagic';
	CritMagic.BuildPersistentEffect(1, true);
	CritMagic.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.LocHelpText, Template.IconImage, true,,Template.AbilitySourceName);
	CritMagic.BonusCritChance = `GetConfigInt('IRI_BH_Nightfall_CritChanceBonusWhenUnseen');
	CritMagic.GrantCritDamageForCritChanceOverflow = `GetConfigInt('IRI_BH_Nightfall_CritDamageBonusPerCritChanceOverflow');
	Template.AddTargetEffect(CritMagic);

	Template.bUniqueSource = true;
	
	return Template;
}

static private function X2AbilityTemplate IRI_BH_HomingMine()
{
	local X2AbilityTemplate							Template;
	local X2Effect_BountyHunter_HomingMine			MineEffect;
	local X2AbilityCost_ActionPoints				ActionPointCost;
	local X2AbilityCost_Charges						ChargeCost;
	local X2AbilityCharges							Charges;
	local X2AbilityMultiTarget_Radius	            RadiusMultiTarget;	//	purely for visualization of the AOE
	local X2Condition_UnitEffects					EffectCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_HomingMine');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_HomingMine";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	
	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.TargetingMethod = class'X2TargetingMethod_HomingMine';

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = `GetConfigFloat('IRI_BH_HomingMine_Radius');
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	ChargeCost = new class'X2AbilityCost_Charges';
	Template.AbilityCosts.AddItem(ChargeCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = `GetConfigInt('IRI_BH_HomingMine_Charges');
	Charges.AddBonusCharge('IRI_BH_DoublePayload', `GetConfigInt('IRI_BH_DoublePayload_NumBonusCharges'));
	Template.AbilityCharges = Charges;

	// Shooter Conditions
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	
	EffectCondition = new class'X2Condition_UnitEffects';
	EffectCondition.AddExcludeEffect('IRI_BH_HomingMine_Effect', 'AA_UnitHasHomingMine');
	Template.AbilityTargetConditions.AddItem(EffectCondition);

	MineEffect = new class'X2Effect_BountyHunter_HomingMine';
	MineEffect.BuildPersistentEffect(1, true, false);
	MineEffect.SetDisplayInfo(ePerkBuff_Penalty, Template.LocFriendlyName, `GetLocalizedString("IRI_BH_HomingMine_Effect_Desc"), Template.IconImage, true);
	MineEffect.AbilityToTrigger = 'IRI_BH_HomingMineDetonation';
	MineEffect.EffectName = 'IRI_BH_HomingMine_Effect';
	Template.AddTargetEffect(MineEffect);

	Template.bSkipPerkActivationActions = false;
	Template.bHideWeaponDuringFire = false;
	
	Template.bAllowUnderhandAnim = true;
	Template.Hostility = eHostility_Neutral;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'HomingMine';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	Template.AdditionalAbilities.AddItem('IRI_BH_HomingMineDetonation');
	Template.DamagePreviewFn = HomingMine_DamagePreview;

	return Template;
}

static private function bool HomingMine_DamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	local XComGameState_Unit SourceUnit;

	MinDamagePreview = `GetConfigDamage("IRI_BH_HomingMine_Damage");
	
	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
	if (SourceUnit != none && SourceUnit.HasSoldierAbility('IRI_BH_DoublePayload'))
	{
		MinDamagePreview.Damage += float(MinDamagePreview.Damage) * `GetConfigFloat('IRI_BH_DoublePayload_BonusDamage');
	}

	MaxDamagePreview = MinDamagePreview;
	return true;
}

static private function X2AbilityTemplate IRI_BH_HomingMineDetonation()
{
	local X2AbilityTemplate							Template;
	local X2AbilityToHitCalc_StandardAim			ToHit;
	local X2AbilityMultiTarget_Radius	            RadiusMultiTarget;
	local X2Condition_UnitProperty					UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage				MineDamage;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_BH_HomingMineDetonation');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_HomingMine";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	
	// Targeting and Triggering
	ToHit = new class'X2AbilityToHitCalc_StandardAim';
	ToHit.bIndirectFire = true;
	ToHit.bGuaranteedHit = true;
	Template.AbilityToHitCalc = ToHit;

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.bAddPrimaryTargetAsMultiTarget = true;
	RadiusMultiTarget.fTargetRadius = `GetConfigFloat('IRI_BH_HomingMine_Radius');
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false; //The grenade can affect interactive objects, others
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	//	special damage effect handles shrapnel vs regular damage
	MineDamage = new class'X2Effect_ApplyWeaponDamage';
	MineDamage.EffectDamageValue = `GetConfigDamage("IRI_BH_HomingMine_Damage");
	MineDamage.EnvironmentalDamageAmount = `GetConfigInt("IRI_BH_HomingMine_EnvDamage");
	MineDamage.bExplosiveDamage = true;
	MineDamage.bIgnoreBaseDamage = true;
	Template.AddMultiTargetEffect(MineDamage);

	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = HomingMineDetonation_BuildVisualization;
	Template.MergeVisualizationFn = HomingMineDetonation_MergeVisualization;
	
	//Template.PostActivationEvents.AddItem('HomingMineDetonated');

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.GrenadeLostSpawnIncreasePerUse;

	return Template;
}

static private function HomingMineDetonation_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability AbilityContext;	
	local VisualizationActionMetadata VisTrack;
	local X2Action_PlayEffect EffectAction;
	local X2Action_SpawnImpactActor ImpactAction;
	//local X2Action_CameraLookAt LookAtAction;
	//local X2Action_Delay DelayAction;
	local X2Action_StartStopSound SoundAction;
	local XComGameState_Unit ShooterUnit;
	local Array<X2Action> ParentActions;
	local X2Action_MarkerNamed JoinAction;
	local XComGameStateHistory History;
	local X2Action_WaitForAbilityEffect WaitForFireEvent;
	local XComGameStateVisualizationMgr VisMgr;
	local Array<X2Action> NodesToParentToWait;
	local int ScanAction;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	

	VisTrack.StateObjectRef = AbilityContext.InputContext.SourceObject;
	VisTrack.VisualizeActor = History.GetVisualizer(VisTrack.StateObjectRef.ObjectID);
	History.GetCurrentAndPreviousGameStatesForObjectID(VisTrack.StateObjectRef.ObjectID,
													   VisTrack.StateObject_OldState, VisTrack.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);	

	WaitForFireEvent = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(VisTrack, AbilityContext));
	//Camera comes first
// 	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
// 	LookAtAction.LookAtLocation = AbilityContext.InputContext.TargetLocations[0];
// 	LookAtAction.BlockUntilFinished = true;
// 	LookAtAction.LookAtDuration = 2.0f;
	
	ImpactAction = X2Action_SpawnImpactActor( class'X2Action_SpawnImpactActor'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent) );
	ParentActions.AddItem(ImpactAction);

	ImpactAction.ImpactActorName = class'X2Ability_ReaperAbilitySet'.default.HomingMineImpactArchetype;
	ImpactAction.ImpactLocation = AbilityContext.InputContext.TargetLocations[0];
	ImpactAction.ImpactLocation.Z = `XWORLD.GetFloorZForPosition( ImpactAction.ImpactLocation );
	ImpactAction.ImpactNormal = vect(0, 0, 1);

	//Do the detonation
	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
	ParentActions.AddItem(EffectAction);

	ShooterUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(VisTrack.StateObjectRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex));
	if (ShooterUnit.HasSoldierAbility('Shrapnel'))
		EffectAction.EffectName = class'X2Ability_ReaperAbilitySet'.default.HomingShrapnelExplosionFX;		
	else 
		EffectAction.EffectName = class'X2Ability_ReaperAbilitySet'.default.HomingMineExplosionFX;
	`CONTENT.RequestGameArchetype(EffectAction.EffectName);

	EffectAction.EffectLocation = AbilityContext.InputContext.TargetLocations[0];
	EffectAction.EffectRotation = Rotator(vect(0, 0, 1));
	EffectAction.bWaitForCompletion = false;
	EffectAction.bWaitForCameraCompletion = false;

	SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, WaitForFireEvent));
	ParentActions.AddItem(SoundAction);
	SoundAction.Sound = new class'SoundCue';

	if (ShooterUnit.HasSoldierAbility('Shrapnel'))
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Proximity_Mine_Explosion';	
	else 
		SoundAction.Sound.AkEventOverride = AkEvent'SoundX2CharacterFX.Proximity_Mine_Explosion';	

	SoundAction.bIsPositional = true;
	SoundAction.vWorldPosition = AbilityContext.InputContext.TargetLocations[0];

	JoinAction = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(VisTrack, AbilityContext, false, None, ParentActions));
	JoinAction.SetName("Join");

	TypicalAbility_BuildVisualization(VisualizeGameState);
	
	// Jwats: Reparent all of the apply weapon damage actions to the wait action since this visualization doesn't have a fire anim
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', NodesToParentToWait);
	for( ScanAction = 0; ScanAction < NodesToParentToWait.Length; ++ScanAction )
	{
		VisMgr.DisconnectAction(NodesToParentToWait[ScanAction]);
		VisMgr.ConnectAction(NodesToParentToWait[ScanAction], VisMgr.BuildVisTree, false, WaitForFireEvent);
		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree, false, NodesToParentToWait[ScanAction]);
	}

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToTerrain', NodesToParentToWait);
	for( ScanAction = 0; ScanAction < NodesToParentToWait.Length; ++ScanAction )
	{
		VisMgr.DisconnectAction(NodesToParentToWait[ScanAction]);
		VisMgr.ConnectAction(NodesToParentToWait[ScanAction], VisMgr.BuildVisTree, false, WaitForFireEvent);
		VisMgr.ConnectAction(JoinAction, VisMgr.BuildVisTree, false, NodesToParentToWait[ScanAction]);
	}	

	//Keep the camera there after things blow up
// 	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(VisTrack, AbilityContext));
// 	DelayAction.Duration = 0.5;
}

static private function HomingMineDetonation_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action_WaitForAbilityEffect WaitForFireEvent;
	local Array<X2Action> DamageActions;
	local int ScanAction;
	local X2Action_ApplyWeaponDamageToUnit TestDamage;
	local X2Action_ApplyWeaponDamageToUnit PlaceWithAction;
	local X2Action_MarkerTreeInsertBegin MarkerStart;
	local XComGameStateContext_Ability Context;

	VisMgr = `XCOMVISUALIZATIONMGR;

	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	Context = XComGameStateContext_Ability(MarkerStart.StateChangeContext);

	// Jwats: Find the apply weapon damage to unit that caused us to explode and put our visualization with it
	WaitForFireEvent = X2Action_WaitForAbilityEffect(VisMgr.GetNodeOfType(BuildTree, class'X2Action_WaitForAbilityEffect'));
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToUnit', DamageActions, , Context.InputContext.PrimaryTarget.ObjectID);
	for( ScanAction = 0; ScanAction < DamageActions.Length; ++ScanAction )
	{
		TestDamage = X2Action_ApplyWeaponDamageToUnit(DamageActions[ScanAction]);
		if( TestDamage.StateChangeContext.AssociatedState.HistoryIndex == Context.DesiredVisualizationBlockIndex )
		{
			PlaceWithAction = TestDamage;
			break;
		}
	}
	
	if( PlaceWithAction != None )
	{
		VisMgr.DisconnectAction(WaitForFireEvent);
		VisMgr.ConnectAction(WaitForFireEvent, VisualizationTree, false, None, PlaceWithAction.ParentActions);
	}
	else
	{
		Context.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
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

static private function X2AbilityTemplate Create_AnimSet_Passive(name TemplateName, string AnimSetPath)
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
