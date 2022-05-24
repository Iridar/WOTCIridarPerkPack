class X2Ability_BountyHunter extends X2Ability;

var private X2Condition_Visibility UnitDoesNotSeeCondition;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Squaddie
	Templates.AddItem(IRI_BH_Headhunter());
	Templates.AddItem(IRI_BH_DeadlyShadow());
	Templates.AddItem(IRI_BH_DeadlyShadow_Passive());

	// Corporal
	Templates.AddItem(IRI_BH_ChasingShot());
	Templates.AddItem(IRI_BH_ChasingShot_Attack());
	Templates.AddItem(IRI_BH_Blindside());

	// Sergeant
	// ..

	// Lieutenant
	Templates.AddItem(IRI_BH_Folowthrough());
	Templates.AddItem(PurePassive('IRI_BH_DeadlierShadow_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	
	// Captain
	Templates.AddItem(IRI_BH_WitchHunt());
	Templates.AddItem(PurePassive('IRI_BH_WitchHunt_Passive', "img:///UILibrary_PerkIcons.UIPerk_standard", false /*cross class*/, 'eAbilitySource_Perk', true /*display in UI*/));
	
	Templates.AddItem(Blind());

	return Templates;
}

static function X2AbilityTemplate IRI_BH_WitchHunt()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	Trigger;

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
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

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

	SetPassive(Template);
	SetHidden(Template);

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

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
	AddCooldown(Template, `GetConfigInt('IRI_DeadlyShadow_Cooldown')); // TODO: Config
	
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

	SetPassive(Template);
	SetHidden(Template);

	// Icon Setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_shadow";

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

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true; // Require ammo only for activation
	Template.AbilityCosts.AddItem(AmmoCost);
	Template.bUseAmmoAsChargesForHUD = true;

	// TODO: Cooldown

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
	local X2AbilityCost_Ammo						AmmoCost;
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
        if (AbilityContext.InputContext.MovementPaths[0].MovementTiles[0] == UnitState.TileLocation)
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
		}
	}	

	return ELR_NoInterrupt;
}

static function X2AbilityTemplate IRI_BH_Blindside()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_Ammo                AmmoCost;
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
	// TODO: Cooldown

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
	// TODO: Cooldown

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

static function X2AbilityTemplate Blind()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          TargetProperty;
	local X2Condition_Visibility            TargetVisibilityCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Blind');

	// Icon Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_soulfire";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	// Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	TargetProperty = new class'X2Condition_UnitProperty';
	TargetProperty.ExcludeRobotic = true;
	TargetProperty.FailOnNonUnits = true;
	TargetProperty.TreatMindControlledSquadmateAsHostile = true;
	Template.AbilityTargetConditions.AddItem(TargetProperty);

	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bAllowSquadsight = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	//AddCooldown(Template, GetConfigInt('IRI_SoulShot_Cooldown'));

	// Effects
	Template.AddTargetEffect(class'X2Effect_Blind'.static.CreateBlindEffect(2, 0));

	// State and Viz
	Template.bShowActivation = false;

	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.ActivationSpeech = 'IonicStorm';
	//Template.CinescriptCameraType = "IRI_SoulShot";

	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.Hostility = eHostility_Offensive;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;
	
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
}
