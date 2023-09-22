class X2Action_RemoveMITV extends X2Action;

event bool BlocksAbilityActivation()
{
	return false;
}

function Init()
{
	super.Init();

	UnitPawn.CleanUpMITV();

	//CleanUpMITV();
}

simulated state Executing
{
Begin:
	CompleteAction();
}

//simulated function CleanUpMITV()
//{
//	local MeshComponent MeshComp;
//	local MaterialInstanceTimeVarying MITV;
//	local int i;
//
//	foreach UnitPawn.AllOwnedComponents(class'MeshComponent', MeshComp)
//	{
//		for (i = 0; i < MeshComp.Materials.Length; i++)
//		{
//			if (MeshComp.GetMaterial(i).IsA('MaterialInstanceTimeVarying'))
//			{
//				MITV = MaterialInstanceTimeVarying(MeshComp.GetMaterial(i));
//				if (String(MITV.Parent) == "M_Warp_Beam_MITV") {
//					`LOG("Remove MITV" @ String(MITV.Parent), ,'SilentTakedown');
//					MeshComp.SetMaterial(i, none);
//				}
//			}
//		}
//	}
//
//	UnitPawn.UpdateAllMeshMaterials();
//}