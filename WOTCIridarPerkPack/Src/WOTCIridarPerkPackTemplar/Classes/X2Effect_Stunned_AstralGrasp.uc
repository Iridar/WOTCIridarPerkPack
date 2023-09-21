class X2Effect_Stunned_AstralGrasp extends X2Effect_Stunned;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Unit StunningUnitState;
	local X2EventManager EventManager;
	local bool IsOurTurn;

	EventManager = `XEVENTMGR;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.ReserveActionPoints.Length = 0;
		UnitState.StunnedActionPoints += StunLevel;

		if(IsTickEveryAction(UnitState) && UnitState.StunnedActionPoints > 1)
		{
			// when ticking per action, randomly subtract an action point, effectively giving rulers a 1-2 stun
			UnitState.StunnedActionPoints -= `SYNC_RAND(1);
		}

		if( UnitState.IsTurret() ) // Stunned Turret.   Update turret state.
		{
			UnitState.UpdateTurretState(false);
		}

		//  If it's the unit's turn, consume action points immediately
		IsOurTurn = UnitState.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef();
		if (IsOurTurn)
		{
			// keep track of how many action points we lost, so we can regain them if the
			// stun is cleared this turn, and also reduce the stun next turn by the
			// number of points lost
			while (UnitState.StunnedActionPoints > 0 && UnitState.ActionPoints.Length > 0)
			{
				UnitState.ActionPoints.Remove(0, 1);
				UnitState.StunnedActionPoints--;
				UnitState.StunnedThisTurn++;
			}
			
			// if we still have action points left, just immediately remove the stun
			if(UnitState.ActionPoints.Length > 0)
			{
				// remove the action points and add them to the "stunned this turn" value so that
				// the remove stun effect will restore the action points correctly
				UnitState.StunnedActionPoints = 0;
				UnitState.StunnedThisTurn = 0;
				NewEffectState.RemoveEffect(NewGameState, NewGameState, true, true);
			}
		}

		// Immobilize to prevent scamper or panic from enabling this unit to move again.
		if(!IsOurTurn || UnitState.ActionPoints.Length == 0) // only if they are not immediately getting back up
		{
			UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1);
		}

		StunningUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		EventManager.TriggerEvent(StunnedTriggerName, StunningUnitState, UnitState, NewGameState);
	}
}

static final function X2Effect_Stunned_AstralGrasp CreateStunnedStatusEffect(int LocStunLevel, int Chance, optional bool bIsMentalDamage = true)
{
	local X2Effect_Stunned_AstralGrasp StunnedEffect;
	local X2Condition_UnitProperty UnitPropCondition;

	StunnedEffect = new class'X2Effect_Stunned_AstralGrasp';
	StunnedEffect.BuildPersistentEffect(1, true, true, false, eGameRule_UnitGroupTurnBegin);
	StunnedEffect.ApplyChance = Chance;
	StunnedEffect.StunLevel = LocStunLevel;
	StunnedEffect.bIsImpairing = true;
	StunnedEffect.EffectHierarchyValue = class'X2StatusEffects'.default.STUNNED_HIERARCHY_VALUE;
	StunnedEffect.EffectName = class'X2AbilityTemplateManager'.default.StunnedName;
	StunnedEffect.VisualizationFn = class'X2StatusEffects'.static.StunnedVisualization;
	StunnedEffect.EffectTickedVisualizationFn = class'X2StatusEffects'.static.StunnedVisualizationTicked;
	StunnedEffect.EffectRemovedVisualizationFn = class'X2StatusEffects'.static.StunnedVisualizationRemoved;
	StunnedEffect.EffectRemovedFn = class'X2StatusEffects'.static.StunnedEffectRemoved;
	StunnedEffect.bRemoveWhenTargetDies = true;
	StunnedEffect.bCanTickEveryAction = true;

	if( bIsMentalDamage )
	{
		StunnedEffect.DamageTypes.AddItem('Mental');
	}

	if (class'X2StatusEffects'.default.StunnedParticle_Name != "")
	{
		StunnedEffect.VFXTemplateName = class'X2StatusEffects'.default.StunnedParticle_Name;
		StunnedEffect.VFXSocket = class'X2StatusEffects'.default.StunnedSocket_Name;
		StunnedEffect.VFXSocketsArrayName = class'X2StatusEffects'.default.StunnedSocketsArray_Name;
	}

	UnitPropCondition = new class'X2Condition_UnitProperty';
	UnitPropCondition.ExcludeFriendlyToSource = false;
	UnitPropCondition.FailOnNonUnits = true;
	StunnedEffect.TargetConditions.AddItem(UnitPropCondition);

	return StunnedEffect;
}

