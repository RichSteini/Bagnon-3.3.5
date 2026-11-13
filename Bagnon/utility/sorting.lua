--[[
	sorting.lua
		Client side bag sorting algorithm
--]]

--local Search = LibStub('ItemSearch-1.3')
local Sort = Bagnon:NewModule('Sorting', 'AceTimer-3.0')
Bagnon.Sorting = Sort

Sort.Proprieties = {
  --'set',
  'class', 'subclass', --'equip',
  'quality',
  'sellValue',
  'level',
  'icon',
  'name', 'id',
  'count'
}

Sort.init = false
Sort.changes = {}
Sort.bindCache = {}
Sort.ClassOverrides = {
  [6948] = 27,  -- Hearthstone
  [7005] = 26,  -- Skinning Knife
  [2901] = 26,  -- Mining Pick

  [6256] = 26,  -- Fishing Pole
  [6365] = 26,  -- Strong Fishing Pole
  [12221] = 26, -- Blump Family Fishing Pole
  [6367] = 26,  -- Big Iron Fishing Pole
  [6366] = 26,  -- Darkwood Fishing Pole
  [19970] = 26, -- Arcanite Fishing Pole
  [19022] = 26, -- Nat Pagle's Extreme Angler FC-5000
  [11122] = 25, -- Carrot on a stick
  [17731] = 25, -- Multi-Spec Scroll
  [23720] = 25, -- Turtle Mount

}


local tooltipScanner = _G['BagnonSortingTooltipScanner'] or
  CreateFrame('GameTooltip', 'BagnonSortingTooltipScanner', UIParent, 'GameTooltipTemplate')

function Sort:IsBindOnEquip(bag, slot, itemID)
  local cached = self.bindCache[itemID]
  if cached ~= nil then
    return cached
  end

  tooltipScanner:SetOwner(UIParent, 'ANCHOR_NONE')
  tooltipScanner:SetBagItem(bag, slot)

  local isBOE = false
  for i = 2, tooltipScanner:NumLines() do
    local line = _G[tooltipScanner:GetName() .. 'TextLeft' .. i]
    if line and line:GetText() == ITEM_BIND_ON_EQUIP then
      isBOE = true
      break
    end
  end

  tooltipScanner:Hide()
  self.bindCache[itemID] = isBOE
  return isBOE
end

function Sort:Init()
  Sort.init = true
  Sort.Classes = {}
  for i, itemClass in ipairs({GetAuctionItemClasses()}) do
    local subClasses = {}
    for j, subClass in ipairs({GetAuctionItemSubClasses(i)}) do
      subClasses[subClass] = j
    end
    Sort.Classes[itemClass] = {index = i, subClasses = subClasses}
  end
end


--[[ Process ]]--

function Sort:Start(itemFrame)
  self.itemFrame = itemFrame
  self.changes = {}
  if not self:CanRun() then
    return
  end

  if not self.init then
    self:Init()
  end

  --self:SendMessage('SORTING_STATUS', itemFrame)
  self:Run()
end

function Sort:Run()
  if self:CanRun() then
    if self:VerifyChanges() then
      ClearCursor()
      self:Iterate()
    else
      self:ScheduleTimer("Run", 0.05)
    end
  else
    self:Stop()
  end
end

