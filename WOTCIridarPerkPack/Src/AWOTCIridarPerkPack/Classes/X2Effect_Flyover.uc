class X2Effect_Flyover extends X2Effect;

var string	CustomFlyover;
var float	LookAtDuration;
var bool	BlockUntilFinished;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyOver;
	local X2AbilityTemplate				AbilityTemplate;
	local XComGameStateContext_Ability	AbilityContext;
	local bool							bGoodAbility;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

	if (EffectApplyResult != 'AA_Success')
		return;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	
	if (AbilityContext == none)
		return;
		
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
	if (AbilityTemplate == none)
		return;

	bGoodAbility = XComGameState_Unit(ActionMetadata.StateObject_NewState).IsFriendlyToLocalPlayer();

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, ActionMetadata.LastActionAdded));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, CustomFlyover != "" ? CustomFlyover : AbilityTemplate.LocFlyOverText, '', bGoodAbility ? eColor_Good : eColor_Bad, AbilityTemplate.IconImage, LookAtDuration, BlockUntilFinished); 
}