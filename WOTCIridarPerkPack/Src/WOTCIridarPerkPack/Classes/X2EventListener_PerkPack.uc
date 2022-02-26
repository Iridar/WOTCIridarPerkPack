class X2EventListener_PerkPack extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(TacticalListeners());

	return Templates;
}

/*
'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState
*/

static function CHEventListenerTemplate TacticalListeners()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_PerkPack_Tactical');

	Template.RegisterInTactical = true;

	Template.AddCHEvent('CleanupTacticalMission', OnCleanupTacticalMission, ELD_Immediate, 50);

	// TODO: DEBUG ONLY
	Template.AddCHEvent('AbilityActivated', OnAbilityActivated, ELD_Immediate, 50);

	return Template;
}

// TODO: DEBUG ONLY
static function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
    local XComGameState_Unit	UnitState;

	local XComGameState_Ability AbilityState;
	local XComGameStateContext_Ability AbilityContext;
	local StateObjectReference UnitRef;

	if (NewGameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	UnitState = XComGameState_Unit(EventSource);
	AbilityState = XComGameState_Ability(EventData);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

	`LOG(UnitState.GetFullName() @ "activated ability:" @ AbilityState.GetMyTemplateName() @ "against" @ AbilityContext.InputContext.MultiTargets.Length @ "multi targets",, 'IRITEST');

	foreach AbilityContext.InputContext.MultiTargets(UnitRef)
	{
		`LOG("---" @ XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),, 'IRITEST');
	}
	
    return ELR_NoInterrupt;
}

static function EventListenerReturn OnCleanupTacticalMission(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID, Object CallbackData)
{
    local XComGameState_Unit	UnitState;
	local XComGameState_Unit	NewUnitState;
    local XComGameStateHistory	History;

    History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitState.IsAlive() && !UnitState.bCaptured)
		{
			NewUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
			if (NewUnitState == none)
			{
				NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			}
			if (UnitState.HasAbilityFromAnySource('IRI_LaughItOff'))
			{
				ApplyLaughItOff(NewUnitState);
			}
			if (UnitState.HasAbilityFromAnySource('IRI_LastingEndurance'))
			{
				ApplyLastingEndurance(NewUnitState);
			}
		}
	}

    return ELR_NoInterrupt;
}

static private function ApplyLaughItOff(XComGameState_Unit UnitState)
{
	local int RecoverHP;

	//`LOG(GetFuncName() @ UnitState.GetFullName() @ "current HP:" @ UnitState.GetCurrentStat(eStat_HP) @ "Max HP:" @ UnitState.GetMaxStat(eStat_HP) @ "Lowest HP:" @ UnitState.LowestHP @ "Highest HP:" @ UnitState.HighestHP @ "Base HP:" @ UnitState.GetBaseStat(eStat_HP),, 'IRITEST');

	RecoverHP = UnitState.GetBaseStat(eStat_HP) * class'X2Ability_PerkPack'.static.GetConfigFloat('IRI_LaughItOff_RecoverPercent');

	//`LOG("RecoverHP initial:" @ RecoverHP,, 'IRITEST');

	if (RecoverHP < class'X2Ability_PerkPack'.static.GetConfigInt('IRI_LaughItOff_Flat'))
		RecoverHP = class'X2Ability_PerkPack'.static.GetConfigInt('IRI_LaughItOff_Flat');

	//`LOG("RecoverHP corrected:" @ RecoverHP,, 'IRITEST');

	UnitState.LowestHP += RecoverHP;

	if (UnitState.GetCurrentStat(eStat_HP) < UnitState.GetMaxStat(eStat_HP))
			UnitState.ModifyCurrentStat(eStat_HP, RecoverHP);

	//`LOG("Effect applied!",, 'IRITEST');
	//`LOG(GetFuncName() @ UnitState.GetFullName() @ "current HP:" @ UnitState.GetCurrentStat(eStat_HP) @ "Max HP:" @ UnitState.GetMaxStat(eStat_HP) @ "Lowest HP:" @ UnitState.LowestHP @ "Highest HP:" @ UnitState.HighestHP @ "Base HP:" @ UnitState.GetBaseStat(eStat_HP),, 'IRITEST');
	//`LOG("-----------------------------------------------------------------------------------",, 'IRITEST');
}

static private function ApplyLastingEndurance(XComGameState_Unit UnitState)
{
	local float RestorePercentage;
	local float CurrentPercentage;

	//`LOG(GetFuncName() @ UnitState.GetFullName() @ "current Will:" @ UnitState.GetCurrentStat(eStat_Will) @ "Max Will:" @ UnitState.GetMaxStat(eStat_Will) @ "Base Will:" @ UnitState.GetBaseStat(eStat_Will),, 'IRITEST');

	RestorePercentage = class'X2Ability_PerkPack'.static.GetConfigFloat('IRI_LastingEndurance_MinWillPercentage');

	CurrentPercentage = UnitState.GetCurrentStat(eStat_Will) / UnitState.GetBaseStat(eStat_Will);

	//`LOG(`ShowVar(RestorePercentage) @ `ShowVar(CurrentPercentage),, 'IRITEST');
	if (CurrentPercentage < RestorePercentage)
	{
	//	`LOG("Restoring Will to:" @ UnitState.GetBaseStat(eStat_Will) * RestorePercentage,, 'IRITEST');
		UnitState.SetCurrentStat(eStat_Will, UnitState.GetBaseStat(eStat_Will) * RestorePercentage);
	}
}