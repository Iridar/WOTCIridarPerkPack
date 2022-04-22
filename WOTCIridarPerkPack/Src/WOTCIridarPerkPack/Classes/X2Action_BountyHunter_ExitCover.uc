class X2Action_BountyHunter_ExitCover extends X2Action_ExitCover;

// Currently unused.

// Copy of the original action that uses 'NO_FireStart_Shadow' instead of 'NO_FireStart'. That is all.

simulated state Executing
{
	//This is used to determine whether the unit is facing the right direction when utilizing the turn node to face a target
	function bool UnitFacingMatchesDesiredDirection()
	{
		local vector CurrentFacing;
		local vector DesiredFacing;
		local float Dot;

		CurrentFacing = Vector(Unit.Rotation);
		DesiredFacing = Normal(TargetLocation - UnitPawn.Location);

		Dot = NoZDot(CurrentFacing, DesiredFacing);

		return Dot > 0.7f; //~45 degrees of tolerance
	}

	simulated event Tick( float DeltaT )
	{
		if(!bHaltAimUpdates)
		{
			if(PrimaryTarget != none)
			{
				UnitPawn.TargetLoc = X2VisualizerInterface(PrimaryTarget).GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
				AimAtLocation = UnitPawn.TargetLoc;
			}
			else
			{
				UnitPawn.TargetLoc = AimAtLocation;
			}

			//If we are very close to the target, just update our aim with a more distance target once and then stop
			if(VSize(UnitPawn.TargetLoc - UnitPawn.Location) < (class'XComWorldData'.const.WORLD_StepSize * 2.0f))
			{
				bHaltAimUpdates = true;
				UnitPawn.TargetLoc = UnitPawn.TargetLoc + (Normal(UnitPawn.TargetLoc - UnitPawn.Location) * 400.0f);
				AimAtLocation = UnitPawn.TargetLoc;
			}
		}

		//Exit cover should never be time dilated, basically. In every case where it is interrupted or needs to wait, it uses wait loops rather than time dilation.
		if (Unit.CustomTimeDilation < 1.0f)
		{
			VisualizationMgr.SetInterruptionSloMoFactor(Unit, 1.0f);		
		}
	}

	function HideFOW()
	{
		local XGPlayer AIPlayer;
		local vector RevealLocation;
		local Actor FOWViewer;
		local XGBattle_SP Battle;

		Battle = XGBattle_SP(`BATTLE);

		AIPlayer = Battle.GetAIPlayer();
		RevealLocation = UnitPawn.Location;
		RevealLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;
		FOWViewer = `XWORLD.CreateFOWViewer(RevealLocation, 3); //3 meters

		if (Unit != None)
		{
			Unit.SetForceVisibility(eForceVisible);			
			UnitPawn.UpdatePawnVisibility();
		}
		
		AIPlayer.SetFOWViewer(FOWViewer);
	}

	function SetTargetUnitDiscState()
	{
		local XGUnit TargetUnit;

		TargetUnit = XGUnit(PrimaryTarget);
		if( TargetUnit != None && TargetUnit.IsMine() )
		{
			if( Unit.IsMine() )
			{
				TargetUnit.SetDiscState(eDS_Good); //If the shooter is mine, make it the good kind of disc
			}
			else
			{
				TargetUnit.SetDiscState(eDS_AttackTarget); //If the shooter is not mine, set the disc state to indicate we're under attack
				Unit.SetDiscState(eDS_Red); //Set the enemy disc state to red
			}
		}
	}

	function CreateFramingCamera()
	{
		local X2AbilityTemplateManager AbilityTemplateManager;
		local X2AbilityTemplate AbilityTemplate;

		// check if this ability even wants a framing camera
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);

		// dkaplan: hacky, but we need to address this more properly in the future anyways;  
		// TODO: replace the template type lookup with an alternate template property setting, perhaps an alternate value to FrameAbilityCameraType
		if(AbilityContext.ShouldFrameAbility() && AbilityTemplate.DataName != 'LostAttack' )
		{
			FramingCamera = new class'X2Camera_FrameAbility';
			FramingCamera.CameraTag = 'AbilityFraming';
			FramingCamera.AbilitiesToFrame.AddItem(AbilityContext);
			`CAMERASTACK.AddCamera(FramingCamera);
		}
	}

	function ManualStartLeanAim(AnimNodeSequence Sequence)
	{
		local XComAnimNotify_Aim AimNotify;

		AimNotify = new class'XComAnimNotify_Aim';
		AimNotify.Enable = true;
		AimNotify.ProfileName = 'RiflePeekFwd';
		AimNotify.BlendTime = 0.4f;
		AimNotify.ManualTrigger(UnitPawn, Sequence);
	}

	function bool ShouldWaitForFramingCamera()
	{
		local X2AbilityTemplate Template;

		if( FramingCamera == None )
		{
			return false;
		}

		if(!Unit.GetVisualizedGameState().IsPlayerControlled())
		{
			// non-humans always wait
			return true;
		}

		Template = AbilityState.GetMyTemplate();
		if( Template.TargetingMethod != None && Template.TargetingMethod.static.ShouldWaitForFramingCamera())
		{
			// if human targeted, check if the targeting method requires us to wait
			return true;
		}

		return false;
	}

	function bool ShouldRevealFOW()
	{
		// Never reveal in MP.
		if (`XENGINE.IsMultiplayerGame())
			return false;
		return !bSkipFOWReveal;
	}

	function bool ShouldFrameCamera()
	{
		local XComGameState_Unit UnitState;
		local XComTacticalController LocalController;
		local StateObjectReference LocalPlayerRef;

		if (bDoNotAddFramingCamera)
			return false;

		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

		if (`XENGINE.IsMultiplayerGame())
		{
			if (UnitState != None)
			{
				if (UnitState.IsFriendlyToLocalPlayer())
				{
					return !bNewUnitSelected;
				}
				LocalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
				LocalPlayerRef = LocalController.ControllingPlayer;
				if (class'X2TacticalVisibilityHelpers'.static.GetTargetIDVisibleForPlayer(UnitState.ObjectID, LocalPlayerRef.ObjectID))
				{
					return !bNewUnitSelected;
				}
			}
			return false;
		}
		return !bNewUnitSelected;
	}


Begin:

	//`log("X2Action_ExitCover::Begin -"@UnitPawn@Unit.ObjectID, , 'XCom_Filtered');

	if( !bSkipExitCoverVisualization )
	{
		if (ShouldRevealFOW())
		{
			HideFOW();
		}

		SetTargetUnitDiscState();

		if (ShouldFrameCamera())
		{
			CreateFramingCamera();
		}
	}

	//Run at full speed if we are interrupting
	VisualizationMgr.SetInterruptionSloMoFactor(Unit, 1.0f);

	//Check whether this is reaction fire, and update the sequencer if so
	if(ReactionFireSequencer.IsReactionFire(AbilityContext))
	{
		ReactionFireSequencer.PushReactionFire(self);
	}

	if( !bSkipExitCoverVisualization )
	{
		UnitPawn.EnableLeftHandIK(true);

		// in some cases, such as OTS targeting, we don't want or need to wait for the framing camera to arrive before continuing.
		// if that is the case, skip the wait and just move on
		if( ShouldWaitForFramingCamera() )
		{
			// wait for the framing camera to finish framing the ability before continuing
			while( FramingCamera != none && !FramingCamera.HasArrived() )
			{
				Sleep(0.0);
			}

			// to make the action sequence flow properly, we do the midpoint camera here,
			// but it should have the same delay as a standalone frame action
			if( AbilityContext.ShouldFrameAbility() && !bNewUnitSelected )
			{
				Sleep(class'X2Action_CameraFrameAbility'.default.FrameDuration * GetDelayModifier());
			}
		}

		LineOfFireFriendlyUnitCrouch();

		//First, we make sure the character is in the proper cover state before they fire. This may not always be the case, eg. we are overwatching in a left peek
		//position ( closest enemy is in that direction ) and an enemy moves into view of our right peek position. In this situation, we would need to switch sides
		//before proceeding with the exit cover + firing actions.
		//****************
		if( bIsEndMoveAbility == false )
		{
			if( !ShouldPlayZipMode() )
			{
				Unit.IdleStateMachine.CheckForStanceUpdate();
				while( Unit.IdleStateMachine.IsEvaluatingStance() ) //Wait for any pending stance update to complete
				{
					Sleep(0.0f);
				}
			}

			//****************

			//A unit's idle state machine must be dormant during firing, or else the idle state machine will fight the firing process for control over the unit's anim nodes. At best
			//this will dirupt the animations/firing process, at worst it will lead to a permanent hang.
			if( !Unit.IdleStateMachine.IsDormant() )
			{
				Unit.IdleStateMachine.GoDormant();
			}

			//@TODO - jbouscher/rmcfall/jwatson - is left hand IK still applied? If so, is it still controlled this way or is it part of the animation controller?
			UnitPawn.EnableLeftHandIK(true);

			//Based on the unit's current cover state, this sets UseCoverDirectionIndex and UsePeekSide to determine which exit cover animation to use. This function also
			//sets our cached anim tree nodes

			StepOutVisibilityHistoryIndex = -1;

			if( bUsePreviousGameState )
			{
				StepOutVisibilityHistoryIndex = CurrentHistoryIndex - 1;
			}

			Unit.bShouldStepOut = Unit.GetStepOutCoverInfo(TargetUnitState, TargetLocation, UseCoverDirectionIndex, UsePeekSide, RequiresLean, bCanSeeDefaultFromDefault, StepOutVisibilityHistoryIndex);

			//Save our location so that it can be reset later in EnterCover if not already stepped out
			Unit.RestoreLocation = UnitPawn.Location;
			Unit.RestoreHeading = vector(UnitPawn.Rotation);			
		}
		// Set our weapon to get the correct animations
		// RAM - this should no longer be necessary. The character's animsets should be fixed based on their current inventory items
		if (UseWeapon == none)
		{
			if (Unit.CurrentPerkAction != none)
			{
				UnitPawn.SetCurrentWeapon(Unit.CurrentPerkAction.GetPerkWeapon());
			}
			else
			{
				UnitPawn.SetCurrentWeapon(none);
			}
		}
		else
		{
			UnitPawn.SetCurrentWeapon(XComWeapon(UseWeapon.m_kEntity));
		}
		UnitPawn.UpdateAnimations();

		if( bIsEndMoveAbility == false )
		{
			//Determine if we need to break out windows / bash open doors to make our shot, and then perform the door/window break. This is done before
			//anything else, as the animations were designed to be done from the starting tile
			//****************
			if( ShouldBreakWindowBeforeFiring(AbilityContext, BreakWindowTouchEventIndex) )
			{
				if( Unit.CanUseCover() )
				{
					AnimParams = default.AnimParams;
					AnimParams.PlayRate = GetNonCriticalAnimationSpeed();
					switch( Unit.m_eCoverState )
					{
					case eCS_LowLeft:
						AnimParams.AnimName = 'LL_WindowBreak';
						break;
					case eCS_HighLeft:
						AnimParams.AnimName = 'HL_WindowBreak';
						break;
					case eCS_LowRight:
						AnimParams.AnimName = 'LR_WindowBreak';
						break;
					case eCS_HighRight:
						AnimParams.AnimName = 'HR_WindowBreak';
						break;
					case eCS_None:
						AnimParams.AnimName = 'NO_WindowBreak';
						break;
					}
					FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
				}
				else
				{
					BreakWindow();
				}
			}
			//****************

			UnitPawn.EnableRMAInteractPhysics(true);
			UnitPawn.EnableRMA(true, true);

			if( Unit.bShouldStepOut && Unit.m_eCoverState != eCS_None )
			{
				AnimParams = default.AnimParams;
				AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

				switch( Unit.m_eCoverState )
				{
				case eCS_LowLeft:
				case eCS_HighLeft:
					AnimParams.AnimName = 'HL_StepOut';
					break;
				case eCS_LowRight:
				case eCS_HighRight:
					AnimParams.AnimName = 'HR_StepOut';
					break;
				}

				// First find the tile we'll be stepping into
				DesiredStartingAtom.Translation = UnitPawn.Location;
				DesiredStartingAtom.Rotation = QuatFromRotator(UnitPawn.Rotation);
				DesiredStartingAtom.Scale = 1.0f;
				UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(AnimParams, DesiredStartingAtom);

				// Find the tile location we are stepping to			
				StepOutLocation = AnimParams.DesiredEndingAtoms[0].Translation;
				if( `XWORLD.GetFloorTileForPosition(StepOutLocation, StepOutTile, false) )
				{
					StepOutLocation.Z = Unit.GetDesiredZForLocation(StepOutLocation);
					bStepoutHasFloor = true;
				}
				else
				{
					bStepoutHasFloor = false;
				}

				if( RequiresLean == 1 )
				{
					//Turn off all IK, the unit may be clipping into railings to make this shot
					UnitPawn.bSkipIK = true;
					UnitPawn.EnableFootIK(false);

					//Step out a little further if there is floor, otherwise don't step outside our tile
					if( bStepoutHasFloor )
					{
						AnimParams.DesiredEndingAtoms[0].Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.70f);
					}
					else
					{
						AnimParams.DesiredEndingAtoms[0].Translation = UnitPawn.Location + (Normal(StepOutLocation - UnitPawn.Location) * VSize(StepOutLocation - UnitPawn.Location) * 0.5f);
					}
				}
				else
				{
					AnimParams.DesiredEndingAtoms[0].Translation = StepOutLocation;
				}

				// Now Determine our facing based on our ending location and the target
				TowardsTarget = TargetLocation - AnimParams.DesiredEndingAtoms[0].Translation;
				TowardsTarget.Z = 0;
				TowardsTarget = Normal(TowardsTarget);
				AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(Rotator(TowardsTarget));

				FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				Unit.bSteppingOutOfCover = true;

			}

			if( Unit.bShouldStepOut == false )
			{
				AnimParams = default.AnimParams;
				AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

				AnimParams.DesiredEndingAtoms.Add(1);
				AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
				AnimParams.DesiredEndingAtoms[0].Translation = UnitPawn.Location;
				
				TowardsTarget = TargetLocation - UnitPawn.Location;
				TowardsTarget.Z = 0;
				TowardsTarget = Normal(TowardsTarget);
				if( PrimaryTarget == Unit || (TowardsTarget.X == 0 && TowardsTarget.Y == 0 && TowardsTarget.Z == 0) )
				{
					AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(UnitPawn.Rotation);
				}
				else
				{
					AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(Rotator(TowardsTarget));
				}
				
				switch( Unit.m_eCoverState )
				{
				case eCS_LowLeft:
				case eCS_LowRight:
					AnimParams.AnimName = 'LL_FireStart';
					break;
				case eCS_HighLeft:
				case eCS_HighRight:
					AnimParams.AnimName = 'HL_FireStart';
					break;
				case eCS_None:
					// ADDED - Use a different Fire Start animation.
					AnimParams.AnimName = 'NO_FireStart_Shadow';
					// END OF ADDED
					break;
				}

				if( UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
				{
					FinishAnimNodeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				}
				else
				{
					if( UseWeapon != None && XComWeapon(UseWeapon.m_kEntity) != None && XComWeapon(UseWeapon.m_kEntity).WeaponAimProfileType != WAP_Unarmed )
					{
						UnitPawn.UpdateAimProfile();
						UnitPawn.SetAiming(true, 0.5f, 'AimOrigin', false);
					}
				}
			}

			//If we need to animate out of cover or switch to our new weapon, finish the anim here. In the case of exiting cover while switching weapons, this animsequence
			//equips the new weapon and finishes the RMA step out of cover animation. In the case of a simple step out, this animsequence just gets out of cover
			//****************
			if( FinishAnimNodeSequence != None )
			{
				FinishAnim(FinishAnimNodeSequence, false, CrossFadeTime);
			}
			//****************
		}
	}

	//If we are reaction fire, wait for the sequencer to give its blessing
	if(ReactionFireSequencer.IsReactionFire(AbilityContext))
	{
		while(!ReactionFireSequencer.AttemptStartReactionFire(self))
		{
			sleep(0.0f);
		}		
	}

	//If the ability which generated this exit cover was interrupted, then process that here
	if( !bSkipExitCoverVisualization && HasNonEmptyInterruption() )
	{		
		//We don't want anyone messing up our step out / fire sequence. ( ie. flinches, get hit anims, etc. ). But we only care if there is a resume. If there is no
		//resume it means we died or otherwise cannot finish this action.
		if(VisualizationBlockContext.GetResumeState() != none)
		{
			UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false); 
		}		
		else
		{
			if (Unit.TargetingCamera != None)
				`CAMERASTACK.RemoveCamera(Unit.TargetingCamera);
		}
		bAllowInterrupt = true;
		CompleteActionWithoutExitingExecution();
	}
	else
	{
		CompleteAction();
	}
}