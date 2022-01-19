class X2Effect_Items_Singe extends X2Effect_Persistent;

// This effect is responsible for triggering Singe whenever 
/*
function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	SourceUnit;
	local Object				EffectObj;
	local XComGameState_Ability	SingeAbilityState;
	local StateObjectReference	AbilityRef;
	local XComGameStateHistory	History;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	History = `XCOMHISTORY;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return;

	//	Try to find Singe ability on the source weapon of the triggering ability.
	AbilityRef = SourceUnit.FindAbility('IRI_Singe', EffectGameState.ApplyEffectParameters.Item);
	if (AbilityRef.ObjectID == 0)
		return;

	SingeAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (SingeAbilityState == none)
		return;

	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', SingeListener, ELD_OnStateSubmitted, 40, SourceUnit,, SingeAbilityState);
}

*/


DefaultProperties
{
    EffectName="IRI_Singe_Effect"
    DuplicateResponse=eDupe_Allow
}

