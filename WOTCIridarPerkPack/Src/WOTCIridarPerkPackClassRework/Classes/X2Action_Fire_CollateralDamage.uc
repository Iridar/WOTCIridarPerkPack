class X2Action_Fire_CollateralDamage extends X2Action_Fire_SaturationFire;

// A version of Saturation Fire, but instead of getting Cone Multi Target from ability template,
// create our own, just for this X2Action.

function Init()
{
	local Vector TempDir;
	local float degree, testDegree, degreeDelta;
	local TTile tile;
	local bool found;
	//local XComGameState_Unit LocTargetUnit;
	local XComGameStateHistory LocHistory;

	local float a;

	super(X2Action_Fire).Init();

	UnitPawn.AimEnabled = true;
	
	SetFireParameters(false, , false);		// Notify targets individually and not at once
	
	LocHistory = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(LocHistory.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	//LocTargetUnit = XComGameState_Unit(LocHistory.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	//if (AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_Cone')
	//{
		coneTemplate = new class'X2AbilityMultiTarget_Cone';
		coneTemplate.bExcludeSelfAsTargetIfWithinRadius = true;
		coneTemplate.ConeEndDiameter = 10 * class'XComWorldData'.const.WORLD_StepSize;
		coneTemplate.bUseWeaponRangeForLength = true;
		coneTemplate.fTargetRadius = 99;     //  large number to handle weapon range - targets will get filtered according to cone constraints
		coneTemplate.bIgnoreBlockingCover = true;

		ConeLength = coneTemplate.GetConeLength(AbilityState);

		// Widen the cone a little bit so the sweep looks more natural when hitting outer units
		ConeWidth = coneTemplate.GetConeEndDiameter(AbilityState) + class'XComWorldData'.const.WORLD_STEPSIZE;

		StartLocation = UnitPawn.Location;
		EndLocation = self.AbilityContext.InputContext.TargetLocations[0];
		//EndLocation = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);

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
	//}

	currDuration = 0.0;
	beginAnim = false;
	doneAnim = false;
}
