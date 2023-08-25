class MedicineInventorySlot extends CHItemSlotSet config(Game);

var localized string strSlotFirstLetter;
var localized string strSlotLocName;

var config EInventorySlot UseSlot;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSlotTemplate());

	return Templates;
}

static function X2DataTemplate CreateSlotTemplate()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'IRI_MedicineSlot');

	Template.InvSlot = default.UseSlot;
	Template.SlotCatMask = Template.SLOT_ITEM;
	Template.IsUserEquipSlot = true;

	Template.IsEquippedSlot = false;
	Template.BypassesUniqueRule = false;

	Template.IsMultiItemSlot = false;
	Template.IsSmallSlot = true;
	Template.NeedsPresEquip = true;
	Template.ShowOnCinematicPawns = true;
	Template.MinimumEquipped = 0;

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
	return UnitState.HasSoldierAbility('IRI_AWC_MedicinePouch');
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
	return ItemTemplate.ItemCat == 'heal' || ItemTemplate.DataName == 'CombatStims';
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
}

function ECHSlotUnequipBehavior SlotGetUnequipBehavior(CHItemSlot Slot, ECHSlotUnequipBehavior DefaultBehavior, XComGameState_Unit UnitState, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{	
	return eCHSUB_AllowEmpty;
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
