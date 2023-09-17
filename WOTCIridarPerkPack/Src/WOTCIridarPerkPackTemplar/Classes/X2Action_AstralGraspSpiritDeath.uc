class X2Action_AstralGraspSpiritDeath extends X2Action_Death;

function Init()
{
	super.Init();

	UnitPawn.AimEnabled = false;
	UnitPawn.AimOffset.X = 0;
	UnitPawn.AimOffset.Y = 0;
}

static function bool AllowOverrideActionDeath(VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	return true;
}

simulated function Name ComputeAnimationToPlay()
{
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	return 'HL_AstralGrasp_Death';
}
