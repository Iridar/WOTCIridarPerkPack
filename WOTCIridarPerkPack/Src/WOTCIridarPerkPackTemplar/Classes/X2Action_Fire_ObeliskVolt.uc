class X2Action_Fire_ObeliskVolt extends X2Action_Fire_Volt;

var private vector	ObeliskFiringLocation;
var private AkEvent	VoltFireSound;

function Init()
{
	Super.Init();

	GetObeliskVisualFiringLocation();

	VoltFireSound = AkEvent(`CONTENT.RequestGameArchetype("XPACK_SoundCharacterFX.Templar_Volt_Fire"));
}

private function GetObeliskVisualFiringLocation()
{
	local XComGameState_Effect			ObeliskEffect;
	local XComGameState_Destructible	ObeliskState;
	local TTile							ObeliskFiringTile;

	ObeliskEffect = SourceUnitState.GetUnitAffectedByEffectState('IRI_TM_Obelisk_Effect');
	if (ObeliskEffect == none)
		return;

	ObeliskState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(ObeliskEffect.CreatedObjectReference.ObjectID));
	if (ObeliskState == none)
		return;

	ObeliskFiringTile = ObeliskState.TileLocation;
	ObeliskFiringTile.Z += 3;
	ObeliskFiringLocation = `XWORLD.GetPositionFromTileCoordinates(ObeliskFiringTile);
}
/*
function HandleSingleTarget(int ObjectID, int TargetObjectID, Name StartSocket, Name EndSocket)
{
	local XComUnitPawn FirstTethered, SecondTethered;
	local int TetherIndex;
	local Vector Origin, Delta;

	if (ObjectID > 0 && TargetObjectID > 0)
	{
		FirstTethered = XGUnit(History.GetVisualizer(ObjectID)).GetPawn();
		SecondTethered = XGUnit(History.GetVisualizer(TargetObjectID)).GetPawn();
		if(ArcTether != None && FirstTethered != None && SecondTethered != None )
		{
			// Spawn then immediately update its location/rotation to be correct
			TetherIndex = TethersSpawned.AddItem(class'WorldInfo'.static.GetWorldInfo().MyEmitterPool.SpawnEmitter(ArcTether, vect(0,0,0), Rotator(vect(0,0,0))));
			
			if( UnitsTethered.Find(ObjectID) == INDEX_NONE )
			{
				UnitsTethered.AddItem(ObjectID);
			}
			if( UnitsTethered.Find(TargetObjectID) == INDEX_NONE )
			{
				UnitsTethered.AddItem(TargetObjectID);
			}

			UpdateSingleTether(TetherIndex, ObjectID, TargetObjectID, StartSocket, EndSocket, Origin, Delta);

			`XEVENTMGR.TriggerEvent('Visualizer_ProjectileHit', History.GetGameStateForObjectID( TargetObjectID ), self);

			NotifyInterveningStateObjects( Origin, Delta );
		}
	}
}
*/
function UpdateSingleTether(int TetherIndex, int FirstObjectID, int SecondObjectID, Name StartSocket, Name EndSocket, optional out vector Origin, optional out vector Delta)
{
	local XComUnitPawn /*FirstTethered,*/ SecondTethered;
	local Vector FirstLocation, SecondLocation;
	local Vector FirstToSecond;
	local float DistanceBetween;
	local Vector DistanceBetweenVector;

	//FirstTethered = XGUnit(History.GetVisualizer(UnitsTethered[TetherIndex])).GetPawn();
	SecondTethered = XGUnit(History.GetVisualizer(UnitsTethered[TetherIndex + 1])).GetPawn();

	//FirstTethered.Mesh.GetSocketWorldLocationAndRotation(StartSocket, FirstLocation);

	FirstLocation = ObeliskFiringLocation;

	SecondTethered.Mesh.GetSocketWorldLocationAndRotation(EndSocket, SecondLocation);
	FirstToSecond = SecondLocation - FirstLocation;
	DistanceBetween = VSize(FirstToSecond);
	FirstToSecond = Normal(FirstToSecond);

	TethersSpawned[TetherIndex].SetAbsolute(true, true);
	TethersSpawned[TetherIndex].SetTranslation(FirstLocation);
	TethersSpawned[TetherIndex].SetRotation(Rotator(FirstToSecond));

	DistanceBetweenVector.X = DistanceBetween;
	DistanceBetweenVector.Y = DistanceBetween;
	DistanceBetweenVector.Z = DistanceBetween;
	TethersSpawned[TetherIndex].SetVectorParameter('Distance', DistanceBetweenVector);
	TethersSpawned[TetherIndex].SetFloatParameter('Distance', DistanceBetween);

	Origin = FirstLocation;
	Delta = SecondLocation - FirstLocation;
}

simulated state Executing
{
	simulated event Tick(float fDeltaT)
	{
		local int TetherIndex;
		local Name UseSocket;

		Super.Tick(fDeltaT);

		// Loop through our tethers and update the distance parameter and their location/rotation
		UseSocket = StartingSocket;
		for( TetherIndex = 0; TetherIndex < TethersSpawned.Length && TetherIndex + 1 < UnitsTethered.Length; ++TetherIndex )
		{
			UpdateSingleTether(TetherIndex, UnitsTethered[TetherIndex], UnitsTethered[TetherIndex + 1], UseSocket, TargetSocket);
			UseSocket = TargetSocket;
		}
	}
Begin:
	//UnitPawn.EnableRMA(true, true);
	//UnitPawn.EnableRMAInteractPhysics(true);
	
	//AnimParams.AnimName = AnimName;
	//if( bComingFromEndMove )
	//{
	//	AnimParams.DesiredEndingAtoms.Add(1);
	//	AnimParams.DesiredEndingAtoms[0].Translation = MoveEndDestination;
	//	AnimParams.DesiredEndingAtoms[0].Translation.Z = Unit.GetDesiredZForLocation(MoveEndDestination);
	//	AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(Rotator(MoveEndDirection));
	//	AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
	//
	//	Unit.RestoreLocation = AnimParams.DesiredEndingAtoms[0].Translation;
	//	Unit.RestoreHeading = vector(QuatToRotator(AnimParams.DesiredEndingAtoms[0].Rotation));
	//}
	//PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	//while( !StartChain /* &&
	//	   !IsTimedOut()*/ )	// // ADDING THIS ISTIMEDOUT UNTIL WE FIX THE VISUALIZATION FOR THESE ABILITIES
	//{
	//	Sleep(0.0f);
	//}

	if (VoltFireSound != none)
	{
		UnitPawn.PlayAkEvent(VoltFireSound,,,, ObeliskFiringLocation);
	}

	HandleSingleTarget(UnitPawn.ObjectID, PrimaryTargetID, StartingSocket, TargetSocket);

	//FinishAnim(PlayingSequence);

	CompleteAction();
}
