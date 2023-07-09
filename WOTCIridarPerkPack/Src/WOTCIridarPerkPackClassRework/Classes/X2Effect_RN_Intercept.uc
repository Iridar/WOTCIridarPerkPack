class X2Effect_RN_Intercept extends X2Effect_Persistent;

var name TriggerEventName;			//	Name of the event that will activate Interception. Not sure it makes sense to have it as anything other than 'AbilityActivated'.
var bool bMoveAfterAttack;			//	Whether the soldier should return to their original tile after Interception.
var int	 iGrantAP;					//	How many AP should be granted before every Interception. Determines the interception distance, mostly.
var bool bAllowInterrupt;			//	Whether Interception is allowed to happen during the interrupt stage.
var bool bAllowNonInterrupt;		//	[...] during non-Interrupt stage.
var bool bAllowNonInterrupt_IfNonInterruptible;	// [...] during non-Interrupt stage, but only for abilities that don't have a BuildInterruptGameStateFn
var bool bInterceptMovementOnly;	//	Whether the soldier is allowed to Intercept only enemy movement.
var bool bAllowCoveringFire;		//	If bInterceptMovementOnly, allow to Intercept all kinds of ability activations, if the soldier has the covering fire ability.
var bool bAllowGuardian;			//	Whether the Intercepting unit can attempt another Interception if they have the Guardian ability.
var name UseActionPoint;			//	Name of the Overwatch Action Point used by Intercept.

//	Mimic X2Effect_ReserveOverwatchPoints, but grant a different overwatch action point type.
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;
	local int i, Points;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	if (TargetUnitState != none)
	{
		Points = GetNumPoints(TargetUnitState);

		TargetUnitState.ActionPoints.Length = 0;

		for (i = 0; i < Points; i++)
		{
			TargetUnitState.ReserveActionPoints.AddItem(default.UseActionPoint);
		}
	}
}

final protected function int GetNumPoints(XComGameState_Unit UnitState)
{
	if (UnitState.HasSoldierAbility('SkirmisherAmbush'))
	{
		return 2; // Waylay interaction - reworked it grants 2 points.
	}
	
	return 1;
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	//local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	//UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
	EventMgr.RegisterForEvent(EffectObj, TriggerEventName, Intercept_Listener, ELD_OnStateSubmitted,, ,, EffectObj);	
}

