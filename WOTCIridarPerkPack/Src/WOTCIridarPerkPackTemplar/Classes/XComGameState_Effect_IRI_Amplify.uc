class XComGameState_Effect_IRI_Amplify extends XComGameState_Effect_Amplify;

function PostCreateInit(EffectAppliedData InApplyEffectParameters, GameRuleStateChange WatchRule, XComGameState NewGameState)
{
	super(XComGameState_Effect).PostCreateInit(InApplyEffectParameters, WatchRule, NewGameState);

	ShotsRemaining = 1;
}
