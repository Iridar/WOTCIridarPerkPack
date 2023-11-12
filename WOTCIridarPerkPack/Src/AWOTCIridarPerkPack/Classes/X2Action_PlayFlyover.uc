class X2Action_PlayFlyover extends X2Action;

var StateObjectReference	ActorRef;
var string					FlyoverMessage;
var string					FlyoverIcon;
var vector					FlyoverLocation;
var EWidgetColor			MessageColor;

simulated state Executing
{
Begin:

	`PRES.QueueWorldMessage(FlyoverMessage, FlyoverLocation, ActorRef, MessageColor, , , /*Unit.m_eTeamVisibilityFlags*/, , , , , FlyoverIcon, , , , , , , , true );
	CompleteAction();
}
