class X2Action_AddRecentSpeech extends X2Action;

var name RecentSpeech;

simulated state Executing
{
Begin:
	Unit.m_arrRecentSpeech.AddItem(RecentSpeech);
	CompleteAction();
}
