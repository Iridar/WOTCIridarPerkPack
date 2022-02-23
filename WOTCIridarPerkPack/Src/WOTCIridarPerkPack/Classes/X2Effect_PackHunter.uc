class X2Effect_PackHunter extends X2Effect_PersistentStatChange config(IridarPerkPack);

var config int iDistanceTiles;
var config int iMaxStacks;
var config int iDodgePerStack;
var config int iCritChancePerStack;
var config int iCritDefensePerStack;

function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotModifier;
	local int iNumStacks;

	iNumStacks = GetNumNearbySquadmates(Target);
	//`LOG(GetFuncName() @ Attacker.GetFullName() @ "vs:" @ Target.GetFullName() @ `ShowVar(iNumStacks),, 'IRITEST');
	if (iNumStacks > 0)
	{
		if (bMelee || bFlanking)
		{
			ShotModifier.ModType = eHit_Crit;
			ShotModifier.Value = iNumStacks * iCritDefensePerStack;
			ShotModifier.Reason = FriendlyName;

			//`LOG(GetFuncName() @ "adding crit chance defense:" @ iNumStacks * iCritDefensePerStack,, 'IRITEST');

			ShotModifiers.AddItem(ShotModifier);
		}
	}
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotModifier;
	local int iNumStacks;

	iNumStacks = GetNumNearbySquadmates(Attacker);
	//`LOG(GetFuncName() @ Attacker.GetFullName() @ "vs:" @ Target.GetFullName() @ `ShowVar(iNumStacks),, 'IRITEST');
	if (iNumStacks > 0)
	{
		if (bMelee || bFlanking)
		{
			ShotModifier.ModType = eHit_Crit;
			ShotModifier.Value = iNumStacks * iCritChancePerStack;
			ShotModifier.Reason = FriendlyName;

			//`LOG(GetFuncName() @ "adding crit chance:" @ iNumStacks * iCritChancePerStack,, 'IRITEST');

			ShotModifiers.AddItem(ShotModifier);
		}
	}
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local int					iNumStacks;

	m_aStatChanges.Length = 0;
	
	UnitState = XComGameState_Unit(kNewTargetState);
	//`LOG(GetFuncName() @ UnitState.GetFullName(),, 'IRITEST');
	if (UnitState != none)
	{
		iNumStacks = GetNumNearbySquadmates(UnitState);
		//`LOG(GetFuncName() @ `ShowVar(iNumStacks),, 'IRITEST');
		if (iNumStacks > 0)
		{
			//`LOG("Adding dodge:" @ iDodgePerStack * iNumStacks,, 'IRITEST');
			AddPersistentStatChange(eStat_Dodge, iDodgePerStack * iNumStacks);
		}
	}

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static private function int GetNumNearbySquadmates(const XComGameState_Unit SourceUnit)
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_Unit				UnitState;
	local StateObjectReference				UnitRef;
	local XComGameStateHistory				History;
	local int								iNumUnits;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	//`LOG(GetFuncName() @ SourceUnit.GetFullName() @ "check squadmates within:" @ default.iDistanceTiles,, 'IRITEST');

	foreach XComHQ.Squad(UnitRef)
	{
		if (UnitRef.ObjectID == SourceUnit.ObjectID)
			continue;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		//`LOG("Found squadmate:" @ UnitState.GetFullName(),, 'IRITEST');
		if (UnitState != none && UnitState.IsAlive())
		{
			if (UnitState.TileDistanceBetween(SourceUnit) <= default.iDistanceTiles)
			{
				iNumUnits++;
			}
			if (default.iMaxStacks != 0 && iNumUnits == default.iMaxStacks)
			{
				break;
			}
		}
	}

	//`LOG(GetFuncName() @ SourceUnit.GetFullName() @ "check squadmates within tiles:" @ default.iDistanceTiles @ "This many:" @ iNumUnits,, 'IRITEST');

	return iNumUnits;
}

defaultproperties
{
	DuplicateResponse = eDupe_Refresh
	EffectName = "X2Effect_PackHunter_Effect"
}