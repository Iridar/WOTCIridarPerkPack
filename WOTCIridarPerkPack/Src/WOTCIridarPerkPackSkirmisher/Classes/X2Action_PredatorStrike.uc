class X2Action_PredatorStrike extends X2Action_Fire;

var private vector			FixupOffset;
var private XComUnitPawn	TargetPawn;
var private vector			OriginalTranslation;
var private float			fPlayingTime;
var private float			OriginalOffset;
var private bool			bDoOverride;

/*
FF_PredatorStrikeMissA
FF_PredatorStrikeStartA
FF_PredatorStrikeStopA

FF_SkulljackedMissA
FF_SkulljackedStartA
FF_SkulljackedStopA

HL_HurtFrontA
*/
	
function Init()
{
	super.Init();

	TargetPawn = TargetUnit.GetPawn();
	
	if (TargetPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedStart'))
	{
		bDoOverride = true;

		// Iridar: Calculate stuff needed to match the vertical position of the shooter and target
		FixupOffset.Z = GetVerticalOffset() + 3; // Put shooter slightly higher than the attacker for better ripjack alignment
		OriginalTranslation = UnitPawn.Mesh.Translation;

		if (bWasHit)
		{
			AnimParams.AnimName = 'FF_PredatorStrikeStart';
		}
		else
		{
			AnimParams.AnimName = 'FF_PredatorStrikeMiss';
		}
	}
}

private function float GetVerticalOffset()
{
	local XComGameState_Unit	TargetUnitState;
	local vector				locTargetLocation;
	local vector				locShooterLocation;
	local XComWorldData			locWorld;
	local int					HistoryIndex;

	locWorld = `XWORLD;
	HistoryIndex = self.StateChangeContext.AssociatedState.HistoryIndex;
	TargetUnitState = TargetUnit.GetVisualizedGameState(HistoryIndex);
	if (TargetUnitState == none)
		return 0;

	locTargetLocation = locWorld.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
	locShooterLocation = locWorld.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
	
	return locTargetLocation.Z - locShooterLocation.Z;
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

		// Iridar: Apply offset to shooter's pawn mesh. Needs to be done here for some reason.
		if (bDoOverride && bWasHit)
		{
			UnitPawn.Mesh.SetTranslation(OriginalTranslation + FixupOffset);
		}
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
	
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

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

	//The fire action must complete, make sure that it can be played.
	if (UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
	{
		// Iridar: play the attack or miss animation
		AnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		TimeoutSeconds += AnimSequence.GetAnimPlaybackLength();
		FinishAnim(AnimSequence);

		// if we hit, also play the Stop animation
		if (bDoOverride && bWasHit)
		{
			AnimParams.AnimName = 'FF_PredatorStrikeStop';
			AnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			TimeoutSeconds += AnimSequence.GetAnimPlaybackLength();

			// Starting from 0.5 sec, for the next 0.35 seconds
			// scale down the vertical offset from 100% to 0%, emulating an animated stepdown instead of a jump.
			// This is needed when the target is on higher or lower elevation than the shooter,
			// and in roughly that spot in the animation the soldier is shuffling their legs, so perfect time
			// to emulate a step down or up.
			if (FixupOffset.Z != 0)
			{
				Sleep(0.5f);
				OriginalOffset = FixupOffset.Z;
				while(fPlayingTime < 0.35f)
				{	
					FixupOffset.Z = OriginalOffset * (1 - fPlayingTime / 0.35f);
					fPlayingTime += 0.01f;
					Sleep(0.01f);
				}
			}
			FinishAnim(AnimSequence);

			UnitPawn.Mesh.SetTranslation(OriginalTranslation);
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