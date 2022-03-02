class X2Ability_PerkPack extends X2Ability config(IridarPerkPack);

struct PerkPackConfigStruct
{
	var name P;
	var string V;
	var array<string> VA;
};
var private config array<PerkPackConfigStruct> PerkPackConfig;
var private config array<WeaponDamageValue> AbilityDamage;


final static function bool GetConfigBool(name Property, optional bool bDefaultValue = false)
{
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		return bool(default.PerkPackConfig[Index].V);
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
	`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');

	return bDefaultValue;
}

final static function int GetConfigInt(name Property)
{
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		return int(default.PerkPackConfig[Index].V);
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
	`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');

	return 0;
}

final static function float GetConfigFloat(name Property)
{
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		return float(default.PerkPackConfig[Index].V);
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
	`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');

	return 0;
}

final static function name GetConfigName(name Property)
{
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		return name(default.PerkPackConfig[Index].V);
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
	`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');

	return '';
}

final static function string GetConfigString(name Property)
{
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		return default.PerkPackConfig[Index].V;
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
	`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');

	return "";
}

final static function array<int> GetConfigArrayInt(name Property)
{
	local array<string> StringArray;
	local array<int> ReturnArray;
	local int Index;

	Index = default.PerkPackConfig.Find('P', Property);
	if (Index != INDEX_NONE)
	{
		StringArray = default.PerkPackConfig[Index].VA;
		for (Index = 0; Index < StringArray.Length; Index++)
		{
			ReturnArray.AddItem(int(StringArray[Index]));
		}
	}
	else
	{
		`LOG("WARNING ::" @ GetFuncName() @ "Failed to find Perk Pack Config for Property:" @ Property,, 'WOTCIridarPerkPack');
		`LOG(GetScriptTrace(),, 'WOTCIridarPerkPack');
	}

	return ReturnArray;
}

final static function int GetArrayMaxInt(const array<int> IntArray)
{
	local int Max;
	local int Val;

	foreach IntArray(Val)
	{
		if (Val > Max)
		{
			Max = Val;
		}
	}
	return Max;
}


final static function WeaponDamageValue GetAbilityDamage(name AbilityName)
{
	local WeaponDamageValue EmptyDamageValue;
	local int Index;

	Index = default.AbilityDamage.Find('Tag', AbilityName);
	if (Index != INDEX_NONE)
	{
		return default.AbilityDamage[Index];
	}

	`LOG("WARNING ::" @ GetFuncName() @ "Failed to find AbilityDamage for ability:" @ AbilityName,, 'WOTCIridarPerkPack');

	EmptyDamageValue.Damage = 0;
	return EmptyDamageValue;
}

//	========================================
//				TRIGGERS
//	========================================

final static function EventListenerReturn FollowUpShot_EventListenerTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Ability			AbilityState;
	local XComGameState_Ability			FollowUpShotAbilityState;
	local XComGameStateContext			FindContext;
    local int							VisualizeIndex;
	local XComGameStateHistory			History;
	local X2AbilityTemplate				AbilityTemplate;
	local X2Effect						Effect;
	local array<X2Effect>				MultiTargetEffects;
	local StateObjectReference			TargetRef;
	local XComGameState_Item			SourceWeapon;
	local X2GrenadeTemplate				GrenadeTemplate;
	local int							Index;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	// Ability State whose activation triggered this Event Listener.
	AbilityState = XComGameState_Ability(EventData);	
	if (AbilityState == none)
		return ELR_NoInterrupt;

	FollowUpShotAbilityState = XComGameState_Ability(CallbackData);
	if (FollowUpShotAbilityState == none ||
		FollowUpShotAbilityState.SourceWeapon != AbilityState.SourceWeapon ||
		AbilityContext.InputContext.AbilityTemplateName == FollowUpShotAbilityState.GetMyTemplateName()) // Prevent inception
		return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;

	// Trigger FollowUpShot against primary target of the triggering ability, if it exists and the ability is capable of dealing damage, and the ability hit.
	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != 0 && AbilityContext.IsResultContextHit())
	{
		foreach AbilityTemplate.AbilityTargetEffects(Effect)
		{
			if (Effect.bAppliesDamage)
			{
				//	Calculate Visualize Index for later use by FollowUpShot's Merge Vis Fn.
				VisualizeIndex = GameState.HistoryIndex;
				FindContext = AbilityContext;
				while (FindContext.InterruptionHistoryIndex > -1)
				{
					FindContext = History.GetGameStateFromHistory(FindContext.InterruptionHistoryIndex).GetContext();
					VisualizeIndex = FindContext.AssociatedState.HistoryIndex;
				}

				FollowUpShotAbilityState.AbilityTriggerAgainstSingleTarget(AbilityContext.InputContext.PrimaryTarget, false, VisualizeIndex);		
				break;
			}
		}
	}

	// Same for each multi target, if the ability can target multiple units.
	if (AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		// First find the array of multi target effects to check if any of them apply damage.
		if (AbilityTemplate.bUseLaunchedGrenadeEffects)
		{
			SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if (SourceWeapon != none)
			{
				GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetLoadedAmmoTemplate(AbilityState));
				if (GrenadeTemplate != none)
				{
					MultiTargetEffects = GrenadeTemplate.LaunchedGrenadeEffects;
				}
			}
		}
		else if (AbilityTemplate.bUseThrownGrenadeEffects)
		{
			SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if (SourceWeapon != none)
			{
				GrenadeTemplate = X2GrenadeTemplate(SourceWeapon.GetMyTemplate());
				if (GrenadeTemplate != none)
				{
					MultiTargetEffects = GrenadeTemplate.ThrownGrenadeEffects;
				}
			}
		}
		else
		{
			MultiTargetEffects = AbilityTemplate.AbilityMultiTargetEffects;
		}
		
		// If ability is capable of dealing damage to multi targets,
		foreach MultiTargetEffects(Effect)
		{
			if (Effect.bAppliesDamage)
			{
				// Trigger FollowUpShot against every multi target, if that target was hit.
				foreach AbilityContext.InputContext.MultiTargets(TargetRef, Index)
				{
					if (AbilityContext.IsResultContextMultiHit(Index))
					{
						// Find index if it wasn't found earlier
						if (VisualizeIndex == 0)
						{
							VisualizeIndex = GameState.HistoryIndex;
							FindContext = AbilityContext;
							while (FindContext.InterruptionHistoryIndex > -1)
							{
								FindContext = History.GetGameStateFromHistory(FindContext.InterruptionHistoryIndex).GetContext();
								VisualizeIndex = FindContext.AssociatedState.HistoryIndex;
							}
						}
						FollowUpShotAbilityState.AbilityTriggerAgainstSingleTarget(TargetRef, false, VisualizeIndex);		
					}
				}
				break;
			}
		}
	}
	return ELR_NoInterrupt;
}