function Sort:Iterate()
  self.changes = {}
  local spaces = self:GetSpaces()
  local families = self:GetFamilies(spaces)
  local updateRequired = false;
  local stackable = function(item)
    return (item.count or 1) < (item.stack or 1)
  end

  for k, target in pairs(spaces) do
    local item = target.item
    if item.id and stackable(item) then
      for j = k+1, #spaces do
        local from = spaces[j]
        local other = from.item

        if item.id == other.id and stackable(other) then
          self:Move(from, target)
          updateRequired = true
        end
      end
    end
  end

  local moveDistance = function(item, goal)
    return math.abs(item.space.index - goal.index)
  end

  for _, family in ipairs(families) do
    local order, spaces = self:GetOrder(spaces, family)
    local n = min(#order, #spaces)

    for index = 1, n do
      local goal = spaces[index]
      local item = order[index]
      item.sorted = true

      if item.space ~= goal then
        local distance = moveDistance(item, goal)

        for j = index, n do
          local other = order[j]
          if other.id == item.id and other.count == item.count then
            local d = moveDistance(other, spaces[j])
            if d > distance then
              item = other
              distance = d
            end
          end
        end

        self:Move(item.space, goal)
        updateRequired = true
      end
    end
  end

  if updateRequired then
    self:ScheduleTimer("Run", 0.2)
  else
    self:Stop()
  end

end

function Sort:Stop()
  self.itemFrame:SendMessage('SORTING_STATUS')
end


--[[ Data Structures ]]--

function Sort:GetSpaces()
  local spaces = {}
  local itemFrame = self.itemFrame
  if itemFrame and itemFrame.GetFrameID and itemFrame:GetFrameID() == 'guildbank' and GetCurrentGuildBankTab then
    local guildTab = GetCurrentGuildBankTab()
    if guildTab and guildTab > 0 then
      local slotsPerTab = NUM_SLOTS_PER_GUILDBANK_TAB or 98
      for slot = 1, slotsPerTab do
        local texture, count, locked, quality = GetGuildBankItemInfo(guildTab, slot)
        local link = GetGuildBankItemLink(guildTab, slot)
        local item = {}
        tinsert(spaces, {index = #spaces, bag = guildTab, slot = slot, family = 0, item = item, guildBank = true})
        item.space = spaces[#spaces]
        if link then
          local itemName, _, _, itemLevel, _, itemType, itemSubType, itemStackCount = GetItemInfo(link)
          item.id = tonumber(link:match("item:(%d+)")) or 0
          item.class = Sort.ClassOverrides[item.id] or (Sort.Classes[itemType] and Sort.Classes[itemType].index or 0)
          item.subclass = Sort.Classes[itemType] and Sort.Classes[itemType].subClasses[itemSubType] or 0
          item.stack = itemStackCount
          item.count = count
          item.locked = locked
          item.quality = quality
          item.icon = texture
          item.level = itemLevel
          item.name = itemName
        end
      end
    end
  else
    for _, bag in itemFrame:GetVisibleBags() do
      local family = Bagnon.BagSlotInfo:GetBagType(itemFrame:GetPlayer(), bag)
      for slot = 1, itemFrame:GetBagSize(bag) do
        local itemSlot = itemFrame:GetItemSlot(bag, slot)
        local texture, count, locked, quality, readable, lootable, link = itemSlot:GetItemSlotInfo()
        local item = {}
        tinsert(spaces, {index = #spaces, bag = bag, slot = slot, family = family, item = item, guildBank = false})
        item.space = spaces[#spaces]
        if link then
          local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, equipSlot, itemTexture, vendorPrice = GetItemInfo(link)
          item.id = tonumber(link:match("item:(%d+)")) or 0
          item.class = Sort.ClassOverrides[item.id] or (Sort.Classes[itemType] and Sort.Classes[itemType].index or 0)
          item.subclass = Sort.Classes[itemType] and Sort.Classes[itemType].subClasses[itemSubType] or 0
          if itemType == "Miscellaneous" and itemSubType == "Mount" then
            item.class = 25
          end
          item.sellValue = 0
          if quality == 0 then
            item.class = 0
            item.subclass = 0
            item.sellValue = (vendorPrice or 0) * (count or 1)
            if type(GetSellValue) == "function" then
              item.sellValue = (GetSellValue(item.id) or 0) * (count or 1)
            end
          elseif itemType == "Consumable" then
            if itemSubType == "Potion" or itemSubType == "Elixir" then
              item.class = 23
            elseif itemSubType == "Flask" then
              item.class = 24
            else
              item.class = 20
            end
          elseif itemType == "Trade Goods" and itemSubType == "Devices" then
            item.class = 21
          elseif itemType == "Miscellaneous" and itemSubType == "Reagent" then
            item.class = 24
          elseif itemType == "Miscellaneous" and itemSubType == "Junk" and item.class < 11 then
            item.class = 24
          elseif quality > 1 and item.class < 20 then
            item.class = 11 + quality
            if self:IsBindOnEquip(bag, slot, item.id) then
              item.class = 2
              item.subclass = 0
            end
          elseif quality == 2 and item.class < 11 then
            item.class = 10
          end
          item.stack = itemStackCount
          item.count = count
          item.locked = locked
          item.quality = quality
          item.icon = texture
          item.level = itemLevel
          item.name = itemName
        end
      end
    end
  end
  --[[
  for _, bag in pairs(self.bags) do
    local link, count, texture = bag:GetBagInfo()
    for slot = 1, (container.count or 0) do
      local item = Bagnon.Bag:GetItemInfo(self.owner, bag, slot)
      tinsert(spaces, {index = #spaces, bag = bag, slot = slot, family = container.family, item = item})

      item.class = item.id and Search:IsQuestItem(item.id) and Enum.ItemClass.Questitem or item.class
      item.space = spaces[#spaces]

      --item.set = item.id and Search:BelongsToSet(item.id) and 0 or 1
    end
  end
  ]]

  return spaces
end

function Sort:GetFamilies(spaces)
  local set = {}
  for _, space in ipairs(spaces) do
    set[space.family] = true
  end

  local list = {}
  for family in pairs(set) do
    tinsert(list, family)
  end

  sort(list, function(a, b) return a > b end)
  return list
end

function Sort:GetOrder(spaces, family)
  local order, slots = {}, {}

  for _, space in ipairs(spaces) do
    local item = space.item
    if item.id and not item.sorted and self:FitsIn(item.id, family) then
      tinsert(order, space.item)
    end

    if space.family == family then
      tinsert(slots, space)
    end
  end

  sort(order, self.Rule)
  return order, slots
end

function Sort:CanRun()
  return not InCombatLockdown() and not UnitIsDead('player')
end

function Sort:FitsIn(id, family)
  if family == 9 then
    return GetItemFamily(id) == 256
  end

  return family == 0 or (bit.band(GetItemFamily(id), family) > 0 and select(9, GetItemInfo(id)) ~= 'INVTYPE_BAG')
end

function Sort.Rule(a, b)
  for _,prop in pairs(Sort.Proprieties) do
    if a[prop] ~= b[prop] then
      return a[prop] > b[prop]
    end
  end

  if a.space.family ~= b.space.family then
    return a.space.family > b.space.family
  end
  return a.space.index < b.space.index
end

function Sort:Move(from, to)
  if from.locked or to.locked or (to.item.id and not self:FitsIn(to.item.id, from.family)) then
    return
  end

  ClearCursor()
  if from.guildBank then
    from.id, from.count = self:GetGuildBankItemID(from.bag, from.slot)
    to.id, to.count = self:GetGuildBankItemID(to.bag, to.slot)
    if from.id == to.id and from.count == to.count then
      return
    end
    tinsert(self.changes, {
      id = from.id or 0,
      count = from.count or 0,
      toBag = to.bag,
      toSlot = to.slot,
      guildBank = true,
    })
    PickupGuildBankItem(from.bag, from.slot)
    PickupGuildBankItem(to.bag, to.slot)
  else
    PickupContainerItem(from.bag, from.slot)
    PickupContainerItem(to.bag, to.slot)
  end
  ClearCursor()

  from.locked = true
  to.locked = true
  return true
end

function Sort:VerifyChanges()
  for _, entry in ipairs(self.changes) do
    local id, count
    if entry.guildBank then
      id, count = self:GetGuildBankItemID(entry.toBag, entry.toSlot)
    else
      local _, itemCount, _, _, _, _, link = GetContainerItemInfo(entry.toBag, entry.toSlot)
      id = link and tonumber(link:match("item:(%d+)")) or 0
      count = itemCount or 0
    end

    if id ~= entry.id or count ~= entry.count then
      return false
    end
  end
  return true
end

function Sort:GetGuildBankItemID(guildTab, slot)
  local _, count = GetGuildBankItemInfo(guildTab, slot)
  local link = GetGuildBankItemLink(guildTab, slot)
  if not link then
    return 0, count
  end
  return tonumber(link:match("item:(%d+)")) or 0, count
end
