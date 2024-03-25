class X2Effect_IRI_Amplify extends X2Effect_Amplify;

// Replace damage mod function with pre default one from CHL, more appropriate for percentage increases.
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState)
{
	return 0;
}

// function float GetPostDefaultDefendingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState)
function float GetPreDefaultDefendingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState)
{
	local XComGameState_Effect_Amplify AmplifyState;
	local int DamageMod;

	if (AppliedData.AbilityInputContext.PrimaryTarget.ObjectID > 0 && class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) && CurrentDamage != 0)
	{
		DamageMod = BonusDamageMult * CurrentDamage;
		if (DamageMod < MinBonusDamage)
			DamageMod = MinBonusDamage;

		//	if NewGameState was passed in, we are really applying damage, so update our counter or remove the effect if it's worn off
		if (NewGameState == none)
			return DamageMod;
		
		AmplifyState = XComGameState_Effect_Amplify(EffectState);
		if (AmplifyState == none)
			return DamageMod;
			
		if (AmplifyState.ShotsRemaining == 1)
		{
			AmplifyState.RemoveEffect(NewGameState, NewGameState);
		}
		else
		{
			AmplifyState = XComGameState_Effect_Amplify(NewGameState.ModifyStateObject(AmplifyState.Class, AmplifyState.ObjectID));
			AmplifyState.ShotsRemaining -= 1;
		}
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(AmplifyDecrement_PostBuildVisualization);
	}
	
	return DamageMod;
}

static function AmplifyDecrement_PostBuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameState_Effect_Amplify	AmplifyState;
	local string						FlyoverString;
	local VisualizationActionMetadata	BuildTrack;
	local XComGameStateHistory			History;
	local X2Action_PlaySoundAndFlyOver	FlyOverAction;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect_Amplify', AmplifyState)
	{
		if (AmplifyState.bRemoved)
		{
			// Iridar: skip the "removed" flyover.
			//FlyoverString = default.AmplifyRemoved;

			//	the effect is not removed through a normal effect removed context, so we need to visualize it here
			AmplifyState.GetX2Effect().AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, 'AA_Success', AmplifyState);
			return;
		}
		else
		{
			FlyoverString = repl(default.AmplifyCountdown, "%d", AmplifyState.ShotsRemaining);
		}
		BuildTrack.VisualizeActor = History.GetVisualizer(AmplifyState.ApplyEffectParameters.TargetStateObjectRef.ObjectID);
		History.GetCurrentAndPreviousGameStatesForObjectID(AmplifyState.ApplyEffectParameters.TargetStateObjectRef.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		if (BuildTrack.StateObject_NewState == none)
			BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
		else if (BuildTrack.StateObject_OldState == none)
			BuildTrack.StateObject_OldState = BuildTrack.StateObject_NewState;

		FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(BuildTrack, VisualizeGameState.GetContext()));
		FlyOverAction.SetSoundAndFlyOverParameters(None, FlyoverString, '', eColor_Bad, "img:///UILibrary_XPACK_Common.PerkIcons.UIPerk_Amplify");

		break;
	}
}

DefaultProperties
{
	GameStateEffectClass = class'XComGameState_Effect_IRI_Amplify'
}
