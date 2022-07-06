class AnimNotify_FireOtherWeapon extends AnimNotify_Scripted;	//created by Robojumper
																//this anim notify allows to use Fire Volley anim notify even on a weapon that's not
																//directly attached to the ability that triggers the animsequence
var() editinline AnimNotify_FireWeaponVolley WrappedVolley;
var() editinline EInventorySlot OtherWeaponSlot;

event Notify(Actor Owner, AnimNodeSequence AnimSeqInstigator)
{
    local XComUnitPawn Pawn;
    local XGUnitNativeBase OwnerUnit;
	local XGWeapon Weapon;
	local XComWeapon Entity, OldWeapon;

    Pawn = XComUnitPawn(Owner);
    if (Pawn != none)
    {
        OwnerUnit = Pawn.GetGameUnit();
        if (OwnerUnit != none)
        {
			Weapon = XGWeapon(OwnerUnit.GetVisualizedGameState().GetItemInSlot(OtherWeaponSlot).GetVisualizer());
			if (Weapon != none)
			{
				Entity = XComWeapon(Weapon.m_kEntity);
				if (Entity != none)
				{
					// Push the new weapon, call the notify, pop
					OldWeapon = XComWeapon(Pawn.Weapon);
					Pawn.SetCurrentWeapon(Entity);
					OwnerUnit.OnFireWeaponVolley(WrappedVolley);
					Pawn.SetCurrentWeapon(OldWeapon);
				}
			}
        }
    }
}