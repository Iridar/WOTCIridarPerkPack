class X2Action_PredatorStrike extends X2Action_Fire;

/*
FF_PredatorStrikeMissA
FF_PredatorStrikeStartA
FF_PredatorStrikeStopA
*/

function Init()
{
	super.Init();

	if (AbilityContext.IsResultContextMiss())
	{
		AnimParams.AnimName = 'FF_PredatorStrikeMiss';
	}
	else
	{
		AnimParams.AnimName = 'FF_PredatorStrikeStart';
	}
}
