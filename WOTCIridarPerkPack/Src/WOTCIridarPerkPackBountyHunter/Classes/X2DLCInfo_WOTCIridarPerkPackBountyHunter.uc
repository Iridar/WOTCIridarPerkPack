class X2DLCInfo_WOTCIridarPerkPackBountyHunter extends X2DownloadableContentInfo;

var privatewrite config bool bLWOTC;

var private SkeletalMeshSocket ShadowTeleportSocket;
var private SkeletalMeshSocket SoulShotFireSocket;
var private SkeletalMeshSocket SoulShotWeaponSocket;
var private SkeletalMeshSocket SoulShotHitSocket;
var private SkeletalMeshSocket InvenRHandCopySocket; // Used by Rifle Grenade and something else.

static function OnPreCreateTemplates()
{
	default.bLWOTC = class'Help'.static.IsModActive('LongWarOfTheChosen') || class'Help'.static.IsModActive('LWAimRolls');
}

static function string DLCAppendSockets(XComUnitPawn Pawn)
{
	local array<SkeletalMeshSocket> NewSockets;

	NewSockets.AddItem(default.ShadowTeleportSocket);
	NewSockets.AddItem(default.SoulShotHitSocket);
	NewSockets.AddItem(default.SoulShotFireSocket);
	NewSockets.AddItem(default.InvenRHandCopySocket);

	Pawn.Mesh.AppendSockets(NewSockets, true);

	return "";
}

static function DLCAppendWeaponSockets(out array<SkeletalMeshSocket> NewSockets, XComWeapon Weapon, XComGameState_Item ItemState)
{
	local SkeletalMeshSocket NewSocket;
	local SkeletalMeshSocket ExistingSocket;

	// For Soul Shot
	if (ItemState.GetWeaponCategory() == 'gauntlet')
	{
		foreach SkeletalMeshComponent(Weapon.Mesh).Sockets(ExistingSocket)
		{
			NewSocket = new class'SkeletalMeshSocket';
			NewSocket.SocketName = 'IRI_SoulBow_Fire';
			NewSocket.BoneName = ExistingSocket.BoneName;
			NewSockets.AddItem(NewSocket);
			return;
		}
	}
}

// Bounty Hunter - Rifle Grenade - must be assigned to a weapon, otherwise fails to work, but game's own logic reassigns it to grenades.
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local XComGameState_Item PrimaryWeapon;
	local int i;

	PrimaryWeapon = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, StartState);
	if (PrimaryWeapon == none)
		return;

	for (i = SetupData.Length - 1; i >= 0; i--)
	{
		if (SetupData[i].TemplateName == 'IRI_BH_RifleGrenade')
		{
			SetupData[i].SourceWeaponRef = PrimaryWeapon.GetReference();
		}
	}
}

