class X2EventListener_ThunderLance extends X2EventListener;

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

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_ThunderLance');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	//Template.AddCHEvent('OnProjectileFireSound', OnProjectilSoundOverride, ELD_Immediate, 50);

	return Template;
}


static function EventListenerReturn OnProjectilSoundOverride(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
}

static function EventListenerReturn OnOverrideProjectileInstance(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComGameStateContext_Ability AbilityContext;
    local XComLWTuple Tuple;
   // local bool bPreventProjectileSpawning;
    local Actor ProjectileTemplate;
	local Actor OverrideProjectileTemplate;
    local AnimNotify_FireWeaponVolley InVolleyNotify;
    local XComWeapon InSourceWeapon;
    local X2Action_Fire CurrentFireAction;
    local XGUnitNativeBase Unit;

    AbilityContext = XComGameStateContext_Ability(EventSource);
	if (AbilityContext == none || AbilityContext.InputContext.AbilityTemplateName != 'IRI_SK_ThunderLance')
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);

    ProjectileTemplate = Actor(Tuple.Data[1].o);
    InVolleyNotify = AnimNotify_FireWeaponVolley(Tuple.Data[2].o);
    InSourceWeapon = XComWeapon(Tuple.Data[3].o);
    CurrentFireAction = X2Action_Fire(Tuple.Data[4].o);
    Unit = XGUnitNativeBase(Tuple.Data[5].o);

	`AMLOG(AbilityContext.InputContext.AbilityTemplateName @ PathName(ProjectileTemplate) @ ProjectileTemplate.Class.Name);

	OverrideProjectileTemplate = Unit.Spawn(class'X2UnifiedProjectile_ThunderLance',Unit, , , , /*ProjectileTemplate*/);

    // Your code here

   // Tuple.Data[0].b = bPreventProjectileSpawning;
    Tuple.Data[1].o = OverrideProjectileTemplate;
    Tuple.Data[2].o = InVolleyNotify;
    Tuple.Data[3].o = InSourceWeapon;
    Tuple.Data[4].o = CurrentFireAction;

    return ELR_NoInterrupt;
}