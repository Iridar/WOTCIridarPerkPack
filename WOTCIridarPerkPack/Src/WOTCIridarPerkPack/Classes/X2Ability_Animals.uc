class X2Ability_Animals extends X2Ability_PerkPack;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_TunnelingClaws());
	Templates.AddItem(IRI_ToxinAptitude());
	Templates.AddItem(IRI_TunnelRat());

	Templates.AddItem(IRI_Scavenger());
	Templates.AddItem(IRI_PackHunter());
	Templates.AddItem(PurePassive('IRI_PackHunter_Passive', "img:///IRIPerkPack_UILibrary.UIPerk_PackHunter", false, 'eAbilitySource_Perk', true));
	Templates.AddItem(PurePassive('IRI_LaughItOff', "img:///IRIPerkPack_UILibrary.UIPerk_LaughItOff", false, 'eAbilitySource_Perk', true));

	Templates.AddItem(IRI_KeenNose());
	Templates.AddItem(PurePassive('IRI_KeenNose_Passive', "img:///IRIPerkPack_UILibrary.UIPerk_PackHunter", false, 'eAbilitySource_Perk', true));

	return Templates;
}

static function X2AbilityTemplate IRI_KeenNose()
{
	local X2AbilityTemplate					Template;
	local X2Condition_UnitProperty			TargetCondition;
	local X2Condition_TargetVisibleToSquad	VisibilityCondition;
	local X2Effect_Persistent				PersistentEffect;
	local X2AbilityMultiTarget_AllUnits		MultiTargetStyle;
	local X2Effect_RemoveEffects			RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_KeenNose');

	//	Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_targetdefinition";
	SetHidden(Template);

	// Triggering
	SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnBegun', ELD_OnStateSubmitted, eFilter_Player, 50);
	SetSelfTarget_WithEventTrigger(Template, 'UnitMoveFinished', ELD_OnStateSubmitted, eFilter_None, 50);

	// Targeting
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	MultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';
	MultiTargetStyle.bAcceptFriendlyUnits = false;
	MultiTargetStyle.bAcceptEnemyUnits = true;
	Template.AbilityMultiTargetStyle = MultiTargetStyle;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Target Conditions
	TargetCondition = new class'X2Condition_UnitProperty';	
	TargetCondition.ExcludeAlive = false;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeFriendlyToSource = true;
	TargetCondition.ExcludeHostileToSource = false;
	TargetCondition.RequireWithinRange = true;
	TargetCondition.WithinRange = class'XComWorldData'.const.WORLD_StepSize * 25;
	Template.AbilityMultiTargetConditions.AddItem(TargetCondition);

	// Add effect that will create a tether to the target via perk content
	PersistentEffect = new class'X2Effect_Persistent';
	PersistentEffect.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnBegin);
	PersistentEffect.EffectName = 'IRI_KeenNose_Effect';
	PersistentEffect.DuplicateResponse = eDupe_Ignore;
	VisibilityCondition = new class'X2Condition_TargetVisibleToSquad';
	VisibilityCondition.bReverseCondition = true; // Can apply only to targets that are NOT visible to XCOM
	PersistentEffect.TargetConditions.AddItem(VisibilityCondition);	
	Template.AddMultiTargetEffect(PersistentEffect);

	// Remove the effect if the unit is visible to any ally
	// Yeah it's a bit awkward to apply the effect to some targets just to remove it right away,
	// but it's the simplest implementation that I could come up with that doesn't involve additional abilities with additional triggers.
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem('IRI_KeenNose_Effect');
	RemoveEffects.TargetConditions.AddItem(new class'X2Condition_TargetVisibleToSquad'); // Can apply only to targets that ARE visible to XCOM
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.ActivationSpeech = 'TargetDefinition';
	Template.bSkipFireAction = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.ConcealmentRule = eConceal_AlwaysEvenWithObjective;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.AdditionalAbilities.AddItem('IRI_KeenNose_Passive');
	
	return Template;
}


static function X2AbilityTemplate IRI_LaughItOff()
{
	local X2AbilityTemplate		Template;	
	local X2Effect_Persistent	Persistent;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_LaughItOff');

	//	Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_LaughItOff";
	SetPassive(Template);

	Persistent = new class'X2Effect_Persistent';
	Persistent.BuildPersistentEffect(1, true);
	Persistent.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Persistent.EffectName = 'IRI_LaughItOff_Effect';
	Template.AddTargetEffect(Persistent);

	return Template;	
}

