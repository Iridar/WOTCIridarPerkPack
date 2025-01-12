class X2EventListener_BountyHunter extends X2EventListener;

/*
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_ListenerTemplate());

	return Templates;
}
*/
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

static private function CHEventListenerTemplate Create_ListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_BH_X2EventListener_BountyHunter');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('OnGetItemRange', OnGetItemRange, ELD_Immediate, 50);

	// Used to override spawning of the second grenade projectile caused by the cosmetic Fire Weapon Volley notify.
	Template.AddCHEvent('OverrideProjectileInstance', OnOverrideProjectileInstance, ELD_Immediate, 50);
	

	return Template;
}

static private function EventListenerReturn OnOverrideProjectileInstance(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local XComGameStateContext_Ability AbilityContext;
	local string strPathName;
	//local XGUnitNativeBase GameUnit;
	local X2Action_Fire FireAction;
	local X2UnifiedProjectile UnifiedProjectile;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(EventSource);
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	if (AbilityContext.InputContext.AbilityTemplateName != 'IRI_BH_RifleGrenade')
		return ELR_NoInterrupt;

	if (Tuple.Data[1].o == none)
	{
		//Tuple.Data[0].b = true;
		return ELR_NoInterrupt;
	}

	//GameUnit = XGUnitNativeBase(Tuple.Data[5].o);

	strPathName = PathName(Tuple.Data[1].o);
	// if (strPathName != "" && strPathName != "IRIBountyHunter.PJ_RifleGrenade")
	// {
	// 	Tuple.Data[0].b = true;
	// }

	FireAction = X2Action_Fire(Tuple.Data[4].o);
	if (FireAction == none)
		return ELR_NoInterrupt;

	foreach FireAction.ProjectileVolleys(UnifiedProjectile)
	{
		//`LOG("Projectile on the fire action:" @ PathName(UnifiedProjectile.ObjectArchetype) @ PathName(UnifiedProjectile.Outer),, 'IRITEST');
		if (PathName(UnifiedProjectile.ObjectArchetype) == strPathName)
		{
			//`LOG("Match, not spawning this projectile",, 'IRITEST');
			Tuple.Data[0].b = true;
			return ELR_NoInterrupt;
		}
	}

	`LOG("Spawn projectile:" @ strPathName @ XComGameState_Item(Tuple.Data[3].o).GetMyTemplateName(),, 'IRITEST');

	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnGetItemRange(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple OverrideTuple;
	local XComGameState_Ability AbilityState;
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;

	OverrideTuple = XComLWTuple(EventData);
	if (OverrideTuple == none)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	if (AbilityState.GetMyTemplateName() == 'IRI_BH_RifleGrenade')
	{
		ItemState = AbilityState.GetSourceAmmo();
		if (ItemState != none)
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if (WeaponTemplate != none)
			{
				OverrideTuple.Data[1].i += WeaponTemplate.iRange + `GetConfigInt("IRI_BH_RifleGrenade_RangeIncrase_Tiles");
			}
		}
	}

	return ELR_NoInterrupt;
}