static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseOb, XComGameState GameState)
{	// 	`AMLOG(ParseObj.Class.Name @ StrategyParseOb.Class.Name);
	// In strategy (ability description): WOTCIridarPerkPack: AbilityTagExpandHandler_CH X2AbilityTemplate XComGameState_Unit
	// In tactical (ability description): WOTCIridarPerkPack: AbilityTagExpandHandler_CH X2AbilityTemplate none (big oof)
	switch (InString)
	{

	case "IRI_BoundWeaponName":
		OutString = GetBoundWeaponName(ParseObj, StrategyParseOb, GameState);
		return true;
	// ======================================================================================================================
	//												BOUNTY HUNTER TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_TAG_BH_Headhunter_Bonuses":
		OutString = BHColor(GetHeadhunterBonusValues(XComGameState_Unit(StrategyParseOb)));
		return true;

	//case "IRI_TAG_BH_Handcannon_Ammo":
	//	OutString = BHColor(GetSecondaryWeaponClipSize(XComGameState_Unit(StrategyParseOb), GameState));
	//	return true;

	case "IRI_BH_Nightfall_Cooldown":
	case "IRI_BH_Nightfall_Duration":
	case "IRI_BH_ShadowTeleport_Cooldown":
	case "IRI_BH_ShadowTeleport_Tile_Radius":
	case "IRI_BH_Nightmare_AimBonus":
	case "IRI_BH_DoublePayload_NumBonusCharges":
	case "IRI_BH_BurstFire_Cooldown":
	case "IRI_BH_UnrelentingPressure_CooldownReduction":
	case "IRI_BH_UnrelentingPressure_CooldownReductionPassive":
	case "IRI_BH_BlindingFire_DurationTurns":
	case "IRI_BH_Terminate_Charges":
	case "IRI_BH_ShadowTeleport_Charges":
	case "IRI_BH_NamedBullet_Charges":
	case "IRI_BH_BurstFire_AmmoCost":
	case "IRI_BH_BurstFire_NumShots":
	case "IRI_BH_Untraceable_CooldownReduction":
	case "IRI_BH_HomingMine_Charges":
	case "IRI_BH_RifleGrenade_RangeIncrase_Tiles":
		OutString = BHColor(`GetConfigInt(InString));
		return true;

	case "IRI_BH_BigGameHunter_CritBonus":
	case "IRI_BH_Nightfall_CritDamageBonusPerCritChanceOverflow":
	case "IRI_BH_Nightfall_CritChanceBonusWhenUnseen":
	case "IRI_BH_NightRounds_CritBonus":
	case "IRI_BH_Headhunter_CritBonus":
	case "IRI_BH_Nightmare_CritBonus":
	case "IRI_BH_RifleGrenade_DamageBonusPercent":
		OutString = BHColor(`GetConfigInt(InString) $ "%");
		return true;

	case "IRI_BH_DoublePayload_BonusDamage":
	case "IRI_BH_BurstFire_SquadSightPenaltyModifier":
		OutString = BHColor(GetPercentValue(InString) $ "%");
		return true;

	case "IRI_BH_HomingMine_Damage":
		OutString = BHColor(`GetConfigDamage("IRI_BH_HomingMine_Damage").Damage);
		return true;
	case "IRI_BH_HomingMine_Shred":
		OutString = BHColor(`GetConfigDamage("IRI_BH_HomingMine_Damage").Shred);
		return true;

	// ======================================================================================================================
	//												REAPER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "IRI_RP_Takedown_Damage":
		OutString = string(`GetConfigDamage("IRI_RP_Takedown_Damage").Crit);
		return true;

	case "IRI_RP_TakedownCharges":
	case "IRI_RP_WoundingShot_BleedDuration":
	case "IRI_RP_WoundingShot_BleedDamage":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_RP_WoundingShot_MobilityMultiplier":
		OutString = string(int(100 - `GetConfigFloat(InString) * 100));
		return true;
		

	// ======================================================================================================================
	//												SKIRMISHER TAGS
	// ----------------------------------------------------------------------------------------------------------------------

	case "IRI_SK_PredatorStrike_HealthPercent":
		OutString = SKColor(GetPercentValue(InString) $ "%");
		return true;
	case "IRI_SK_PredatorStrike_Cooldown":
		OutString = SKColor(`GetConfigInt(InString));
		return true;

	case "IRI_SK_ThunderLance_DamageBonusPercent":
		OutString = SKColor(GetPercentValue(InString) $ "%");
		return true;
	case "IRI_SK_ThunderLance_RangeIncrase_Tiles":
		OutString = SKColor(`GetConfigInt(InString));
		return true;
		
	// ======================================================================================================================
	//												TEMPLAR TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_TM_SoulShot_Cooldown":
	case "IRI_TM_Obelisk_Duration":
	case "IRI_TM_Obelisk_FocusCost":
	case "IRI_TM_Obelisk_Volt_Distance_Tiles":
	case "IRI_TM_Ghost_FocusCost":
	case "IRI_TM_Ghost_InitialFocus":
	case "IRI_TM_Ghost_InitialActions":
	case "IRI_TM_Deflect_FocusCost":
	case "IRI_TM_Amplify_MinDamageBonus":
	case "IRI_TM_SoulShot_ToHitBonus":
		OutString = TMColor(`GetConfigInt(InString));
		return true;

	case "IRI_TM_Amplify_DamageMult":
		OutString = TMColor(GetPercentValue(InString));
		return true;

	case "IRI_TM_SiphonedEffects":
		OutString = GetSiphonedEffects(ParseObj, StrategyParseOb, GameState);
		return true;

	// ======================================================================================================================
	//												RANGER TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_RN_ZephyrStrike_Cooldown":
		OutString = string(`GetConfigInt(InString));
		return true;

	case "IRI_RN_ZephyrStrike_Radius_Tiles":
		OutString = TruncateFloat(`GetConfigFloat(InString));
		return true;		

	// ======================================================================================================================
	//												SHARPSHOOTER TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_SH_Standoff_Radius_Tiles":
		OutString = TruncateFloat(`GetConfigFloat(InString));
		return true;	

	// ======================================================================================================================
	//												GRENADIER TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_GN_CollateralDamage_AmmoCost":
		OutString = string(`GetConfigInt(InString));
		return true;	
	
	case "IRI_GN_CollateralDamage_DamageMod":
		OutString = string(int((1 + `GetConfigFloat(InString)) * 100));
		return true;	

	// ======================================================================================================================
	//												SPECIALIST TAGS
	// ----------------------------------------------------------------------------------------------------------------------
	case "IRI_SP_ScoutingProtocol_InitCharges":
		OutString = string(`GetConfigInt(InString));
		return true;	
		
		

	// ----------------------------------------------------------------------------------------------------------------------
	default:
		break;
	}

	return false;
}

static private function string TruncateFloat(float value)
{
	local string FloatString, TempString;
	local int i;
	local float TempFloat, TestFloat;

	TempFloat = value;
	for (i = 0; i < 2; i++)
	{
		TempFloat *= 10.0;
	}
	TempFloat = Round(TempFloat);
	for (i=0; i < 2; i++)
	{
		TempFloat /= 10.0;
	}

	TempString = string(TempFloat);
	for (i = InStr(TempString, ".") + 1; i < Len(TempString) ; i++)
	{
		FloatString = Left(TempString, i);
		TestFloat = float(FloatString);
		if (TempFloat ~= TestFloat)
		{
			break;
		}
	}

	if (Right(FloatString, 1) == ".")
	{
		FloatString $= "0";
	}

	return FloatString;
}

static private function string GetSiphonedEffects(Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	local XComGameState_Effect	EffectState;
	local XComGameState_Unit	UnitState;
	local UnitValue		UV;
	local array<string> AppliedEffects;
	local string		RetString;
	local int			i;

	EffectState = XComGameState_Effect(ParseObj);
	if (EffectState != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		if (UnitState != none)
		{
			if (UnitState.GetUnitValue('IRI_TM_Siphon_fire', UV))
			{
				AppliedEffects.AddItem(Locs(class'UIEventNoticesTactical'.default.BurningTitle));
			}
			if (UnitState.GetUnitValue('IRI_TM_Siphon_acid', UV))
			{
				AppliedEffects.AddItem(Locs(class'UIEventNoticesTactical'.default.AcidBurningTitle));
			}
			if (UnitState.GetUnitValue('IRI_TM_Siphon_poison', UV))
			{
				AppliedEffects.AddItem(Locs(class'UIEventNoticesTactical'.default.PoisonedTitle));
			}
			if (UnitState.GetUnitValue('IRI_TM_Siphon_Frost', UV))
			{
				AppliedEffects.AddItem(Locs(class'UIEventNoticesTactical'.default.FrozenTitle));
			}
		}
	}
	if (AppliedEffects.Length == 1)
	{
		return AppliedEffects[0];
	}
	RetString = AppliedEffects[0];
	for (i = 1; i < AppliedEffects.Length; i++)
	{
		RetString $= ", " $ AppliedEffects[i];
	}
	return RetString;
}

static private function string GetBoundWeaponName(Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
	local X2AbilityTemplate		AbilityTemplate;
	local X2ItemTemplate		ItemTemplate;
	local XComGameState_Effect	EffectState;
	local XComGameState_Ability	AbilityState;
	local XComGameState_Item	ItemState;

	AbilityTemplate = X2AbilityTemplate(ParseObj);
	if (StrategyParseObj != none && AbilityTemplate != none)
	{
		ItemTemplate = GetItemBoundToAbilityFromUnit(XComGameState_Unit(StrategyParseObj), AbilityTemplate.DataName, GameState);
	}
	else
	{
		EffectState = XComGameState_Effect(ParseObj);
		if (EffectState != none)
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		}
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
		}

		if (AbilityState != none)
		{
			ItemState = AbilityState.GetSourceWeapon();

			if (ItemState != none)
				ItemTemplate = ItemState.GetMyTemplate();
		}
	}

	if (ItemTemplate != none)
	{
		return ItemTemplate.GetItemAbilityDescName();
	}
	return AbilityTemplate.LocDefaultPrimaryWeapon;
}

static private function X2ItemTemplate GetItemBoundToAbilityFromUnit(XComGameState_Unit UnitState, name AbilityName, XComGameState GameState)
{
	local SCATProgression		Progression;
	local XComGameState_Item	ItemState;
	local EInventorySlot		Slot;

	if (UnitState == none)
		return none;

	Progression = UnitState.GetSCATProgressionForAbility(AbilityName);
	if (Progression.iRank == INDEX_NONE || Progression.iBranch == INDEX_NONE)
		return none;

	Slot = UnitState.AbilityTree[Progression.iRank].Abilities[Progression.iBranch].ApplyToWeaponSlot;
	if (Slot == eInvSlot_Unknown)
		return none;

	ItemState = UnitState.GetItemInSlot(Slot, GameState);
	if (ItemState != none)
	{
		return ItemState.GetMyTemplate();
	}

	return none;
}

static private function string BHColor(coerce string strInput)
{
	return "<font color='#ffd700'>" $ strInput $ "</font>"; // gold
}

static private function string TMColor(coerce string strInput)
{
	return "<font color='#b6b5d4'>" $ strInput $ "</font>"; // light purple
}

static private function string SKColor(coerce string strInput)
{
	return "<font color='#e50000'>" $ strInput $ "</font>"; // deep red
}

static private function string GetPercentValue(string ConfigName)
{
	local int PercentValue;

	PercentValue = `GetConfigFloat(ConfigName) * 100;

	return string(PercentValue);
}

