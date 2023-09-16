class X2Character_AstralGrasp extends X2Character;

// TODO: Delete

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateAstralGraspUnit());

	return Templates;
}

static private function X2CharacterTemplate CreateAstralGraspUnit()
{
	local X2CharacterTemplate CharTemplate;

	//`CREATE_X2CHARACTER_TEMPLATE(CharTemplate, 'IRI_TM_AstralGraspUnit');
	`CREATE_X2TEMPLATE(class'X2CharacterTemplate_AstralGrasp', CharTemplate, 'IRI_TM_AstralGraspUnit');
	
	CharTemplate.CharacterGroupName = 'Shadowbind';

	CharTemplate.BehaviorClass = class'XGAIBehavior';
	//CharTemplate.strPawnArchetypes.AddItem("GameUnit_ShadowBind.ARC_ShadowBindUnit_M");
	//CharTemplate.strPawnArchetypes.AddItem("GameUnit_ShadowBind.ARC_ShadowBindUnit_F");
	CharTemplate.bNeverShowFirstSighted = true;

	CharTemplate.UnitSize = 1;

	// TODO: Targeting icon

	// Traversal Rules
	CharTemplate.bCanUse_eTraversal_Normal = true;
	CharTemplate.bCanUse_eTraversal_ClimbOver = false;
	CharTemplate.bCanUse_eTraversal_ClimbOnto = false;
	CharTemplate.bCanUse_eTraversal_ClimbLadder = false;
	CharTemplate.bCanUse_eTraversal_DropDown = false;
	CharTemplate.bCanUse_eTraversal_Grapple = false;
	CharTemplate.bCanUse_eTraversal_Landing = true;
	CharTemplate.bCanUse_eTraversal_BreakWindow = true;
	CharTemplate.bCanUse_eTraversal_KickDoor = true;
	CharTemplate.bCanUse_eTraversal_JumpUp = false;
	CharTemplate.bCanUse_eTraversal_WallClimb = false;
	CharTemplate.bCanUse_eTraversal_BreakWall = false;
	CharTemplate.bCanUse_eTraversal_Launch = true;
	CharTemplate.bCanUse_eTraversal_Flying = true;
	CharTemplate.bCanUse_eTraversal_Land = true;
	
	CharTemplate.bAppearanceDefinesPawn = false;
	CharTemplate.bSetGenderAlways = true;
	
	CharTemplate.bCanTakeCover = false;
	CharTemplate.CanFlankUnits = false;

	CharTemplate.bIsAlien = true;
	CharTemplate.bIsAdvent = false;
	CharTemplate.bIsCivilian = false;
	CharTemplate.bIsPsionic = true;
	CharTemplate.bIsRobotic = false;
	CharTemplate.bIsSoldier = false;

	CharTemplate.bCanBeTerrorist = false;
	CharTemplate.bCanBeCriticallyWounded = false;
	CharTemplate.bIsAfraidOfFire = false;

	CharTemplate.strScamperBT = "ScamperRoot_NoShotChance";

	//CharTemplate.Abilities.AddItem('DarkEventAbility_Barrier');
	//CharTemplate.Abilities.AddItem('ShadowUnitInitialize');
	CharTemplate.Abilities.AddItem('IRI_TM_AstralGrasp_DamageImmunity');
	
	//CharTemplate.ImmuneTypes.AddItem('Mental');

	return CharTemplate;
}
