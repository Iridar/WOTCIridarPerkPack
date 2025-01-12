class X2TargetingMethod_RifleGrenade extends X2TargetingMethod_Grenade;

// This custom targeting method is used for the Rifle Grenade ability.
// It uses a custom Grenade Path class to remove visual bounces from the previewed trajectory,
// as well as to raise the trajectory whenever there's a unit at the center of the targeted area.
// We also mark that unit with a sword crosshair to denote a "direct hit", which does bonus damage under ability's gameplay logic.

var private UITacticalHUD	TacticalHUD;
var private vector			TargetedLocation;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComWeapon WeaponEntity;
	local PrecomputedPathData WeaponPrecomputedPathData;
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;
	
	super(X2TargetingMethod).Init(InAction, NewTargetIndex);
	
	AssociatedPlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	
	// determine our targeting range
	TargetingRange = Ability.GetAbilityCursorRangeMeters();
	
	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);
	
	// set the cursor location to itself to make sure the chain distance updates
	Cursor.CursorSetLocation(Cursor.GetCursorFeetLocation(), false, true); 
	
	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;
	
	GetGrenadeWeaponInfo(WeaponEntity, WeaponPrecomputedPathData);
	// Tutorial Band-aid #2 - Should look at a proper fix for this
	if (WeaponEntity.m_kPawn == none)
	{
		WeaponEntity.m_kPawn = FiringUnit.GetPawn();
	}
	
	// Spawn a custom path here.
	GrenadePath = `BATTLE.spawn(class'XComPrecomputedPath_CustomPath');
	XComPrecomputedPath_CustomPath(GrenadePath).UpdateGrenadePathFn = UpdateGrenadePath;
	GrenadePath.ClearOverrideTargetLocation(); // Clear this flag in case the grenade target location was locked.
	GrenadePath.ActivatePath(WeaponEntity, FiringUnit.GetTeam(), WeaponPrecomputedPathData);
	
	// setup the blast emitter
	ExplosionEmitter = `BATTLE.spawn(class'XComEmitter');
	if(AbilityIsOffensive)
	{
		ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere", class'ParticleSystem')));
	}
	else
	{
		ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere_Neutral", class'ParticleSystem')));
	}
	ExplosionEmitter.LifeSpan = 60 * 60 * 24 * 7; // never die (or at least take a week to do so)

	TacticalHUD = `PRES.GetTacticalHUD();
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;

	NewTargetLocation = GetSplashRadiusCenter();

	if (NewTargetLocation != CachedTargetLocation)
	{		
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawAOETiles(Tiles);

		MaybeUpdateTargetForUnitOnTile(NewTargetLocation, UnitState.GetReference());
		TargetedLocation = NewTargetLocation;
		
		UpdateGrenadePath();
		MarkDirectImpactTarget(NewTargetLocation);
	}
	DrawSplashRadius( );

	super(X2TargetingMethod).Update(DeltaTime);
}

// Adjusted to not care about grenade path, so that by raising the path's impact point when targeting a unit, we don't also raise the splash radius indicator.
simulated protected function Vector GetSplashRadiusCenter( bool SkipTileSnap = false )
{
	local vector Center;
	local TTile SnapTile;

	Center = Cursor.GetCursorFeetLocation();
	if (SnapToTile && !SkipTileSnap)
	{
		SnapTile = `XWORLD.GetTileCoordinatesFromPosition( Center );
		
		// keep moving down until we find a floor tile.
		while ((SnapTile.Z >= 0) && !`XWORLD.GetFloorPositionForTile( SnapTile, Center ))
		{
			--SnapTile.Z;
		}
	}

	return Center;
}

private function MarkDirectImpactTarget(const vector VectorLocation)
{
	local XComWorldData					World;
	local TTile							TileLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local XGUnit						GameUnitOnTile;
	local XComGameState_Unit			UnitOnTile;

	World = `XWORLD;

	TileLocation = World.GetTileCoordinatesFromPosition(VectorLocation);
	TargetsOnTile = World.GetUnitsOnTile(TileLocation);

	if (TargetsOnTile.Length > 0)
	{
		UnitOnTile = GetLivingUnitFromHistory(TargetsOnTile);
		if (UnitOnTile != none)
		{
			GameUnitOnTile = XGUnit(UnitOnTile.GetVisualizer());
			if (GameUnitOnTile != none)
			{
				TacticalHUD.m_kTargetReticle.SetTarget(GameUnitOnTile);
				TacticalHUD.m_kTargetReticle.SetMode(eUIReticle_Sword);
				TacticalHUD.m_kTargetReticle.SetVisible(true);
			}
		}
	}
	else
	{
		TacticalHUD.m_kTargetReticle.SetTarget();
		TacticalHUD.m_kTargetReticle.SetVisible(false);
	}
}

