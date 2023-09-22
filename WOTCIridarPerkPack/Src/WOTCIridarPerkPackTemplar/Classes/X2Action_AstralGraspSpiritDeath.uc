class X2Action_AstralGraspSpiritDeath extends X2Action_Death;

function Init()
{
	super.Init();

	UnitPawn.AimEnabled = false;
	UnitPawn.AimOffset.X = 0;
	UnitPawn.AimOffset.Y = 0;
	`AMLOG("DEATH HANDLER");
}

static function bool AllowOverrideActionDeath(VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	`AMLOG("DEATH HANDLER");
	return true;
}

simulated function Name ComputeAnimationToPlay()
{
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

	`AMLOG("DEATH HANDLER");

	return 'HL_AstralGrasp_Death';
}




function bool ShouldRunDeathHandler()
{
`AMLOG("DEATH HANDLER");
	return false;
}

function bool ShouldPlayDamageContainerDeathEffect()
{
`AMLOG("DEATH HANDLER");
	return false;
}

function bool DamageContainerDeathSound()
{
`AMLOG("DEATH HANDLER");
	return false;
}

simulated function name GetAssociatedAbilityName()
{
`AMLOG("DEATH HANDLER");
	return 'IRI_TM_AstralGrasp_SpiritDeath';
}
