class X2Action_PredatorStrike_Death extends X2Action_Death;

var private bool				bDoOverride;
var private AnimNodeSequence	SecondAnimSequence;
var private CustomAnimParams	SecondAnimParams;
var private vector				ShooterLocation;
var private vector				LocationShift;
var private vector				LocationShiftDirection;
var private float				PlayingTime;

function Init()
{
	super.Init();

	if (UnitPawn.GetAnimTreeController().CanPlayAnimation('FF_SkulljackedStart'))
	{	
		bDoOverride = true;
		UnitPawn.bUseDesiredEndingAtomOnDeath = false;
		//bWaitUntilNotified = true;
		`AMLOG("Target pawn CAN play animation");
	}
	else
	{
		`AMLOG("Target pawn CANNOT play animation");
	}
}

//event OnAnimNotify(AnimNotify ReceiveNotify)
//{
//    super.OnAnimNotify(ReceiveNotify);
//
//    if((XComAnimNotify_NotifyTarget(ReceiveNotify) != none) && (AbilityContext != none))
//    {
//        bWaitUntilNotified = false;
//    }
//}

static function bool AllowOverrideActionDeath(VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(XComGameStateContext_Ability(Context).InputContext.AbilityRef.ObjectID, eReturnType_Reference));
	if (AbilityState != none && AbilityState.GetMyTemplate().ActionFireClass == class'X2Action_PredatorStrike')
	{
		return true;
	}
	return false;
}

function bool ShouldRunDeathHandler()
{
	if (bDoOverride)
	{
		return false;
	}
	return super.ShouldRunDeathHandler();
}

function bool ShouldPlayDamageContainerDeathEffect()
{
	if (bDoOverride)
	{
		return false;
	}
	return super.ShouldPlayDamageContainerDeathEffect();
}

function bool DamageContainerDeathSound()
{
	if (bDoOverride)
	{
		return false;
	}
	return super.DamageContainerDeathSound();
}

simulated state Executing
{	

Begin:
	`AMLOG("Running");
	StopAllPreviousRunningActions(Unit);

	Unit.SetForceVisibility(eForceVisible);

	//Ensure Time Dilation is full speed
	VisualizationMgr.SetInterruptionSloMoFactor(Metadata.VisualizeActor, 1.0f);

	Unit.PreDeathRotation = UnitPawn.Rotation;

	if (!UnitPawn.bPlayedDeath)
	{
		`AMLOG("Unit played death:" @ UnitPawn.bPlayedDeath);
		if (bDoOverride)
		{
			// Always allow new animations to play.
			UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

			SecondAnimParams.AnimName = 'FF_SkulljackedStart';
			SecondAnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(SecondAnimParams);
			SecondAnimSequence.SetEndTime(4.0f);
			TimeoutSeconds += SecondAnimSequence.GetAnimPlaybackLength();

			`AMLOG("Initial Z:" @ UnitPawn.Location.Z);
			
			ShooterLocation = DamageDealer.Location;
			ShooterLocation.Z -= 15;

			// Move the target to be on slightly lower Z level than the shooter for better alignment with ripjack blade
			// This is instant teleport at the start of the animation, ugly, but don't got much choice
			// And it should be fine since cinescript starts on the ~same frame
			LocationShift = UnitPawn.Location;
			LocationShift.Z = ShooterLocation.Z;

			UnitPawn.EnableRMA(true, true);
			UnitPawn.EnableRMAInteractPhysics(true);
			UnitPawn.SetCollision(false /* bCollideActors */, false /* bBlockActors */, true /* bIgnoreEncroachers */);
			UnitPawn.SetLocationNoCollisionCheck(LocationShift);

			`AMLOG("Adjusted Z:" @ UnitPawn.Location.Z);

			Sleep(0.4f);

			LocationShiftDirection = (ShooterLocation - UnitPawn.Location) / 60;

			// Translate the target towards the attacker until they're slightly closer than 1 tile apart
			// for better ripjack alignment
			while (VSize(UnitPawn.Location - ShooterLocation) > 93.0f || PlayingTime > 1.5f)
			{	
				UnitPawn.SetLocationNoCollisionCheck(UnitPawn.Location + LocationShiftDirection);
				Sleep(0.01f);
				PlayingTime += 0.01f;

				`AMLOG("Distance:" @ VSize(UnitPawn.Location - ShooterLocation) @ UnitPawn.Location.Z);
			}

			`AMLOG("Start");


			//UnitPawn.UnitSpeak('TakingDamage'); //This doesn't work.
			// And apparently can't work, "I'm hurt" voice is played by specific AkEvents called by specific animations

			// Play the death scream 2 seconds into the animation
			Sleep(1.5f - PlayingTime);
			UnitPawn.UnitSpeak('DeathScream');

			FinishAnim(SecondAnimSequence);
			`AMLOG("Finished anim.");
		}

		
		//Unit.OnDeath(m_kDamageType, XGUnit(DamageDealer));
		OnDeath();

		if (bDoOverride)
		{
			AnimationName = 'FF_SkulljackedStop';
		}
		else
		{
			AnimationName = ComputeAnimationToPlay();
		}

		`AMLOG("AnimationName:" @ AnimationName);

		UnitPawn.SetFinalRagdoll(true);
		UnitPawn.TearOffMomentum = vHitDir; //Use archaic Unreal values for great justice	
		UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), AnimationName, Destination);
	}

	//Since we have a unit dying, update the music if necessary
	`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();

	Unit.GotoState('Dead');

	if( bDoOverrideAnim )
	{
		// Turn off new animation playing
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	while( DoWaitUntilNotified() && !IsTimedOut() )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}

private function OnDeath()
{
	local int i;
	local XGUnit SurvivingUnit;
	local XGPlayer PlayerToNotify;	
	local bool kIsRobotic;

	// Death scream was here

	// Notify all players of the death
	for (i=0; i < `BATTLE.m_iNumPlayers; ++i)
	{
		PlayerToNotify = `BATTLE.m_arrPlayers[i];
		PlayerToNotify.OnUnitKilled(Unit, XGUnit(DamageDealer));
	}

	if (Unit.m_bInCover)
		Unit.HideCoverIcon();

	Unit.SetDiscState(eDS_Hidden); //Hide the unit disc	

	if(!Unit.PRES().USE_UNIT_RING)
		Unit.m_kDiscMesh.SetHidden(true);

	Unit.m_bStunned = false;

	Unit.m_bIsFlying = false;

	if( !Unit.IsActiveUnit() )
		Unit.GotoState( 'Dead' );

	if( Unit.m_kForceConstantCombatTarget != none )
	{
		Unit.m_kForceConstantCombatTarget.m_kConstantCombatUnitTargetingMe = none;
	}

	if( Unit.m_kConstantCombatUnitTargetingMe != none )
	{
		Unit.m_kConstantCombatUnitTargetingMe.ConstantCombatSuppress(false,none);
		Unit.m_kConstantCombatUnitTargetingMe = none;
	}

	//RAM - Constant Combat

	SurvivingUnit = Unit.GetSquad().GetNextGoodMember();
	kIsRobotic = Unit.IsRobotic();

	if (SurvivingUnit != none && !kIsRobotic && !Unit.IsAlien_CheckByCharType())
		SurvivingUnit.UnitSpeak( 'SquadMemberDead' );
}
