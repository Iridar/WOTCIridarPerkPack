class X2Action_PredatorStrike extends X2Action_Fire;

/*
FF_PredatorStrikeMissA
FF_PredatorStrikeStartA
FF_PredatorStrikeStopA

FF_SkulljackedMissA
FF_SkulljackedStartA
FF_SkulljackedStopA

HL_HurtFrontA
*/

var private CustomAnimParams	AnimParams_2;

var private XComGameState_Unit	TargetUnitState;
var private CustomAnimParams	TargetAnimParams;
var private CustomAnimParams	TargetAnimParams_2;
var private AnimNodeSequence	TargetPlayingSequence;
var private XGUnit				TargetGameUnit;
var private XComUnitPawn		TargetPawn;
var private bool				bHumanoidTarget;
var private XComWorldData		World;
var private vector				SourceToTarget;

// var private float				PlayingTime;

function Init()
{
	super.Init();

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnitState == none)
	{
		`AMLOG("WARNING :: No Target Unit State!!!");
		return;
	}
	TargetGameUnit = XGUnit(History.GetVisualizer(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetGameUnit == none)
	{
		`AMLOG("WARNING :: No Target Game Unit!!!");
		return;
	}
	TargetPawn = TargetGameUnit.GetPawn();
	if (TargetPawn == none)
	{
		`AMLOG("WARNING :: No Target Pawn!!!");
		return;
	}

	World = `XWORLD;

	SourceToTarget = TargetPawn.Location - UnitPawn.Location;
	SourceToTarget = Normal(SourceToTarget);
	SourceToTarget.Z = 0;
}
simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		Unit.CurrentFireAction = self;
	}

	simulated event Tick( float fDeltaT )
	{	
		NotifyTargetTimer -= fDeltaT;		

		if( bUseAnimToSetNotifyTimer && !bNotifiedTargets && NotifyTargetTimer < 0.0f )
		{
			NotifyTargetsAbilityApplied();
		}

		UpdateAim(fDeltaT);
	}

	simulated function UpdateAim(float DT)
	{
		if (PrimaryTargetID == SourceUnitState.ObjectID) //We can't aim at ourselves, or IK will explode
			return;

		if(class'XComTacticalGRI'.static.GetReactionFireSequencer().FiringAtMovingTarget())
		{
			//Use a special aiming location if we are part of a reaction fire sequence
			UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
		}		
		else if(!bNotifiedTargets && !bHaltAimUpdates && !UnitPawn.ProjectileOverwriteAim ) //Projectile overwrites the normal aim upon firing, as projectile have the ability to miss Chang You Wong 2015-23-6
		{
			if((PrimaryTarget != none) && AbilityContext.ResultContext.HitResult != eHit_Miss)
			{
				UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
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
			}
		}
	}

	function SetTargetUnitDiscState()
	{
		if( TargetUnit != None && TargetUnit.IsMine() )
		{
			TargetUnit.SetDiscState(eDS_Hidden);
		}

		if( Unit != None )
		{
			Unit.SetDiscState(eDS_Hidden);
		}
	}

	function HideFOW()
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		SourceFOWViewer = `XWORLD.CreateFOWViewer(Unit.GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);
		Unit.SetForceVisibility(eForceVisible);
		Unit.GetPawn().UpdatePawnVisibility();
	}

Begin:
	//Per Jake, the primary target should never be fogged
	if ((XGUnit(PrimaryTarget) != none))
	{
		HideFOW();
	}

	//Run at full speed if we are interrupting
	VisualizationMgr.SetInterruptionSloMoFactor(Unit, 1.0f);

	// Iridar - just in case
	//StopAllPreviousRunningActions(TargetGameUnit);
	//
	//// Iridar = turn the unit(s) to face each other
	//TargetGameUnit.IdleStateMachine.ForceHeading(-SourceToTarget);
	//Unit.IdleStateMachine.ForceHeading(SourceToTarget);
	//while (Unit.IdleStateMachine.IsEvaluatingStance() || TargetGameUnit.IdleStateMachine.IsEvaluatingStance())
	//{
	//	if (!TargetGameUnit.IdleStateMachine.IsEvaluatingStance())
	//	{
	//		TargetGameUnit.IdleStateMachine.GoDormant(UnitPawn);
	//	}
	//	Sleep(0.0f);
	//}
	
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	// Iridar: prep target for animations too.
	TargetPawn.EnableRMA(true, true);
	TargetPawn.EnableRMAInteractPhysics(true);
	TargetPawn.bSkipIK = true;

	class'XComPerkContent'.static.GetAssociatedPerkInstances(Perks, UnitPawn, AbilityContext.InputContext.AbilityTemplateName);
	for( x = 0; x < Perks.Length; ++x )
	{
		kPerkContent = Perks[x];

		if( kPerkContent.IsInState('ActionActive') &&
			kPerkContent.m_PerkData.CasterActivationAnim.PlayAnimation &&
			kPerkContent.m_PerkData.CasterActivationAnim.AdditiveAnim )
		{
			PerkAdditiveAnimNames.AddItem(class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.m_PerkData.CasterActivationAnim));
		}
	}

	for( x =0; x < PerkAdditiveAnimNames.Length; ++x )
	{
		AdditiveAnimParams.AnimName = PerkAdditiveAnimNames[x];
		UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AdditiveAnimParams);
	}
	for (x = 0; x < ShooterAdditiveAnims.Length; ++x)
	{
		AdditiveAnimParams.AnimName = ShooterAdditiveAnims[x];
		UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AdditiveAnimParams);
	}

	// dkaplan - removed TheLost quick fire animations - 12/5/16
	//if( ZombieMode() )
	//{
	//	AnimParams.PlayRate = GetNonCriticalAnimationSpeed();
	//}

	// Iridar: pick the animations for the shooter and the target
	if (bWasHit)
	{
		AnimParams.AnimName = 'FF_PredatorStrikeStart';
		AnimParams_2.AnimName = 'FF_PredatorStrikeStop';

		// We want to use Skulljack animations on the target, if we can.
		if (TargetPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedStart'))
		{
			bHumanoidTarget = true;
			TargetAnimParams.AnimName = 'FF_SkulljackedStart';

			//if (TileDistanceBetween() > 1.0f)
			//{
			//	AnimParams_2.DesiredEndingAtoms.Add(1);
			//	AnimParams_2.DesiredEndingAtoms[0].Scale = 1.0f;
			//	AnimParams_2.DesiredEndingAtoms[0].Translation = World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
			//}

			TargetAnimParams_2.AnimName = 'FF_SkulljackedStop';
		}
		else
		{
			TargetAnimParams.AnimName = 'HL_HurtFront';
		}
	}
	else
	{
		AnimParams.AnimName = 'FF_PredatorStrikeMiss';

		if (TargetPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedMiss'))
		{
			bHumanoidTarget = true;
			TargetAnimParams.AnimName = 'FF_SkulljackedMiss';
		}
		else
		{
			TargetAnimParams.AnimName = 'HL_HurtFront';
		}
	}

	//The fire action must complete, make sure that it can be played.
	if (UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
	{
		// Play first half of the animation
		AnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		AnimSequence.SetEndTime(4.0f);

		TimeoutSeconds += 4.0f;

		TargetPlayingSequence = TargetPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(TargetAnimParams);
		TargetPlayingSequence.SetEndTime(4.0f);

		FinishAnim(AnimSequence);
		FinishAnim(TargetPlayingSequence);

		//NotifyTargetsAbilityApplied();

		// Play second half of the animation
		if (bWasHit)
		{
			//AnimParams_2.DesiredEndingAtoms.Add(1);
			//AnimParams_2.DesiredEndingAtoms[0].Scale = 1.0f;
			//AnimParams_2.DesiredEndingAtoms[0].Translation = World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);

			AnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams_2);
			TimeoutSeconds += AnimSequence.GetAnimPlaybackLength();

			if (bHumanoidTarget)
			{
				// If the target is humanoid, we just play the second part of getting skulljacked animation.
				//TargetPlayingSequence = TargetPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(TargetAnimParams_2);

				//UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), TargetAnimParams_2.AnimName, World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation));
			}
			else
			{
				// If not, enable ragdoll and attach the target by the head to the skirmisher's right arm.
			}
			
			// Endeaden the target
			StopAllPreviousRunningActions(TargetGameUnit);
			TargetGameUnit.SetForceVisibility(eForceVisible);
			VisualizationMgr.SetInterruptionSloMoFactor(Metadata.VisualizeActor, 1.0f); //Ensure Time Dilation is full speed
			TargetGameUnit.PreDeathRotation = TargetPawn.Rotation;
			TargetGameUnit.OnDeath(none, Unit);
			TargetPawn.SetFinalRagdoll(true);
			TargetPawn.TearOffMomentum = Normal(TargetPawn.Location - UnitPawn.Location); // vect(0, 0, 0);
			TargetPawn.PlayDying(none, TargetPawn.GetHeadshotLocation(), 'FF_SkulljackedStop', World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation));
			TargetGameUnit.GotoState('Dead');
			TargetPawn.GetAnimTreeController().SetAllowNewAnimations(false); // Turn off new animation playing

			FinishAnim(AnimSequence);
			//FinishAnim(TargetPlayingSequence);
		}
	}
	else
	{
		//Notify that the ability hit if the fire animation could not be completed. Failure to 
		`XEVENTMGR.TriggerEvent('Visualizer_AbilityHit', self, self);
		`redscreen("Fire action failed to play animation" @ AnimParams.AnimName @ "for ability" @ string(AbilityTemplate.DataName) @ ". This is an ability configuration error! @gameplay");
	}

	for( x =0; x < PerkAdditiveAnimNames.Length; ++x )
	{
		AdditiveAnimParams.AnimName = PerkAdditiveAnimNames[x];
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AdditiveAnimParams);
	}
	for (x = 0; x < ShooterAdditiveAnims.Length; ++x)
	{
		AdditiveAnimParams.AnimName = ShooterAdditiveAnims[x];
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AdditiveAnimParams);
	}

	//Signal that we are done with our fire animation
	`XEVENTMGR.TriggerEvent('Visualizer_AnimationFinished', self, self);

	// Taking a shot causes overwatch to be removed
	PresentationLayer.m_kUnitFlagManager.RealizeOverwatch(Unit.ObjectID, History.GetCurrentHistoryIndex());

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	SetTargetUnitDiscState();

	if( FOWViewer != none )
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);

		if( XGUnit(PrimaryTarget).IsAlive() )
		{
			XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
			XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
		}
		else
		{
			//Force dead bodies visible
			XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
			XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
		}
	}

	if( SourceFOWViewer != none )
	{
		`XWORLD.DestroyFOWViewer(SourceFOWViewer);

		Unit.SetForceVisibility(eForceNone);
		Unit.GetPawn().UpdatePawnVisibility();
	}

	//Wait for any projectiles we created to finish their trajectory before continuing
	while ( ShouldWaitToComplete() )
	{
		Sleep(0.0f);
	};

	CompleteAction();
	
	//reset to false, only during firing would the projectile be able to overwrite aim
	UnitPawn.ProjectileOverwriteAim = false;
}

function float TileDistanceBetween()
{
	local vector UnitLoc;
	local vector TargetLoc;

	UnitLoc = World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
	TargetLoc = World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);

	return VSize(UnitLoc - TargetLoc) / World.WORLD_StepSize; 
}

function vector GetTargetDragLocation()
{
	// 0.65 sec after animation start: begin drag
	// 1.9 sec: finish drag
	// Hit comes at 0.4 sec
}

/*
simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		Unit.CurrentFireAction = self;
	}

	simulated event Tick( float fDeltaT )
	{	
		NotifyTargetTimer -= fDeltaT;		

		if( bUseAnimToSetNotifyTimer && !bNotifiedTargets && NotifyTargetTimer < 0.0f )
		{
			NotifyTargetsAbilityApplied();
		}

		UpdateAim(fDeltaT);
	}

	simulated function UpdateAim(float DT)
	{
		if (PrimaryTargetID == SourceUnitState.ObjectID) //We can't aim at ourselves, or IK will explode
			return;

		if(class'XComTacticalGRI'.static.GetReactionFireSequencer().FiringAtMovingTarget())
		{
			//Use a special aiming location if we are part of a reaction fire sequence
			UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
		}		
		else if(!bNotifiedTargets && !bHaltAimUpdates && !UnitPawn.ProjectileOverwriteAim ) //Projectile overwrites the normal aim upon firing, as projectile have the ability to miss Chang You Wong 2015-23-6
		{
			if((PrimaryTarget != none) && AbilityContext.ResultContext.HitResult != eHit_Miss)
			{
				UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
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
			}
		}
	}

	function SetTargetUnitDiscState()
	{
		if( TargetUnit != None && TargetUnit.IsMine() )
		{
			TargetUnit.SetDiscState(eDS_Hidden);
		}

		if( Unit != None )
		{
			Unit.SetDiscState(eDS_Hidden);
		}
	}

	function HideFOW()
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		SourceFOWViewer = `XWORLD.CreateFOWViewer(Unit.GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);
		Unit.SetForceVisibility(eForceVisible);
		Unit.GetPawn().UpdatePawnVisibility();
	}

Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	

	// ## 1. Play firing animation.
	//Params.AnimName = 'NO_ShadowTeleport_Fire';
	//FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	// send messages to do the window break visualization
	//SendWindowBreakNotifies();

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	// ## 2. Play jumping into teleport animation.
	//Params.AnimName = 'NO_ShadowTeleport_Start';
	//DesiredLocation.Z = Unit.GetDesiredZForLocation(DesiredLocation);
	//DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	//StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	//StartingAtom.Translation = UnitPawn.Location;
	//StartingAtom.Scale = 1.0f;
	//UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);
	//
	//PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	//
	//// Play the animation until there's less than 0.1 seconds left
	//while (PlayingSequence.AnimSeq.SequenceLength - PlayingTime > 0.1f)
	//{
	//	Sleep(0.05f);
	//	PlayingTime += 0.05f;
	//}
	//
	//// Then hide the pawn. The final part of the animation moves the pawn by the pelvis to a X coordinate
	//// that is somewhat close to the X coordinate of the next "jumping out of the teleport" animation, so we achieve better animation sync this way.
	//GameUnit.m_bForceHidden = true;
	//UnitPawn.UpdatePawnVisibility();
	//
	//// Make unit aim at the enemy location
	//UnitPawn.TargetLoc = TargetUnitLocation;
	//UnitPawn.SetLocationNoCollisionCheck(DesiredLocation);
	//
	//FinishAnim(PlayingSequence);
	//
	//// ## 3. Play jumping out of teleport animation.
	//Params = default.Params;
	//Params.AnimName = 'NO_ShadowTeleport_Stop';
	//
	//Params.DesiredEndingAtoms.Add(1);
	//Params.DesiredEndingAtoms[0].Scale = 1.0f;
	//Params.DesiredEndingAtoms[0].Translation = DesiredLocation;
	//DesiredRotation.Pitch = 0.0f;
	//DesiredRotation.Roll = 0.0f;
	//Params.DesiredEndingAtoms[0].Rotation = QuatFromRotator(DesiredRotation);
	//
	//PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	//
	//// Play a bit of the animation so that the pawn can get into the position
	//Sleep(0.05f);
	//
	//// And only then unhide it.
	//GameUnit.m_bForceHidden = false;
	//UnitPawn.UpdatePawnVisibility();
	//
	//FinishAnim(PlayingSequence);
	//
	//
	//UnitPawn.bSkipIK = false;
	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();
}
*/