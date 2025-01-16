//  FILE:    Help.uc
//  AUTHOR:  Iridar  --  20/04/2022
//  PURPOSE: Helper class for static functions and script snippet repository.     
//---------------------------------------------------------------------------------------

class Help extends Object abstract config(Game);

var config bool bLog;

/*

### Creating and Submitting a Game State

local XComGameState NewGameState;

NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Optional Debug Comment");

`GAMERULES.SubmitGameState(NewGameState);

### Random Number Generation

FRand() returns a random `float` value from the [0; 1] range. 
int(x * FRand()) - returns a random `int` value from [0; x] range.

FRand() can only return 32 768 distinct results. (c) robojumper

`SYNC_FRAND() - returns a random `flaot` value from [0; 1) range
`SYNC_FRAND_STATIC()

`SYNC_RAND(x) - returns a random `int` value from [0; x) range.
`SYNC_RAND_STATIC(x)

`SYNC_VRAND() - returns a random `vector`, each component of the vector will have value from (-1; 1) range.
`SYNC_VRAND_STATIC()

`SYNC_VRAND() * x - return a random `vector` where each component is from the (-x; x) range.

### Action Points

class'X2CharacterTemplateManager'.default.StandardActionPoint
class'X2CharacterTemplateManager'.default.MoveActionPoint
class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint
class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint
class'X2CharacterTemplateManager'.default.GremlinActionPoint
class'X2CharacterTemplateManager'.default.RunAndGunActionPoint
class'X2CharacterTemplateManager'.default.EndBindActionPoint
class'X2CharacterTemplateManager'.default.GOHBindActionPoint
class'X2CharacterTemplateManager'.default.CounterattackActionPoint
class'X2CharacterTemplateManager'.default.UnburrowActionPoint
class'X2CharacterTemplateManager'.default.ReturnFireActionPoint
class'X2CharacterTemplateManager'.default.DeepCoverActionPoint
class'X2CharacterTemplateManager'.default.MomentumActionPoint
class'X2CharacterTemplateManager'.default.SkirmisherInterruptActionPoint


### Ability Icon Colors

'eAbilitySource_Perk': yellow
'eAbilitySource_Debuff': red
'eAbilitySource_Psionic': purple
'eAbilitySource_Commander': green 
'eAbilitySource_Item': blue 
'eAbilitySource_Standard': blue

### Persistent Effects applied to Units

if (UnitState.IsUnitAffectedByEffectName('NameOfTheEffect'))
{
    // Do stuff
}

# Get an effect's Effect State from unit

local XComGameState_Effect EffectState;

EffectState = UnitState.GetUnitAffectedByEffectState('NameOfTheEffect');

if (EffectState != none)
{
    // Do stuff
}

# Iterate over all effects on unit

local StateObjectReference EffectRef;
local XComGameStateHistory History;
local XComGameState_Effect EffectState;

History = `XCOMHISTORY;

foreach UnitState.AffectedByEffects(EffectRef)
{
    EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

    // Do stuff with EffectState
}


### Working with ClassDefaultObjects

class'XComEngine'.static.GetClassDefaultObject(class SeachClass);
class'XComEngine'.static.GetClassDefaultObjectByName(name ClassName);

// This method will give you an array of CDOs for the specified class and all of its subclasses, in case you need to handle them as well.
class'XComEngine'.static.GetClassDefaultObjects(class SeachClass);

class'Engine'.static.FindClassDefaultObject(string ClassName)

### Check if a Unit can see a Location

local XComGameState_Unit UnitState;
local TTile TileLocation;

if (class'X2TacticalVisibilityHelpers'.static.CanUnitSeeLocation(UnitState.ObjectID, TileLocation))
{
    // Do stuff
}

### Modnames of commonly required mods

PrototypeArmoury
CovertInfiltration
LongWarOfTheChosen
XCOM2RPGOverhaul
X2WOTCCommunityPromotionScreen
WOTCIridarTemplateMaster
PrimarySecondaries
TruePrimarySecondaries
DualWieldedPistols
WOTC_LW2SecondaryWeapons

*/

static final function XComGameState_HeadquartersXCom GetAndPrepXComHQ(XComGameState NewGameState)
{
    local XComGameState_HeadquartersXCom XComHQ;

    foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
    {
        break;
    }

    if (XComHQ == none)
    {
        XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
        XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
    }

    return XComHQ;
}

static final function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}

static final function bool AreModsActive(const array<name> ModNames)
{
	local name ModName;

	foreach ModNames(ModName)
	{
		if (!IsModActive(ModName))
		{
			return false;
		}
	}
	return true;
}

