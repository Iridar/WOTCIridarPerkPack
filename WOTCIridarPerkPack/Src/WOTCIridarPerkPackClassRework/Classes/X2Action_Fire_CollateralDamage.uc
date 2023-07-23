class X2Action_Fire_CollateralDamage extends X2Action_Fire_SaturationFire;

var private X2AbilityMultiTarget_Radius RadiusTemplate;
var private int iCurrentPass;

function Init()
{
	local Vector TempDir;
	local float degree, testDegree, degreeDelta;
	local TTile tile;
	local bool found;

	local float a;

	super.Init();

	UnitPawn.AimEnabled = true;
	
	SetFireParameters(false, , false);		// Notify targets individually and not at once
	
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	if (AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_Cone')
	{
		RadiusTemplate = X2AbilityMultiTarget_Radius(AbilityState.GetMyTemplate().AbilityMultiTargetStyle);

		ConeLength = `UNITSTOMETERS(VSize(AbilityContext.InputContext.TargetLocations[0] - self.Unit.Location));

		// Widen the cone a little bit so the sweep looks more natural when hitting outer units
		ConeWidth = RadiusTemplate.GetTargetRadius(AbilityState) + class'XComWorldData'.const.WORLD_STEPSIZE;

		StartLocation = UnitPawn.Location;
		EndLocation = AbilityContext.InputContext.TargetLocations[0];

		ConeDir = EndLocation - StartLocation;
		UnitDir = Normal(ConeDir);

		ConeAngle = ConeWidth / ConeLength;

		ArcDelta = ConeAngle / Duration;

		degreeDelta = ConeAngle / (ConeWidth / 96);

		TempDir.x = UnitDir.x * cos(-ConeAngle / 2) - UnitDir.y * sin(-ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(-ConeAngle / 2) + UnitDir.y * cos(-ConeAngle / 2);
		TempDir.z = 0;

		SweepEndLocation_Begin = StartLocation + (TempDir * VSize(ConeDir));

		TempDir.x = UnitDir.x * cos(ConeAngle / 2) - UnitDir.y * sin(ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(ConeAngle / 2) + UnitDir.y * cos(ConeAngle / 2);
		TempDir.z = 0;

		SweepEndLocation_End = StartLocation + (TempDir * VSize(ConeDir));


		for (degree = 0; degree < ConeAngle; degree += degreeDelta)
		{
			testDegree = degree - (ConeAngle / 2);

			TempDir.x = UnitDir.x * cos(testDegree) - UnitDir.y * sin(testDegree);
			TempDir.y = UnitDir.x * sin(testDegree) + UnitDir.y * cos(testDegree);
			TempDir.z = 0;

			EndLocation = StartLocation + (TempDir * VSize(ConeDir));

			tile = `XWORLD.GetTileCoordinatesFromPosition(EndLocation);
			found = false;
			a = VSize(EndLocation - StartLocation);
			while (found == false && a >= (class'XComWorldData'.const.WORLD_STEPSIZE * 2))
			{
				found = FindTile(tile, AbilityContext.InputContext.VisibleTargetedTiles);

				if (found == false)
				{
					if (FindTile(tile, CornerTiles) == false)
					{
						CornerTiles.AddItem(tile);
					}
					EndLocation -= (TempDir * class'XComWorldData'.const.WORLD_STEPSIZE);
					tile = `XWORLD.GetTileCoordinatesFromPosition(EndLocation);
					a = VSize(EndLocation - StartLocation);
				}
			}
		}

		TargetsLeftToNotify = AbilityContext.InputContext.MultiTargets;
	}

	currDuration = 0.0;
	beginAnim = false;
	doneAnim = false;
}
/*
simulated state Executing
{
	simulated event Tick(float fDeltaT)
	{
		local StateObjectReference targetIter;
		local XComGameState_Unit targetUnitState;
		local XComGameState_Destructible targetDestructibleState;
		local Vector tilePoint;
		local Rotator hittingTargetRotator;
		local Rotator currentAimingRotator;

		NotifyTargetTimer -= fDeltaT;

		if (bUseAnimToSetNotifyTimer && !bNotifiedTargets && NotifyTargetTimer < 0.0f)
		{
			NotifyTargetsAbilityApplied();
		}

		UpdateAim(fDeltaT);
		
		//Sweep across the targets - notify those we've passed
		currentAimingRotator = Rotator(EndLocation - StartLocation);
		foreach TargetsLeftToNotify(targetIter)
		{
			targetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(targetIter.ObjectID));
			targetDestructibleState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(targetIter.ObjectID));

			if (targetUnitState != None)
				tilePoint = `XWORLD.GetPositionFromTileCoordinates(targetUnitState.TileLocation);
			else if (targetDestructibleState != None)
				tilePoint = `XWORLD.GetPositionFromTileCoordinates(targetDestructibleState.TileLocation);
			else
				continue;

			hittingTargetRotator = Rotator(tilePoint - StartLocation);
			if (Normalize(hittingTargetRotator - currentAimingRotator).Yaw < 0) //We passed this target
			{
				// VISUALIZATION REWRITE - MESSAGE
				TargetsLeftToNotify.RemoveItem(targetIter);
				break; //To avoid issues modifying an array while in a foreach
			}
		}
	}

	simulated function UpdateAim(float DT)
	{
		local float angle;
		local Vector TempDir;
		local bool aimDone;

		aimDone = true;

		if (UnitPawn.AimEnabled)
		{
			aimDone = false;

			angle = ArcDelta * currDuration - (ConeAngle / 2);

			
			TempDir.z = 0;

			if (iCurrentPass == 1)
			{
				TempDir.x = UnitDir.x * cos(angle) + UnitDir.y * sin(angle);
				TempDir.y = UnitDir.x * sin(angle) - UnitDir.y * cos(angle);
				EndLocation = StartLocation - (TempDir * VSize(ConeDir));
			}
			else
			{
				TempDir.x = UnitDir.x * cos(angle) - UnitDir.y * sin(angle);
				TempDir.y = UnitDir.x * sin(angle) + UnitDir.y * cos(angle);
				EndLocation = StartLocation + (TempDir * VSize(ConeDir));
			}
		
			//blend aim anim
			UnitPawn.TargetLoc = EndLocation;

			if (currDuration > 1)
			{
				currDuration = 0;
				iCurrentPass++;

				StartLocation = UnitPawn.TargetLoc;
			}
		}

		if (!aimDone)
		{
			currDuration += DT;

			if (iCurrentPass > 2)
			{
				currDuration = Duration;
				aimDone = true;
			}
		}

		if (aimDone && currDuration > 0.0)
		{
			CompleteAction();
		}
	}

	function SetTargetUnitDiscState()
	{
		local XGUnit ThisTargetUnit;

		ThisTargetUnit = XGUnit(PrimaryTarget);
		if (ThisTargetUnit != None && ThisTargetUnit.IsMine())
		{
			ThisTargetUnit.SetDiscState(eDS_Hidden);
		}

		if (Unit != None)
		{
			Unit.SetDiscState(eDS_Hidden);
		}
	}
	
Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral || XGUnit(PrimaryTarget).GetTeam() == eTeam_Resistance)
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	Unit.CurrentFireAction = self;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	while (!bNotifiedTargets && !IsTimedOut())
		Sleep(0.0f);

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	if (IsTimedOut())
	{
		NotifyTargetsAbilityApplied();
	}

	SetTargetUnitDiscState();

	if (FOWViewer != none)
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);
		XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
	}

	CompleteAction();
}*/
