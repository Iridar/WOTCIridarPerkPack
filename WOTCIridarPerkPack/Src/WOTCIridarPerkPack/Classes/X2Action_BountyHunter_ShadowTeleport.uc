class X2Action_BountyHunter_ShadowTeleport extends X2Action_Fire;

// MaterialInstanceTimeVarying'FX_Cyberus_Materials.M_Cyberus_Invisible_MITV'

var vector  DesiredLocation;

var private BoneAtom StartingAtom;
var private Rotator DesiredRotation;
var private CustomAnimParams Params;
var private vector StartingLocation;
var private float DistanceFromStartSquared;
var private bool ProjectileHit;
var private float StopDistanceSquared; // distance from the origin of the grapple past which we are done
var private AnimNodeSequence PlayingSequence;
var private Rotator DesiredEndRotation;

var private XComGameState_Unit TargetUnitState;
var private vector TargetUnitLocation;

function Init()
{
	super.Init();

	TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	TargetUnitLocation = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
	TargetUnitLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;

	//DesiredEndRotation = UnitPawn.Rotation;
	// Desired rotation is towards enemy location.
	DesiredEndRotation = Rotator(Normal(TargetUnitLocation - DesiredLocation));
	DesiredEndRotation.Pitch = 0.0f;
	DesiredEndRotation.Roll = 0.0f;
}
function ProjectileNotifyHit(bool bMainImpactNotify, Vector HitLocation)
{
	ProjectileHit = true;
}

simulated state Executing
{
	function SendWindowBreakNotifies()
	{	
		local XComGameState_EnvironmentDamage EnvironmentDamage;
				
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			`XEVENTMGR.TriggerEvent('Visualizer_WorldDamage', EnvironmentDamage, self);
		}
	}

Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;
	
	// ## 1. Play firing animation.
	Params.AnimName = 'NO_ShadowTeleport_Fire';
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// send messages to do the window break visualization
	// -> Earlier.
	SendWindowBreakNotifies();

	while (ProjectileHit == false)
	{
		Sleep(0.0f);
	}
	// Let projectile hit PFX play for a bit.
	Sleep(0.1f);

	// ## 2. Play jumping into teleport animation.
	Params.AnimName = 'NO_ShadowTeleport_Start';
	DesiredLocation.Z = Unit.GetDesiredZForLocation(DesiredLocation);
	DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	// Play first part of the animation, then jump teleport the unit to the end tile.
	Sleep(0.25f);
	UnitPawn.SetLocationNoCollisionCheck(DesiredLocation);

	// Make unit aim at the enemy location
	UnitPawn.TargetLoc = TargetUnitLocation;

	// ## 3. Play jumping out of teleport animation.
	Params = default.Params;
	Params.AnimName = 'NO_ShadowTeleport_Stop';
	Params.DesiredEndingAtoms.Add(1);
	Params.DesiredEndingAtoms[0].Scale = 1.0f;
	Params.DesiredEndingAtoms[0].Translation = DesiredLocation;
	Params.DesiredEndingAtoms[0].Rotation = QuatFromRotator(DesiredEndRotation);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	UnitPawn.bSkipIK = false;

	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	// since we step out of and step into cover from different tiles, 
	// need to set the enter cover restore to the destination location
	Unit.RestoreLocation = DesiredLocation;
}

defaultproperties
{
	ProjectileHit = false;
}