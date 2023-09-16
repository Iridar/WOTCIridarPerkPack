class X2Effect_AstralGrasp extends X2Effect_SpawnUnit;

//var XComGameState_Unit TargetUnitRef;

// TODO: Override TriggerSpawnEvent and use the same character template as the enemy lol

function TriggerSpawnEvent(const out EffectAppliedData ApplyEffectParameters, XComGameState_Unit EffectTargetUnit, XComGameState NewGameState, XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit SourceUnitState, TargetUnitState, SpawnedUnit, CopiedUnit, ModifiedEffectTargetUnit;
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local StateObjectReference NewUnitRef;
	local XComWorldData World;
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;
	SpawnManager = `SPAWNMGR;
	World = `XWORLD;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( TargetUnitState == none )
	{
		`RedScreen("TargetUnitState in X2Effect_SpawnUnit::TriggerSpawnEvent does not exist. @dslonneger");
		return;
	}
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	if( bClearTileBlockedByTargetUnitFlag )
	{
		World.ClearTileBlockedByUnitFlag(TargetUnitState);
	}

	if( bCopyTargetAppearance )
	{
		CopiedUnit = TargetUnitState;
	}
	else if ( bCopySourceAppearance )
	{
		CopiedUnit = SourceUnitState;
	}

	// Spawn the new unit
	NewUnitRef = SpawnManager.CreateUnit(
		GetSpawnLocation(ApplyEffectParameters, NewGameState), 
		TargetUnitState.GetMyTemplateName(), 
		GetTeam(ApplyEffectParameters), 
		false, 
		false, 
		NewGameState, 
		CopiedUnit, 
		, 
		, 
		bCopyReanimatedFromUnit,
		(SourceUnitState != None && (bAddToSourceGroup || SourceUnitState.IsMine()) ) ? SourceUnitState.GetGroupMembership(NewGameState).ObjectID : -1,
		bCopyReanimatedStatsFromUnit);

	SpawnedUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	SpawnedUnit.bTriggerRevealAI = !bSetProcessedScamperAs;

	// Don't allow scamper
	GroupState = SpawnedUnit.GetGroupMembership(NewGameState);
	if( GroupState != None )
	{
		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
		GroupState.bProcessedScamper = bSetProcessedScamperAs;
	}

	ModifiedEffectTargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', EffectTargetUnit.ObjectID));
	ModifiedEffectTargetUnit.SetUnitFloatValue('SpawnedUnitValue', NewUnitRef.ObjectID, eCleanup_Never);
	ModifiedEffectTargetUnit.SetUnitFloatValue('SpawnedThisTurnUnitValue', NewUnitRef.ObjectID, eCleanup_BeginTurn);

	EffectGameState.CreatedObjectReference = SpawnedUnit.GetReference();

	OnSpawnComplete(ApplyEffectParameters, NewUnitRef, NewGameState, EffectGameState);
}

// Spawn the spirit unit near the shooter.
function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local Vector				PreferredDirection;
	local TTIle					FoundTile;
	local XComWorldData			World;
	local XComGameStateHistory	History;
	local XComGameState_Unit	SourceUnitState;
	local XComGameState_Unit	TargetUnitState;

	History = `XCOMHISTORY;
	World = `XWORLD;

	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnitState == none)
	{
		`AMLOG("ERROR :: No source unit state!");
		return vect(0, 0, 0);
	}

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState == none)
	{
		`AMLOG("ERROR :: No target unit state!");
		return World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation); // Better janky than broken. assuming it would even work anyway
	}
	
	PreferredDirection = Normal(World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation) - World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation));

	if (!SourceUnitState.FindAvailableNeighborTileWeighted(PreferredDirection, FoundTile))
	{
		`AMLOG("ERROR :: No neighbor tile available!");
		return World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
	}
		
	`AMLOG("SUCCESS :: Found neighbor tile:" @ FoundTile.X @ FoundTile.Y @ FoundTile.Z);

	return World.GetPositionFromTileCoordinates(FoundTile);
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetTargetUnitsTeam(ApplyEffectParameters, true);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Unit	TargetUnit;
	//local EffectAppliedData		NewEffectParams;
	//local X2Effect ShadowboundLinkEffect;
	local X2EventManager		EventMgr;
	local Object				EffectObj;

	TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none)
	{
		`AMLOG("ERROR :: No Shadowbind Target unit state!");
		return;
	}

	SpawnedUnit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', NewUnitRef.ObjectID));
	if (SpawnedUnit == none)
	{
		`AMLOG("ERROR :: No Shadowbind unit state!");
		return;
	}

	SpawnedUnit.ActionPoints.Length = 0;

	`AMLOG("Setting Max HP to:" @ TargetUnit.GetMaxStat(eStat_HP) @ "Current HP:" @ TargetUnit.GetCurrentStat(eStat_HP));

	SpawnedUnit.SetBaseMaxStat(eStat_HP, TargetUnit.GetMaxStat(eStat_HP));
	SpawnedUnit.SetCurrentStat(eStat_HP, TargetUnit.GetCurrentStat(eStat_HP));

	// Link the Source and Shadow units
	//NewEffectParams = ApplyEffectParameters;
	//NewEffectParams.EffectRef.ApplyOnTickIndex = INDEX_NONE;
	//NewEffectParams.EffectRef.LookupType = TELT_AbilityTargetEffects;
	//NewEffectParams.EffectRef.SourceTemplateName = class'X2Ability_Spectre'.default.ShadowboundLinkName;
	//NewEffectParams.EffectRef.TemplateEffectLookupArrayIndex = 0;
	//NewEffectParams.TargetStateObjectRef = SpawnedUnit.GetReference();
	//
	//ShadowboundLinkEffect = class'X2Effect'.static.GetX2Effect(NewEffectParams.EffectRef);
	//if (ShadowboundLinkEffect != none)
	//{
	//	ShadowboundLinkEffect.ApplyEffect(NewEffectParams, SpawnedUnit, NewGameState);
	//}
	//else `AMLOG("ERROR :: No Shadowbind Link effect!");

	// Shadow units need the anim sets of the units they copied. They are all humanoid units so this should be fine
	SpawnedUnit.ShadowUnit_CopiedUnit = TargetUnit.GetReference();

	//TargetUnitRef = TargetUnit;

	//X2CharacterTemplate_AstralGrasp(SpawnedUnit.GetMyTemplate()).GetPawnArchetypeStringFn = GetPawnArchetypeString;
	
	//SpawnedUnit.GetMyTemplate().strTargetIconImage = TargetUnit.GetMyTemplate().strTargetIconImage;

	EventMgr = `XEVENTMGR;
	EffectObj = NewEffectState;
	EventMgr.RegisterForEvent(EffectObj, 'UnitDied', ShadowbindUnitDeathListener, ELD_OnStateSubmitted,, SpawnedUnit,, NewEffectState);
}
/*
simulated function string GetPawnArchetypeString(XComGameState_Unit kUnit, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	//local XComGameState_Unit SpawnedUnit;
	//local XComGameState_Unit TargetUnit;
	//
	//TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(SpawnedUnit.ShadowUnit_CopiedUnit.ObjectID));

	`AMLOG("I'm reanimated from unit:" @ TargetUnitRef.GetFullName());
	
	return TargetUnitRef.GetMyTemplate().GetPawnArchetypeString(TargetUnitRef);
}
*/
// Copied from X2Effect_Executed
static private function EventListenerReturn ShadowbindUnitDeathListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Effect EffectState;
	local XComGameState_Unit TargetUnit;
	local int KillAmount;
	local bool bForceBleedOut;
	local XComGameState NewGameState;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit == none)
		return ELR_NoInterrupt;

	// If a unit is bleeding out, kill it
	// If a unit is alive AND cannot become bleeding out, kill it
	// if a unit is alive AND can become bleeding out, set it to bleeding out
	KillAmount = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);

	if (!TargetUnit.IsBleedingOut() && TargetUnit.CanBleedOut())
	{
		bForceBleedOut = true;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Astral Grasp Damage");
	TargetUnit.TakeEffectDamage(EffectState.GetX2Effect(), KillAmount, 0, 0, EffectState.ApplyEffectParameters, NewGameState, bForceBleedOut);
	`GAMERULES.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local array<XComGameState_Unit>		SpawnedUnits;
	local XComGameState_Unit			SpawnedUnit;
	local XComGameState_Unit			TargetUnit;
	local VisualizationActionMetadata	EmptyTrack;
	local VisualizationActionMetadata	SpawnedUnitTrack;
	local XComGameStateContext_Ability	AbilityContext;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	TargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none)
		return;

	FindNewlySpawnedUnit(VisualizeGameState, SpawnedUnits);

	foreach SpawnedUnits(SpawnedUnit)
	{
		SpawnedUnitTrack = EmptyTrack;
		SpawnedUnitTrack.StateObject_OldState = SpawnedUnit;
		SpawnedUnitTrack.StateObject_NewState = SpawnedUnit;
		SpawnedUnitTrack.VisualizeActor = `XCOMHISTORY.GetVisualizer(SpawnedUnit.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(SpawnedUnitTrack, AbilityContext);

		AddSpawnVisualizationsToTracks(AbilityContext, SpawnedUnit, SpawnedUnitTrack, TargetUnit);
	}
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack )
{

	local X2Action_CreateDoppelganger CopyUnitAction;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Copy the thrower unit's appearance to the mimic
	CopyUnitAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTree(SpawnedUnitTrack, Context));
	CopyUnitAction.OriginalUnit = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
	CopyUnitAction.ShouldCopyAppearance = true;
	CopyUnitAction.bReplacingOriginalUnit = false;
	CopyUnitAction.bIgnorePose = false;

	//class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(SpawnedUnitTrack, Context);

	// TODO: visualize pull
	// TODO: Apply MITV
}


defaultproperties
{
	DamageTypes(0) = "Psi"
	//UnitToSpawnName = "IRI_TM_AstralGraspUnit"
	bCopyTargetAppearance = false
	bKnockbackAffectsSpawnLocation = true
	EffectName = "IRI_X2Effect_AstralGrasp"
	bCopyReanimatedFromUnit = false // don't need to copy inventory, abilities, etc.
	//bCopyReanimatedStatsFromUnit=true // apparently not used by the code?
	bSetProcessedScamperAs = true
}
