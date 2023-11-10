class X2Action_PlaySound extends X2Action;

// a reinvented bicycle of playing a sound during ability visualization

var string SoundCue;
var float AfterActionDelay;

simulated state Executing
{
Begin:
	//Unit.PlaySound(SoundCue(DynamicLoadObject(SoundCue, class'SoundCue')), true);
	Unit.PlaySound(SoundCue(`CONTENT.RequestGameArchetype(SoundCue)), true );
	Sleep(AfterActionDelay);
	CompleteAction();
}