//	========================================
//				VISUALIZATION
//	========================================

// Typical BuildVis, but with Damage Terrain actions being replaced with custom versions that do not flinch nearby units.
final static function FollowUpShot_BuildVisualization(XComGameState VisualizeGameState)
{	
	local XComGameStateVisualizationMgr		VisMgr;
	local XComGameStateContext_Ability		AbilityContext;
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local X2Action							ChildAction;
	local VisualizationActionMetadata		ActionMetadata;
	local X2Action_MarkerNamed				EmptyAction;
	local X2Action_ApplyWeaponDamageToTerrain			DamageTerrainAction;
	local X2Action_ApplyWeaponDamageToTerrain_NoFlinch	NoFlinchAction;

	TypicalAbility_BuildVisualization(VisualizeGameState);

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToTerrain', FindActions);

	foreach FindActions(FindAction)
	{
		DamageTerrainAction = X2Action_ApplyWeaponDamageToTerrain(FindAction);
		ActionMetadata = DamageTerrainAction.Metadata;

		NoFlinchAction = X2Action_ApplyWeaponDamageToTerrain_NoFlinch(class'X2Action_ApplyWeaponDamageToTerrain_NoFlinch'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, DamageTerrainAction.ParentActions));

		foreach DamageTerrainAction.ChildActions(ChildAction)
		{
			VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, NoFlinchAction);
		}

		// Nuke the original action out of the tree.
		EmptyAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		EmptyAction.SetName("ReplaceDamageTerrainAction");
		VisMgr.ReplaceNode(EmptyAction, DamageTerrainAction);
	}
}

