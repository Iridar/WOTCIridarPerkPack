class X2Effect_AstralGrasp extends X2Effect_SpawnUnit;

simulated function ModifyAbilitiesPreActivation(StateObjectReference NewUnitRef, out array<AbilitySetupData> AbilityData, XComGameState NewGameState)
{
	local AbilitySetupData NewData;
	local AbilitySetupData EmptyData;

	AbilityData.Length = 0;

	NewData.TemplateName = 'IRI_TM_AstralGrasp_Spirit';
	NewData.Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(NewData.TemplateName);
	if (NewData.Template != none)
	{
		AbilityData.AddItem(NewData);
	}

	NewData = EmptyData;
	NewData.TemplateName = 'HolyWarriorDeath';
	NewData.Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(NewData.TemplateName);
	if (NewData.Template != none)
	{
		AbilityData.AddItem(NewData);
	}
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

	`AMLOG("Source unit:" @ SourceUnitState.GetFullName() @ SourceUnitState.TileLocation.X @ SourceUnitState.TileLocation.Y @ SourceUnitState.TileLocation.Z @ "Target unit:" @ TargetUnitState.GetFullName() @ TargetUnitState.TileLocation.X @ TargetUnitState.TileLocation.Y @ TargetUnitState.TileLocation.Z @ "Direction:" @ PreferredDirection);
	
	if (SourceUnitState.FindAvailableNeighborTileWeighted(PreferredDirection, FoundTile, IsTileValidForBind))
	{
		`AMLOG("SUCCESS :: Found neighbor tile:" @ FoundTile.X @ FoundTile.Y @ FoundTile.Z);
		return World.GetPositionFromTileCoordinates(FoundTile);
	}

	// Fallback to any neighbor tile, without validation
	if (SourceUnitState.FindAvailableNeighborTileWeighted(PreferredDirection, FoundTile))
	{
		`AMLOG("WARNING :: Found neighbor tile:" @ FoundTile.X @ FoundTile.Y @ FoundTile.Z @ "without validation.");
		return World.GetPositionFromTileCoordinates(FoundTile);
	}

	// Fallback to the shooter's own tile.
	`AMLOG("ERROR :: No neighbor tile available!");
	return World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameState_Unit	TargetUnit;
	//local XComGameState_Unit	SourceUnit;

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
	SpawnedUnit.SetBaseMaxStat(eStat_ShieldHP, 0);
	SpawnedUnit.SetBaseMaxStat(eStat_ArmorMitigation, 0);
	SpawnedUnit.SetBaseMaxStat(eStat_Defense, 0);
	SpawnedUnit.SetBaseMaxStat(eStat_Dodge, 0);
	SpawnedUnit.SetBaseMaxStat(eStat_SightRadius, 0);
	SpawnedUnit.SetBaseMaxStat(eStat_Mobility, 0);

	SpawnedUnit.SetCurrentStat(eStat_HP, TargetUnit.GetCurrentStat(eStat_HP));
	SpawnedUnit.SetCurrentStat(eStat_ShieldHP, 0);
	SpawnedUnit.SetCurrentStat(eStat_ArmorMitigation, 0);
	SpawnedUnit.SetCurrentStat(eStat_Defense, 0);
	SpawnedUnit.SetCurrentStat(eStat_Dodge, 0);
	SpawnedUnit.SetCurrentStat(eStat_SightRadius, 0);
	SpawnedUnit.SetCurrentStat(eStat_Mobility, 0);
	//SpawnedUnit.StunnedActionPoints = 2;

	SpawnedUnit.SetUnitFloatValue('IRI_TM_AstralGrasp_SpiritLink', TargetUnit.ObjectID, eCleanup_BeginTactical);
	TargetUnit.SetUnitFloatValue('IRI_TM_AstralGrasp_SpiritLink', SpawnedUnit.ObjectID, eCleanup_BeginTactical);
	
	// Shadow units need the anim sets of the units they copied. They are all humanoid units so this should be fine
	// Iridar: not sure if this is still necessary
	SpawnedUnit.ShadowUnit_CopiedUnit = TargetUnit.GetReference();
	`XEVENTMGR.TriggerEvent('IRI_AstralGrasp_SpiritSpawned', TargetUnit, SpawnedUnit, NewGameState);
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

		//class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(SpawnedUnitTrack, AbilityContext);

		// TypicalAbility_BuildVisualization doesn't call this, so do it manually.
		AddSpawnVisualizationsToTracks(AbilityContext, SpawnedUnit, SpawnedUnitTrack, TargetUnit);
	}
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack, XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack)
{
	local VisualizationActionMetadata		ShooterMetadata;
	local X2Action_AstralGrasp				GetOverHereTarget;
	local X2Action_CreateDoppelganger		CopyUnitAction;
	local vector							NewUnitLoc;
	local X2Action_ApplyMITV				ApplyMITV;
	//local XComGameState_Unit				TargetUnit;
	local XComGameStateContext_Ability		AbilityContext;
	local XComGameStateHistory				History;
	local X2Action_PlayAnimation			PlayAnimation;
	local X2Action							ExitCover;
	local X2Action_ViperGetOverHere			FireAction;
	local X2Action_MarkerNamed				NamedMarker;

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(Context);
	//TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	// TRACK FOR THE SHOOTER

	ShooterMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	ShooterMetadata.StateObject_NewState = Context.AssociatedState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
	ShooterMetadata.VisualizeActor = History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID);

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ShooterMetadata, Context);
	
	ExitCover = class'X2Action_ExitCover'.static.AddToVisualizationTree(ShooterMetadata, Context, false, ShooterMetadata.LastActionAdded);
	FireAction = X2Action_ViperGetOverHere(class'X2Action_ViperGetOverHere'.static.AddToVisualizationTree(ShooterMetadata, Context, false, ShooterMetadata.LastActionAdded));
	FireAction.StartAnimName = 'NO_AstralGrasp_Start';
	FireAction.StopAnimName = 'NO_AstralGrasp_Stop';
	FireAction.SetFireParameters(true, SpawnedUnit.ObjectID);
	class'X2Action_EnterCover'.static.AddToVisualizationTree(ShooterMetadata, Context, false, ShooterMetadata.LastActionAdded);

	// TRACK FOR THE SPAWNED UNIT

	// This will create the visualizer for the spawned unit, and put them on the tile they were supposed to spawn at
	// in this case - near the shooter
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, ExitCover);

	// This will copy the thrower unit's appearance and put the visualizer on top of the target pawn,
	// which is exactly what I want
	CopyUnitAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	CopyUnitAction.OriginalUnit = XGUnit(`XCOMHISTORY.GetVisualizer(EffectTargetUnit.ObjectID));
	CopyUnitAction.ShouldCopyAppearance = true;
	CopyUnitAction.bReplacingOriginalUnit = false;
	CopyUnitAction.bIgnorePose = false;

	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	ApplyMITV.MITVPath = "FX_Warlock_SpectralArmy.M_SpectralArmy_Activate_MITV";

	NamedMarker = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	NamedMarker.SetName("IRI_AstralGrasp_MarkerStart");

	NamedMarker = X2Action_MarkerNamed(class'X2Action_MarkerNamed'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	NamedMarker.SetName("IRI_AstralGrasp_MarkerEnd");

	// This will drag the spawned pawn from the target unit to the tile near the shooter
	GetOverHereTarget =  X2Action_AstralGrasp(class'X2Action_AstralGrasp'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	NewUnitLoc = `XWORLD.GetPositionFromTileCoordinates(XComGameState_Unit(SpawnedUnitTrack.StateObject_NewState).TileLocation);
	GetOverHereTarget.SetDesiredLocation(NewUnitLoc, XGUnit(SpawnedUnitTrack.VisualizeActor));
	
	
	// Play the start stun animation
	//PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	//PlayAnimation.Params.AnimName = 'HL_StunnedStart';
	//PlayAnimation.bResetWeaponsToDefaultSockets = true;
	//
	//PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, false, SpawnedUnitTrack.LastActionAdded));
	//PlayAnimation.Params.AnimName = 'HL_StunnedIdle';
	//PlayAnimation.bResetWeaponsToDefaultSockets = true;
	//PlayAnimation.Params.Looping = true;
}

// ------------------------------------------------------------------

// Iridar: use the target unit's own char template, otherwise identical.
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
		TargetUnitState.GetMyTemplateName(), // Iridar: use the target unit's own template.
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

static private function bool IsTileValidForBind(const out TTile TileOption, const out TTile SourceTile, const out Object PassedObject)
{
	local XComWorldData World;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local vector SourceLoc, TargetLoc;
	local ECoverType Cover;
	local float TargetCoverAngle;
	World = `XWORLD;
	// Match the tile visibility condition checks from the Bind ability template as much as possible. (X2Ability_Viper::CreateBindAbility)
	//   Actual conditions from Bind ability cannot be directly tested without the units in place 
	//	 i.e. gameplay visibility not tested via CanSeeTileToTile.
	if( World.CanSeeTileToTile(SourceTile, TileOption, OutVisibilityInfo) ) // Visible? 
	{
		if( OutVisibilityInfo.bVisibleFromDefault ) // No peeking!
		{
			// No high cover allowed for bind.  CanSeeTileToTile does not update TargetCover either, so we must check this manually.
			SourceLoc = World.GetPositionFromTileCoordinates(SourceTile);
			TargetLoc = World.GetPositionFromTileCoordinates(TileOption);
			Cover = World.GetCoverTypeForTarget(SourceLoc, TargetLoc, TargetCoverAngle);
			if( Cover != CT_Standing )
			{
				return true;
			}
		}
	}
	return false;
}

// Spawn the spirit on the same team as the target.
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetTargetUnitsTeam(ApplyEffectParameters, true);
}


defaultproperties
{
	DamageTypes(0) = "Psi"
	bCopyTargetAppearance = false
	bKnockbackAffectsSpawnLocation = false
	EffectName = "IRI_X2Effect_AstralGrasp"
	bCopyReanimatedFromUnit = true // don't need to copy inventory, abilities, etc.
	//bCopyReanimatedStatsFromUnit=true // apparently not used by the code?
	bSetProcessedScamperAs = true
}
