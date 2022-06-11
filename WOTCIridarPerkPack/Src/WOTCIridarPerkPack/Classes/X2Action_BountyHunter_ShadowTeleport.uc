class X2Action_BountyHunter_ShadowTeleport extends X2Action_Fire;

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
var private float PlayingTime;
var private XGUnit GameUnit;

function Init()
{
	super.Init();

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	TargetUnitLocation = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
	TargetUnitLocation.Z += class'XComWorldData'.const.WORLD_FloorHeight;

	//DesiredEndRotation = UnitPawn.Rotation;
	// Desired rotation is towards enemy location.
	DesiredEndRotation = Rotator(Normal(TargetUnitLocation - DesiredLocation));
	DesiredEndRotation.Pitch = 0.0f;
	DesiredEndRotation.Roll = 0.0f;

	GameUnit = XGUnit(History.GetVisualizer(AbilityContext.InputContext.SourceObject.ObjectID));
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
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	// send messages to do the window break visualization
	SendWindowBreakNotifies();

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	// ## 2. Play jumping into teleport animation.
	Params.AnimName = 'NO_ShadowTeleport_Start';
	DesiredLocation.Z = Unit.GetDesiredZForLocation(DesiredLocation);
	DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);

	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// Play the animation until there's less than 0.1 seconds left
	while (PlayingSequence.AnimSeq.SequenceLength - PlayingTime > 0.1f)
	{
		Sleep(0.05f);
		PlayingTime += 0.05f;
	}
	
	// Then hide the pawn. The final part of the animation moves the pawn by the pelvis to a X coordinate
	// that is somewhat close to the X coordinate of the next "jumping out of the teleport" animation, so we achieve better animation sync this way.
	GameUnit.m_bForceHidden = true;
	UnitPawn.UpdatePawnVisibility();

	// Make unit aim at the enemy location
	UnitPawn.TargetLoc = TargetUnitLocation;
	UnitPawn.SetLocationNoCollisionCheck(DesiredLocation);

	FinishAnim(PlayingSequence);

	// ## 3. Play jumping out of teleport animation.
	Params = default.Params;
	Params.AnimName = 'NO_ShadowTeleport_Stop';
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// Play a bit of the animation so that the pawn can get into the position
	Sleep(0.05f);

	// And only then unhide it.
	GameUnit.m_bForceHidden = false;
	UnitPawn.UpdatePawnVisibility();
	
	FinishAnim(PlayingSequence);


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