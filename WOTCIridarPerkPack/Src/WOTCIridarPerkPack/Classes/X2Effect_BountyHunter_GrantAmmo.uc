class X2Effect_BountyHunter_GrantAmmo extends X2Effect_Persistent;

// This effect will grant Ammo to the weapon in the specified slot. If that ammo is not spent by the time the effect is removed, the ammo is taken away.
// Unit Value is applied when this effect is applied, to signify that we have granted bonus ammo.
// Unit Value stores the ObjectID of the item to which we granted ammo.
// If an ability is activated that consumed ammo on this item, unit value is removed,
// signifying that the granted ammo was spent.
// When the effect is removed from the unit, if the unit value is still there, it means the ammo was not spent, so we take it away ourselves.

var EInventorySlot	Slot;
var bool			bShowFlyovers;
var int				iAmmo;

// Display the effect on the unit while the unit value is there = ammo unspent.
function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) 
{
	local UnitValue UV;

	return TargetUnit.GetUnitValue(EffectName, UV); 
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit	UnitState;
	local XComGameState_Item	ItemState;
	local XComGameState_Item	NewItemState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState == none) // Shouldn't be possible
	{
		`AMLOG("ERROR :: Grant Ammo effect added to a unit that doesn't exist!");
		NewEffectState.RemoveEffect(NewGameState, NewGameState,, true);
		return;
	}

	ItemState = UnitState.GetItemInSlot(default.Slot, NewGameState);
	if (ItemState == none)
	{
		`AMLOG("ERROR :: Grant Ammo effect added to a unit with no weapon in Slot:" @ Slot);
		NewEffectState.RemoveEffect(NewGameState, NewGameState,, true);
		return;
	}

	NewItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ItemState.ObjectID));
	if (NewItemState == none)
	{
		NewItemState = XComGameState_Item(NewGameState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
	}

	UnitState.SetUnitFloatValue(default.EffectName, NewItemState.ObjectID, eCleanup_BeginTactical);
	NewItemState.Ammo += default.iAmmo;
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

static private function GrantAmmo_EffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed)
{
	local XComGameState_Item	ItemState;
	local XComGameState_Item	NewItemState;
	local XComGameState_Unit	UnitState;
	local UnitValue				UV;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	}

	if (UnitState == none)
		return;

	if (!UnitState.GetUnitValue(default.EffectName, UV))
		return;

	ItemState = UnitState.GetItemInSlot(default.Slot);
	if (ItemState != none && UV.fValue == ItemState.ObjectID)
	{
		NewItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ItemState.ObjectID));
		if (NewItemState == none)
		{
			NewItemState = XComGameState_Item(NewGameState.ModifyStateObject(ItemState.Class, ItemState.ObjectID));
		}

		if (NewItemState != none)
		{
			NewItemState.Ammo -= default.iAmmo;
			if (NewItemState.Ammo < 0)
			{
				`AMLOG("WARNING :: Reduced ammo below zero! Shouldn't be possible!" @ UnitState.GetFullName() @ ItemState.GetMyTemplateName());
				NewItemState.Ammo = 0;
			}
		}
	}	

	UnitState.ClearUnitValue(default.EffectName);
}

function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local XComGameState_Item	OldItemState;
	local UnitValue				UV;

	if (AffectWeapon.InventorySlot != Slot)
		return false;

	if (!SourceUnit.GetUnitValue(EffectName, UV))
		return false;

	if (AffectWeapon.ObjectID != UV.fValue)
		return false;
	
	OldItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(AffectWeapon.ObjectID));
	if (OldItemState == none)
		return false;

	if (OldItemState.Ammo > AffectWeapon.Ammo)
	{
		SourceUnit.ClearUnitValue(EffectName);
	}

	return false;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	if (EffectApplyResult == 'AA_Success')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, `GetLocalizedString('IRI_BH_FeelingLucky_Flyover_Added'), '', eColor_Good);
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameState_Unit UnitState;
	local UnitValue	UV;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState != none && UnitState.GetUnitValue(EffectName, UV))
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, `GetLocalizedString('IRI_BH_FeelingLucky_Flyover_Removed'), '', eColor_Bad);
	}
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
}

defaultproperties
{	
	iAmmo = 1
	Slot = eInvSlot_SecondaryWeapon
	bShowFlyovers = true
	EffectRemovedFn = GrantAmmo_EffectRemoved
	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_BountyHunter_GrantAmmo"
}