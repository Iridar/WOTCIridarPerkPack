class X2Action_BountyHunter_MoveBegin extends X2Action_MoveBegin;

// Same as original, but don't add rushcam. Used in Chasing Shot.

simulated state Executing
{
	function SetMovingUnitDiscState()
	{
		local XComGameState_Unit UnitState;
		
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID));

		if( Unit != None )
		{
			if( Unit.IsMine() )
			{
				// remove the unit ring while he is running
				Unit.SetDiscState(eDS_Hidden);
			}
			else if (UnitState != None && (UnitState.IsFriendlyToLocalPlayer() || UnitState.IsCivilian()))
			{
				Unit.SetDiscState(eDS_Good); //Set the enemy disc state to red when moving	
			}
			else
			{
				Unit.SetDiscState(eDS_Red); //Set the enemy disc state to red when moving		
			}
		}
	}

	function AddRushCam()
	{
	//	local XComGameState_Unit UnitState;
	//	local XComGameStateHistory History;
	//
	//	if( `CHEATMGR == none || !`CHEATMGR.bAlwaysRushCam )
	//	{
	//		// no rush cams if the user has fancy cameras turned off
	//		if( !`Battle.ProfileSettingsGlamCam() )
	//		{
	//			return;
	//		}
	//
	//		// only do a rush cam if the unit is dashing
	//		if( Unit.CurrentMoveData.CostIncreases.Length == 0 )
	//		{
	//			return;
	//		}
	//
	//		// only do a rush cam if this is the human player on the local machine
	//		if( !bLocalUnit )
	//		{
	//			return;
	//		}
	//
	//		// no rush cams if they have been disabled by a cheat
	//		if( class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableRushCams )
	//		{
	//			return;
	//		}
	//
	//		History = `XCOMHISTORY;
	//
	//			foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	//		{
	//			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, , AbilityContext.AssociatedState.HistoryIndex));
	//			if( UnitState == none ) continue; // unit didn't exist at this point in the past
	//
	//			if( Unit.ObjectID == UnitState.ObjectID ) // this is the moving unit
	//			{
	//				// don't do a rush cam if the unit is panicking 
	//				if( UnitState.IsPanicked() )
	//				{
	//					return;
	//				}
	//
	//				if( !UnitState.GetMyTemplate().bAllowRushCam )
	//				{
	//					return;
	//				}
	//			}
	//			else if( MovingUnitPlayerID == UnitState.ControllingPlayer.ObjectID // this is another unit on the moving unit's team
	//				&& !UnitState.GetMyTemplate().bIsCosmetic
	//				&& UnitState.NumActionPoints() > 0 )
	//			{
	//				// don't do a rush cam if this isn't the last move of the player's turn.
	//				// (this check ensures all other non-cosmetic units are out of moves)
	//				return;
	//			}
	//		}
	//	}
	//
	//	RushCam = new class'X2Camera_RushCam';
	//	RushCam.AbilityToFollow = AbilityContext;
	//	RushCam.CameraTag = 'MovementFramingCamera';
	//	`CAMERASTACK.AddCamera(RushCam);
	}

