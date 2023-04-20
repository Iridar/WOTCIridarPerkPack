class X2Effect_IgnoreCoverDefense extends X2Effect_Persistent config(TemplateEditor);

struct IgnoreCoverDefenseStruct
{
	var ECoverType TargetCover;
	var name TemplateName;
	var int DamageMod;
};
var private config array<IgnoreCoverDefenseStruct> IgnoreCoverDefense;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{	
	local ShotModifierInfo				ModInfo;
	local GameRulesCache_VisibilityInfo VisInfo;

	if (EffectState.ApplyEffectParameters.ItemStateObjectRef != AbilityState.SourceWeapon) return;

	if (Target.CanTakeCover() && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, Target.ObjectID, VisInfo))
	{	
		switch (VisInfo.TargetCover)
		{
			case CT_MidLevel:
				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = FriendlyName;
				ModInfo.Value = class'X2AbilityToHitCalc_StandardAim'.default.LOW_COVER_BONUS;
				ShotModifiers.AddItem(ModInfo);
				break;
			case CT_Standing:
				ModInfo.ModType = eHit_Success;
				ModInfo.Reason = FriendlyName;
				ModInfo.Value = class'X2AbilityToHitCalc_StandardAim'.default.HIGH_COVER_BONUS;
				ShotModifiers.AddItem(ModInfo);
				break;
			default:
				break;
		}
	}
}

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local int							DamageMod;
	local XComGameState_Unit			TargetUnit;
	local XComGameState_Item			SourceWeapon;
	local X2WeaponTemplate				WeaponTemplate;
	local GameRulesCache_VisibilityInfo VisInfo;
	local X2AbilityTemplate				AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;	

	if (EffectState.ApplyEffectParameters.ItemStateObjectRef != AbilityState.SourceWeapon) return 0;

	// Cover doesn't reduce damage of reaction fire if the shooter has Covering Fire.
	if (Attacker.HasSoldierAbility('IRI_SP_CoveringFire'))
	{
		AbilityTemplate = AbilityState.GetMyTemplate();
		if(AbilityTemplate != none)
		{
			ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
			if (ToHitCalc != none && ToHitCalc.bReactionFire)
			{			
				return 0;		
			}
		}
	}

	TargetUnit = XComGameState_Unit(TargetDamageable);

	if (TargetUnit != none && TargetUnit.CanTakeCover() && `TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, TargetUnit.ObjectID, VisInfo))
	{	
		switch (VisInfo.TargetCover)
		{
			case CT_Standing:
				SourceWeapon = AbilityState.GetSourceWeapon();
				if (SourceWeapon == none)
					return 0;
				WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
				if (WeaponTemplate == none)
					return 0;

				DamageMod = GetDamageModHighCover(WeaponTemplate);
				break;
			case CT_MidLevel:
				SourceWeapon = AbilityState.GetSourceWeapon();
				if (SourceWeapon == none)
					return 0;
				WeaponTemplate = X2WeaponTemplate(SourceWeapon.GetMyTemplate());
				if (WeaponTemplate == none)
					return 0;

				DamageMod = GetDamageModLowCover(WeaponTemplate);
				break;
			default:
				break;
		}
	}
	return DamageMod; 
}

static private function int GetDamageModHighCover(const X2WeaponTemplate WeaponTemplate)
{
	local IgnoreCoverDefenseStruct IgnCovDef;

	foreach default.IgnoreCoverDefense(IgnCovDef)
	{
		if (IgnCovDef.TargetCover == CT_Standing && 
			IgnCovDef.TemplateName == WeaponTemplate.DataName)
		{
			return IgnCovDef.DamageMod;
		}
	}
	return 0;
}
static private function int GetDamageModLowCover(const X2WeaponTemplate WeaponTemplate)
{
	local IgnoreCoverDefenseStruct IgnCovDef;

	foreach default.IgnoreCoverDefense(IgnCovDef)
	{
		if (IgnCovDef.TargetCover == CT_MidLevel && 
			IgnCovDef.TemplateName == WeaponTemplate.DataName)
		{
			return IgnCovDef.DamageMod;
		}
	}
	return 0;
}

defaultproperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_IgnoreCoverDefense_Effect"
	bDisplayInSpecialDamageMessageUI = true
}
