// -----------------------------------------------------------
//	Class:	X2Action_ApplyDamageSpacer
//	Author: Mr. Nice
//	
//-----------------------------------------------------------

//	Created by MrNice, used in various Merge Visualization functions 

class X2Action_ApplyDamageSpacer extends X2Action;

var float DelayTimer;

//work around for protected property
static function ChangeActionContext(X2Action Action, XComGameStateContext NewContext)
{
	Action.StateChangeContext=NewContext;
}

simulated state Executing
{
begin:
	//Sleep(DelayTimer);
	CompleteAction();
}

DefaultProperties
{
	InputEventIDs.Add( "Visualizer_AbilityHit" )
	InputEventIDs.Add( "Visualizer_ProjectileHit" )
	OutputEventIDs.Add( "Visualizer_AbilityHit" )
	OutputEventIDs.Add( "Visualizer_ProjectileHit" )
}