static function X2AbilityTemplate IRI_PackHunter()
{
	local X2AbilityTemplate		Template;	
	local X2Effect_PackHunter	PackHunter;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_PackHunter');

	//	Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_PackHunter";
	SetHidden(Template);

	// Triggering
	SetSelfTarget_WithEventTrigger(Template, 'PlayerTurnBegun', ELD_OnStateSubmitted, eFilter_None, 50);
	SetSelfTarget_WithEventTrigger(Template, 'UnitMoveFinished', ELD_OnStateSubmitted, eFilter_None, 50);

	//	Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	PackHunter = new class'X2Effect_PackHunter';
	PackHunter.BuildPersistentEffect(1, true);
	PackHunter.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(PackHunter);

	Template.bSkipFireAction = true;
	Template.bShowActivation = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;

	Template.AdditionalAbilities.AddItem('IRI_PackHunter_Passive');

	return Template;	
}

static function X2AbilityTemplate IRI_Scavenger()
{
	local X2AbilityTemplate			Template;	
	local X2Condition_UnitProperty	UnitPropertyCondition;	
	local X2AbilityCharges			Charges;
	local X2AbilityCost_Charges		ChargeCost;
	local X2Condition_UnitValue		UntiValueCondition;
	local X2Effect_SetUnitValue		UnitValueEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_Scavenger');

	//	Icon setup
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_Scavenger"; 
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.LOOT_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_Charges');
	Template.HideErrors.AddItem('AA_CannotAfford_ActionPoints');

	//	Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	AddCooldown(Template, GetConfigInt('IRI_Scavenger_Cooldown'));

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = GetConfigInt('IRI_Scavenger_Charges');
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	//ChargeCost.bFreeCost = true; // Doesn't work with X2Ability_Charges. Firaxis being inconsistent, per usual.
	Template.AbilityCosts.AddItem(ChargeCost);

	//	Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// Target Conditions
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = 144; // 1.5 tiles
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// Use Unit Value to mark the target so that Scavenge can be attempted at each target only once.
	UntiValueCondition = new class'X2Condition_UnitValue';
	UntiValueCondition.AddCheckValue('IRI_Scavenger_Value', 0);
	Template.AbilityShooterConditions.AddItem(UntiValueCondition);

	// Effects
	UnitValueEffect = new class'X2Effect_SetUnitValue';
	UnitValueEffect.UnitName = 'IRI_Scavenger_Value';
	UnitValueEffect.NewValueToSet = 1;
	UnitValueEffect.CleanupType = eCleanup_BeginTactical;
	Template.AddTargetEffect(UnitValueEffect);

	//Template.CinescriptCameraType = "Loot";
	SetFireAnim(Template, 'HL_Scavenger');
	Template.bSkipFireAction = false;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = Scavenger_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;	
}

simulated function XComGameState Scavenger_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateHistory			History;
	local XComGameState					NewGameState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			TargetUnit;
	local array<XComGameState_Item>		LootItems;
	local X2LootTableManager			LootManager;
	local LootResults					GeneratedLoot;
	local XComGameState_Ability			AbilityState;
	local bool							bLootCreated;
	local int							MaxLootItems;

	NewGameState = TypicalAbility_BuildGameState(Context);

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(Context);

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit != none)
	{
		LootManager = class'X2LootTableManager'.static.GetLootTableManager();
		LootManager.RollForLootCarrier(TargetUnit.GetMyTemplate().TimedLoot, GeneratedLoot);
		if (GeneratedLoot.LootToBeCreated.Length > 0)
		{
			MaxLootItems = GetConfigInt('IRI_Scavenger_MaxLootItems');
			if (MaxLootItems != 0 && GeneratedLoot.LootToBeCreated.Length > MaxLootItems)
			{
				GeneratedLoot.LootToBeCreated.Length = MaxLootItems;
			}

			LootItems = MakeAvailableLoot(NewGameState, GeneratedLoot);
			if (LootItems.Length > 0)
			{	
				class'XComGameState_LootDrop'.static.CreateLootDrop(NewGameState, LootItems, TargetUnit, false);
				bLootCreated = true;
			}
		}
	}

	// Refund charge cost if no loot was created.
	if (!bLootCreated)
	{
		AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
		AbilityState.iCharges++;
	}
	return NewGameState;
}