static final function EventListenerReturn Intercept_Listener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
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
	local bool							bUnitWasSuperConcealed;
	local bool							bMoveActivated;
	local XComGameState_Ability			AbilityState;
	local XComGameState_Ability			GuardianAbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local XGUnit						Visualizer;
	local array<TTile>					Path;
	local TTile							ReturnTile;
	local array<Vector>					ReturnLocations;
	local int i, j, z;

	//	========================================================================
	//			Initial Checks Start
	
	EffectState = XComGameState_Effect(CallbackData);
	InterceptEffect = X2Effect_RN_Intercept(EffectState.GetX2Effect()); //	Grab the Intercept Effect so we can freely check its properties in this static function.
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext == none || InterceptEffect == none || EffectState == none) return ELR_NoInterrupt;

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	if (AbilityTemplate == none || IsReactionFireAbility(AbilityTemplate))
	{
		// Forbid reaction to reaction attacks as that can cause a visualization softlock, see: https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/1162

		`LOG("X2Effect_RN_Intercept: Intercept_Listener:" @ AbilityContext.InputContext.AbilityTemplateName @ "is a reaction fire attack, cannot react to it, exiting.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
		return ELR_NoInterrupt;
	}

	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
    {
		//	If we don't allow interrupt, and this is an interrupt stage, exit.
		// 2023: Have to allow interrupt to interrupt enemy movement, duh
		if (!InterceptEffect.bAllowInterrupt)
			return ELR_NoInterrupt;
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
					`LOG("X2Effect_RN_Intercept: Intercept_Listener: ability is not interruptible, and this is not an interrupt stage, the effect is configured to allow to proceed.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
				}
				else return ELR_NoInterrupt;	//	This ability is interruptible in principle, so we exit the listener outside of the interrupt stage.
			}
			else return ELR_NoInterrupt;	//	We don't allow non-interruptible abilities to proceed during non-interrupt stage.
		}
	}
	
	//	Exit listener if it was activated by the unit who applied this effect.
	if (AbilityContext.InputContext.SourceObject == EffectState.ApplyEffectParameters.SourceStateObjectRef) return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//	Exit Listener if we only want to intercept movement abilities and this ability doesn't contain movement
	if (InterceptEffect.bInterceptMovementOnly && AbilityContext.InputContext.MovementPaths.Length == 0) 
	{
		//	Unless we allow Covering Fire, and the soldier has that ability.
		if (!InterceptEffect.bAllowCoveringFire || !UnitState.HasSoldierAbility('CoveringFire', true))
		{
			`LOG("X2Effect_RN_Intercept: Intercept_Listener: exiting because the ability doesn't include movement, and the Intercept is set up to react only to movement, and the soldier has Covering Fire:" @ UnitState.HasSoldierAbility('CoveringFire', true) @ ", Covering Fire allowed:" @ InterceptEffect.bAllowCoveringFire, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
			return ELR_NoInterrupt;
		}
		else
		{
			`LOG("X2Effect_RN_Intercept: Intercept_Listener: the ability doesn't include movement, and the Intercept is set up to react only to movement, but the soldier has Covering Fire:" @ UnitState.HasSoldierAbility('CoveringFire', true) @ ", and Covering Fire allowed:" @ InterceptEffect.bAllowCoveringFire, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
		}
	}
	
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	`LOG("X2Effect_RN_Intercept: Intercept_Listener: activated for" @ UnitState.GetFullName() @ "against unit:" @ TargetUnit.GetFullName() @ "using ability: " @ AbilityContext.InputContext.AbilityTemplateName @ "we interrupt:" @ GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt @ "History Index:" @ History.GetCurrentHistoryIndex() @ "with event:" @ InterceptEffect.TriggerEventName @ "DesiredVisualizationBlockIndex:" @ AbilityContext.DesiredVisualizationBlockIndex, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
	
	//	Exit listener if the moving unit is not an enemy or if the source unit is concealed.
	if (!UnitState.IsEnemyUnit(TargetUnit) || TargetUnit.IsDead() || UnitState.IsConcealed())
	{
		`LOG("X2Effect_RN_Intercept: Intercept_Listener: exiting listener because the TargetUnit is not an enemy:" @ !UnitState.IsEnemyUnit(TargetUnit) @ "Target Unit is dead:" @ TargetUnit.IsDead() @ "or Intercepting unit is concealed, which we don't allow:" @ UnitState.IsConcealed(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
		return ELR_NoInterrupt;
	}

	//	If the enemy is using an ability that involves movement and has the Intercepting unit as the primary target, it's probably a running melee attack, and that unit is gonna approach us anyway. 
	//	In that case, we dely the interception until the enemy is very close to us.  We solve two birds with this:
	//	1. Avoid moving the soldier if the enemy would be approaching them anyway, reducing the chance of the soldier getting themselves into trouble, like triggering Overwatch fire and revealing pods.
	//	2. This is pretty much necessary for sensible visualization if we don't perform a return move action, because then the enemy would still continue running to the tile that was formerly occupied by the unit 
	//	before they performed the Interception.
	if (AbilityContext.InputContext.MovementPaths.Length != 0 && AbilityContext.InputContext.PrimaryTarget.ObjectID == UnitState.ObjectID)
	{
		if (AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length != 0)
		{
			if (TargetUnit.TileLocation != AbilityContext.InputContext.MovementPaths[0].MovementTiles[AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1]) 
			{
				`LOG("X2Effect_RN_Intercept: Intercept_Listener: TargetUnit is performing a running melee attack against the intercepting unit, current distance is:" @ UnitState.TileDistanceBetween(TargetUnit), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
				return ELR_NoInterrupt;
			}
			else `LOG("X2Effect_RN_Intercept: Intercept_Listener: TargetUnit is performing a running melee attack against the intercepting unit and is now on their last tile of movement.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
		}
	}

	//	Grab the Reference to the ability we want to Intercept with. Exit Listener if the soldier doesn't have this ability, which shouldn't really happen.
	AbilityRef = UnitState.FindAbility('IRI_RN_Intercept_Attack');
	if (AbilityRef.ObjectID == 0) 
	{
		`LOG("X2Effect_RN_Intercept: Intercept_Listener: ERROR, no Intercept Abiltiy",, 'IRI_RIDER_INTERCEPT');
		return ELR_NoInterrupt;
	}

	//	Exit if the ability the target unit is using to move is typically ignored by Overwatch (e.g. Teleport)
	if (AbilityContext != none)
	{
		if (class'X2Ability_DefaultAbilitySet'.default.OverwatchIgnoreAbilities.Find(AbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE)
		{
			`LOG("X2Effect_RN_Intercept: Intercept_Listener: ability is ignored by overwatch, exiting: " @ AbilityContext.InputContext.AbilityTemplateName, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
			return ELR_NoInterrupt;
		}
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
				`LOG("X2Effect_RN_Intercept: Intercept_Listener: unit has an effect that makes it ignored by overwatch: " @ ExcludedEffectName, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
				return ELR_NoInterrupt;
			}
		}
	}

	//	Proceed only if the soldier has a Reserve AP
	if (UnitState.ReserveActionPoints.Find(default.UseActionPoint) == INDEX_NONE)
	{
		`LOG("X2Effect_RN_Intercept: Intercept_Listener: Source unit has no Overwatch Reserve AP, exiting.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
		return ELR_NoInterrupt;
	}
	
	//			Initial Checks End
	//	========================================================================

	//	========================================================================
	//			Begin Interception

	`LOG("X2Effect_RN_Intercept: Intercept_Listener: Initial checks passed, proceeding with Interception. History Index: " @ History.GetCurrentHistoryIndex() @ "Chain Start Index: " @ ChainStartIndex @ "Interrupting: " @ AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt @ "Ability: " @ AbilityContext.InputContext.AbilityTemplateName, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');

	//	######### Grant Action Points #########
	//	To the Intercepting Unit
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Give AP");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	//	First remove any AP they have so that they don't get too many AP due to subsequent Interceptions or Windcaller's Passive.
	UnitState.ActionPoints.Length = 0;
	for (i = 0; i < InterceptEffect.iGrantAP; i++)
	{
		UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}
	//	Submit the GameState so our changes to AP "take effect"
	`GAMERULES.SubmitGameState(NewGameState);

	if (!`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))	//we get UnitCache for the soldier that triggered this ability
	{
		`LOG("X2Effect_RN_Intercept: Intercept_Listener: ERROR, could not get Game Rules Catche for Intercepting Unit, exiting listener." @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
	}

	for (i = 0; i < UnitCache.AvailableActions.Length; ++i)	//then in all actions available to them
	{
		if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID)	//we find our Interception Attack ability
		{
			if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')	// check that it can be activated (i.e. unit is not stunned or something)
			{
				for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; j++)	//	Search for the target that was moving just now.
				{
					if (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget.ObjectID == TargetUnit.ObjectID)
					{
						`LOG("X2Effect_RN_Intercept: Intercept_Listener: found interecept ability that can be activated against this target." @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');

						//	Remember the Tile Location of the Intercepting unit so they can return to it later.
						ReturnTile = UnitState.TileLocation;

						//	Check if the Interception ability is ready to be activated against this enemy. If it is, then apply any associated costs and marks just before attacking.
						AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
						if (AbilityState.CanActivateAbilityForObserverEvent(TargetUnit, UnitState) == 'AA_Success')
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Apply Cost");
							UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

							//	######### Apply Reserve AP cost #########
							for (z = 0; z < UnitState.ReserveActionPoints.Length; z++)
							{
								if (UnitState.ReserveActionPoints[z] == default.UseActionPoint)
								{
									`LOG("X2Effect_RN_Intercept: Intercept_Listener: removing one Reserve AP." @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
									UnitState.ReserveActionPoints.Remove(z, 1);
									break;
								}
							}
							
							`GAMERULES.SubmitGameState(NewGameState);

							`LOG("X2Effect_RN_Intercept: Intercept_Listener: Activating Intercept ability" @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
							//class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j,,,,, GameState.HistoryIndex,, SPT_BeforeParallel);

							//	######### Perform the Intercept Attack action. #########
							class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j, /*TargetLocations*/, /*TargetingMethod*/, /*PathTiles*/, /*WaypointTiles*/, GameState.HistoryIndex,, /*SPT_*/);
						}
						else `LOG("X2Effect_RN_Intercept: Intercept_Listener: WARNING, could NOT activate the Intercept Attack." @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
					
						//	######### Perform the Move Action. #########
						
						//	Give Move AP
						if (InterceptEffect.bMoveAfterAttack)
						{
	
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Give AP");
							UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
							//	First remove any AP they have so that they don't get too many AP due to subsequent Interceptions or Windcaller's Passive.
							//	Grant an extra Move AP in case the soldier somehow travels longer distance during Interception.
							UnitState.ActionPoints.Length = 0;
							for (i = 0; i < InterceptEffect.iGrantAP + 1; i++)
							{
								UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
							}
							`GAMERULES.SubmitGameState(NewGameState);

							//	Build a path to the original tile.
							Visualizer = XGUnit(UnitState.GetVisualizer());
							if (Visualizer.m_kReachableTilesCache.BuildPathToTile(ReturnTile, Path))
							{
								//	Get the reference to the Return Move ability. 
								AbilityRef = UnitState.FindAbility('IRI_RN_Intercept_Return');
								if (AbilityRef.ObjectID == 0) 
								{
									`LOG("X2Effect_RN_Intercept: Intercept_Listener: ERROR, no Move ability.",, 'IRI_RIDER_INTERCEPT');
								}
								else if (`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
								{
									for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
									{
										if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID)
										{
											//	Could fail to activate if the unit got shot by something that reduces mobility during interception or otherwise disabled.
											`LOG("X2Effect_RN_Intercept: Intercept_Listener: activating Move ability" @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
											bMoveActivated = class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i],,,, Path,, GameState.HistoryIndex,, SPT_AfterSequential);
										}
									}
								}
							}
							else `LOG("X2Effect_RN_Intercept: Intercept_Listener: WARNING, could not build a path for Move ability" @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
							

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
										`LOG("X2Effect_RN_Intercept: Intercept_Listener: found ability context at history index: " @ i @ "for ability" @ AbilityContext.InputContext.AbilityTemplateName @ ", inserting PostBuildViz.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
										AbilityContext.PostBuildVisualizationFn.AddItem(Intercept_PostBuildVisualization);
										break;
									}
									i--;
								}
								until (i <= 0);
							}
							else `LOG("X2Effect_RN_Intercept: Intercept_Listener: WARNING, could not activate Return Move.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
						}

						UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID));
						if (UnitState.ActionPoints.Length > 0)
						{
							`LOG("X2Effect_RN_Intercept: Intercept_Listener: removing AP", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');

							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Rider Intercept: Remove AP");
							UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

							//	Remove any left over AP from the Return Move.
							UnitState.ActionPoints.Length = 0;							

							//	Roll for Guardian, if applicable
							if (InterceptEffect.bAllowGuardian)
							{
								//	Check history to find out if the Intercept Attack we just used has hit
								AbilityRef = UnitState.FindAbility('Sentinel');
								if (AbilityRef.ObjectID != 0)
								{
									if (`SYNC_RAND_STATIC(100) < class'X2Ability_SpecialistAbilitySet'.default.GUARDIAN_PROC && DidLatestInterceptionHit('IRI_RN_Intercept_Attack', UnitState.ObjectID, TargetUnit.ObjectID))
									{
										UnitState.ReserveActionPoints.AddItem(default.UseActionPoint);
										GuardianAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
										`XEVENTMGR.TriggerEvent('GuardianTriggered', GuardianAbilityState, UnitState, NewGameState);
									}
								}					
							}

							`GAMERULES.SubmitGameState(NewGameState);
						}
						
						//	Exit listener
						`LOG("X2Effect_RN_Intercept: Intercept_Listener: everything processed, exiting listener" @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
						return ELR_NoInterrupt;
					}
				}
			}
		}
	}
	
	`LOG("X2Effect_RN_Intercept: Intercept_Listener: WARNING, something went wrong, exiting listener." @ "History Index: " @ History.GetCurrentHistoryIndex(), class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
	return ELR_NoInterrupt;
}

static final function bool IsReactionFireAbility(const X2AbilityTemplate Template)
{	
	local X2AbilityTrigger Trigger;
	local X2AbilityTrigger_EventListener EventListenerTrigger;

	foreach Template.AbilityTriggers(Trigger)
	{
		EventListenerTrigger = X2AbilityTrigger_EventListener(Trigger);
		if (EventListenerTrigger == none)
			continue;
			
		if (EventListenerTrigger.ListenerData.EventID == 'AbilityActivated')
			return true;
	}
	return false;
}

static final function bool DidLatestInterceptionHit(name InterceptAttackName, int SourceID, int TargetID)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameStateHistory			History;

	History = `XCOMHISTORY;

	//	Cycle through all ability activations in recent history.
	foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', AbilityContext,,, History.GetEventChainStartIndex())
	{
		//	Find the first case of Intercept Attack being used by the same unit against the same target.
		if (AbilityContext.InputContext.AbilityTemplateName == InterceptAttackName && 
			AbilityContext.InputContext.SourceObject.ObjectID == SourceID && 
			AbilityContext.InputContext.PrimaryTarget.ObjectID == TargetID)
		{
			`LOG("X2Effect_RN_Intercept: DidLatestInterceptionHit: found Intercept Attack used at: " @ AbilityContext.AssociatedState.HistoryIndex @ "hit:" @ AbilityContext.IsResultContextHit() @ "hit result:" @ AbilityContext.ResultContext.HitResult, class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');
			return AbilityContext.IsResultContextHit();
		}
	}
	return false;
}

static final function Intercept_PostBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateVisualizationMgr		VisMgr;
	local X2Action_MarkerNamed				ReplaceAction;
	local X2Action							FindAction;
	local array<X2Action>					FindActions;
	local XComGameStateContext_Ability		AbilityContext;
	local X2Action_PlaySoundAndFlyOver		SoundAndFlyOver;
	local XComGameState_Unit				UnitState;

	`LOG("X2Effect_RN_Intercept: Intercept_PostBuildVisualization: running.", class'Help'.default.bLog, 'IRI_RIDER_INTERCEPT');

	VisMgr = `XCOMVISUALIZATIONMGR;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	/*
	`log("======================================",, 'IRIPISTOLVIZ');
	`log("Build Tree",, 'IRIPISTOLVIZ');
	PrintActionRecursive(VisMgr.BuildVisTree.TreeRoot, 0);
	`log("--------------------------------------",, 'IRIPISTOLVIZ');*/

	//	Remove any instances of cinematic camera from the viz tree. Looks janky otherwise.
	
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_StartCinescriptCamera', FindActions);
	foreach FindActions(FindAction)
	{
		ReplaceAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', AbilityContext));
		ReplaceAction.SetName("ReplaceCinescriptCamera");
		VisMgr.ReplaceNode(ReplaceAction, FindAction);
	}
	//	Insert Interception Flyover

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
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

//	=============================================================
//				HELPER FUNCTIONS
//	-------------------------------------------------------------

static final function PrintActionRecursive(X2Action Action, int iLayer)
{
	local X2Action ChildAction;

	`LOG("Action layer: " @ iLayer @ ": " @ Action.Class.Name,, 'IRIPISTOLVIZ'); 
	foreach Action.ChildActions(ChildAction)
	{
		PrintActionRecursive(ChildAction, iLayer + 1);
	}
}

defaultproperties
{
	iGrantAP = 1
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_Rider_Intercept_Effect"
	TriggerEventName = "UnitMoveFinished"
	bMoveAfterAttack = true
	UseActionPoint = "intercept"
}