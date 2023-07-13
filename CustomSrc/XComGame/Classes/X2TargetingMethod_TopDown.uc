//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_TopDown.uc
//  AUTHOR:  David Burchanowski  --  8/04/2014
//  PURPOSE: Simple top down targeting method for selecting a target object.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_TopDown extends X2TargetingMethod;

var /*private*/ X2Camera_LookAtActor LookatCamera;
var protected int LastTarget;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	super.Init(InAction, NewTargetIndex);
	
	// make sure this ability has a target
	`assert(InAction.AvailableTargets.Length > 0);

	LookatCamera = new class'X2Camera_LookAtActor';
	LookatCamera.UseTether = false;
	`CAMERASTACK.AddCamera(LookatCamera);

	DirectSetTarget(0);
}

function Canceled()
{
	super.Canceled();
	`CAMERASTACK.RemoveCamera(LookatCamera);
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

function Update(float DeltaTime);

function NextTarget()
{
	DirectSetTarget(LastTarget + 1);
}

function PrevTarget()
{
	DirectSetTarget(LastTarget - 1);
}

function int GetTargetIndex()
{
	return LastTarget;
}

function DirectSetTarget(int TargetIndex)
{
	local XComPresentationLayer Pres;
	local UITacticalHUD TacticalHud;
	local Actor TargetedActor;
	local array<TTile> Tiles;
	local TTile TargetedActorTile;
	local XGUnit TargetedPawn;
	local vector TargetedLocation;
	local XComWorldData World;
	local int NewTarget;
	local array<Actor> CurrentlyMarkedTargets;
	local X2AbilityTemplate AbilityTemplate;

	World = `XWORLD;

	// put the targeting reticle on the new target
	Pres = `PRES;
	TacticalHud = Pres.GetTacticalHUD();

	// advance the target counter
	NewTarget = TargetIndex % Action.AvailableTargets.Length;
	if(NewTarget < 0) NewTarget = Action.AvailableTargets.Length + NewTarget;

	LastTarget = NewTarget;
	TacticalHud.TargetEnemy(Action.AvailableTargets[NewTarget].PrimaryTarget.ObjectID);

	// have the idle state machine look at the new target
	if(FiringUnit != none)
	{
		FiringUnit.IdleStateMachine.CheckForStanceUpdate();
	}

	// have the camera look at the new target (or the source unit if no target is available)
	TargetedActor = GetTargetedActor();
	if(TargetedActor != none)
	{
		LookatCamera.ActorToFollow = TargetedActor;
	}
	else if(FiringUnit != none)
	{
		LookatCamera.ActorToFollow = FiringUnit;
	}

	TargetedPawn = XGUnit(TargetedActor);
	if( TargetedPawn != none )
	{
		TargetedLocation = TargetedPawn.GetFootLocation();
		TargetedActorTile = World.GetTileCoordinatesFromPosition(TargetedLocation);
		TargetedLocation = World.GetPositionFromTileCoordinates(TargetedActorTile);
	}
	else
	{
		TargetedLocation = TargetedActor.Location;
	}

	AbilityTemplate = Ability.GetMyTemplate();

	if ( AbilityTemplate.AbilityMultiTargetStyle != none)
	{
		AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(Ability, TargetedLocation, Tiles);
	}

	if( AbilityTemplate.AbilityTargetStyle != none )
	{
		AbilityTemplate.AbilityTargetStyle.GetValidTilesForLocation(Ability, TargetedLocation, Tiles);
	}

	if( Tiles.Length > 1 )
	{
		GetTargetedActors(TargetedLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None);
		DrawAOETiles(Tiles);
	}
	else if( AbilityTemplate.DataName == 'Interact_ActivateAscensionGate' )
	{
		bSeriousConsequencesForAction = true;
	}
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	local Actor TargetedActor;
	local X2VisualizerInterface TargetVisualizer;

	TargetedActor = GetTargetedActor();

	if(TargetedActor != none)
	{
		TargetVisualizer = X2VisualizerInterface(TargetedActor);
		if( TargetVisualizer != None )
		{
			Focus = TargetVisualizer.GetTargetingFocusLocation();
		}
		else
		{
			Focus = TargetedActor.Location;
		}
		
		return true;
	}
	
	return false;
}