static final function array<XComGameState_Item> MakeAvailableLoot(XComGameState ModifyGameState, LootResults PendingLoot)
{
	local X2ItemTemplateManager		ItemTemplateManager;
	local X2ItemTemplate			ItemTemplate;
	local XComGameState_Item		NewItem;
	local XComGameState_Item		SearchItem;
	local array<XComGameState_Item> CreatedLoots;
	local name LootName;
	local bool bStacked;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CreatedLoots.Length = 0; // Avoid compiler warning.
	foreach PendingLoot.LootToBeCreated(LootName)
	{		
		ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
		if (ItemTemplate != none)
		{
			bStacked = false;
			if (ItemTemplate.MaxQuantity > 1)
			{
				foreach CreatedLoots(SearchItem)
				{
					if (SearchItem.GetMyTemplate() == ItemTemplate)
					{
						if (SearchItem.Quantity < ItemTemplate.MaxQuantity)
						{
							SearchItem.Quantity++;
							bStacked = true;
							break;
						}
					}
				}
				if (bStacked)
				{
					continue;
				}
				else
				{
					NewItem = ItemTemplate.CreateInstanceFromTemplate(ModifyGameState);
					`LOG("Generated loot item:" @ NewItem.GetMyTemplateName(),, 'IRITEST');
					CreatedLoots.AddItem(NewItem);
				}
			}	
			else
			{
				NewItem = ItemTemplate.CreateInstanceFromTemplate(ModifyGameState);
				`LOG("Generated loot item:" @ NewItem.GetMyTemplateName(),, 'IRITEST');
				CreatedLoots.AddItem(NewItem);
			}			
		}
	}
	return CreatedLoots;
}



static function X2AbilityTemplate IRI_TunnelingClaws()
{
	local X2AbilityTemplate						Template;	
	local X2Effect_PersistentTraversalChange	TraversalChange;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TunnelingClaws');

	//	Icon setup
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY; //	Same as Heavy Weapons

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_TunnelingClaws";

	//	Targeting and Triggering
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	Template.AbilityCosts.AddItem(default.FreeActionCost);
	AddCooldown(Template, GetConfigInt('IRI_TunnelingClaws_Cooldown'));

	//	Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	
	TraversalChange = new class'X2Effect_PersistentTraversalChange';
	TraversalChange.BuildPersistentEffect(1, false,,, eGameRule_PlayerTurnEnd);
	TraversalChange.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	TraversalChange.AddTraversalChange(eTraversal_BreakWall, true);
	TraversalChange.EffectName = 'IRI_TunnelingClaws_Effect';
	TraversalChange.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(TraversalChange);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.Hostility = eHostility_Neutral;

	Template.bFrameEvenWhenUnitIsHidden = true;

	return Template;	
}

static function X2AbilityTemplate IRI_ToxinAptitude()
{
	local X2AbilityTemplate			Template;	
	local X2Effect_ToxinAptitude	ToxinAptitude;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_ToxinAptitude');

	//	Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_ToxinAptitude";
	SetPassive(Template);

	ToxinAptitude = new class'X2Effect_ToxinAptitude';
	ToxinAptitude.BuildPersistentEffect(1, true);
	ToxinAptitude.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	ToxinAptitude.DamageModifier = GetConfigFloat('IRI_ToxinAptitude_DamageModifier');
	Template.AddTargetEffect(ToxinAptitude);

	return Template;	
}

static function X2AbilityTemplate IRI_TunnelRat()
{
	local X2AbilityTemplate				Template;	
	local X2Effect_PersistentStatChange	StatChange;
	local X2Condition_AllowedPlots		AllowedPlots;
	local X2Effect_Persistent			IconEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TunnelRat');

	//	Icon setup
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///IRIPerkPack_UILibrary.UIPerk_TunnelRat";
	SetPassive(Template);

	IconEffect = new class'X2Effect_Persistent';
	IconEffect.BuildPersistentEffect(1, true);
	IconEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true);
	Template.AddTargetEffect(IconEffect);

	StatChange = new class 'X2Effect_PersistentStatChange';
	StatChange.BuildPersistentEffect(1, true);
	StatChange.AddPersistentStatChange(eStat_Mobility, GetConfigInt('IRI_TunnelRat_MobilityBonus'));
	StatChange.AddPersistentStatChange(eStat_DetectionModifier, GetConfigFloat('IRI_TunnelRat_DetectionModifier'));

	AllowedPlots = new class'X2Condition_AllowedPlots';
	//AllowedPlots.AllowedPlots.AddItem("Shanty");
	//AllowedPlots.AllowedPlots.AddItem("Slums");
	AllowedPlots.AllowedPlots.AddItem("Tunnels_Subway");
	AllowedPlots.AllowedPlots.AddItem("Tunnels_Sewer");
	//AllowedPlots.AllowedPlots.AddItem("Abandoned");
	StatChange.TargetConditions.AddItem(AllowedPlots);

	Template.AddTargetEffect(StatChange);

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