--[[
	transferButton.lua
		A void storage transfer button
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-VoidStorage')
local TransferButton = Bagnon:NewClass('TransferButton', 'Button', Bagnon.MoneyFrame)
TransferButton.ICON_SIZE = 30
TransferButton.ICON_OFF = 8


--[[ Constructor ]]--

function TransferButton:New (...)
	local f = Bagnon.MoneyFrame.New(self, ...)
	local b = CreateFrame('Button', nil, f)
	b:SetPoint('RIGHT', self.ICON_SIZE - 3, 0)
	b:SetSize(self.ICON_SIZE, self.ICON_SIZE)
	b:SetScript('OnClick', function() f:OnClick() end)
	b:SetScript('OnEnter', function() f:OnEnter() end)
	b:SetScript('OnLeave', function() f:OnLeave() end)

	local pt = b:CreateTexture()
	pt:SetTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	pt:SetAllPoints()
	b:SetPushedTexture(pt)

	local ht = b:CreateTexture()
	ht:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	ht:SetAllPoints()
	b:SetHighlightTexture(ht)
	
	local icon = b:CreateTexture()
	icon:SetTexture('Interface/Icons/ACHIEVEMENT_GUILDPERK_BARTERING')
	icon:SetAllPoints()
	
	f.icon = icon
	f.info = MoneyTypeInfo["STATIC"]
	f:SetHeight(self.ICON_SIZE + self.ICON_OFF * 2)
	f:SetScript('OnHide', self.UnregisterEvents)
	f:SetScript('OnShow', self.RegisterEvents)
	f:Update()

	return f
end


--[[ Interaction ]]--

function TransferButton:OnClick ()
	if self:HasTransfer() then
		self:GetParent():ShowTransferFrame(true)
	end
end

function TransferButton:OnEnter ()
	local withdraws = GetNumVoidTransferWithdrawal()
	local deposits = GetNumVoidTransferDeposit()
	
	if (withdraws + deposits) > 0 then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText(TRANSFER)
		
		if withdraws > 0 then
			GameTooltip:AddLine(format(L.NumWithdraw, withdraws), 1,1,1)
		end
		
		if deposits > 0 then
			GameTooltip:AddLine(format(L.NumDeposit, deposits), 1,1,1)
		end
		
		GameTooltip:Show()
	end
end


--[[ Update ]]--

function TransferButton:RegisterEvents()
	self:RegisterEvent('VOID_STORAGE_DEPOSIT_UPDATE', 'Update')
	self:RegisterEvent('VOID_STORAGE_CONTENTS_UPDATE', 'Update')
	self:RegisterEvent('VOID_TRANSFER_DONE', 'Update')
end

function TransferButton:Update()
	MoneyFrame_Update(self:GetName(), GetVoidTransferCost())
	
	if self.icon then
		self.icon:SetDesaturated(not self:HasTransfer())
	end
end

function TransferButton:HasTransfer()
	return (GetNumVoidTransferWithdrawal() + GetNumVoidTransferDeposit()) > 0
end