//static private function string GetSecondaryWeaponClipSize(const XComGameState_Unit UnitState, optional XComGameState CheckGameState)
//{
//	local XComGameState_Item ItemState;
//
//	if (UnitState != none)
//	{
//		ItemState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState);
//		if(ItemState != none)
//		{
//			return string(ItemState.GetClipSize());
//		}
//	}
//
//	return "N/A";
//}

static private function string GetHeadhunterBonusValues(const XComGameState_Unit UnitState)
{
	local X2DataTemplate				DataTemplate;
	local X2CharacterTemplate			CharTemplate;
	local array<name>					HandledCharGroups;
	local X2CharacterTemplateManager	CharMgr;
	local string						ReturnString;
	local UnitValue						UV;
	local name							ValuePrefix;

	if (UnitState != none)
	{
		CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		ValuePrefix = class'X2Effect_BountyHunter_Headhunter'.default.UVPrefix;
		foreach CharMgr.IterateTemplates(DataTemplate)
		{
			CharTemplate = X2CharacterTemplate(DataTemplate);
			if (CharTemplate == none)
				continue;

			if (HandledCharGroups.Find(CharTemplate.CharacterGroupName) != INDEX_NONE)
				continue;

			HandledCharGroups.AddItem(CharTemplate.CharacterGroupName);

			if (UnitState.GetUnitValue(name(ValuePrefix $ CharTemplate.CharacterGroupName), UV))
			{
				if (CharTemplate.strCharacterName != "")
				{
					ReturnString $= "<br/>- " $ CharTemplate.strCharacterName $ ": " $ int(UV.fValue * `GetConfigInt('IRI_BH_Headhunter_CritBonus')) $ "%";
				}
				else
				{
					// Fallback to character group in case there's no localized character name. Not ideal, but shouldn't come into play all that often.
					ReturnString $= "<br/>- " $ CharTemplate.CharacterGroupName $ ": " $ int(UV.fValue * `GetConfigInt('IRI_BH_Headhunter_CritBonus')) $ "%";
				}
			}
		}
	}
	if (ReturnString == "")
	{
		ReturnString = " " $ class'UIPhotoboothBase'.default.m_strEmptyOption;
	}
	return ReturnString;
}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	Skirmisher_ThunderLance_PatchOverrideicons();
	Ranger_TacticalAdvance_PatchAbilityCosts();

	// Reaper_PatchShadow(); // Needed for Takedown

	CopyAbilityLocalization('IRI_TM_Aftershock', 'Reverberation');
	CopyAbilityLocalization('IRI_TM_FocusKillTracker', 'FocusKillTracker');
	Templar_PatchMeditationPreparation();
	
	
	//local X2SoldierClassTemplateManager	ClassMgr;
	//local X2SoldierClassTemplate		ClassTemplate;
	//
	//ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	//ClassTemplate = ClassMgr.FindSoldierClassTemplate('IRI_BountyHunter');
	//if (ClassTemplate != none)
	//{
	//	ClassTemplate.CheckSpecialCritLabelFn = BountyHunter_SpecialCritLabelDelegate;
	//}
	//
	/*
	local X2AbilityTemplateManager	AbilityTemplateManager;
    local X2AbilityTemplate			Template;
    local array<X2DataTemplate>		DataTemplates;
    local X2DataTemplate			DataTemplate;
	
	local X2ItemTemplateManager		ItemMgr;
	local X2WeaponTemplate			Template;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    AbilityTemplateManager.FindDataTemplateAllDifficulties('TemplateName', DataTemplates);

    foreach DataTemplates(DataTemplate)
    {
        Template = X2AbilityTemplate(DataTemplate);
        if (Template != none)
        {
            // Make changes to Template
        }
    }
	
	*/
}

