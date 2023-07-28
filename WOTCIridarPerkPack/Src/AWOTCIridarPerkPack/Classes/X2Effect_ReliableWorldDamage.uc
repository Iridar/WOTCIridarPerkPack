class X2Effect_ReliableWorldDamage extends X2Effect;

var int DamageAmount;
var bool bSkipGroundTiles;

//	Similar to X2Effect_ApplyDirectionalWorldDamage, but works even without target/multi target units.

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameStateContext_Ability		AbilityContext;
	local XComGameState_Unit				SourceUnit;
	local vector							TargetLocation;
	local XComGameState_EnvironmentDamage	DamageEvent;
	local XComWorldData						WorldData;
	local Vector							DamageDirection;
	local Vector							SourceLocation;
	local TTile								SourceTile;
	//local XComGameState_Ability				AbilityState;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none || AbilityContext.InputContext.TargetLocations.Length == 0)
		return;
	
	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (SourceUnit == none)
		return;

	//AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	//if (AbilityState == none)
	//	return;

	WorldData = `XWORLD;

	SourceTile = SourceUnit.TileLocation;
	TargetLocation = AbilityContext.InputContext.TargetLocations[0];

	if (bSkipGroundTiles)
	{
		//	Raise height of the attack by 1 tile so we don't strike ground tiles.
		SourceTile.Z++;
		TargetLocation.Z += WorldData.WORLD_HalfFloorHeight;
	}
	SourceLocation = WorldData.GetPositionFromTileCoordinates(SourceTile);

	DamageDirection = SourceLocation - TargetLocation;
	DamageDirection.Z = 0.0f;
	DamageDirection = Normal(DamageDirection);
		
	DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
	DamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_ApplyDirectionalWorldDamage:ApplyEffectToWorld";
	DamageEvent.DamageAmount = DamageAmount;
	DamageEvent.DamageTypeTemplateName = 'melee';
	
	DamageEvent.Momentum = DamageDirection;
	DamageEvent.DamageDirection = DamageDirection; //Limit environmental damage to the attack direction( ie. spare floors )
	DamageEvent.PhysImpulse = 100;
	DamageEvent.DamageCause = SourceUnit.GetReference();
	DamageEvent.DamageSource = DamageEvent.DamageCause;
	//DamageEvent.HitLocation = TargetLocation;
	//DamageEvent.DamageRadius = AbilityState.GetAbilityRadius();	
	//DamageEvent.bRadialDamage = true;
	DamageEvent.DamageTiles = AbilityContext.ResultContext.RelevantEffectTiles;
	DamageEvent.bAllowDestructionOfDamageCauseCover = true;
}
