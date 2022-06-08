class X2Effect_BountyHunter_Headhunter extends X2Effect_Persistent;

var private name UVPrefix;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
	EventMgr.RegisterForEvent(EffectObj, 'IRI_X2Effect_BountyHunter_Headhunter_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted,, UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted,, UnitState,, EffectObj);	
}

static private function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			KilledUnit;
	local UnitValue						UV;
	local name							GroupName;
	local XComGameState					NewGameState;
	local name							ValueName;
	local DamageResult					DmgResult;
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Item			ItemState;
	local XComGameState_Ability			AbilityState;
	local XComGameState_Effect			EffectState;
		
	KilledUnit = XComGameState_Unit(EventData);
	if (KilledUnit == none || KilledUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;

	GroupName = KilledUnit.GetMyTemplateGroupName();
	if (GroupName == '')
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	DmgResult = KilledUnit.DamageResults[KilledUnit.DamageResults.Length - 1];
	AbilityContext = XComGameStateContext_Ability(DmgResult.Context);
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (ItemState == none || ItemState.GetWeaponCategory() != 'iri_bounty_pistol')
		return ELR_NoInterrupt;

	ValueName = Name(default.UVPrefix $ GroupName);
	SourceUnit.GetUnitValue(ValueName, UV);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Increase Headhunter count:" @ GroupName);
	SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
	SourceUnit.SetUnitFloatValue(ValueName, UV.fValue + 1, eCleanup_Never);

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState != none)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			`XEVENTMGR.TriggerEvent('IRI_X2Effect_BountyHunter_Headhunter_Event', AbilityState, SourceUnit, NewGameState);
		}
	}
	
	`GAMERULES.SubmitGameState(NewGameState);
	
    return ELR_NoInterrupt;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo		ShotModifier;
	local UnitValue				UV;
	local name					GroupName;
	local XComGameState_Item	SourceWeapon;

	GroupName = Target.GetMyTemplateGroupName();
	if (GroupName == '')
		return;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.GetWeaponCategory() == 'iri_bounty_pistol' && Attacker.GetUnitValue(Name(UVPrefix $ GroupName), UV))
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