class X2Effect_BountyHunter_Headhunter extends X2Effect_Persistent;

var privatewrite name UVPrefix;
var int iCritBonus;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
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
	local XComGameState_Ability			AbilityState;
	local XComGameState_Effect			EffectState;
		
	KilledUnit = XComGameState_Unit(EventData);
	if (KilledUnit == none || KilledUnit.DamageResults.Length == 0)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	DmgResult = KilledUnit.DamageResults[KilledUnit.DamageResults.Length - 1];
	AbilityContext = XComGameStateContext_Ability(DmgResult.Context);
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	// Damage must be applied from the secondary weapon.
	if (AbilityContext.InputContext.ItemObject.ObjectID != EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	SourceUnit = XComGameState_Unit(EventSource);
	if (SourceUnit == none)
		return ELR_NoInterrupt;

	GroupName = KilledUnit.GetMyTemplateGroupName();
	if (GroupName == '')
		return ELR_NoInterrupt;

	ValueName = Name(default.UVPrefix $ GroupName);
	SourceUnit.GetUnitValue(ValueName, UV);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Increase Headhunter count:" @ GroupName);
	SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
	SourceUnit.SetUnitFloatValue(ValueName, UV.fValue + 1, eCleanup_Never);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if (AbilityState != none)
	{
		NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID);
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).PostBuildVisualizationFn.AddItem(TriggerHeadhunterFlyoverVisualizationFn);
	}
	
	`GAMERULES.SubmitGameState(NewGameState);
	
    return ELR_NoInterrupt;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo		ShotModifier;
	local UnitValue				UV;
	local name					GroupName;

	if (EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID != AbilityState.SourceWeapon.ObjectID)
		return;

	GroupName = Target.GetMyTemplateGroupName();
	if (GroupName == '')
		return;

	if (Attacker.GetUnitValue(Name(UVPrefix $ GroupName), UV))
	{
		ShotModifier.ModType = eHit_Crit;
		ShotModifier.Value = UV.fValue * iCritBonus;
		ShotModifier.Reason = self.FriendlyName;
		ShotModifiers.AddItem(ShotModifier);
	}
}

static private function TriggerHeadhunterFlyoverVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;
	local X2Effect_BountyHunter_Headhunter HeadhunterEffect;
	local X2Effect Effect;
	local string Msg;
	local XComGameStateVisualizationMgr VisMgr;
	local array<X2Action> LeafNodes;
	
	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Ability', AbilityState)
		{
			break;
		}
		if (AbilityState == none)
		{
			`RedScreenOnce("Ability state missing from" @ GetFuncName() @ "-jbouscher @gameplay");
			return;
		}

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none)
		{
			foreach AbilityTemplate.AbilityTargetEffects(Effect)
			{
				HeadhunterEffect = X2Effect_BountyHunter_Headhunter(Effect);
				if (HeadhunterEffect == none)
					continue;

				Msg = AbilityTemplate.LocFlyOverText $ "+" $ HeadhunterEffect.iCritBonus $ "%" $ " " $ class'XLocalizedData'.default.CritLabel;

				// That should make the flyover appear after everything else has been visualized.
				VisMgr.GetAllLeafNodes(VisMgr.BuildVisTree, LeafNodes);

				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false,, LeafNodes));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Msg, '', eColor_Good, AbilityTemplate.IconImage, `DEFAULTFLYOVERLOOKATTIME, true);
				break;
			}
		}
		break;
	}
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_BountyHunter_Headhunter_Effect"
	UVPrefix = "IRI_BH_HH_"
}