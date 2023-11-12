class X2Action_Fire_ObeliskVolt extends X2Action_Fire_Volt;

private function vector GetObeliskFiringLocation()
{
	local XComGameState_Effect			ObeliskEffect;
	local XComGameState_Destructible	ObeliskState;
	local TTile							ObeliskFiringTile;

	ObeliskEffect = SourceUnitState.GetUnitAffectedByEffectState('IRI_TM_Obelisk_Effect');
	if (ObeliskEffect == none)
		return vect(0, 0, 0);

	ObeliskState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(ObeliskEffect.CreatedObjectReference.ObjectID));
	if (ObeliskState == none)
		return vect(0, 0, 0);

	ObeliskFiringTile = ObeliskState.TileLocation;
	ObeliskFiringTile.Z += 2;

	return `XWORLD.GetPositionFromTileCoordinates(ObeliskFiringTile);
}

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

function UpdateSingleTether(int TetherIndex, int FirstObjectID, int SecondObjectID, Name StartSocket, Name EndSocket, optional out vector Origin, optional out vector Delta)
{
	local XComUnitPawn FirstTethered, SecondTethered;
	local Vector FirstLocation, SecondLocation;
	local Vector FirstToSecond;
	local float DistanceBetween;
	local Vector DistanceBetweenVector;

	FirstTethered = XGUnit(History.GetVisualizer(UnitsTethered[TetherIndex])).GetPawn();
	SecondTethered = XGUnit(History.GetVisualizer(UnitsTethered[TetherIndex + 1])).GetPawn();

	FirstTethered.Mesh.GetSocketWorldLocationAndRotation(StartSocket, FirstLocation);
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

DefaultProperties
{
	//AnimName = "HL_Obelisk_Volt"
}