final static function FollowUpShot_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local array<X2Action>					FindActions;
	local X2Action							FindAction;
	local X2Action							FireAction;
	local X2Action_MarkerTreeInsertBegin	MarkerStart;
	local X2Action_MarkerTreeInsertEnd		MarkerEnd;
	local X2Action							WaitAction;
	local X2Action							ChildAction;
	local X2Action_MarkerNamed				MarkerAction;
	local array<X2Action>					MarkerActions;
	local array<X2Action>					DamageUnitActions;
	local array<X2Action>					DamageTerrainActions;
	local XComGameStateContext_Ability		AbilityContext;
	local VisualizationActionMetadata		ActionMetadata;
	local bool								bFoundHistoryIndex;

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);
	
	//	Find all Fire Actions in the triggering ability's Vis Tree performed by the unit that used the FollowUpShot.
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_Fire', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
	
	// Find all Damage Unit / Damage Terrain actions in the triggering ability visualization tree that are playing on the primary target of the follow up shot.
	// Damage Terrain actions play the damage flyover for damageable non-unit objects, like Alien Relay.
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToUnit', DamageUnitActions,, AbilityContext.InputContext.PrimaryTarget.ObjectID);
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToTerrain', DamageTerrainActions,, AbilityContext.InputContext.PrimaryTarget.ObjectID);

	// If there are several Fire Actions in the triggering ability tree (e.g. Faceoff), we need to find the right Fire Action that fires at the same target this instance of Follow Up Shot was fired at.
	// This info is not stored in the Fire Action itself, so we find the needed Fire Action by looking at its children Damage Unit / Damage Terrain actions,
	// as well as the visualization index recorded in FollowUpShot's context by its ability trigger.
	foreach FindActions(FireAction)
	{
		if (FireAction.StateChangeContext.AssociatedState.HistoryIndex == AbilityContext.DesiredVisualizationBlockIndex)
		{	
			foreach FireAction.ChildActions(ChildAction)
			{
				if (DamageTerrainActions.Find(ChildAction) != INDEX_NONE)
				{
					bFoundHistoryIndex = true;
					break;
				}
				if (DamageUnitActions.Find(ChildAction) != INDEX_NONE)
				{
					bFoundHistoryIndex = true;
					break;
				}
			}
		}

		if (bFoundHistoryIndex)
				break;
	}

	// If we didn't find the correct Fire Action, we call the failsafe Merge Vis Function,
	// which will make both Singe's Target Effects apply seperately after the triggering ability's visualization finishes.
	if (!bFoundHistoryIndex)
	{
		`LOG("WARNING ::" @ GetFuncName() @ "Failed to find the correct Fire Action, using a failsafe.",, 'WOTCIridarPerkPack');
		AbilityContext.SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
		return;
	}

	// Find the start and end of the FollowUpShot's Vis Tree
	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	MarkerEnd = X2Action_MarkerTreeInsertEnd(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd'));

	// Will need these later to tie the shoelaces.
	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', MarkerActions);

	//	Add a Wait For Effect Action after the triggering ability's Fire Action. This will allow Singe's Effects to visualize the moment the triggering ability connects with the target.
	ActionMetaData = FireAction.Metadata;
	WaitAction = class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetaData, AbilityContext, false, FireAction);

	//	Insert the Singe's Vis Tree right after the Wait For Effect Action
	VisMgr.ConnectAction(MarkerStart, VisualizationTree, false, WaitAction);

	// Main part of Merge Vis is done, now we just tidy up the ending part. 
	// As I understood from MrNice, this is necessary to make sure Vis will look fine if Fire Action ends before Singe finishes visualizing
	// Cycle through Marker Actions we got earlier and find the 'Join' Marker that comes after the Triggering Shot's Fire Action.
	foreach MarkerActions(FindAction)
	{
		MarkerAction = X2Action_MarkerNamed(FindAction);

		if (MarkerAction.MarkerName == 'Join' && MarkerAction.StateChangeContext.AssociatedState.HistoryIndex == AbilityContext.DesiredVisualizationBlockIndex)
		{
			//	TBH can't imagine circumstances where MarkerEnd wouldn't exist, but okay
			if (MarkerEnd != none)
			{
				//	"tie the shoelaces". Vis Tree won't move forward until both Singe Vis Tree and Triggering Shot's Fire action are fully visualized.
				VisMgr.ConnectAction(MarkerEnd, VisualizationTree,,, MarkerAction.ParentActions);
				VisMgr.ConnectAction(MarkerAction, BuildTree,, MarkerEnd);
			}
			else
			{
				VisMgr.GetAllLeafNodes(BuildTree, FindActions);
				VisMgr.ConnectAction(MarkerAction, BuildTree,,, FindActions);
			}
			break;
		}
	}
}

//	========================================
//				COMMON CODE
//	========================================

static function AddCooldown(out X2AbilityTemplate Template, int Cooldown, optional bool bGlobal = false)
{
	local X2AbilityCooldown					AbilityCooldown;
	local X2AbilityCooldown_LocalAndGlobal	GlobalCooldown;

	if (Cooldown > 0)
	{
		if (bGlobal)
		{
			GlobalCooldown = new class'X2AbilityCooldown_LocalAndGlobal';
			GlobalCooldown.iNumTurns = Cooldown;
			GlobalCooldown.NumGlobalTurns = Cooldown;
			Template.AbilityCooldown = GlobalCooldown;
		}
		else
		{	
			AbilityCooldown = new class'X2AbilityCooldown';
			AbilityCooldown.iNumTurns = Cooldown;
			Template.AbilityCooldown = AbilityCooldown;
		}
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

static final function RemoveActionsOfClass(XComGameStateVisualizationMgr VisMgr, class<X2Action> ActionClass, X2Action SearchTree, optional Actor Visualizer, optional int ObjectID)
{
	local X2Action_MarkerNamed	ReplaceAction;	
	local array<X2Action>		FindActions;
	local X2Action				FindAction;

	VisMgr.GetNodesOfType(SearchTree, ActionClass, FindActions, Visualizer, ObjectID);
	foreach FindActions(FindAction)
	{
		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', FindAction.StateChangeContext));
		ReplaceAction.SetName("ReplaceActionStub");
		VisMgr.ReplaceNode(ReplaceAction, FindAction);
	}
}