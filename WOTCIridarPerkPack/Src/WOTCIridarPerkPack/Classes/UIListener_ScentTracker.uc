class UIListener_ScentTracker extends UIScreenListener;

var private string PathToActor; // "weak reference" to the Actor, implemented per robojumper's recommendation. Better performance than iterating through all Actors on a Screen.

event OnInit (UIScreen Screen)
{
	local ActorScentTracker TheActor;

	if (UITacticalHUD(Screen) != none)
	{		

		// Exit early if the actor already exists.
		if (PathToActor != "")
		{
			TheActor = ActorScentTracker(FindObject(PathToActor, class'ActorScentTracker'));
			if (TheActor != none)
				return;
		}

		// IF we're still here, then actor either doesn't exist or has never been created, so create one now.
		TheActor = `XCOMGRI.Spawn(class'ActorScentTracker');
		PathToActor = PathName(TheActor);

		`LOG("Created actor:" @ PathToActor,, 'IRIACTOR');
	}
}

event OnRemoved (UIScreen Screen)
{
	local ActorScentTracker TheActor;
	
	if (UITacticalHUD(Screen) != none && PathToActor != "")
	{
		TheActor = ActorScentTracker(FindObject(PathToActor, class'ActorScentTracker'));
		if (TheActor != none)
		{
			TheActor.Destroy();
			`LOG("Destroyed Actor",, 'IRIACTOR');
		}
	}
}
