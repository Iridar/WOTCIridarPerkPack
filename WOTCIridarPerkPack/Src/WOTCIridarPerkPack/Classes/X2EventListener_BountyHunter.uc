class X2EventListener_BountyHunter extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_ListenerTemplate());

	return Templates;
}

/*
'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState
*/

static function CHEventListenerTemplate Create_ListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_BountyHunter');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	//Template.AddCHEvent('RetainConcealmentOnActivation', OnRetainConcealmentOnActivation, ELD_Immediate, 50);

	return Template;
}
/*
static function EventListenerReturn OnRetainConcealmentOnActivation(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameStateContext_Ability AbilityContext;

	Tuple = XComLWTuple(EventData);
	if (Tuple.Data[0].b)
	{
		AbilityContext = XComGameStateContext_Ability(EventSource);
	}

	return ELR_NoInterrupt;
}*/