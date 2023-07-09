class X2TargetingMethod_RN_Intercept extends X2TargetingMethod;

var private int LastTarget;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local array<TTile>	Tiles;
	local int			AP;
	local float			Mobility;

	super.Init(InAction, NewTargetIndex);
	
	//	Change unit's mobility if the have Ghost Rider
	Mobility = UnitState.GetCurrentStat(eStat_Mobility);
	AP = 1;

	 //	Calculate the maximum travel distance of the unit, in meters. 1 Tile = 1.5 meters
	FiringUnit.m_kReachableTilesCache.GetAllPathableTiles(Tiles,  Mobility * AP);

	//	Mark the tiles the unit can reach with the ability
	DrawAOETiles(Tiles);

	DirectSetTarget(0);
}

//	Targeting code fluff is necessary because apparantely at some point the Targeting Method is used to validate the target selected by the ability
//	So without this code AbilityTargetEffects won't have a target to apply to.

function NextTarget()
{
	DirectSetTarget(LastTarget + 1);
}

function PrevTarget()
{
	if(LastTarget > 0)
	{
		DirectSetTarget(LastTarget - 1);
	}
	else
	{
		DirectSetTarget(Action.AvailableTargets.Length - 1);
	}
}

function int GetTargetIndex()
{
	return LastTarget;
}

function DirectSetTarget(int TargetIndex)
{
	local XComPresentationLayer Pres;
	local UITacticalHUD TacticalHud;

	// advance the target counter
	LastTarget = TargetIndex % Action.AvailableTargets.Length;

	// put the targeting reticle on the new target
	Pres = `PRES;
	TacticalHud = Pres.GetTacticalHUD();
	TacticalHud.TargetEnemy(GetTargetedObjectID());

	// have the idle state machine look at the new target
	FiringUnit.IdleStateMachine.CheckForStanceUpdate();
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
    TargetLocations.Length = 0;
    TargetLocations.AddItem(FiringUnit.GetLocation());
}


function Committed()
{
	Canceled();
}