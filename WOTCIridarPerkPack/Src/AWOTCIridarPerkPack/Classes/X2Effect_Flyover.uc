class X2Effect_Flyover extends X2Effect;

var string	CustomFlyover;			// If specified, this will be the displayed flyover text.
									// If not, the effect will use the flyover text from the template of the ability that applied the effect.
var name	AbilityName;			// Unless the template name of a different ability is specified here, in which case the effect will take the flyover from there.

var float	LookAtDuration;
var bool	BlockUntilFinished;
var name	Voiceline;
var bool	bPlayOnSource;			// If true, the flyover will be displayed on the source unit of the effect
var bool	bPlayOnlyOnUnits;		// In testing sometimes the effect was applied to XComGameState_EnvironmentDamage. If true, the flyover will display only when the effect is applied to a unit.

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameStateContext_Ability	AbilityContext;
	local bool							bGoodAbility;
	local string						strFlyoverText;
	local VisualizationActionMetadata	UseMetadata;
	local XComGameStateHistory			History;
	local X2AbilityTemplateManager		AbilityMgr;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

	if (EffectApplyResult != 'AA_Success')
		return;
		
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	
	if (AbilityContext == none)
		return;

	if (bPlayOnlyOnUnits)
	{
		if (XComGameState_Unit(ActionMetadata.StateObject_NewState) == none)
			return;
	}

	if (CustomFlyover != "")
	{	
		strFlyoverText = CustomFlyover;
	}
	else 
	{
		AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		if (AbilityName != '')
		{
			AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityName);
		}
		else
		{
			AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		}
		if (AbilityTemplate == none)
			return;

		strFlyoverText = AbilityTemplate.LocFlyOverText;
	}
	if (strFlyoverText == "")
		return;

	if (bPlayOnSource)
	{
		History = `XCOMHISTORY;
		UseMetadata.StateObject_OldState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID,, VisualizeGameState.HistoryIndex - 1);
		UseMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);
		if (UseMetadata.StateObject_NewState == none)
			return;

		UseMetadata.VisualizeActor = UseMetadata.StateObject_NewState.GetVisualizer();
	}
	else
	{
		UseMetadata = ActionMetadata;
	}

	bGoodAbility = XComGameState_Unit(UseMetadata.StateObject_NewState).IsFriendlyToLocalPlayer();

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(UseMetadata, AbilityContext, false, UseMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, strFlyoverText, Voiceline, bGoodAbility ? eColor_Good : eColor_Bad, AbilityTemplate.IconImage, LookAtDuration, BlockUntilFinished); 
}

defaultproperties
{
	bPlayOnlyOnUnits = true
}