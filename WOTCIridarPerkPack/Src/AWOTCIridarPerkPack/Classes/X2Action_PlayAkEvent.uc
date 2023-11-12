class X2Action_PlayAkEvent extends X2Action;

var string			AkEventPath;
var vector			SoundLocation; // optional

// Cached stuff
var private AkEvent	EventToPlay;

function Init()
{
	super.Init();

	EventToPlay = AkEvent(`CONTENT.RequestGameArchetype(AkEventPath));
}

simulated state Executing
{
Begin:
	UnitPawn.PlayAkEvent(EventToPlay,,,, SoundLocation);
	CompleteAction();
}
