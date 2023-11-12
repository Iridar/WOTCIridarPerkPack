class X2Condition_ObeliskVolt extends X2Condition;

// Checks whether the target unit can see the Obelisk's firing location.

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	local XComGameState_Unit			SourceUnit;
	local XComGameState_Unit			TargetUnit;
	local XComGameState_Effect			ObeliskEffect;
	local XComGameState_Destructible	ObeliskState;
	local TTile							ObeliskFiringTile;
	local GameRulesCache_VisibilityInfo	OutVisInfo;
		
	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	SourceUnit = XComGameState_Unit(kSource);
	if (SourceUnit == none)
		return 'AA_NotAUnit';

	ObeliskEffect = SourceUnit.GetUnitAffectedByEffectState('IRI_TM_Obelisk_Effect');
	if (ObeliskEffect == none)
		return 'AA_MissingRequiredEffect';

	ObeliskState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(ObeliskEffect.CreatedObjectReference.ObjectID));
	if (ObeliskState == none)
		return 'AA_MissingRequiredEffect';

	//`AMLOG("Running for:" @ SourceUnit.GetFullName() @ "against:" @ TargetUnit.GetFullName());

	ObeliskFiringTile = ObeliskState.TileLocation;
	ObeliskFiringTile.Z += 2;

	`XWORLD.CanSeeTileToTile(TargetUnit.TileLocation, ObeliskFiringTile, OutVisInfo);

	//`AMLOG("Clear LOS:" @ OutVisInfo.bClearLOS @ "distance:" @ OutVisInfo.DefaultTargetDist @ "peek distance:" @ OutVisInfo.PeekToTargetDist @ "vs:" @ `METERSTOUNITS_SQ(10 * 1.5f) @ "in range:" @ OutVisInfo.PeekToTargetDist < `TILESTOUNITS(10));

	if (OutVisInfo.bClearLOS && OutVisInfo.PeekToTargetDist < `METERSTOUNITS_SQ(10 * 1.5f)) // 1.5f = TILESTOMETERS // TODO: Cache this as class var
	{
		//`AMLOG("Condition success!");
		return 'AA_Success'; 
	}
	//`AMLOG("Condition fail!");

	return 'AA_NotVisible';
}