// Allows Mentally Awake to work with the new Templar Focus passive.
static private function Templar_PatchMeditationPreparation()
{
	local X2AbilityTemplateManager				AbilityMgr;
	local X2AbilityTemplate						AbilityTemplate;
	local X2AbilityTrigger_OnAbilityActivated	ActivationTrigger;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityMgr.FindAbilityTemplate('MeditationPreparation');
	if (AbilityTemplate == none)	
		return;

	ActivationTrigger = new class'X2AbilityTrigger_OnAbilityActivated';
	ActivationTrigger.SetListenerData('IRI_TM_TemplarFocus');
	AbilityTemplate.AbilityTriggers.AddItem(ActivationTrigger);
}

static private function Reaper_PatchShadow()
{
	local X2AbilityTemplateManager			AbilityMgr;
	local X2AbilityTemplate					AbilityTemplate;
	local X2Effect_Charges					SetCharges;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	SetCharges = new class'X2Effect_Charges';
	SetCharges.AbilityName = 'IRI_RP_Takedown';
	SetCharges.Charges = `GetConfigInt("IRI_RP_TakedownCharges");
	SetCharges.bSetCharges = true;

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('Shadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
	}

	AbilityTemplate = AbilityMgr.FindAbilityTemplate('DistractionShadow');
	if (AbilityTemplate != none)	
	{
		AbilityTemplate.AddTargetEffect(SetCharges);
	}
}

static private function Ranger_TacticalAdvance_PatchAbilityCosts()
{
	local array<X2AbilityTemplate>		AbilityTemplates;
	local X2AbilityTemplate				AbilityTemplate;
	local X2AbilityTemplateManager		AbilityMgr;
	local array<name>					TemplateNames;
	local name							TemplateName;
	local X2AbilityTrigger				Trigger;
	local bool							bInputTriggered;
	local X2AbilityCost					Cost;
	local X2AbilityCost_ActionPoints	ActionPointCost;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityMgr.GetTemplateNames(TemplateNames);
	foreach TemplateNames(TemplateName)
	{
		AbilityMgr.FindAbilityTemplateAllDifficulties(TemplateName, AbilityTemplates);
		foreach AbilityTemplates(AbilityTemplate)
		{
			if (AbilityTemplate.Hostility != eHostility_Offensive)
				continue;

			bInputTriggered = false;
			foreach AbilityTemplate.AbilityTriggers(Trigger)
			{
				if (Trigger.IsA('X2AbilityTrigger_PlayerInput'))
				{
					bInputTriggered = true;
					break;
				}
			}
			if (!bInputTriggered)
				continue;

			if (!AbilityTemplate.TargetEffectsDealDamage(none, none))
				continue;

			foreach AbilityTemplate.AbilityCosts(Cost)
			{
				ActionPointCost = X2AbilityCost_ActionPoints(Cost);
				if (ActionPointCost != none)
				{
					ActionPointCost.DoNotConsumeAllEffects.AddItem('IRI_RN_X2Effect_TacticalAdvance_Effect');
				}
			}
		}
	}
}



static private function Skirmisher_ThunderLance_PatchOverrideicons()
{
	local X2ItemTemplateManager		ItemMgr;
	local X2WeaponTemplate			WeaponTemplate;
	local array<X2WeaponTemplate>	WeaponTemplates;
	local X2GrenadeTemplate			GrenadeTemplate;
	local AbilityIconOverride		IconOverride;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	WeaponTemplates = ItemMgr.GetAllWeaponTemplates();

	foreach WeaponTemplates(WeaponTemplate)
	{	
		GrenadeTemplate = X2GrenadeTemplate(WeaponTemplate);
		if (GrenadeTemplate == none)
			continue;
		
		foreach GrenadeTemplate.AbilityIconOverrides(IconOverride)
		{
			if (IconOverride.AbilityName == 'LaunchGrenade')
			{
				GrenadeTemplate.AddAbilityIconOverride('IRI_SK_ThunderLance', IconOverride.OverrideIcon);
				break;
			}
		}
	}
}

static private function CopyAbilityLocalization(const name AcceptorAbility, const name DonorAbility)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate Template;
	local X2AbilityTemplate DonorTemplate;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = AbilityTemplateManager.FindAbilityTemplate(AcceptorAbility);
	DonorTemplate = AbilityTemplateManager.FindAbilityTemplate(DonorAbility);

	if (Template != none && DonorTemplate != none)
	{
		Template.LocFriendlyName = DonorTemplate.LocFriendlyName;
		Template.LocHelpText = DonorTemplate.LocHelpText;                   
		Template.LocLongDescription = DonorTemplate.LocLongDescription;
		Template.LocPromotionPopupText = DonorTemplate.LocPromotionPopupText;
		Template.LocFlyOverText = DonorTemplate.LocFlyOverText;
		Template.LocMissMessage = DonorTemplate.LocMissMessage;
		Template.LocHitMessage = DonorTemplate.LocHitMessage;
		Template.LocFriendlyNameWhenConcealed = DonorTemplate.LocFriendlyNameWhenConcealed;      
		Template.LocLongDescriptionWhenConcealed = DonorTemplate.LocLongDescriptionWhenConcealed;   
		Template.LocDefaultSoldierClass = DonorTemplate.LocDefaultSoldierClass;
		Template.LocDefaultPrimaryWeapon = DonorTemplate.LocDefaultPrimaryWeapon;
		Template.LocDefaultSecondaryWeapon = DonorTemplate.LocDefaultSecondaryWeapon;
	}
}

/*
static private function string BountyHunter_SpecialCritLabelDelegate(XComGameState_Unit UnitState, XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState)
{
	if (UnitState.IsUnitAffectedByEffectName(class'X2Effect_BountyHunter_CritMagic'.default.EffectName) &&
		class'X2Effect_BountyHunter_CritMagic'.static.IsCritGuaranteed(UnitState, TargetState))
	{
		return "CRIT DMG INCREASE";
	}
	return "";
}
*/

static private function SkeletalMeshSocket CreateSocket(const name SocketName, const name BoneName, optional const float X, optional const float Y, optional const float Z, optional const float dRoll, optional const float dPitch, optional const float dYaw, optional float ScaleX = 1.0f, optional float ScaleY = 1.0f, optional float ScaleZ = 1.0f)
{
	local SkeletalMeshSocket NewSocket;

	NewSocket = new class'SkeletalMeshSocket';
    NewSocket.SocketName = SocketName;
    NewSocket.BoneName = BoneName;

    NewSocket.RelativeLocation.X = X;
    NewSocket.RelativeLocation.Y = Y;
    NewSocket.RelativeLocation.Z = Z;

    NewSocket.RelativeRotation.Roll = dRoll * DegToUnrRot;
    NewSocket.RelativeRotation.Pitch = dPitch * DegToUnrRot;
    NewSocket.RelativeRotation.Yaw = dYaw * DegToUnrRot;

	NewSocket.RelativeScale.X = ScaleX;
	NewSocket.RelativeScale.Y = ScaleY;
	NewSocket.RelativeScale.Z = ScaleZ;
    
	return NewSocket;
}

/// Start Issue #245
/// Called from XGWeapon:Init.
/// This function gets called when the weapon archetype is initialized.
static function WeaponInitialized(XGWeapon WeaponArchetype, XComWeapon Weapon, optional XComGameState_Item ItemState = none)
{
	local XComContentManager			Content;
	local X2UnifiedProjectile			Projectile;
	local X2UnifiedProjectileElement	Element;

    if (ItemState == none) 
	{	
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponArchetype.ObjectID));
	}
	if (ItemState == none)
		return;

	// Add Soul Shot projectiles and animations.
	if (ItemState.GetWeaponCategory() == 'gauntlet') // Templar Shard Gauntlet
	{
		Content = `CONTENT;
		Weapon.CustomUnitPawnAnimsets.AddItem(AnimSet(Content.RequestGameArchetype("IRISoulShot2.Anims.AS_SoulShot")));

		Projectile = X2UnifiedProjectile(Content.RequestGameArchetype("IRISoulShot2.Archetypes.PJ_SoulBow"));
		foreach Projectile.ProjectileElements(Element)
		{
			`AMLOG("Adding projectile elements into array:" @ Weapon.DefaultProjectileTemplate.ProjectileElements.Length);
			Weapon.DefaultProjectileTemplate.ProjectileElements.AddItem(Element);
		}

		Projectile = X2UnifiedProjectile(Content.RequestGameArchetype("IRISoulShot2.Archetypes.PJ_SoulBow_ArcWave"));
		foreach Projectile.ProjectileElements(Element)
		{
			Weapon.DefaultProjectileTemplate.ProjectileElements.AddItem(Element);
		}
	}

}
/// End Issue #245

defaultproperties
{
	Begin Object Class=SkeletalMeshSocket Name=DefaultShadowTeleportSocket
		SocketName = "IRIShadowTeleportSocket"
		BoneName = "RHand"
	End Object
	ShadowTeleportSocket = DefaultShadowTeleportSocket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultSoulShotFireSocket
		SocketName = "IRI_SoulBow_Arrow"
		BoneName = "RHand"
		RelativeRotation=(Pitch=-1183, Yaw=-364)
	End Object
	SoulShotFireSocket = DefaultSoulShotFireSocket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultSoulShotWeaponSocket
		SocketName = "IRI_SoulBow_Fire"
		BoneName = "GauntletRootL"
	End Object
	SoulShotWeaponSocket = DefaultSoulShotWeaponSocket;
	

	// For playing the "arrow stuck in body" particle effect when hit by the soul bow
	Begin Object Class=SkeletalMeshSocket Name=DefaultSoulShotHitSocket
		SocketName = "IRI_SoulBow_Arrow_Hit"
		BoneName = "Ribcage"
		RelativeRotation=(Roll=-16384, Yaw=16384)
	End Object
	SoulShotHitSocket = DefaultSoulShotHitSocket;

	Begin Object Class=SkeletalMeshSocket Name=DefaultInvenRHandCopySocket
		SocketName = "IRI_R_Hand"
		BoneName = "Inven_R_Hand"
	End Object
	InvenRHandCopySocket = DefaultInvenRHandCopySocket;
}

