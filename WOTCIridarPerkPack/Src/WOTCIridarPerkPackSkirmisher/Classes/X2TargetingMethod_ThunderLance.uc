class X2TargetingMethod_ThunderLance extends X2TargetingMethod_Grenade;

// Mix of X2TargetingMethod_Grapple and X2TargetingMethod_Grenade

var private X2GrapplePuck_ThunderLance GrapplePuck;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	super.Init(InAction, NewTargetIndex);

	// create the actor to draw the target location tiles on the ground
	GrapplePuck = `CURSOR.Spawn(class'X2GrapplePuck_ThunderLance', `CURSOR);
	GrapplePuck.InitForUnitState(UnitState);
}

function Canceled()
{
	GrapplePuck.Destroy();
	super.Canceled();
}

function Committed()
{
	GrapplePuck.ShowConfirmAndDestroy();

	super.Committed();
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	local Vector TargetLocation;

	TargetLocations.Length = 0;

	if (GrapplePuck.GetGrappleTargetLocation(TargetLocation))
	{
		TargetLocations.AddItem(TargetLocation);
	}
}

simulated protected function Vector GetSplashRadiusCenter( bool SkipTileSnap = false )
{
	local vector Center;

	if (GrapplePuck.GetGrappleTargetLocation(Center))
	{
		return Center;
	}

	return vect(0, 0, 0);
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	local vector Center;

	if (GrapplePuck.GetGrappleTargetLocation(Center))
	{
		Ability.GatherAdditionalAbilityTargetsForLocation(Center, AdditionalTargets);
		return true;
	}

	return false;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	local vector Center;

	if (GrapplePuck.GetGrappleTargetLocation(Center))
	{
		Focus = Center;
		return true;
	}

	return false;
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;

	NewTargetLocation = GetSplashRadiusCenter();

	if (GrapplePuck.GetGrappleTargetLocation(NewTargetLocation) && NewTargetLocation != CachedTargetLocation)
	{
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawAOETiles(Tiles);
	}

	DrawSplashRadius( );

	super.Update(DeltaTime);
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	return TargetLocations.Length == 1 ? 'AA_Success' : 'AA_NoTargets';
}

static function bool UseGrenadePath() { return false; }