static final function bool IsInStrategy()
{
    return `HQPRES != none;
}

static final function bool ReallyIsInStrategy()
{
	return `HQGAME  != none && `HQPC != None && `HQPRES != none;
}

// Sound managers don't exist in Shell, have to do it by hand.
static final function PlayStrategySoundEvent(string strKey, Actor InActor)
{
	local string	SoundEventPath;
	local AkEvent	SoundEvent;

	foreach class'XComStrategySoundManager'.default.SoundEventPaths(SoundEventPath)
	{
		if (InStr(SoundEventPath, strKey) != INDEX_NONE)
		{
			SoundEvent = AkEvent(`CONTENT.RequestGameArchetype(SoundEventPath));
			if (SoundEvent != none)
			{
				InActor.WorldInfo.PlayAkEvent(SoundEvent);
				return;
			}
		}
	}
}

// For using hex color.
static function string ColourText(string strValue, string strColour)
{
	return "<font color='#" $ strColour $ "'>" $ strValue $ "</font>";
}





static final function int GetForceLevel()
{
	local XComGameStateHistory		History;
	local XComGameState_BattleData	BattleData;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));
	if (BattleData == none)
	{
		`AMLOG("WARNING :: No Battle Data!" @ GetScriptTrace());
		return -1;
	}

	return BattleData.GetForceLevel();
}

static final function AddItemToHQInventory(const name TemplateName)
{
    local XComGameState						NewGameState;
    local XComGameState_HeadquartersXCom    XComHQ;
    local XComGameState_Item                ItemState;
    local X2ItemTemplate                    ItemTemplate;
    local X2ItemTemplateManager				ItemMgr;

    ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();    

    ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);

    if (ItemTemplate != none)
    {
        NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding item to HQ Inventory");
        XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', `XCOMHQ.ObjectID));

        ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);     

		// XComHQ.PutItemInInventory() is unable to work with infinite items. Use XComHQ.AddItemToHQInventory(ItemState) for those.		
        XComHQ.PutItemInInventory(NewGameState, ItemState);
        `GAMERULES.SubmitGameState(NewGameState);
    }
}


// Get Bond Level between two soldiers
static final function int GetBondLevel(const XComGameState_Unit SourceUnit, const XComGameState_Unit TargetUnit)
{
    local SoldierBond BondInfo;

    if (SourceUnit.GetBondData(SourceUnit.GetReference(), BondInfo))
    {
        if (BondInfo.Bondmate.ObjectID == TargetUnit.ObjectID)
        {
            return BondInfo.BondLevel;
        }
    }
    return 0;
}

// Check if a Unit has a Weapon of specified WeaponCategory equipped
static final function bool HasWeaponOfCategory(const XComGameState_Unit UnitState, const name WeaponCat, optional XComGameState CheckGameState)
{
    local XComGameState_Item Item;
    local StateObjectReference ItemRef;

    foreach UnitState.InventoryItems(ItemRef)
    {
        Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

        if (Item != none && Item.GetWeaponCategory() == WeaponCat)
        {
            return true;
        }
    }

    return false;
}

// Similar check, but also for a specific slot:
static final function bool HasWeaponOfCategoryInSlot(const XComGameState_Unit UnitState, const name WeaponCat, const EInventorySlot Slot, optional XComGameState CheckGameState)
{
    local XComGameState_Item Item;
    local StateObjectReference ItemRef;

    foreach UnitState.InventoryItems(ItemRef)
    {
        Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

        if (Item != none && Item.GetWeaponCategory() == WeaponCat && Item.InventorySlot == Slot)
        {
            return true;
        }
    }
    return false;
}

// Check if a Unit has one of the specified items equipped
static final function bool UnitHasItemEquipped(const XComGameState_Unit UnitState, const array<name> ItemNames, optional XComGameState CheckGameState)
{
    local XComGameState_Item Item;
    local StateObjectReference ItemRef;

    foreach UnitState.InventoryItems(ItemRef)
    {
        Item = UnitState.GetItemGameState(ItemRef, CheckGameState);

        if (Item != none && ItemNames.Find(Item.GetMyTemplateName()) != INDEX_NONE)
        {
            return true;
        }
    }

    return false;
}

static final function int TileDistanceBetweenUnitAndTile(const XComGameState_Unit UnitState, const TTile TileLocation)
{
	local XComWorldData WorldData;
	local vector UnitLoc, TargetLoc;
	local float Dist;
	local int Tiles;

	if (UnitState.TileLocation == TileLocation)
		return 0;

	WorldData = `XWORLD;
	UnitLoc = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);
	TargetLoc = WorldData.GetPositionFromTileCoordinates(TileLocation);
	Dist = VSize(UnitLoc - TargetLoc);
	Tiles = Dist / WorldData.WORLD_StepSize;

	return Tiles;
}

