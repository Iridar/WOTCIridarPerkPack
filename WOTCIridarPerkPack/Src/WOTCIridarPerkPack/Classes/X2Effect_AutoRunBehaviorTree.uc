class X2Effect_AutoRunBehaviorTree extends X2Effect;

var name BehaviorTree;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
    local XComGameState_Unit UnitState;
    
    UnitState = XComGameState_Unit(kNewTargetState);
    if (UnitState == none)
        return;

    if (UnitState.isStunned())
        return;

	`AMLOG(UnitState.GetFullName() @ "running behavior tree:" @ BehaviorTree);
    UnitState.AutoRunBehaviorTree(BehaviorTree, 1, `XCOMHISTORY.GetCurrentHistoryIndex() + 1, true);
}
