class X2TargetingMethod_RifleGrenade extends X2TargetingMethod_Grenade;

var private UITacticalHUD	TacticalHUD;
var private vector			TargetedLocation;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComGameStateHistory History;
	local XComWeapon WeaponEntity;
	local PrecomputedPathData WeaponPrecomputedPathData;
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityTemplate AbilityTemplate;
	
	super(X2TargetingMethod).Init(InAction, NewTargetIndex);
	
	History = `XCOMHISTORY;
	
	AssociatedPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	`assert(AssociatedPlayerState != none);
	
	// determine our targeting range
	AbilityTemplate = Ability.GetMyTemplate();
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
	
	if (UseGrenadePath())
	{
		GrenadePath = `BATTLE.spawn(class'XComPrecomputedPath_CustomPath');
		XComPrecomputedPath_CustomPath(GrenadePath).UpdateGrenadePathFn = UpdateGrenadePath;
		GrenadePath.ClearOverrideTargetLocation(); // Clear this flag in case the grenade target location was locked.
		GrenadePath.ActivatePath(WeaponEntity, FiringUnit.GetTeam(), WeaponPrecomputedPathData);
	}	
	
	if (!AbilityTemplate.SkipRenderOfTargetingTemplate)
	{
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
	}

	//super.Init(InAction, NewTargetIndex);
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

		MaybeUpdateTargetForUnitOnTile(NewTargetLocation);
		TargetedLocation = NewTargetLocation;
		
		UpdateGrenadePath();
		MarkDirectImpactTarget(NewTargetLocation);
	}
	DrawSplashRadius( );

	super(X2TargetingMethod).Update(DeltaTime);
}

// Adjusted to not care about grenade path
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

private function MaybeUpdateTargetForUnitOnTile(out vector VectorLocation)
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
			VectorLocation = GameUnit.GetShootAtLocation(eHit_Success, UnitState.GetReference());
		}
	}
}


function GetGrenadeWeaponInfo(out XComWeapon WeaponEntity, out PrecomputedPathData WeaponPrecomputedPathData)
{
	local XComGameState_Item WeaponItem;
	local X2WeaponTemplate WeaponTemplate;
	local XGWeapon WeaponVisualizer;
	
	WeaponItem = Ability.GetSourceAmmo(); // Use source ammo instead of source weapon
	
	WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
	WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
	
	// Tutorial Band-aid fix for missing visualizer due to cheat GiveItem
	if (WeaponVisualizer == none)
	{
		class'XGItem'.static.CreateVisualizer(WeaponItem);
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
		WeaponEntity = XComWeapon(WeaponVisualizer.CreateEntity(WeaponItem));
	
		if (WeaponEntity != none)
		{
			WeaponEntity.m_kPawn = FiringUnit.GetPawn();
		}
	}
	else
	{
		WeaponEntity = WeaponVisualizer.GetEntity();
	}
	
	// This won't actually be used since I use my own logic for drawing the path.
	WeaponPrecomputedPathData.InitialPathTime = 1.0f;
	WeaponPrecomputedPathData.MaxPathTime = 2.5f;
	WeaponPrecomputedPathData.MaxNumberOfBounces = 0;
}

private function UpdateGrenadePath()
{
	UpdateGrenadePathTarget(TargetedLocation);
}

// Needed to add some vertical shift for the trajectory for a "direct hit" on the targeted unit.
private function UpdateGrenadePathTarget(const vector PathEndLocation)
{
	local vector	PathStartLocation;
	local float		iKeyframes;
	local float		i;
	local float		Delta;
	local float		HalfDelta;
	local vector	KeyPosition;
	local float		VerticalShift;
	local float		MaxVerticalShift;
	local float		Distance;
	
	PathStartLocation = FiringUnit.Location;
	iKeyframes = GrenadePath.iNumKeyframes;

	// These are probably unnecessary
	GrenadePath.bUseOverrideSourceLocation = true;
	GrenadePath.OverrideSourceLocation = PathStartLocation;
	GrenadePath.bUseOverrideTargetLocation = true;
	GrenadePath.OverrideTargetLocation = PathEndLocation;

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

		GrenadePath.akKeyframes[i].vLoc = KeyPosition;
	}
}


// super.Committed() calls Canceled() too.
/*
function Canceled()
{
	super.Canceled();

	// unlock the 3d cursor
	//Cursor.m_fMaxChainedDistance = -1;

	CustomPath.ClearPathGraphics();
	//XComWeapon(WeaponVisualizer.m_kEntity).bPreviewAim = false;

	CustomPath.Destroy();
}*/