// Calculate Tile Distance Between Tiles
static final function int GetTileDistanceBetweenTiles(const TTile TileA, const TTile TileB) 
{
	local XComWorldData WorldData;
	local vector LocA;
	local vector LocB;
	local float Dist;
	local int TileDistance;

	WorldData = `XWORLD;
	LocA = WorldData.GetPositionFromTileCoordinates(TileA);
	LocB = WorldData.GetPositionFromTileCoordinates(TileB);

	Dist = VSize(LocA - LocB);
	TileDistance = Dist / WorldData.WORLD_StepSize;
	
	return TileDistance;
}

// Rank = 0 for Squaddie
// Note: ModifyEarnedSoldierAbilities DLC hook is usually better for non-temporary ability granting.
static function GiveSoldierAbilityToUnit(const name AbilityName, const int Rank, XComGameState_Unit UnitState, XComGameState NewGameState)
{	
	local SoldierClassAbilityType AbilityStruct;
	local int Index;

	AbilityStruct.AbilityName = AbilityName;
	UnitState.AbilityTree[Rank].Abilities.AddItem(AbilityStruct);

	Index = UnitState.AbilityTree[Rank].Abilities.Length - 1;

	UnitState.BuySoldierProgressionAbility(NewGameState, Rank, Index, 0); // 0 = ability points cost
}

/*
The GetLocalizedString() function is a helper with the purpose similar to that of the Config Engine:
make using localized strings more convenient without having to explicitly declare localized them as variables.

It relies on using Localize() function, which probably is far from optimal in terms of performance,
so you probably shouldn't use it *too much*, especially in performance-sensitive code.

Set localized value:

# Setting: 

WOTCIridarPerkPack.int
[Help]
StringName = "Wow fancy localized string!"

# Getting: 

YourString = class'Help'.static.GetLocalizedString('StringName');

Or with global macro for brevity:

YourString = `GetLocalizedString('StringName');

*/
static final function string GetLocalizedString(const coerce string StringName)
{
	return Localize("Help", StringName, "WOTCIridarPerkPack");
}

final static function EventListenerReturn FollowUpShot_EventListenerTrigger_CritOnly(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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
		//FollowUpShotAbilityState.SourceWeapon != AbilityState.SourceWeapon ||
		AbilityContext.InputContext.AbilityTemplateName == FollowUpShotAbilityState.GetMyTemplateName()) // Prevent inception
		return ELR_NoInterrupt;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	
	// Trigger FollowUpShot against primary target of the triggering ability, if it exists and the ability is capable of dealing damage, and the ability hit.
	if (AbilityContext.InputContext.PrimaryTarget.ObjectID != 0 && AbilityContext.ResultContext.HitResult == eHit_Crit)
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
					if (AbilityContext.ResultContext.MultiTargetHitResults[Index] == eHit_Crit)
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

	class'X2Ability'.static.TypicalAbility_BuildVisualization(VisualizeGameState);

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


static final function InsertAfterMarker_MergeVisualization(X2Action BuildTree, out X2Action VisualizationTree, const name MarkerName)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local XComGameStateContext_Ability		AbilityContext;
	local array<X2Action>					FoundActions;
	local X2Action							FoundAction;
	local X2Action_MarkerNamed				NamedMarker;
	local X2Action_MarkerTreeInsertBegin	MarkerStart;
	local X2Action_MarkerTreeInsertEnd		MarkerEnd;

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(BuildTree.StateChangeContext);

	VisMgr.GetNodesOfType(VisualizationTree, class'X2Action_MarkerNamed', FoundActions,, AbilityContext.InputContext.SourceObject.ObjectID);

	MarkerStart = X2Action_MarkerTreeInsertBegin(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin'));
	MarkerEnd = X2Action_MarkerTreeInsertEnd(VisMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd'));

	if (MarkerStart != none && MarkerEnd != none)
	{
		foreach FoundActions(FoundAction)
		{
			NamedMarker = X2Action_MarkerNamed(FoundAction);
			if (NamedMarker.MarkerName == MarkerName)
			{
				VisMgr.InsertSubtree(MarkerStart, MarkerEnd, NamedMarker);
				return;
			}
		}
	}

	// Fallback to generic merge vis in case something goes wrong
	XComGameStateContext_Ability(BuildTree.StateChangeContext).SuperMergeIntoVisualizationTree(BuildTree, VisualizationTree);
}
