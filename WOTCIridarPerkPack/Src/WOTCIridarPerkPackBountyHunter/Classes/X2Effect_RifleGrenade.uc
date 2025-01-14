class X2Effect_RifleGrenade extends X2Effect_Persistent;

function float GetPreDefaultAttackingDamageModifier_CH(XComGameState_Effect EffectState, XComGameState_Unit SourceUnit, Damageable Target, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters, float CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, XComGameState NewGameState) 
{ 
	if (NewGameState != none) // So it doesn't affect damage preview
	{
		if (ApplyEffectParameters.AbilityInputContext.AbilityTemplateName == 'IRI_BH_RifleGrenade' &&
			ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		{
			return `GetConfigFloat("IRI_BH_RifleGrenade_DamageBonusPercent") * CurrentDamage; 
		}
	}
	return 0.0f;
}

function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData ApplyEffectParameters) 
{
	if (ApplyEffectParameters.AbilityInputContext.AbilityTemplateName == 'IRI_BH_RifleGrenade' &&
			ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
	{
		return 999; 
	}
	return 0; 
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager		EventMgr;
	//local XComGameState_Unit	UnitState;
	local Object				EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	//UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
	EventMgr.RegisterForEvent(EffectObj, 'OnGetItemRange', OnGetItemRange, ELD_Immediate,, ,, EffectObj);	

	// Used to override spawning of the second grenade projectile caused by the cosmetic Fire Weapon Volley notify.
	EventMgr.RegisterForEvent(EffectObj, 'OverrideProjectileInstance', OnOverrideProjectileInstance, ELD_Immediate,, ,, EffectObj);	

	// Socket management
	EventMgr.RegisterForEvent(EffectObj, 'OverrideWeaponScale', OnOverrideWeaponScale, ELD_Immediate, 0, ,, EffectObj);	
}

static function EventListenerReturn OnOverrideWeaponScale(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
    local XComUnitPawn			UnitPawn;
    local XComLWTuple			Tuple;
    local float					fWeaponScale;
    local XComGameState_Item	ItemState;
	local SkeletalMeshSocket	Socket;
	local SkeletalMeshSocket	NewSocket;
	local XGWeapon				GameWeapon;
	local XComWeapon			Weapon;
	local SkeletalMeshComponent	SkelMeshComp;
	local array<SkeletalMeshSocket>	NewSockets;

    UnitPawn = XComUnitPawn(EventSource);
	if (UnitPawn == none)
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	ItemState = XComGameState_Item(Tuple.Data[2].o);
	if (ItemState == none)
		return ELR_NoInterrupt;

	if (ItemState.InventorySlot != eInvSlot_PrimaryWeapon)
		return ELR_NoInterrupt;

	GameWeapon = XGWeapon(ItemState.GetVisualizer());
	if (GameWeapon == none)
		return ELR_NoInterrupt;

	Weapon = GameWeapon.GetEntity();
	if (Weapon == none)
		return ELR_NoInterrupt;

	SkelMeshComp = SkeletalMeshComponent(Weapon.Mesh);
	if (SkelMeshComp == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[0].b)
	{
		fWeaponScale = Tuple.Data[1].f; // Weapon scale overridden by prior listeners in mods
	}
	else
	{
		fWeaponScale = UnitPawn.WeaponScale; // Uses default weapon scale for gender
	}

	foreach SkelMeshComp.Sockets(Socket)
	{
		if (Socket.SocketName == 'gun_fire')
		{
			//`LOG("Weapon" @ ItemState.GetMyTemplateName() @ "has socket:" @ Socket.SocketName @ Socket.BoneName @ Socket.RelativeLocation @ "Weapon Scale:" @ fWeaponScale,, 'IRITEST');

			// Socket Left
			NewSocket = new class'SkeletalMeshSocket';
			NewSocket.SocketName = 'IRI_RifleGrenade_Left';
			NewSocket.BoneName = 'Inven_L_Hand';

			NewSocket.RelativeLocation = Socket.RelativeLocation;
			NewSocket.RelativeLocation.X += 12.5;
			NewSocket.RelativeLocation *= fWeaponScale;

			NewSocket.RelativeRotation.Roll = 16384;
			NewSocket.RelativeRotation.Yaw = 16384;
			
			NewSockets.AddItem(NewSocket);

			// Socket Right
			NewSocket = new class'SkeletalMeshSocket';
			NewSocket.SocketName = 'IRI_RifleGrenade_Right';
			NewSocket.BoneName = 'Inven_R_Hand';

			NewSocket.RelativeLocation = Socket.RelativeLocation;
			NewSocket.RelativeLocation.X += 12.5;
			NewSocket.RelativeLocation *= fWeaponScale;

			NewSocket.RelativeRotation.Roll = 16384;
			NewSocket.RelativeRotation.Yaw = 16384;
			
			NewSockets.AddItem(NewSocket);

			// Add, exit
			UnitPawn.Mesh.AppendSockets(NewSockets, true);
			break;
		}
	}


    return ELR_NoInterrupt;
}


static private function EventListenerReturn OnOverrideProjectileInstance(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple					Tuple;
	local XComGameStateContext_Ability	AbilityContext;
	local string						strPathName;
	local X2Action_Fire					FireAction;
	local X2UnifiedProjectile			UnifiedProjectile;
	local XComGameState_Effect			EffectState;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(EventSource);
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	if (AbilityContext.InputContext.SourceObject.ObjectID != EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	if (AbilityContext.InputContext.AbilityTemplateName != 'IRI_BH_RifleGrenade')
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[1].o == none)
		return ELR_NoInterrupt;

	FireAction = X2Action_Fire(Tuple.Data[4].o);
	if (FireAction == none)
		return ELR_NoInterrupt;

	strPathName = PathName(Tuple.Data[1].o);

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

	`LOG("Spawn projectile:" @ strPathName,, 'IRITEST');

	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnGetItemRange(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			OverrideTuple;
	local XComGameState_Ability	AbilityState;
	local XComGameState_Item	ItemState;
	local X2WeaponTemplate		WeaponTemplate;
	local XComGameState_Effect	EffectState;

	ItemState = XComGameState_Item(EventSource);
	if (ItemState == none)
		return ELR_NoInterrupt;

	EffectState = XComGameState_Effect(CallbackData);
	if (EffectState == none)
		return ELR_NoInterrupt;

	// Exit if the owner of the item is not the same as the target of this effect.
	if (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID != ItemState.OwnerStateObject.ObjectID)
		return ELR_NoInterrupt;

	OverrideTuple = XComLWTuple(EventData);
	if (OverrideTuple == none)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(OverrideTuple.Data[2].o);
	if (AbilityState == none)
		return ELR_NoInterrupt;

	if (AbilityState.GetMyTemplateName() != 'IRI_BH_RifleGrenade')
		return ELR_NoInterrupt;
	
	ItemState = AbilityState.GetSourceAmmo();
	if (ItemState == none)
		return ELR_NoInterrupt;

	
	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate == none)
		return ELR_NoInterrupt;
	
	OverrideTuple.Data[1].i += WeaponTemplate.iRange + `GetConfigInt("IRI_BH_RifleGrenade_RangeIncrase_Tiles");

	return ELR_NoInterrupt;
}


defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_BH_X2Effect_RifleGrenade_Effect"
	bDisplayInSpecialDamageMessageUI = true
}
