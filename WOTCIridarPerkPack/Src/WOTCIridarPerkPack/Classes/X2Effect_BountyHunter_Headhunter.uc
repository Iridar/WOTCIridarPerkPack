class X2Effect_BountyHunter_Headhunter extends X2Effect_Persistent;

var private name UVPrefix;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	//EventMgr.RegisterForEvent(EffectObj, 'X2Effect_BountyHunter_Headhunter_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);

	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_BountyHunter_Headhunter_Event', AbilityState, SourceUnit, NewGameState);
	
	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted,, UnitState);	
}

static private function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit    SourceUnit;
	local XComGameState_Unit    KilledUnit;
	local UnitValue				UV;
	local name					GroupName;
	local XComGameState			NewGameState;
	local name					ValueName;
		
	KilledUnit = XComGameState_Unit(EventData);
	if (KilledUnit == none)
		return ELR_NoInterrupt;

	GroupName = KilledUnit.GetMyTemplateGroupName();
	if (GroupName == '')
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	ValueName = Name(default.UVPrefix $ GroupName);
	SourceUnit.GetUnitValue(ValueName, UV);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Increase Headhunter count:" @ GroupName);
	SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
	SourceUnit.SetUnitFloatValue(ValueName, UV.fValue + 1, eCleanup_Never);
	`GAMERULES.SubmitGameState(NewGameState);
	
    return ELR_NoInterrupt;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo	ShotModifier;
	local UnitValue			UV;
	local name				GroupName;

	GroupName = Target.GetMyTemplateGroupName();
	if (GroupName == '')
		return;

	if (Attacker.GetUnitValue(Name(UVPrefix $ GroupName), UV))
	{
		ShotModifier.ModType = eHit_Crit;
		ShotModifier.Value = UV.fValue;
		ShotModifier.Reason = self.FriendlyName;
		ShotModifiers.AddItem(ShotModifier);
	}
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_BountyHunter_Headhunter_Effect"
	UVPrefix = "IRI_BH_HH_"
}