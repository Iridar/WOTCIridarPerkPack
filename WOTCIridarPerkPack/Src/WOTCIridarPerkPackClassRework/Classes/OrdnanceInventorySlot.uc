class OrdnanceInventorySlot extends CHItemSlotSet config(Game);

var localized string strSlotFirstLetter;
var localized string strSlotLocName;

var config EInventorySlot UseSlot;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	if (default.UseSlot != eInvSlot_Unknown)
	{
		Templates.AddItem(CreateSlotTemplate());
	}
	return Templates;
}

static function X2DataTemplate CreateSlotTemplate()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'IRI_OrdnanceSlot');

	Template.InvSlot = default.UseSlot;
	Template.SlotCatMask = Template.SLOT_ITEM;
	Template.IsUserEquipSlot = true;

	Template.IsEquippedSlot = false;
	Template.BypassesUniqueRule = true;

	Template.IsMultiItemSlot = false;
	Template.IsSmallSlot = true;
	Template.NeedsPresEquip = false;
	Template.ShowOnCinematicPawns = false;
	Template.MinimumEquipped = 1;

	Template.CanAddItemToSlotFn = CanAddItemToSlot;

	Template.UnitHasSlotFn = HasSlot;
	Template.GetPriorityFn = SlotGetPriority;
	
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = SlotValidateLoadout;
	Template.GetSlotUnequipBehaviorFn = SlotGetUnequipBehavior;
	Template.GetDisplayLetterFn = GetSlotDisplayLetter;
	Template.GetDisplayNameFn = GetDisplayName;

	return Template;
}

static private function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{    
	return UnitState.HasSoldierAbility('IRI_GN_OrdnancePouch');
}

static private function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	return IsTemplateValidForSlot(Slot.InvSlot, ItemTemplate, Unit, CheckGameState);
}

static private function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit UnitState, X2ItemTemplate ItemTemplate, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{    
	//	If there is no item in the slot
	if(UnitState.GetItemInSlot(Slot.InvSlot, CheckGameState) == none)
	{
		return IsTemplateValidForSlot(Slot.InvSlot, ItemTemplate, UnitState, CheckGameState);
	}

	//	Slot is already occupied, cannot add any more items to it.
	return false;
}

static private function bool IsTemplateValidForSlot(EInventorySlot InvSlot, X2ItemTemplate ItemTemplate, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	if (IsItemValidGrenade(ItemTemplate))
	{
		return true;
	}
	if (X2AmmoTemplate(ItemTemplate) != none)
	{
		return !DoesUnitHaveAmmoEquippedInOtherSlot(UnitState);
	}
	return false;
}

static private function bool DoesUnitHaveAmmoEquippedInOtherSlot(const XComGameState_Unit UnitState)
{
    local array<XComGameState_Item> InventoryItems;
    local XComGameState_Item        InventoryItem;
 
    InventoryItems = UnitState.GetAllInventoryItems();
 
    foreach InventoryItems(InventoryItem)
    {
		if (InventoryItem.InventorySlot == default.UseSlot)
			continue;

		//	Filtering for the Unknown slot is necessary so that items don't get unequipped before they get properly equipped first.
		if (InventoryItem.InventorySlot == eInvSlot_Unknown)
			continue;

        if (X2AmmoTemplate(InventoryItem.GetMyTemplate()) != none)
        {
            return true;
        }
    }
    return false;
}

static private function bool IsItemValidGrenade(const X2ItemTemplate ItemTemplate)
{
	local X2GrenadeTemplate GrenadeTemplate;

	GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);

	if (GrenadeTemplate != none)
	{
		return GrenadeTemplate.LaunchedGrenadeEffects.Length > 0;
	}
	return false;
}

static private function SlotValidateLoadout(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item	ItemState;
	local string				strDummy;
	local bool					HasSlot;
	local bool					bShouldUnequip;

	ItemState = Unit.GetItemInSlot(Slot.InvSlot, NewGameState);
	HasSlot = Slot.UnitHasSlot(Unit, strDummy, NewGameState);
	if (!HasSlot)
	{
		bShouldUnequip = true;
	}
	else if (ItemState != none)
	{
		if (!IsTemplateValidForSlot(Slot.InvSlot, ItemState.GetMyTemplate(), Unit, NewGameState))
		{
			bShouldUnequip = true;
		}
	}

	//	If there's an item equipped in the slot, but the unit is not supposed to have the slot, or the item is not supposed to be in the slot, then unequip it and put it into HQ Inventory.
	if (bShouldUnequip && ItemState != none)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		if (Unit.RemoveItemFromInventory(ItemState, NewGameState))
		{
			XComHQ.PutItemInInventory(NewGameState, ItemState);
		}	
	}

	ItemState = Unit.GetItemInSlot(Slot.InvSlot, NewGameState);
	if (HasSlot && ItemState == none)
	{
		ItemState = FindBestInfiniteItemForSlot(Unit, Slot.InvSlot, NewGameState);
		if (ItemState != none)
		{
			Unit.AddItemToInventory(ItemState, Slot.InvSlot, NewGameState);
		}
	}
}

static private function XComGameState_Item FindBestInfiniteItemForSlot(const XComGameState_Unit UnitState, EInventorySlot ForSlot, XComGameState NewGameState)
{
	local X2ItemTemplate					ItemTemplate;
	local XComGameStateHistory				History;
	local int								HighestTier;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				BestItemState;
	local StateObjectReference				ItemRef;
	local XComGameState_HeadquartersXCom	XComHQ;

	HighestTier = -999;
	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if (ItemState != none)
		{
			ItemTemplate = ItemState.GetMyTemplate();

			if (ItemTemplate != none && ItemTemplate.bInfiniteItem && ItemTemplate.Tier > HighestTier && 
				IsTemplateValidForSlot(ForSlot, ItemTemplate, UnitState, NewGameState) && 
				UnitState.CanAddItemToInventory(ItemTemplate, ForSlot, NewGameState, 1, ItemState))
			{	
				HighestTier = ItemTemplate.Tier;
				BestItemState = ItemState;
			}
		}
	}

	if (BestItemState != none)
	{
		XComHQ.GetItemFromInventory(NewGameState, BestItemState.GetReference(), BestItemState);
	}
	return BestItemState;
}

function ECHSlotUnequipBehavior SlotGetUnequipBehavior(CHItemSlot Slot, ECHSlotUnequipBehavior DefaultBehavior, XComGameState_Unit UnitState, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{	
	return eCHSUB_AttemptReEquip;
}

static function int SlotGetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return 55;
}

static function string GetSlotDisplayLetter(CHItemSlot Slot)
{
	return default.strSlotFirstLetter;
}

static function string GetDisplayName(CHItemSlot Slot)
{
	return default.strSlotLocName;
}
