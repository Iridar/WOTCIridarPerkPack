class X2Effect_RallyingHowl extends X2Effect_Persistent;

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) 
{
	local X2AbilityTemplate		AbilityTemplate;
	local XComGameState_Unit	OldUnit;
	local XComGameState_Unit	HowlSourceUnit;
	local XComGameStateHistory	History;
	local int					OldTileDistance;
	local int					NewTileDistance;
	local XComGameState_Ability	HowlAbilityState;
	local UnitValue				UV;

	if (SourceUnit.GetUnitValue(EffectName, UV))
		return false; 

	// Ability includes movement and does not deal damage
	if (AbilityContext.InputContext.MovementPaths.Length > 0 && kAbility.IsAbilityInputTriggered())
	{
		AbilityTemplate = kAbility.GetMyTemplate();
		if (AbilityTemplate != none && AbilityTemplate.Hostility == eHostility_Movement && !AbilityTemplate.TargetEffectsDealDamage(AffectWeapon, kAbility))
		{	
			History = `XCOMHISTORY;
			OldUnit = XComGameState_Unit(History.GetGameStateForObjectID(SourceUnit.ObjectID));
			HowlSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			if (OldUnit != none && HowlSourceUnit != none)
			{
				OldTileDistance = OldUnit.TileDistanceBetween(HowlSourceUnit);
				NewTileDistance = SourceUnit.TileDistanceBetween(HowlSourceUnit);
				if (NewTileDistance < OldTileDistance)
				{
					SourceUnit.ActionPoints = PreCostActionPoints;
					SourceUnit.ReserveActionPoints = PreCostReservePoints;
					SourceUnit.SetUnitFloatValue(EffectName, 1.0f, eCleanup_BeginTurn);

					HowlAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
					`XEVENTMGR.TriggerEvent('IRI_X2Effect_RallyingHowl_Event', HowlAbilityState, SourceUnit, NewGameState);
				}
			}
		}
	}
	return false; 
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMgr.RegisterForEvent(EffectObj, 'IRI_X2Effect_RallyingHowl_Event', OnTriggerAbilityFlyover, ELD_OnStateSubmitted,, ,, EffectObj);
}

static function EventListenerReturn OnTriggerAbilityFlyover(Object EventData, Object EventSource, XComGameState GameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit    UnitState;
    local XComGameState_Ability AbilityState;
	local XComGameState			NewGameState;
	local XComGameState_Effect	EffectState;
		
	EffectState = XComGameState_Effect(CallbackData);
	UnitState = XComGameState_Unit(EventSource);

	if (EffectState == none || UnitState == none || EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != UnitState.ObjectID)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Rallying Howl Flyover");
	
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = EffectState.TriggerAbilityFlyoverVisualizationFn;

	`GAMERULES.SubmitGameState(NewGameState);
	
    return ELR_NoInterrupt;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	FlyOver;
	local X2AbilityTemplate				AbilityTemplate;

	if (EffectApplyResult == 'AA_Success' && XComGameState_Unit(ActionMetadata.StateObject_NewState) != none)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(XComGameStateContext_Ability(VisualizeGameState.GetContext()).InputContext.AbilityTemplateName);
		FlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		FlyOver.SetSoundAndFlyOverParameters(none, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage, 0, false);
	}
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{ 
	local UnitValue UV;

	return !TargetUnit.GetUnitValue(EffectName, UV); 
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "X2Effect_RallyingHowl_Effect"
}