static private function XComGameState_Unit GetLivingUnitFromHistory(array<StateObjectReference>	TargetsOnTile)
{
	local XComGameStateHistory	History;
	local StateObjectReference	UnitRef;
	local XComGameState_Unit	TileUnitState;

	History = `XCOMHISTORY;
	foreach TargetsOnTile(UnitRef)
	{
		TileUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (TileUnitState == none)
			continue;

		if (TileUnitState.IsDead())
			continue;

		if (TileUnitState.GetMyTemplate().bIsCosmetic)
			continue;

		return TileUnitState;
	}
	return none;
}

static final function MaybeUpdateTargetForUnitOnTile(out vector VectorLocation, const StateObjectReference ShooterRef)
{
	local XComWorldData					World;
	local TTile							TileLocation;
	local array<StateObjectReference>	TargetsOnTile;
	local XComGameStateHistory			History;
	local XGUnit						GameUnit;

	World = `XWORLD;

	TileLocation = World.GetTileCoordinatesFromPosition(VectorLocation);
	TargetsOnTile = World.GetUnitsOnTile(TileLocation);

	//	If there's a unit on the tile, or the tile contains a high cover object
	if (TargetsOnTile.Length > 0)
	{
		History = `XCOMHISTORY;
		GameUnit = XGUnit(History.GetVisualizer(TargetsOnTile[0].ObjectID));
		if (GameUnit != none)
		{
			VectorLocation = GameUnit.GetShootAtLocation(eHit_Success, ShooterRef);
		}
	}
}

// This will make the projectile visible impact the target, but it will also alter where the actual explosion happens, and I'd rather not do that.

function GetTargetLocations(out array<Vector> TargetLocations)
{
	//local vector LocTargetLocation;

	super.GetTargetLocations(TargetLocations);

	`LOG("Target Location from Targeting Method:" @ TargetLocations[0],, 'IRITEST');
}


private function UpdateGrenadePath()
{
	UpdateGrenadePathTarget(GrenadePath, FiringUnit.Location, TargetedLocation);
}

// Needed to add some vertical shift for the trajectory for a "direct hit" on the targeted unit.
static final function UpdateGrenadePathTarget(XComPrecomputedPath LocGrenadePath, const vector PathStartLocation, const vector PathEndLocation)
{
	local float		iKeyframes;
	local float		i;
	local float		Delta;
	local vector	KeyPosition;
	local float		VerticalShift;
	local float		MaxVerticalShift;
	local float		Distance;
	
	iKeyframes = LocGrenadePath.iNumKeyframes;

	// These are probably unnecessary
	LocGrenadePath.bUseOverrideSourceLocation = true;
	LocGrenadePath.OverrideSourceLocation = PathStartLocation;
	LocGrenadePath.bUseOverrideTargetLocation = true;
	LocGrenadePath.OverrideTargetLocation = PathEndLocation;

	Distance = VSize(PathEndLocation - PathStartLocation);

	// 0.1f is an arbitrary "trajectory curvature coefficient". If I was smarter, I'd write an actual function that would calculate realistic trajectory curvature based on speed and free fall acceleration, but this is gewd enuff
	MaxVerticalShift = Distance * 0.1f; 

	for (i = 1; i < iKeyframes; i = i + 1)
	{
		Delta = i /  iKeyframes;

		// Calculate horizontal movement - this is a straight line at this point
		KeyPosition = PathStartLocation * (1 - Delta) + PathEndLocation * Delta;
		
		// This creates a parabolic trajectory. The sin function scales from 0 to 1 at Pi/2 then back to 0 at Pi.
		VerticalShift = MaxVerticalShift * Sin(Delta * const.Pi);
		
		KeyPosition.Z += VerticalShift;

		LocGrenadePath.akKeyframes[i].vLoc = KeyPosition;
	}
}

// super.Committed() calls Canceled() too.
function Canceled()
{
	super.Canceled();

	GrenadePath.ClearPathGraphics();
	GrenadePath.Destroy();
}
