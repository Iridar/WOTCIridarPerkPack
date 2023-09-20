//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ViperGetOverHereTarget extends X2Action;

//Cached info for the unit performing the action
//*************************************
var /*private*/ XComGameStateContext_Ability AbilityContext;
var /*private*/ CustomAnimParams	Params;
var /*private*/ Vector				DesiredLocation;
var /*private*/ float				DistanceFromStartSquared;
var /*private*/ AnimNodeSequence	PlayingSequence;
var /*private*/ float				StopDistanceSquared;
	/*       */
var /*private*/ BoneAtom StartingAtom;
var /*private*/ Rotator DesiredRotation;
	/*       */
var /*private*/ bool StoredAllowNewAnimations;

var Name StartAnimName;
var Name StopAnimName;
//*************************************

function Init()
{
	super.Init();

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
}

function bool CheckInterrupted()
{
	return false;
}

function SetDesiredLocation(Vector NewDesiredLocation, XGUnit NeededForZ)
{
	DesiredLocation = NewDesiredLocation;

	//Don't get the floor Z because by the time this is called the floor might have exploded. Trust that the tile requested is correct
	DesiredLocation.Z = NeededForZ.GetDesiredZForLocation(DesiredLocation, false); 
}

simulated state Executing
{
Begin:
	StoredAllowNewAnimations = UnitPawn.GetAnimTreeController().GetAllowNewAnimations();
	if( StoredAllowNewAnimations )
	{
		//Wait for our turn to complete... and then set our rotation to face the destination exactly
		while( UnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance() )
		{
			Sleep(0.01f);
		}
	}
	else
	{
		UnitPawn.SetRotation(Rotator(Normal(DesiredLocation - UnitPawn.Location)));
	}

	UnitPawn.EnableRMA(true,true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	Params.AnimName = StartAnimName;
	DesiredRotation = Rotator(Normal(DesiredLocation - UnitPawn.Location));
	StartingAtom.Rotation = QuatFromRotator(DesiredRotation);
	StartingAtom.Translation = UnitPawn.Location;
	StartingAtom.Scale = 1.0f;
	UnitPawn.GetAnimTreeController().GetDesiredEndingAtomFromStartingAtom(Params, StartingAtom);
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// hide the targeting icon
	Unit.SetDiscState(eDS_None);

	StopDistanceSquared = Square(VSize(DesiredLocation - StartingAtom.Translation) - UnitPawn.fStrangleStopDistance);

	// to protect against overshoot, rather than check the distance to the target, we check the distance from the source.
	// Otherwise it is possible to go from too far away in front of the target, to too far away on the other side
	DistanceFromStartSquared = 0;
	while( DistanceFromStartSquared < StopDistanceSquared )
	{
		if( !PlayingSequence.bRelevant || !PlayingSequence.bPlaying || PlayingSequence.AnimSeq == None )
		{
			if( DistanceFromStartSquared < StopDistanceSquared )
			{
				`RedScreen("Get Over Here Target never made it to the destination");
			}
			break;
		}

		Sleep(0.0f);
		DistanceFromStartSquared = VSizeSq(UnitPawn.Location - StartingAtom.Translation);
	}
	
	UnitPawn.bSkipIK = false;
	Params = default.Params;
	Params.AnimName = StopAnimName;
	Params.DesiredEndingAtoms.Add(1);
	Params.DesiredEndingAtoms[0].Scale = 1.0f;
	Params.DesiredEndingAtoms[0].Translation = DesiredLocation;
	DesiredRotation = UnitPawn.Rotation;
	DesiredRotation.Pitch = 0.0f;
	DesiredRotation.Roll = 0.0f;
	Params.DesiredEndingAtoms[0].Rotation = QuatFromRotator(DesiredRotation);
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(StoredAllowNewAnimations);

	CompleteAction();
}

DefaultProperties
{
	StartAnimName=NO_StrangleStart
	StopAnimName=NO_StrangleStop
	InputEventIDs.Add( "Visualizer_AbilityHit" )
	InputEventIDs.Add( "Visualizer_ProjectileHit" )
}
