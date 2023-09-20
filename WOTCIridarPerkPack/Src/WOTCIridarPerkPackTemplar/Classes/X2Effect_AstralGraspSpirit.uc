class X2Effect_AstralGraspSpirit extends X2Effect_Persistent;

var private name StunStartAnimName;
var private name StunStopAnimName;

function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return false; }
function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) { return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) { return false; }
function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	// Only psi damage should be allowed, but then it would block Rend too.
	return DamageType != 'Psi' && DamageType != 'Melee';
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	SourceUnit;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Unit	SpawnedUnit;
	local Object				EventObj;
	local XComGameState_Ability AbilityState;
	local StateObjectReference	AbilityRef;
	local XComGameStateHistory	History;
	local UnitValue				UV;
	local XGUnit				Visualizer;
	local XComUnitPawn			UnitPawn;
	
	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return;

	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SpawnedUnit == none)
		return;

	if (!SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(UV.fValue));
	if (TargetUnit == none)
		return;

	AbilityRef = SourceUnit.FindAbility('IRI_TM_AstralGrasp_DamageLink');
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	`AMLOG("Found everything, registering damage link");

	EventMgr = `XEVENTMGR;
	EventObj = TargetUnit;
	EventMgr.RegisterForEvent(EventObj, 'UnitTakeEffectDamage', OnUnitTakeEffectDamage, ELD_OnStateSubmitted, 100, TargetUnit,, AbilityState);	

	EventObj = SpawnedUnit;
	EventMgr.RegisterForEvent(EventObj, 'UnitTakeEffectDamage', OnUnitTakeEffectDamage, ELD_OnStateSubmitted, 100, SpawnedUnit,, AbilityState);	

	Visualizer = XGUnit(SpawnedUnit.GetVisualizer());
	if (Visualizer == none)
		return;

	UnitPawn = Visualizer.GetPawn();
	if (UnitPawn == none)
		return;

	`AMLOG("Found everything, registering on hit effects");

	EventMgr.RegisterForEvent(EventObj, 'OverrideHitEffects', OnOverrideHitEffects, ELD_Immediate,, UnitPawn);	
	EventMgr.RegisterForEvent(EventObj, 'OverrideMetaHitEffect', OnOverrideMetaHitEffect, ELD_Immediate,, UnitPawn);	
}

static private function EventListenerReturn OnOverrideHitEffects(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComUnitPawn Pawn;
    local XComLWTuple Tuple;
    local bool OverrideHitEffect;
    local float Damage;
    local Actor InstigatedBy;
    local vector HitLocation;
    local name DamageTypeName;
    local vector Momentum;
    local bool bIsUnitRuptured;
    local EAbilityHitResult HitResult;

    Pawn = XComUnitPawn(EventSource);
    Tuple = XComLWTuple(EventData);

    OverrideHitEffect = Tuple.Data[0].b;
    Damage = Tuple.Data[1].f;
    InstigatedBy = Actor(Tuple.Data[2].o);
    HitLocation = Tuple.Data[3].v;
    DamageTypeName = Tuple.Data[4].n;
    Momentum = Tuple.Data[5].v;
    bIsUnitRuptured = Tuple.Data[6].b;
    HitResult = EAbilityHitResult(Tuple.Data[7].i);

    // Your code here

	OverrideHitEffect = true;

    Tuple.Data[0].b = OverrideHitEffect;
    Tuple.Data[1].f = Damage;
    Tuple.Data[3].v = HitLocation;
    Tuple.Data[4].n = DamageTypeName;
    Tuple.Data[5].v = Momentum;
    Tuple.Data[6].b = bIsUnitRuptured;
    Tuple.Data[7].i = HitResult;

    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideMetaHitEffect(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComUnitPawn Pawn;
    local XComLWTuple Tuple;
    local bool OverrideMetaHitEffect;
    local vector HitLocation;
    local name DamageTypeName;
    local vector Momentum;
    local bool bIsUnitRuptured;
    local EAbilityHitResult HitResult;

    Pawn = XComUnitPawn(EventSource);
    Tuple = XComLWTuple(EventData);

    OverrideMetaHitEffect = Tuple.Data[0].b;
    HitLocation = Tuple.Data[1].v;
    DamageTypeName = Tuple.Data[2].n;
    Momentum = Tuple.Data[3].v;
    bIsUnitRuptured = Tuple.Data[4].b;
    HitResult = EAbilityHitResult(Tuple.Data[5].i);

	OverrideMetaHitEffect = true;

    // Your code here

    Tuple.Data[0].b = OverrideMetaHitEffect;
    Tuple.Data[1].v = HitLocation;
    Tuple.Data[2].n = DamageTypeName;
    Tuple.Data[3].v = Momentum;
    Tuple.Data[4].b = bIsUnitRuptured;
    Tuple.Data[5].i = HitResult;

    return ELR_NoInterrupt;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	TargetUnit;
	local XComGameState_Unit	SpawnedUnit;
	local Object				EventObj;
	local XComGameStateHistory	History;
	local UnitValue				UV;
	
	History = `XCOMHISTORY;

	SpawnedUnit = XComGameState_Unit(History.GetGameStateForObjectID(RemovedEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SpawnedUnit == none)
		return;

	if (!SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(UV.fValue));
	if (TargetUnit == none)
		return;

	EventMgr = `XEVENTMGR;
	EventObj = TargetUnit;
	EventMgr.UnRegisterFromEvent(EventObj, 'UnitTakeEffectDamage', ELD_OnStateSubmitted, OnUnitTakeEffectDamage);

	EventObj = SpawnedUnit;
	EventMgr.UnRegisterFromEvent(EventObj, 'UnitTakeEffectDamage', ELD_OnStateSubmitted, OnUnitTakeEffectDamage);	

	//if (SpawnedUnit.IsDead())
	//{
		//SpawnedUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SpawnedUnit.Class, SpawnedUnit.ObjectID));
		//SpawnedUnit.EvacuateUnit(NewGameState); // Effectively removes unit from play, but without immediately nuking the visualizer.

		EventMgr.TriggerEvent('UnitRemovedFromPlay', SpawnedUnit, SpawnedUnit, NewGameState);
	//}
}

static private function EventListenerReturn OnUnitTakeEffectDamage(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            DamagedUnit;
	local XComGameState_Unit            LinkedUnit;
    local XComGameState_Ability         AbilityState;
	local UnitValue						UV;
	local XComGameStateContext_Ability	AbilityContext;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	// No insheeption pl0x
	if (AbilityContext.InputContext.AbilityTemplateName == 'IRI_TM_AstralGrasp_DamageLink')
		return ELR_NoInterrupt;
		
	AbilityState = XComGameState_Ability(CallbackData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	DamagedUnit = XComGameState_Unit(EventSource);
	if (DamagedUnit == none)
		return ELR_NoInterrupt;

	if (!DamagedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
		return ELR_NoInterrupt;

	LinkedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	if (LinkedUnit == none)
		return ELR_NoInterrupt;

	`AMLOG("Triggering damage link from:" @ DamagedUnit.GetFullName() @ "to:" @ LinkedUnit.GetFullName());
	AbilityState.AbilityTriggerAgainstSingleTarget(LinkedUnit.GetReference(), false);

    return ELR_NoInterrupt;
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local X2Action_ApplyMITV	ApplyMITV;
	//local XComGameState_Unit	SpawnedUnit;
	//local XComGameState_Unit	TargetUnit;
	//local X2Action_PlayEffect	TetherEffect;
	//local UnitValue				UV;

	//SpawnedUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	//if (SpawnedUnit == none)
	//	return;
	
	//if (SpawnedUnit.IsDead())
	//{
	//	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	//	ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Dissolve_MITV";
	//	return;
	//}

	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
	
	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	ApplyMITV.MITVPath = "FX_Warlock_SpectralArmy.M_SpectralArmy_Activate_MITV";

	//if (SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
	//{
	//	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	//	if (TargetUnit != none)
	//	{
	//		TetherEffect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	//		TetherEffect.EffectName = "FX_Psi_Mind_Control.P_Psi_Mind_Control_Tether_Persistent";
	//		TetherEffect.AttachToSocketName = 'FX_Chest';
	//		TetherEffect.TetherToSocketName = 'Root';
	//		TetherEffect.TetherToUnit = XGUnit(TargetUnit.GetVisualizer());
	//	}
	//}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_ApplyMITV	ApplyMITV;
	local X2Action_TimedWait	TimedWait;
	local XComGameState_Unit	SpawnedUnit;
	//local XComGameState_Unit	TargetUnit;
	local X2Action_PlayAnimation PlayAnimation;
	//local X2Action_PlayEffect	TetherEffect;
	//local UnitValue				UV;
	
	
	SpawnedUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (SpawnedUnit == none)
		return;

	if (SpawnedUnit.IsAlive())
	{	
		// Play the start stun animation
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		PlayAnimation.Params.AnimName = StunStopAnimName;
		PlayAnimation.bResetWeaponsToDefaultSockets = true;
	}

	//if (SpawnedUnit.GetUnitValue('IRI_TM_AstralGrasp_SpiritLink', UV))
	//{
	//	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UV.fValue));
	//	if (TargetUnit != none)
	//	{
	//		`AMLOG("Stopping tether effect");
	//		TetherEffect = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	//		TetherEffect.EffectName = "FX_Psi_Mind_Control.P_Psi_Mind_Control_Tether_Persistent";
	//		TetherEffect.AttachToSocketName = 'FX_Chest';
	//		TetherEffect.TetherToSocketName = 'FX_Chest';
	//		TetherEffect.TetherToUnit = XGUnit(TargetUnit.GetVisualizer());
	//		TetherEffect.bStopEffect = true;
	//	}
	//}
	
	ApplyMITV = X2Action_ApplyMITV(class'X2Action_ApplyMITV'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	ApplyMITV.MITVPath = "FX_Corrupt.M_SpectralZombie_Dissolve_MITV";

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	TimedWait.DelayTimeSec = 3.0f;

	class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	bRemoveWhenSourceDies = false
	bRemoveWhenTargetDies = true
	bIsImpairing = true
	CustomIdleOverrideAnim="HL_StunnedIdle"
	StunStopAnimName="HL_StunnedStop"
}
