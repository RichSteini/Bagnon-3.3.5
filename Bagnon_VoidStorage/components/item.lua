--[[
	item.lua
		A void storage item slot button
--]]

local ItemSlot = Bagnon:NewClass('VaultSlot', 'Button', Bagnon.ItemSlot)
ItemSlot.nextID = 0
ItemSlot.unused = {}


--[[ Constructor ]]--

function ItemSlot:Create()
	local item = Bagnon.ItemSlot.Create(self)
	item:SetScript('OnReceiveDrag', self.OnDragStart)
	item:SetScript('OnDragStart', self.OnDragStart)
	item:SetScript('OnClick', self.OnClick)

	return item
end

function ItemSlot:Construct(id)
	return CreateFrame('Button', 'BagnonVaultItemSlot' .. id, nil, 'ContainerFrameItemButtonTemplate')
end

function ItemSlot:GetBlizzard()
end


--[[ Interaction ]]--

function ItemSlot:OnClick(button)
	if IsModifiedClick() then
		local _,_,_,_,_,_, link = self:GetInfo()
		if link then
			HandleModifiedItemClick(link)
		end
	elseif self.bag == 'vault' and not self:IsCached() then
		local isRight = button == 'RightButton'
		local type, _, link = GetCursorInfo()
		local cursor = self.Cursor
		
		if not isRight and cursor and type == 'item' and link == cursor:GetItem() then
			cursor:GetScript('PreClick')(cursor, 'RightButton') -- simulates a click on the button, less code to maintain
			cursor:GetScript('OnClick')(cursor, 'RightButton')
		
		elseif isRight and self:IsLocked() and self.withdrawSlot then
			ClickVoidTransferWithdrawalSlot(1, self.withdrawSlot, true)

		else
			for i = 1,9 do
				if not GetVoidTransferWithdrawalInfo(i) then
					self.withdrawSlot = i
					break
				end
			end
			
			ClickVoidStorageSlot(1, self:GetID(), isRight)
		end
	end
end

function ItemSlot:OnDragStart()
	self:OnClick('LeftButton')
end


--[[ Tooltip ]]--

function ItemSlot:ShowTooltip()
	if self.bag == 'vault' then
		GameTooltip:SetVoidItem(1, self:GetID())
	elseif self.bag == DEPOSIT then
		GameTooltip:SetVoidDepositItem(self:GetID())
	else
		GameTooltip:SetVoidWithdrawalItem(self:GetID())
	end

	if IsModifiedClick('DRESSUP') then
		ShowInspectCursor()
	end
end


--[[ Proprieties ]]--

function ItemSlot:IsCached()
	-- delicious hack: behave as cached (disable interaction) while vault has not been purchased
	return not CanUseVoidStorage() or Bagnon.ItemSlot.IsCached(self)
end

function ItemSlot:GetInfo()
	local id, icon, locked = self:GetRawInfo()
	local link, quality
	if id then
		link, quality = select(2, GetItemInfo(id))
	end
	
	return icon, 1, locked and self.bag == 'vault', quality, nil, nil, link
end

function ItemSlot:GetRawInfo()
	if self.bag == 'vault' then
		return Bagnon.ItemSlot.GetInfo(self)
	else
		local get = self.bag == DEPOSIT and GetVoidTransferDepositInfo or GetVoidTransferWithdrawalInfo
		local count = self:GetID()
		
		for i = 1,9 do
			if get(i) then
				count = count - 1
				if count == 0 then
					return get(i)
				end
			end
		end
	end
end

function ItemSlot:IsQuestItem()
	return false
end

function ItemSlot:IsNew()
	return false
end


--[[ Fake Methods ]]--

function ItemSlot:UpdateSlotColor() end
function ItemSlot:UpdateCooldown() end