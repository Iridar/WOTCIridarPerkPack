class X2Effect_RN_Intercept extends X2Effect_Persistent;

var name TriggerEventName;			//	Name of the event that will activate Interception. Not sure it makes sense to have it as anything other than 'AbilityActivated'.
var bool bMoveAfterAttack;			//	Whether the soldier should return to their original tile after Interception.
var bool bAllowInterrupt;			//	Whether Interception is allowed to happen during the interrupt stage.
var bool bAllowNonInterrupt;		//	[...] during non-Interrupt stage.
var bool bAllowNonInterrupt_IfNonInterruptible;	// [...] during non-Interrupt stage, but only for abilities that don't have a BuildInterruptGameStateFn
var bool bInterceptMovementOnly;	//	Whether the soldier is allowed to Intercept only enemy movement.
var bool bAllowCoveringFire;		//	If bInterceptMovementOnly, allow to Intercept all kinds of ability activations, if the soldier has the covering fire ability.

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager	EventMgr;
	local Object			EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	EventMgr.RegisterForEvent(EffectObj, TriggerEventName, Intercept_Listener, ELD_OnStateSubmitted,, ,, EffectObj);	
}

static private function EventListenerReturn Intercept_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit			TargetUnit, ChainStartTarget, UnitState;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameStateHistory			History;
	local int							ChainStartIndex;
	local Name							ExcludedEffectName;
	local X2Effect_RN_Intercept			InterceptEffect;
	local XComGameState_Effect			EffectState;
	local XComGameState					NewGameState;
	local GameRulesCache_Unit			UnitCache;
	local StateObjectReference			AbilityRef;
	local bool							bMoveActivated;
	local XComGameState_Ability			AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local XGUnit						Visualizer;
	local array<TTile>					Path;
	local TTile							ReturnTile;
	local bool							bTargetMoving;
	local TTile							ClosestAttackTile;
	local int i, j;

	//	========================================================================
	//			Initial Checks Start
	
	EffectState = XComGameState_Effect(CallbackData);
	InterceptEffect = X2Effect_RN_Intercept(EffectState.GetX2Effect()); //	Grab the Intercept Effect so we can freely check its properties in this static function.
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || InterceptEffect == none || EffectState == none)
		return ELR_NoInterrupt;

	//	Exit listener if it was activated by the unit who applied this effect.
	if (AbilityContext.InputContext.SourceObject == EffectState.ApplyEffectParameters.SourceStateObjectRef)
		return ELR_NoInterrupt;

	//	Exit if the ability the target unit is using to move is typically ignored by Overwatch (e.g. Teleport)
	if (class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
	{
		`AMLOG("EXIT :: ability is ignored by overwatch: " @ AbilityContext.InputContext.AbilityTemplateName);
		return ELR_NoInterrupt;
	}

	if (class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(AbilityContext))
	{
		// Forbid reaction to reaction attacks as that can cause a visualization softlock, see: https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1162
		`AMLOG("EXIT ::" @ AbilityContext.InputContext.AbilityTemplateName @ "is a reaction fire attack, cannot react to it.");
		return ELR_NoInterrupt;
	}

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	if (AbilityTemplate == none)
		return ELR_NoInterrupt;

	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
		//	If we don't allow interrupt, and this is an interrupt stage, exit.
		// 2023: Have to allow interrupt to interrupt enemy movement, duh
		if (!InterceptEffect.bAllowInterrupt)
		{
			`AMLOG("EXIT :: This is an interrupt stage, which is not allowed.");
			return ELR_NoInterrupt;
		}
    }
	else
	{
		//	If we don't allow non-interrupt, and this is not an interrupt stage, exit...
		if (!InterceptEffect.bAllowNonInterrupt)
		{
			//	... unless this effect is set up so it allows the non-interrupt stage for abilities that cannot be interrupted at all.
			if (InterceptEffect.bAllowNonInterrupt_IfNonInterruptible)
			{
				if (AbilityTemplate.BuildInterruptGameStateFn == none)
				{
					//	Do nothing, let the listener code proceed.
					`AMLOG("CONTINUE :: ability is not interruptible, and this is not an interrupt stage, the effect is configured to allow to proceed.");
				}
				else return ELR_NoInterrupt;	//	This ability is interruptible in principle, so we exit the listener outside of the interrupt stage.
			}
			else return ELR_NoInterrupt;	//	We don't allow non-interruptible abilities to proceed during non-interrupt stage.
		}
	}

	// Don't Intercept while concealed
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (UnitState == none || UnitState.IsConcealed())
	{
		`AMLOG("EXIT :: Intercepting unit is missing:" @ UnitState == none @ "or concealed:" @ UnitState.IsConcealed());
		return ELR_NoInterrupt;
	}

	//	Proceed only if the soldier has a Reserve AP
	if (UnitState.ReserveActionPoints.Find('iri_intercept_ap') == INDEX_NONE)
	{
		`AMLOG("EXIT :: Intercepting unit has no Overwatch Reserve AP, exiting.");
		return ELR_NoInterrupt;
	}

	bTargetMoving = IsTargetUnitMoving(AbilityContext.InputContext.SourceObject.ObjectID, AbilityContext.InputContext.MovementPaths);

	//	Exit Listener if we only want to intercept movement abilities and this ability doesn't contain movement
	if (InterceptEffect.bInterceptMovementOnly && !bTargetMoving) 
	{
		//	Unless we allow Covering Fire, and the soldier has that ability.
		if (!InterceptEffect.bAllowCoveringFire || !UnitState.HasSoldierAbility('CoveringFire', true))
		{
			`AMLOG("EXIT :: ability doesn't include movement, and the Intercept is set up to react only to movement, and the soldier has Covering Fire:" @ UnitState.HasSoldierAbility('CoveringFire', true) @ ", Covering Fire allowed:" @ InterceptEffect.bAllowCoveringFire);
			return ELR_NoInterrupt;
		}
		else
		{
			`AMLOG("CONTINUE :: ability doesn't include movement, and the Intercept is set up to react only to movement, but the soldier has Covering Fire:" @ UnitState.HasSoldierAbility('CoveringFire', true) @ ", and Covering Fire allowed:" @ InterceptEffect.bAllowCoveringFire);
		}
	}
	
	TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	`AMLOG("CONTINUE :: " @ UnitState.GetFullName() @ "against unit:" @ TargetUnit.GetFullName() @ "using ability:" @ AbilityContext.InputContext.AbilityTemplateName @ "we interrupt:" @ GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt @ "History Index:" @ History.GetCurrentHistoryIndex() @ "with event:" @ InterceptEffect.TriggerEventName @ "DesiredVisualizationBlockIndex:" @ AbilityContext.DesiredVisualizationBlockIndex);
	
	//	Exit listener if the moving unit is not an enemy
	if (TargetUnit == none || !UnitState.IsEnemyUnit(TargetUnit) || TargetUnit.IsDead())
	{
		`AMLOG("EXIT :: Target Unit is not an enemy:" @ !UnitState.IsEnemyUnit(TargetUnit) @ "Target Unit is dead:" @ TargetUnit.IsDead());
		return ELR_NoInterrupt;
	}

	// If target is moving, intercept it when it's closest to the interceptor.
	if (bTargetMoving)
	{
		if (!OnClosestTileInPath(UnitState.TileLocation, TargetUnit.TileLocation, AbilityContext.InputContext.SourceObject.ObjectID, AbilityContext.InputContext.MovementPaths))
		{
			`AMLOG("EXIT :: TargetUnit is not on closest tile, current distance is:" @ UnitState.TileDistanceBetween(TargetUnit));
			return ELR_NoInterrupt;
		}
	}

	//	Grab the Reference to the ability we want to Intercept with. Exit Listener if the soldier doesn't have this ability, which shouldn't really happen.
	AbilityRef = UnitState.FindAbility('IRI_RN_Intercept_Attack');
	if (AbilityRef.ObjectID == 0) 
	{
		`AMLOG("EXIT :: no Intercept Abiltiy");
		return ELR_NoInterrupt;
	}

	// Exit if the moving unit is under any effects that allow to bypass Overwatch.
	ChainStartIndex = History.GetEventChainStartIndex();
	if (ChainStartIndex != INDEX_NONE)
	{
		ChainStartTarget = XComGameState_Unit(History.GetGameStateForObjectID(TargetUnit.ObjectID, , ChainStartIndex));
		foreach class'X2Ability_DefaultAbilitySet'.default.OverwatchExcludeEffects(ExcludedEffectName)
		{
			if (ChainStartTarget.IsUnitAffectedByEffectName(ExcludedEffectName))
			{
				`AMLOG("EXIT :: unit has an effect that makes it ignored by overwatch: " @ ExcludedEffectName);
				return ELR_NoInterrupt;
			}
		}
	}

	Visualizer = XGUnit(UnitState.GetVisualizer());
	if (Visualizer == none)
		return ELR_NoInterrupt;
	
	//			Initial Checks End
	//	========================================================================

	//	========================================================================
	//			Begin Interception

	`AMLOG("CONTINUE :: Initial checks passed, proceeding with Interception. History Index: " @ History.GetCurrentHistoryIndex() @ "Chain Start Index: " @ ChainStartIndex @ "Interrupting: " @ AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt @ "Ability: " @ AbilityContext.InputContext.AbilityTemplateName);

	//	######### Grant Action Points #########
	//	To the Intercepting Unit
	//	This must be implemented this way, because moving melee targeting requires the soldier to have AP they can move with.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Give AP");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	UnitState.ActionPoints.Length = 0;
	UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	`GAMERULES.SubmitGameState(NewGameState);

	if (!`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this ability
	{
		`AMLOG("ERROR :: Could not get Game Rules Catche for Intercepting Unit, exiting listener. History Index: " @ History.GetCurrentHistoryIndex());
	}

	for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
	{
		//`AMLOG("Looking at ability:" @ XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID)).GetMyTemplateName());

		if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID)	//we find our Interception Attack ability
		{
			`AMLOG("Found Intercept Attack, availability code:" @ UnitCache.AvailableActions[i].AvailableCode);
			if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it can be activated (i.e. unit is not stunned or something)
			{
				for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; j++)	//	Search for the target that was moving just now.
				{
					//`AMLOG("Looking at target:" @ XComGameState_Unit(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget.ObjectID)).GetFullName());
				
					if (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget.ObjectID == TargetUnit.ObjectID)
					{
						`AMLOG("CONTINUE :: Found Interecept ability that can be activated against this target. History Index: " @ History.GetCurrentHistoryIndex());

						//	Remember the Tile Location of the Intercepting unit so they can return to it later.
						ReturnTile = UnitState.TileLocation;

						//	Check if the Interception ability is ready to be activated against this enemy. If it is, then apply any associated costs and marks just before attacking.
						AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
						if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit, UnitState) == 'AA_Success')
						{
							`AMLOG("CONTINUE :: Activating Intercept ability" @ "History Index: " @ History.GetCurrentHistoryIndex());

							//	######### Perform the Intercept Attack action. #########
							ClosestAttackTile = GetClosestAttackTile(UnitState, TargetUnit, Visualizer.m_kReachableTilesCache);
							Visualizer.m_kReachableTilesCache.BuildPathToTile(ClosestAttackTile, Path);

							class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j, /*TargetLocations*/, /*TargetingMethod*/, Path /*PathTiles*/, /*WaypointTiles*/, GameState.HistoryIndex,, /*SPT_*/);
						}
						else `AMLOG("WARNING :: Could NOT activate the Intercept Attack. History Index: " @ History.GetCurrentHistoryIndex());
					
						//	######### Perform the Move Action. #########
						
						if (InterceptEffect.bMoveAfterAttack)
						{
							//	Give Move AP
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Give AP");
							UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
							UnitState.ActionPoints.Length = 0;
							UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
							`GAMERULES.SubmitGameState(NewGameState);

							//	Build a path to the original tile.
							if (Visualizer.m_kReachableTilesCache.BuildPathToTile(ReturnTile, Path))
							{
								//	Get the reference to the Return Move ability. 
								AbilityRef = UnitState.FindAbility('IRI_RN_Intercept_Return');
								if (AbilityRef.ObjectID == 0) 
								{
									`AMLOG("ERROR :: no Move ability.");
								}
								else if (`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
								{
									for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
									{
										if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID)
										{
											//	Could fail to activate if the unit got shot by something that reduces mobility during interception or otherwise disabled.
											`AMLOG("CONTINUE :: Activating Move ability. History Index: " @ History.GetCurrentHistoryIndex());
											bMoveActivated = class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],,,, Path,, GameState.HistoryIndex,, SPT_AfterSequential);
										}
									}
								}
							}
							else `AMLOG("WARNING :: Could not build a path for Move ability. History Index: " @ History.GetCurrentHistoryIndex());
							

							//	Find the Game State where Return Move was activated and insert a PostBuildViz function into its context.
							if (bMoveActivated)
							{
								i = History.GetCurrentHistoryIndex();
								do
								{
									NewGameState = History.GetGameStateFromHistory(i);
									AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());

									if (AbilityContext != none && AbilityContext.InputContext.AbilityTemplateName == 'IRI_RN_Intercept_Return' && AbilityContext.InputContext.SourceObject.ObjectID == UnitState.ObjectID)
									{
										`AMLOG("CONTINUE :: Found ability context at history index: " @ i @ "for ability" @ AbilityContext.InputContext.AbilityTemplateName @ ", inserting PostBuildViz.");
										AbilityContext.PostBuildVisualizationFn.AddItem(Intercept_PostBuildVisualization);
										break;
									}
									i--;
								}
								until (i <= 0);
							}
							else `AMLOG("WARNING :: Could not activate Return Move.");
						}
						
						//	Exit listener
						`AMLOG("SUCCESS :: Everything processed, exiting listener. History Index: " @ History.GetCurrentHistoryIndex());
						return ELR_NoInterrupt;
					}
				}
			}
		}
	}
	
	`AMLOG("WARNING :: Something went wrong, exiting listener. History Index: " @ History.GetCurrentHistoryIndex());
	return ELR_NoInterrupt;
}

static private function TTile GetClosestAttackTile(XComGameState_Unit UnitState, XComGameState_Unit TargetUnit, X2ReachableTilesCache ActiveCache)
{
	local array<TTile>               TargetTiles; // Array of tiles occupied by the target; these tiles can be attacked by melee.
	local TTile                      TargetTile;
	local array<TTile>               AdjacentTiles;	// Array of tiles adjacent to Target Tiles; the attacking unit can move to these tiles to attack.
	local TTile                      AdjacentTile;
	local array<TTile>				 PossibleTiles;
	
	GatherTilesOccupiedByUnit(TargetUnit, TargetTiles);

	// Collect non-duplicate tiles around every Target Tile to see which tiles we can attack from.
	GatherTilesAdjacentToTiles(TargetTiles, AdjacentTiles);

	foreach TargetTiles(TargetTile)
	{
		foreach AdjacentTiles(AdjacentTile)
		{
			if (class'Helpers'.static.FindTileInList(AdjacentTile, PossibleTiles) != INDEX_NONE)
				continue;		
				
			if (class'X2AbilityTarget_MovingMelee'.static.IsValidAttackTile(UnitState, AdjacentTile, TargetTile, ActiveCache))
			{	
				PossibleTiles.AddItem(AdjacentTile);
			}
		}
	}
	return GetClosestTile(UnitState.TileLocation, PossibleTiles);
}

static private function GatherTilesOccupiedByUnit(const XComGameState_Unit TargetUnit, out array<TTile> OccupiedTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local Box                VisibilityExtents;

	TargetUnit.GetVisibilityExtents(VisibilityExtents);
	
	WorldData = `XWORLD;
	WorldData.CollectTilesInBox(TilePosPairs, VisibilityExtents.Min, VisibilityExtents.Max);

	foreach TilePosPairs(TilePair)
	{
		OccupiedTiles.AddItem(TilePair.Tile);
	}
}

static private function GatherTilesAdjacentToTiles(out array<TTile> TargetTiles, out array<TTile> AdjacentTiles)
{	
	local XComWorldData      WorldData;
	local array<TilePosPair> TilePosPairs;
	local TilePosPair        TilePair;
	local TTile              TargetTile;
	local vector             Minimum;
	local vector             Maximum;
	
	WorldData = `XWORLD;

	// Collect a 3x3 box of tiles around every target tile, excluding duplicates.
	// Melee attacks can happen diagonally upwards or downwards too,
	// so collecting tiles on the same Z level would not be enough.
	foreach TargetTiles(TargetTile)
	{
		Minimum = WorldData.GetPositionFromTileCoordinates(TargetTile);
		Maximum = Minimum;

		Minimum.X -= WorldData.WORLD_StepSize;
		Minimum.Y -= WorldData.WORLD_StepSize;
		Minimum.Z -= WorldData.WORLD_FloorHeight;

		Maximum.X += WorldData.WORLD_StepSize;
		Maximum.Y += WorldData.WORLD_StepSize;
		Maximum.Z += WorldData.WORLD_FloorHeight;

		WorldData.CollectTilesInBox(TilePosPairs, Minimum, Maximum);

		foreach TilePosPairs(TilePair)
		{
			if (class'Helpers'.static.FindTileInList(TilePair.Tile, AdjacentTiles) != INDEX_NONE)
				continue;

			AdjacentTiles.AddItem(TilePair.Tile);
		}
	}
}

static private function bool IsTargetUnitMoving(const int ObjectID, const array<PathingInputData> MovementPaths)
{
	local PathingInputData MovementPath;
	local int i;

	`AMLOG("Running for objectID:" @ ObjectID @ "num movement paths:" @ MovementPaths.Length);
	
	foreach MovementPaths(MovementPath, i)
	{
		`AMLOG("Path number i:" @ i @ MovementPath.MovingUnitRef.ObjectID @ MovementPath.MovementTiles.Length);
		if (MovementPath.MovingUnitRef.ObjectID == ObjectID && MovementPath.MovementTiles.Length > 0)
		{
			`AMLOG("Target is moving");
			return true;
		}
	}
	`AMLOG("Target is NOT moving");
	return false;
}

static private function TTile GetClosestTile(const TTile SourceTile, const array<TTile> TileArray)
{
	local TTile	 ClosestTile;
	local TTile	 TestTile;
	local int	 ClosestDistance;
	local int	 TestDistance;

	ClosestDistance = const.MaxInt;

	foreach TileArray(TestTile)
	{
		TestDistance = TileDistanceBetweenTiles(SourceTile, TestTile);
		if (TestDistance < ClosestDistance)
		{
			ClosestDistance = TestDistance;
			ClosestTile = TestTile;
		}
	}

	return ClosestTile;
}

static private function bool OnClosestTileInPath(const TTile InterceptorTileLocation, const TTile TargetTileLocation, const int TargetObjectID, const array<PathingInputData> MovementPaths)
{
	local PathingInputData	MovementPath;
	local TTile				MovementTile;
	local int				ShortestDistance;
	local int				CurrentDistance;
	local int				CalcDistance;
	
	foreach MovementPaths(MovementPath)
	{
		if (MovementPath.MovingUnitRef.ObjectID == TargetObjectID && MovementPath.MovementTiles.Length > 0)
		{
			ShortestDistance = const.MaxInt;

			foreach MovementPath.MovementTiles(MovementTile)
			{
				CalcDistance = TileDistanceBetweenTiles(InterceptorTileLocation, MovementTile);
				if (CalcDistance < ShortestDistance)
				{	
					ShortestDistance = CalcDistance;
				}
			}

			CurrentDistance = TileDistanceBetweenTiles(InterceptorTileLocation, TargetTileLocation);

			return CurrentDistance <= ShortestDistance;
		}
	}
	return false;
}

static private function int TileDistanceBetweenTiles(const TTile TileA, const TTile TileB)
{
	local XComWorldData WorldData;
	local vector UnitLoc;
	local vector TargetLoc;
	local float Dist;
	local int Tiles;

	if (TileA == TileB)
		return 0;

	WorldData = `XWORLD;
	UnitLoc = WorldData.GetPositionFromTileCoordinates(TileA);
	TargetLoc = WorldData.GetPositionFromTileCoordinates(TileB);
	Dist = VSize(UnitLoc - TargetLoc);
	Tiles = Dist / WorldData.WORLD_StepSize;

	return Tiles;
}

static final function Intercept_PostBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action_MarkerNamed				ReplaceAction;
	local X2Action							FindAction;
	local array<X2Action>					FindActions;
	local XComGameStateContext_Ability		AbilityContext;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyOver;

	`AMLOG("Running.");

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//	Remove any instances of cinematic camera from the viz tree. Looks janky otherwise.
	
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_StartCinescriptCamera', FindActions);
	foreach FindActions(FindAction)
	{
		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		ReplaceAction.SetName("ReplaceCinescriptCamera");
		VisMgr.ReplaceNode(ReplaceAction, FindAction);
	}
	//	Insert Interception Flyover

	//	Remove soldier's speech for the standard move performed after interception
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_PlaySoundAndFlyOver', FindActions,, AbilityContext.InputContext.SourceObject.ObjectID);
	foreach FindActions(FindAction)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(FindAction);
		if (SoundAndFlyOver.CharSpeech == 'Moving' || SoundAndFlyOver.CharSpeech == 'Dashing')
		{
			SoundAndFlyOver.CharSpeech = '';
		}
	}
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_RN_Intercept_Effect"
	TriggerEventName = "UnitMoveFinished"
	bMoveAfterAttack = true
}
