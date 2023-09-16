class X2CharacterTemplate_AstralGrasp extends X2CharacterTemplate;

// TODO: Delete

var delegate<GetPawnArchetypeStringDelegate> GetPawnArchetypeStringFn;

delegate string GetPawnArchetypeStringDelegate(XComGameState_Unit kUnit, optional const XComGameState_Unit ReanimatedFromUnit = None);

simulated function string GetPawnArchetypeString(XComGameState_Unit kUnit, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	`AMLOG(kUnit.GetFullName() @ ReanimatedFromUnit.GetFullName());
	if (GetPawnArchetypeStringFn != none)
	{
		return GetPawnArchetypeStringFn(kUnit, ReanimatedFromUnit);
	}
	return super.GetPawnArchetypeString(kUnit, ReanimatedFromUnit);
}
