class X2Action_PredatorStrike_Death extends X2Action_Death;

var private bool				bDoOverride;
var private AnimNodeSequence	AnimSequence;
var private CustomAnimParams	AnimParams;
var private vector				LocationShift;

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

			AnimParams.AnimName = 'FF_SkulljackedStart';
			AnimSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			AnimSequence.SetEndTime(4.0f);
			TimeoutSeconds += AnimSequence.GetAnimPlaybackLength();

			LocationShift = UnitPawn.Location;

			FinishAnim(AnimSequence);
		}

		Unit.OnDeath(m_kDamageType, XGUnit(DamageDealer));

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