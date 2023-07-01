class X2Effect_TacticalAdvance extends X2Effect_Persistent;

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
}

// Remove the effect after it made one ability not end turn.
function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local X2AbilityTemplate				AbilityTemplate;
	local X2AbilityCost					Cost;
	local X2AbilityCost_ActionPoints	ActionPointCost;

	AbilityTemplate = kAbility.GetMyTemplate();
	if (AbilityTemplate == none)
		return false;

	foreach AbilityTemplate.AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Cost);
		if (ActionPointCost != none)
		{
			// Compatibility: same effect name used in X2DLCInfo_WOTCIridarPerkPackBountyHunter
			if (ActionPointCost.DoNotConsumeAllEffects.Find('IRI_RN_X2Effect_TacticalAdvance_Effect') != INDEX_NONE)
			{
				// Remove if the unit spent action points.
				if (!AbilityArraysMatch(SourceUnit.ActionPoints, PreCostActionPoints))
				{
					`AMLOG("X2Effect_TacticalAdvance :: Removing effect after ability activation:" @ AbilityContext.InputContext.AbilityTemplateName);
					EffectState.RemoveEffect(NewGameState, NewGameState, true);
					return false;
				}
			}
		}
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

defaultproperties
{
	DuplicateResponse = eDupe_Refresh
	EffectName = "IRI_RN_X2Effect_TacticalAdvance_Effect"
}
