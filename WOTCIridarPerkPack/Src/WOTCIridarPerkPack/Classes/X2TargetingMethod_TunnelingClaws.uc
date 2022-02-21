class X2TargetingMethod_TunnelingClaws extends X2TargetingMethod_VoidRift;

var protected X2Actor_ConeTarget ConeActor;
var protected vector FiringLocation;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	super.Init(InAction, NewTargetIndex);

	FiringLocation = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);

	// setup the targeting mesh
	ConeActor = `BATTLE.Spawn(class'X2Actor_ConeTarget');
	ConeActor.MeshLocation = "IRIAnimalAbilities.Meshes.TunnelingClaws_Plane";
	ConeActor.InitConeMesh(1, 1);
	ConeActor.SetLocation(FiringLocation);
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;
	local Vector ShooterToTarget;
	local Rotator ConeRotator;

	NewTargetLocation = Cursor.GetCursorFeetLocation();

	if (NewTargetLocation != CachedTargetLocation)
	{		
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, FiringUnit.GetTeam());
	}
	
	super(X2TargetingMethod).Update(DeltaTime);

	if (ConeActor != none)
	{
		ShooterToTarget = NewTargetLocation - FiringLocation;
		ConeRotator = rotator(ShooterToTarget);

		//	Make the targeting mesh parallel to the ground
		ConeRotator.Pitch = 0;
		ConeActor.SetRotation(ConeRotator);
	}
}

function Canceled()
{
	super.Canceled();
	// clean up the ui
	ConeActor.Destroy();
}

function bool GetAbilityIsOffensive()
{
	return true;
}

defaultproperties
{
	ProjectileTimingStyle=""
	OrdnanceTypeName=""
}