class X2Effect_AstralGraspSpirit extends X2Effect_Persistent;

function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return false; }
function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) { return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) { return false; }
function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return DamageType == 'KnockbackDamage';
}


simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit	SpawnedUnit;
	local XComGameStateHistory	History;
	//local XComGameState_Effect	EffectState;
	//local X2Effect_Persistent	PersistentEffect;
	//local UnitValue				UV;
	//local StateObjectReference	EffectRef;
	
	History = `XCOMHISTORY;
	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(RemovedEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SpawnedUnit == none)
		return;

	//if (SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
	//{
	//	foreach SpawnedUnit.AppliedEffects(EffectRef)
	//	{
	//		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
	//		if (EffectState == none || EffectState.bRemoved)
	//			continue;
	//		
	//		if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != UV.fValue)
	//			continue;
	//
	//		PersistentEffect = EffectState.GetX2Effect();
	//		if (PersistentEffect == none || PersistentEffect.EffectName != 'IRI_AstralGrasp_SpiritKillEffect')
	//			continue;
	//
	//		EffectState.RemoveEffect(NewGameState, NewGameState, false);
	//
	//	}
	//}

	`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', SpawnedUnit, SpawnedUnit, NewGameState);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_ApplyMITV ApplyMITV;
	
	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Pulsing_MITV";

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local X2Action_ApplyMITV ApplyMITV;
	
	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Pulsing_MITV";
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_ApplyMITV		ApplyMITV;
	//local X2Action_TimedWait		TimedWait;
	local XComGameState_Unit		SpawnedUnit;
	local X2Action_PlayAnimation	PlayAnimation;
	local UnitValue					UV;
	local XComGameState_Unit		TargetUnit;
	local vector					NewUnitLoc;
	local X2Action_AstralGrasp		GetOverHereTarget;
	
	SpawnedUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (SpawnedUnit == none)
		return;

	if (SpawnedUnit.IsAlive())
	{	
		// Play the start stun animation
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
		PlayAnimation.Params.AnimName = 'HL_StunnedStop';
		PlayAnimation.bResetWeaponsToDefaultSockets = true;

		ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Dissolve_MITV";

		if (SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		{
			TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
			if (TargetUnit != none && TargetUnit.IsAlive())
			{
				GetOverHereTarget =  X2Action_AstralGrasp(class'X2Action_AstralGrasp'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				NewUnitLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
				GetOverHereTarget.SetDesiredLocation(NewUnitLoc, XGUnit(TargetUnit.GetVisualizer()));
			}
		}
		
		class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);		
	}
}


// ------------------------- HIT EFFECT EVENTS -------------------------

// These should be preventing things like blood effects when the spirit is getting hit
function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	SpawnedUnit;
	local Object				EventObj;
	local XGUnit				Visualizer;
	local XComUnitPawn			UnitPawn;

	SpawnedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SpawnedUnit == none)
		return;

	Visualizer = XGUnit(SpawnedUnit.GetVisualizer());
	if (Visualizer == none)
		return;

	UnitPawn = Visualizer.GetPawn();
	if (UnitPawn == none)
		return;

	`AMLOG("Found everything, registering on hit effects");

	EventObj = EffectGameState;
	EventMgr = `XEVENTMGR;
	EventMgr.RegisterForEvent(EventObj, 'OverrideHitEffects', OnOverrideHitEffects, ELD_Immediate,, UnitPawn);	
	EventMgr.RegisterForEvent(EventObj, 'OverrideMetaHitEffect', OnOverrideMetaHitEffect, ELD_Immediate,, UnitPawn);	
}

static private function EventListenerReturn OnOverrideHitEffects(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    //local XComUnitPawn Pawn;
    local XComLWTuple Tuple;
    //local bool OverrideHitEffect;
    //local float Damage;
    //local Actor InstigatedBy;
    //local vector HitLocation;
    //local name DamageTypeName;
    //local vector Momentum;
    //local bool bIsUnitRuptured;
    //local EAbilityHitResult HitResult;

    //Pawn = XComUnitPawn(EventSource);
    Tuple = XComLWTuple(EventData);

    //OverrideHitEffect = Tuple.Data[0].b;
    //Damage = Tuple.Data[1].f;
    //InstigatedBy = Actor(Tuple.Data[2].o);
    //HitLocation = Tuple.Data[3].v;
    //DamageTypeName = Tuple.Data[4].n;
    //Momentum = Tuple.Data[5].v;
    //bIsUnitRuptured = Tuple.Data[6].b;
    //HitResult = EAbilityHitResult(Tuple.Data[7].i);

    Tuple.Data[0].b = true; //OverrideHitEffect;
    //Tuple.Data[1].f = Damage;
    //Tuple.Data[3].v = HitLocation;
    //Tuple.Data[4].n = DamageTypeName;
    //Tuple.Data[5].v = Momentum;
    //Tuple.Data[6].b = bIsUnitRuptured;
    //Tuple.Data[7].i = HitResult;

    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideMetaHitEffect(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    //local XComUnitPawn Pawn;
    local XComLWTuple Tuple;
    //local bool OverrideMetaHitEffect;
    //local vector HitLocation;
    //local name DamageTypeName;
    //local vector Momentum;
    //local bool bIsUnitRuptured;
    //local EAbilityHitResult HitResult;

   // Pawn = XComUnitPawn(EventSource);
    Tuple = XComLWTuple(EventData);

    //OverrideMetaHitEffect = Tuple.Data[0].b;
    //HitLocation = Tuple.Data[1].v;
    //DamageTypeName = Tuple.Data[2].n;
    //Momentum = Tuple.Data[3].v;
    //bIsUnitRuptured = Tuple.Data[4].b;
    //HitResult = EAbilityHitResult(Tuple.Data[5].i);

    Tuple.Data[0].b = true; // OverrideMetaHitEffect;
    //Tuple.Data[1].v = HitLocation;
    //Tuple.Data[2].n = DamageTypeName;
    //Tuple.Data[3].v = Momentum;
    //Tuple.Data[4].b = bIsUnitRuptured;
    //Tuple.Data[5].i = HitResult;

    return ELR_NoInterrupt;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	bRemoveWhenSourceDies = false
	bRemoveWhenTargetDies = true
}
