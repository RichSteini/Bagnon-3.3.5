--[[
	transferFrame.lua
		Overview frame of void storage transfers
--]]

local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon-VoidStorage')
local TransferFrame = Bagnon:NewClass('TransferFrame', 'Frame')

function TransferFrame:New(parent)
	local f = self:Bind(CreateFrame('Frame', nil, parent))
	local deposit = f:NewSection(DEPOSIT)
	deposit:SetPoint('TOPLEFT', 10, -20)
	
	local withdraw = f:NewSection(WITHDRAW)
	withdraw:SetPoint('TOPLEFT', deposit, 'BOTTOMLEFT', 0, -20)

	return f
end

function TransferFrame:NewSection(title)
	local frame = Bagnon.VaultItemFrame:New(self, {title})
	local text = frame:CreateFontString(nil, nil, 'GameFontHighlight')
	text:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT')
	text:SetText(title)

	return frame
end

function TransferFrame:UpdateSize() end -- fool item frames