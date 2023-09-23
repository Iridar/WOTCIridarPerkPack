class X2Action_AstralGraspSpiritDeath extends X2Action_Death;
/*
var private vector			AstralGraspBodyLocation;
var private XComWorldData	World;
var private bool			bHaveBodyLocation;
var private vector			TowardsBodyDirection;
var private vector			NudgeAmount;
var private vector			LocationDiff;
*/
function Init()
{
	//local XComGameState_Unit BodyUnit;
	//local UnitValue	UV;

	super.Init();

	UnitPawn.AimEnabled = false;
	UnitPawn.AimOffset.X = 0;
	UnitPawn.AimOffset.Y = 0;

	`AMLOG("Running");

	//if (NewUnitState.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
	//{
	//	BodyUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	//	if (BodyUnit != none)
	//	{
	//		bHaveBodyLocation = true;
	//		World = `XWORLD;
	//		AstralGraspBodyLocation = World.GetPositionFromTileCoordinates(BodyUnit.TileLocation);
	//
	//		TowardsBodyDirection = Normal(AstralGraspBodyLocation - UnitPawn.Location);		
	//
	//		`AMLOG(`ShowVar(AstralGraspBodyLocation) @ `ShowVar(TowardsBodyDirection));
	//
	//		NudgeAmount = TowardsBodyDirection * World.WORLD_StepSize;
	//
	//		`AMLOG(`ShowVar(NudgeAmount));
	//	}
	//}
}

static function bool AllowOverrideActionDeath(VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	return true;
}
/*
simulated function Name ComputeAnimationToPlay()
{
	local XComGameStateVisualizationMgr		VisMgr;
	local array<X2Action>					FoundActions;
	local X2Action							FoundAction;
	local X2Action_ApplyWeaponDamageToUnit	DamageAction;

	`AMLOG("Running");

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	VisMgr = `XCOMVISUALIZATIONMGR;

	VisMgr.GetNodesOfType(VisMgr.VisualizationTree, class'X2Action_ApplyWeaponDamageToUnit', FoundActions,, NewUnitState.ObjectID);

	`AMLOG("Found this many actions" @ FoundActions.Length @ "For ObjectID:" @ NewUnitState.ObjectID);

	foreach FoundActions(FoundAction)
	{
		DamageAction = X2Action_ApplyWeaponDamageToUnit(FoundAction);

		`AMLOG("Computed animation:" @ DamageAction.ComputeAnimationToPlay(""));

		return DamageAction.ComputeAnimationToPlay("");
	}
	
	`AMLOG("Found no actions, falling back");

	return 'HL_HurtFront';
}*/


function bool ShouldRunDeathHandler()
{
	return false;
}

function bool ShouldPlayDamageContainerDeathEffect()
{
	return false;
}

function bool DamageContainerDeathSound()
{
	return false;
}

simulated function name GetAssociatedAbilityName()
{
	return 'IRI_TM_AstralGrasp_SpiritDeath';
}


/*
simulated state Executing
{	

Begin:
	StopAllPreviousRunningActions(Unit);

	Unit.SetForceVisibility(eForceVisible);

	//Ensure Time Dilation is full speed
	VisualizationMgr.SetInterruptionSloMoFactor(Metadata.VisualizeActor, 1.0f);

	Unit.PreDeathRotation = UnitPawn.Rotation;

	//Death might already have been played by X2Actions_Knockback.
	if (!UnitPawn.bPlayedDeath)
	{
		Unit.OnDeath(m_kDamageType, XGUnit(DamageDealer));

		AnimationName = ComputeAnimationToPlay();

		UnitPawn.SetFinalRagdoll(true);
		UnitPawn.TearOffMomentum = vHitDir; //Use archaic Unreal values for great justice	
		UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), AnimationName, Destination);
	}

	//Since we have a unit dying, update the music if necessary
	`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();

	Unit.GotoState('Dead');

	if( bDoOverrideAnim )
	{
		// Turn off new animation playing
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	if (bHaveBodyLocation)
	{
		`AMLOG("Begin nudging spirit pawn");
		UnitPawn.EnableRMA(true, true);
		UnitPawn.EnableRMAInteractPhysics(true);
		do
		{
			LocationDiff = AstralGraspBodyLocation - UnitPawn.Location;
			`AMLOG(`ShowVar(LocationDiff) @ VSize(LocationDiff));

			UnitPawn.SetLocationNoCollisionCheck(UnitPawn.Location + NudgeAmount);
			Sleep(0.03f);
		} 
		until (VSize(LocationDiff) <= World.WORLD_StepSize * 2 || IsTimedOut());

		`AMLOG("Finished nudging spirit pawn");
		UnitPawn.SetLocationNoCollisionCheck(AstralGraspBodyLocation);
		UnitPawn.EnableRMA(false, false);
		UnitPawn.EnableRMAInteractPhysics(false);
		Sleep(0.2f);
	}

	while (DoWaitUntilNotified() && !IsTimedOut() )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}*/
