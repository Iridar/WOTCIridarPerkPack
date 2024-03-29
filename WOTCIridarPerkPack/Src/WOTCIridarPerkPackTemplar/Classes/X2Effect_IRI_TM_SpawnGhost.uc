class X2Effect_IRI_TM_SpawnGhost extends X2Effect_SpawnGhost;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local Object				EffectObj;
	local XComGameState_Player	PlayerState;
	local XComGameState_Unit	SourceUnit;
	local XComGameStateHistory	History;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return;
	
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(SourceUnit.ControllingPlayer.ObjectID));
	if (PlayerState == none)
		return;
	

	EventMgr.RegisterForEvent(EffectObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted,, PlayerState,, EffectObj);	
}

static private function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Effect	EffectState;


	`AMLOG("Running");

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	SpawnedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.CreatedObjectReference.ObjectID));
	if (SpawnedUnit!= none)
	{
		`AMLOG("Triggering Kill Ghost Event:" @ SpawnedUnit.GetFullName());
		`XEVENTMGR.TriggerEvent('IRI_TM_GhostKill', SpawnedUnit, SpawnedUnit, GameState);
	}

    return ELR_NoInterrupt;
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit				NewUnitState;
	//local XComGameState_Effect_TemplarFocus	FocusState;
	local int i;

	NewUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	if (NewUnitState == none)
		return;

	NewUnitState.GhostSourceUnit = ApplyEffectParameters.SourceStateObjectRef;
	NewUnitState.kAppearance.bGhostPawn = true;
	NewUnitState.SetBaseMaxStat(eStat_HP, 1, ECSMAR_None);
	NewUnitState.SetCurrentStat(eStat_HP, 1);
	NewUnitState.SetCharacterName(default.FirstName, default.LastName, "");
	NewUnitState.SetUnitFloatValue('NewSpawnedUnit', 1, eCleanup_BeginTactical);

	// Action Points
	NewUnitState.ActionPoints.Length = 0;
	for (i = `GetConfigInt("IRI_TM_Ghost_InitialActions") - 1; i >= 0; i--)
	{
		NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}

	// Templar Focus - Doesn't work, too early.
	//FocusState = NewUnitState.GetTemplarFocusEffectState();
	//if (FocusState != none)
	//{
	//	FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
	//	FocusState.SetFocusLevel(`GetConfigInt("IRI_TM_Ghost_InitialFocus"), NewUnitState, NewGameState, true);
	//	`AMLOG("Setting Focus to:" @ `GetConfigInt("IRI_TM_Ghost_InitialFocus"));
	//}
	//else
	//{
	//	`AMLOG("Failed to get Focus State");
	//}
}

simulated function ModifyAbilitiesPreActivation(StateObjectReference NewUnitRef, out array<AbilitySetupData> AbilityData, XComGameState NewGameState)
{
	local array<name>				AbilityList;
	local X2AbilityTemplate			AbilityTemplate;
	local AbilitySetupData			SetupData;
	local name						AbilityName;
	local name						AdditionalAbility;
	local X2AbilityTemplateManager	AbilityMgr;
	local int i;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// Remove all abilities from the Ghost other than explicitly allowed ones.
	AbilityList = `GetConfigArrayName("IRI_TM_Ghost_AllowedAbilities");

	// But first expand the list with additional abilities of allowed abilities.
	foreach AbilityList(AbilityName)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityName);
		if (AbilityTemplate == none)
			continue;

		foreach AbilityTemplate.AdditionalAbilities(AdditionalAbility)
		{
			if (AbilityList.Find(AdditionalAbility) == INDEX_NONE)
			{
				AbilityList.AddItem(AdditionalAbility);
			}
		}
	}

	for (i = AbilityData.Length - 1; i >= 0; i--)
	{
		if (AbilityList.Find(AbilityData[i].TemplateName) == INDEX_NONE)
		{
			`AMLOG("Removing ability from Ghost:" @ AbilityData[i].TemplateName);
			AbilityData.Remove(i, 1);
		}
		else
		{
			`AMLOG("Allowing Ghost ability:" @ AbilityData[i].TemplateName);
		}
	}

	

	// Add abilities that Ghosts need to have, but regular Templars don't get.
	AbilityList = `GetConfigArrayName("IRI_TM_Ghost_AlwaysAddAbilities");
	for (i = 0; i < AbilityList.Length; i++)
	{
		AbilityName = AbilityList[i];
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityName);
		if (AbilityTemplate == None)
		{
			`AMLOG("WARNING :: Failed to find Templar Ghost ability template:" @ AbilityName);
			continue;
		}
		`AMLOG("Adding ability to Ghost:" @ AbilityName);

		SetupData.Template = AbilityTemplate;
		SetupData.TemplateName = AbilityName;
		AbilityData.AddItem(SetupData);
	}
}
/*
// Returns true if the associated XComGameSate_Effect should NOT be removed
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication, XComGameState_Player Player)
{
	local XComGameState_Unit	SpawnedUnit;
	local bool					bEffectKeepsTicking;

	bEffectKeepsTicking = super.OnEffectTicked(ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication, Player);

	`AMLOG("Running" @ bEffectKeepsTicking);

	if (!bEffectKeepsTicking)
	{
		SpawnedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kNewEffectState.CreatedObjectReference.ObjectID));
		if (SpawnedUnit!= none)
		{
			`AMLOG("Triggering Kill Ghost Event:" @ SpawnedUnit.GetFullName());
			`XEVENTMGR.TriggerEvent('IRI_TM_GhostKill', SpawnedUnit, SpawnedUnit, NewGameState);
		}
	}

	return bEffectKeepsTicking;
}
*/