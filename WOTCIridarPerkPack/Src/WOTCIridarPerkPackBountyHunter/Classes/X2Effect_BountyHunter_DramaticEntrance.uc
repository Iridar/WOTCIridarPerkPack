class X2Effect_BountyHunter_DramaticEntrance extends X2Effect_Persistent;

// Based on Quick Feet from Extended Perk Pack.

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != none)
	{
		EventMgr.RegisterForEvent(EffectObj, EffectName, EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	}
}

	//class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(AbilityContext.InputContext.PrimaryTarget.ObjectID, 
	//												  out array<StateObjectReference> VisibleUnits,
	//												  optional array<X2Condition> RequiredConditions,
	//												  int HistoryIndex = -1)

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local XComGameStateHistory			History;
	local XComGameState_Ability			AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
	local UnitValue						UV;
	local array<StateObjectReference>	EnemyViewers;
	local StateObjectReference			UnitRef;
	local bool							bAllMultiTargetsCanSeeShooter;
	local bool							bShouldActivate;
	local XComGameState_Unit			MultiTargetUnit;
	local int i;

	if (AbilityArraysMatch(PreCostActionPoints, SourceUnit.ActionPoints))
	{
		//`AMLOG("Ability was free action, exiting");
		return false;
	}
	
	if (SourceUnit.GetUnitValue(EffectName, UV))
	{
		//`AMLOG("Unit value is present, exiting");
		return false;
	}
	if(!kAbility.IsAbilityInputTriggered())
	{
		//`AMLOG(kAbility.GetMyTemplateName() @ "is not player-triggered = notvalid for Dramatic Entrance");
		return false;
	}
	AbilityTemplate = kAbility.GetMyTemplate();
	if (AbilityTemplate == none)
		return false;

	if (!AbilityTemplate.TargetEffectsDealDamage(kAbility.GetSourceWeapon(), kAbility))
	{
		//`AMLOG(kAbility.GetMyTemplateName() @ "is doesn't deal damage");
		return false; 
	}

	History = `XCOMHISTORY;
	class'X2TacticalVisibilityHelpers'.static.GetEnemyViewersOfTarget(SourceUnit.ObjectID, EnemyViewers, History.GetEventChainStartIndex());

	// If the BH was observed by enemies, check if any of those enemies can see the BH. If at least one enemy affected by this ability can't see the BH, Explosive Action will activate.
	if (EnemyViewers.Length > 0)
	{
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 && EnemyViewers.Find('ObjectID', AbilityContext.InputContext.PrimaryTarget.ObjectID) == INDEX_NONE)
		{
			// Primary target exists and it couldn't see BH.
			bShouldActivate = true;
		}
		else if (AbilityContext.InputContext.MultiTargets.Length > 0)
		{
			bAllMultiTargetsCanSeeShooter = true;
		
			foreach AbilityContext.InputContext.MultiTargets(UnitRef)
			{
				if (EnemyViewers.Find('ObjectID', UnitRef.ObjectID) == INDEX_NONE)
				{
					MultiTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
					if (MultiTargetUnit == none)
						continue;

					for (i = MultiTargetUnit.DamageResults.Length - 1; i >= 0; i--)
					{
						if (MultiTargetUnit.DamageResults[i].Context == AbilityContext && MultiTargetUnit.DamageResults[i].DamageAmount > 0)
						{
							bAllMultiTargetsCanSeeShooter = false;
							break;
						}
					}
					if (!bAllMultiTargetsCanSeeShooter)
					{
						break;
						bShouldActivate = true;
					}					
				}
			}
		}
	}

	//`AMLOG("Triggering Dramatic Entrance");
	if (bShouldActivate)
	{
		SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);
		SourceUnit.SetUnitFloatValue(EffectName, 1.0f, eCleanup_BeginTurn);

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		`XEVENTMGR.TriggerEvent(EffectName, AbilityState, SourceUnit, NewGameState);
	}
	return false;
}

static private function bool AbilityArraysMatch(array<name> ArrayA, array<name> ArrayB)
{
	local int i;
	local int Index;

	for (i = ArrayA.Length - 1; i >= 0; i--)
	{
		Index = ArrayB.Find(ArrayA[i]);
		if (Index == INDEX_NONE)
			return false;

		ArrayA.Remove(i, 1);
		ArrayB.Remove(Index, 1);
	}
	return ArrayA.Length == 0 && ArrayB.Length == 0;
}

static final function MaybeTriggerExplosiveAction(out XComGameState_Unit NewUnitState, XComGameState NewGameState, optional bool bNeedToModifyUnitState)
{
	local XComGameState_Effect		EffectState;
	local XComGameState_Ability		AbilityState;
	local UnitValue					UV;

	if (bNeedToModifyUnitState)
	{
		NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(NewUnitState.Class, NewUnitState.ObjectID));
	}
	EffectState = NewUnitState.GetUnitAffectedByEffectState(default.EffectName);
	if (EffectState == none)
	{
		//`AMLOG("Dramatic Entrance effect is not present, exiting");
		return;
	}
	if (NewUnitState.GetUnitValue(default.EffectName, UV))
	{
		//`AMLOG("Unit value is present, exiting");
		return;
	}

	//`AMLOG("Triggering Dramatic Entrance");

	NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.RunAndGunActionPoint);
	NewUnitState.SetUnitFloatValue(default.EffectName, 1.0f, eCleanup_BeginTurn);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	`XEVENTMGR.TriggerEvent(default.EffectName, AbilityState, NewUnitState, NewGameState);
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_ExplosiveAction_Effect"
}