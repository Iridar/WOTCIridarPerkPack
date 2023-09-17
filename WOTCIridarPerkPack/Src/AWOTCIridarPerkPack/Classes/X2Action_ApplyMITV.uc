class X2Action_ApplyMITV extends X2Action;

var string MITVPath;
var bool bApplyToSecondaryWeapon;

event bool BlocksAbilityActivation()
{
	return false;
}

function Init()
{
	local XComWeapon							SecondaryWeapon;
	local MaterialInstanceTimeVarying			MITV;
	local SkeletalMeshComponent					SkelMesh;

	super.Init();

	MITV = MaterialInstanceTimeVarying(DynamicLoadObject(MITVPath, class'MaterialInstanceTimeVarying'));

	if (bApplyToSecondaryWeapon) {
		SecondaryWeapon = XComWeapon(Unit.GetInventory().m_kSecondaryWeapon.m_kEntity);
		if (SecondaryWeapon != none) {
			SkelMesh = SkeletalMeshComponent(SecondaryWeapon.Mesh);
			UnitPawn.ApplyMITVToSkeletalMeshComponent(SkelMesh, MITV);
		}
	}
	else {
		UnitPawn.ApplyMITV(MITV);
	}
}


simulated state Executing
{
Begin:
	CompleteAction();
}

defaultproperties
{
	bApplyToSecondaryWeapon=false
}