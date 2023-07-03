class X2Action_Fire_Faceoff_CS extends X2Action_Fire;

// Copied from Chimera Squad

var public float FireAnimBlendTime;
var bool bEnableRMATranslation;
var transient vector vTargetLocation;

var private AnimNodeSequence FireSeq;
var name AnimationOverride;

simulated state Executing
{
	// This overrides (and is based on) the parent version, but is simpler.
	simulated function UpdateAim(float DT)
	{
		local Vector NewTargetLoc;

		if (!bNotifiedTargets && !bHaltAimUpdates )
		{
			if((PrimaryTarget != none))
			{
				NewTargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
				UnitPawn.TargetLoc = NewTargetLoc;
			}
			else
			{
				UnitPawn.TargetLoc = AimAtLocation;
			}

			//If we are very close to the target, just update our aim with a more distance target once and then stop
			if(VSize(UnitPawn.TargetLoc - UnitPawn.Location) < (class'XComWorldData'.const.WORLD_StepSize * 2.0f))
			{
				bHaltAimUpdates = true;
				NewTargetLoc = UnitPawn.TargetLoc + (Normal(UnitPawn.TargetLoc - UnitPawn.Location) * 400.0f);
				UnitPawn.TargetLoc = NewTargetLoc;
			}
		}
	}

	// Snap-Rotate the unit if it is facing too far away from the target.
	simulated function SnapUnitPawnToTargetDirIfNeeded()
	{
		local vector   vTargetDir;
		local Rotator  DesiredRotation;
		local float    fDot;

		vTargetDir = vTargetLocation - UnitPawn.Location;
		vTargetDir.Z = 0;
		vTargetDir = normal(vTargetDir);
		fDot = vTargetDir dot vector(UnitPawn.Rotation);

		// 90 degrees check.
		if (fDot < 0.0f)
		{
			DesiredRotation = Normalize(Rotator(vTargetDir));
			DesiredRotation.Pitch = 0;
			DesiredRotation.Roll = 0;
			UnitPawn.SetRotation( DesiredRotation );
		}
	}

Begin:

	UnitPawn.EnableRMA(bEnableRMATranslation, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	SnapUnitPawnToTargetDirIfNeeded();

	AnimParams.BlendTime = FireAnimBlendTime;

	if (AnimationOverride != '')
	{
		AnimParams.AnimName = AnimationOverride;

		
	}
	`AMLOG("AnimParams.AnimName:" @ AnimParams.AnimName);
	// Iridar: 
	// Skip first part of the fire animation where the soldier pulls out their sword
	AnimParams.StartOffsetTime = 0.5f;
	FireSeq = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	// Iridar: skip ending part of the fire animation where the soldier puts their sword back.
	FireSeq.SetEndTime(1.3f);

	FinishAnim(FireSeq);

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	SetTargetUnitDiscState();

	if (FOWViewer != none)
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);

		if(XGUnit(PrimaryTarget).IsAlive())
		{
			XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
			XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
		}
	}

	CompleteAction();
}

defaultproperties
{
	FireAnimBlendTime=0.25f
	bEnableRMATranslation=true
}