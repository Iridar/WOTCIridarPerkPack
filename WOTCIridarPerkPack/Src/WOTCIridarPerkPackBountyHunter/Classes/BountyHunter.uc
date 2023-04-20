class BountyHunter extends Object abstract;

static final function bool IsAbilityValidForDarkNight(const XComGameState_Ability AbilityState)
{
	local X2AbilityTemplate Template;

	Template = AbilityState.GetMyTemplate();

	return Template.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState) && Template.Hostility == eHostility_Offensive;
}

static final function bool IsAbilityValidForFollowthrough(const XComGameState_Ability AbilityState)
{
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return false;

	if (!AbilityTemplate.TargetEffectsDealDamage(AbilityState.GetSourceWeapon(), AbilityState))
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it doesn't deal damage.");
		return false;
	}
	if (AbilityTemplate.Hostility != eHostility_Offensive)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it's not offensive.");
		return false;
	}
	if (X2AbilityTarget_Single(AbilityTemplate.AbilityTargetStyle) == none)
	{
		`AMLOG(AbilityTemplate.DataName @ "Ability is not valid for followthrough because it's not single target style.");
		return false;
	}
	return true;
}


static final function SuppressionBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	local XComGameState_Ability         Ability;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
  
	// Variables for Issue #45
	local XComGameState_Item	SourceWeapon;
	local XGWeapon						WeaponVis;
	local XComUnitPawn					UnitPawn;
	local XComWeapon					Weapon;
  
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
  
	// Start Issue #45
	// Check the actor's pawn and weapon, see if they can play the suppression effect
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SourceWeapon = XComGameState_Item(History.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	WeaponVis = XGWeapon(SourceWeapon.GetVisualizer());

	UnitPawn = XGUnit(ActionMetadata.VisualizeActor).GetPawn();
	Weapon = WeaponVis.GetEntity();
	if (
		Weapon != None &&
		!UnitPawn.GetAnimTreeController().CanPlayAnimation(Weapon.WeaponSuppressionFireAnimSequenceName) &&
		!UnitPawn.GetAnimTreeController().CanPlayAnimation(class'XComWeapon'.default.WeaponSuppressionFireAnimSequenceName))
	{
		// The unit can't play their weapon's suppression effect. Replace it with the normal fire effect so at least they'll look like they're shooting
		Weapon.WeaponSuppressionFireAnimSequenceName = Weapon.WeaponFireAnimSequenceName;
	}
  
	// End Issue #45
	
	class'X2Action_ExitCover'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
	class'X2Action_StartSuppression'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		//****************************************************************************************
	//Configure the visualization track for the target
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	// Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1)); issue #45, collect earlier
	ActionMetadata = EmptyTrack;
	ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	ActionMetadata.VisualizeActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Good);
	if (XComGameState_Unit(ActionMetadata.StateObject_OldState).ReserveActionPoints.Length != 0 && XComGameState_Unit(ActionMetadata.StateObject_NewState).ReserveActionPoints.Length == 0)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(none, class'XLocalizedData'.default.OverwatchRemovedMsg, '', eColor_Good);
	}
}

static final function SuppressionBuildVisualizationSync(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	local X2Action_ExitCover ExitCover;

	if (EffectName == class'X2Effect_Suppression'.default.EffectName)
	{
		ExitCover = X2Action_ExitCover(class'X2Action_ExitCover'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() ));
		ExitCover.bIsForSuppression = true;

		class'X2Action_StartSuppression'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() );
	}
}

static final function XComGameState_Ability GetAbilityFromUnit(const XComGameState_Unit UnitState, const name AbilityName, optional StateObjectReference MatchWeapon, optional XComGameState CheckGameState)
{
	local StateObjectReference	AbilityRef;
	local XComGameState_Ability AbilityState;

	AbilityRef = UnitState.FindAbility(AbilityName, MatchWeapon);
	if (AbilityRef.ObjectID != 0)
	{
		if (CheckGameState != none)
		{
			AbilityState = XComGameState_Ability(CheckGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
		}
		else
		{
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
		}
	}
	return AbilityState;
}