Begin:
	//If this unit is set to follow another unit, insert a delay into the beginning of the move
	if (Unit.bNextMoveIsFollow)
	{
		sleep(UnitPawn.FollowDelay * GetDelayModifier());
	}
	else
	{
		sleep(DefaultGroupFollowDelay * float(MovePathIndex) * GetDelayModifier()); //If we are part of a group, add an increasing delay based on which group index we are
	}

	while( Unit.IdleStateMachine.IsEvaluatingStance() )
	{
		sleep(0.0f);
	}

	//If a move has a tracking camera, make the model visible for the duration of the move	
	UnitPawn.SetUpdateSkelWhenNotRendered(true);//even if the unit is not visible, update the skeleton so it can animate

	SetMovingUnitDiscState();

	if( !bNewUnitSelected )
	{
		AddRushCam();
	}

	if (Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Normal || Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch)
	{	
		UnitPawn.SetApexClothingMaxDistanceScale_Manual(0.1f);

		if(Unit.CurrentMoveData.MovementData.Length == 1)
		{
			`RedScreen("Movement data only has 1 entry. Bummer. Unit #"@Unit.ObjectID@"UnitType="$XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID)).GetMyTemplateName()@"-JBouscher ");
		}
		
		RunStartDistanceAvailable = GetStraightNormalDistance(); 

		if( RunStartDistanceAvailable >= RunStartRequiredDistance
			|| Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch) // always play the move start when launching into the air
		{
			UnitPawn.vMoveDirection = Normal(Unit.CurrentMoveData.MovementData[1].Position - UnitPawn.Location);
			UnitPawn.vMoveDestination = Unit.CurrentMoveData.MovementData[1].Position;

			if(!bShouldUseWalkAnim) //For determining whether to walk we want to know the state as of the beginning of the move
			{
				RunStartDestination = Unit.VisualizerUsePath.FindPointOnPath(UnitPawn.fRunStartDistance);

				// if we are transitioning to flying, bump the fixup up to match the flight path
				// otherwise snap the unit to the ground
				if( Unit.CurrentMoveData.MovementData[0].Traversal == eTraversal_Launch )
				{
					if( UnitPawn.CollisionComponent != None )
					{
						RunStartDestination.Z += UnitPawn.CollisionComponent.Bounds.BoxExtent.Z;
					}

					MoveDirectionRotator = UnitPawn.GetFlyingDesiredRotation();
				}
				else
				{
					RunStartDestination.Z = Unit.GetDesiredZForLocation(RunStartDestination);
					MoveDirectionRotator = Rotator(RunStartDestination - UnitPawn.Location);
					MoveDirectionRotator.Pitch = 0.0f;
					MoveDirectionRotator = Normalize(MoveDirectionRotator);
				}

				RotatorBetween = Normalize(MoveDirectionRotator - UnitPawn.Rotation);
				AngleBetween = RotatorBetween.Yaw * UnrRotToDeg;

				if (AngleBetween > 120.0f)
				{
					AnimParams.AnimName = 'MV_RunBackRight_Start';
				}
				else if (AngleBetween > 45.0f)
				{
					AnimParams.AnimName = 'MV_RunRight_Start';
				}
				else if (AngleBetween < -120.0f)
				{
					AnimParams.AnimName = 'MV_RunBackLeft_Start';
				}
				else if (AngleBetween < -45.0f)
				{
					AnimParams.AnimName = 'MV_RunLeft_Start';
				}
				else // AngleBetween >= -45 && AngleBetween <= 45
				{
					AnimParams.AnimName = 'MV_RunFwd_Start';
				}

				UnitPawn.EnableRMA(true, true);
				UnitPawn.EnableRMAInteractPhysics(true);
				
				AnimParams.PlayRate = GetMoveAnimationSpeed();
				AnimParams.DesiredEndingAtoms.Add(1);
				AnimParams.DesiredEndingAtoms[0].Translation = RunStartDestination;
				AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(MoveDirectionRotator);
				AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
				AnimParams.PlayRate = AnimationRateModifier;

				FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
				UnitPawn.m_fDistanceMovedAlongPath += UnitPawn.fRunStartDistance;
				UnitPawn.EnableRMAInteractPhysics(false);
			}
		}
		else
		{
			// At least make sure you are facing the correct direction
			MoveDirectionRotator = Normalize(Rotator(Unit.CurrentMoveData.MovementData[1].Position - Unit.CurrentMoveData.MovementData[0].Position));
			RotatorBetween = Normalize(MoveDirectionRotator - UnitPawn.Rotation);
			AngleBetween = abs(RotatorBetween.Yaw * UnrRotToDeg);

			if( AngleBetween > TurnAngleThreshold ) // Only Turn if we are far off from our desired facing
			{
				FinishAnim(UnitPawn.StartTurning(Unit.CurrentMoveData.MovementData[1].Position));
			}
		}
	}

	UnitPawn.UpdateAnimations();

	//At the point we force the pawn to be visible. AI paths that come out of the fog are updated so that portions of the path in the fog are removed.
	Unit.SetForceVisibility(eForceVisible);
	UnitPawn.UpdatePawnVisibility();

	CompleteAction();
}