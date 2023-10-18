--[[
	frame.lua
		A specialized version of the bagnon frame for void storage
--]]

local Frame = Bagnon:NewClass('VaultFrame', 'Frame', Bagnon.Frame)
Frame.Title = LibStub('AceLocale-3.0'):GetLocale('Bagnon-VoidStorage').Title
Frame.ItemFrame = Bagnon.VaultItemFrame
Frame.MoneyFrame = Bagnon.TransferButton
Frame.Bags = {'vault'}

Frame.OpenSound = 'UI_EtherealWindow_Open'
Frame.CloseSound = 'UI_EtherealWindow_Close'
Frame.BrokerSpacing = 4


--[[ Events ]]--

function Frame:OnShow()
	Bagnon.Frame.OnShow(self)
	self:ShowTransferFrame(false)
end

function Frame:OnHide()
	Bagnon.Frame.OnHide(self)
	
	StaticPopup_Hide('BAGNON_CANNOT_PURCHASE_VAULT')
	StaticPopup_Hide('BAGNON_COMFIRM_TRANSFER')
	StaticPopup_Hide('BAGNON_VAULT_PURCHASE')
	StaticPopup_Hide('VOID_DEPOSIT_CONFIRM')
	CloseVoidStorageFrame()
end


--[[ Components ]]--

function Frame:ShowTransferFrame(show)
	self:FadeOutFrame(show and self.itemFrame or self.transferFrame)
	self:FadeInFrame(show and self:GetTransferFrame() or self.itemFrame)

	if show then
		StaticPopup_Show('BAGNON_COMFIRM_TRANSFER').data = self
	else
		StaticPopup_Hide('BAGNON_COMFIRM_TRANSFER')
	end
end

function Frame:GetTransferFrame()
	return self.transferFrame or self:CreateTransferFrame()
end

function Frame:CreateTransferFrame()
	local frame = Bagnon.TransferFrame:New(self)
	frame:SetAllPoints(self.itemFrame)
	self.transferFrame = frame
	return frame
end

function Frame:GetSpecialButtons() end
function Frame:HasMoneyFrame()
	return true
end

function Frame:HasBagFrame()
	return false
end