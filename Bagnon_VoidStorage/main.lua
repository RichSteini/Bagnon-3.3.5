--[[
	main.lua
		The bagnon driver thingy
--]]

local Vault = Bagnon:NewModule('VoidStorage', 'AceEvent-3.0')

function Vault:OnEnable()
	self:RegisterEvent('VOID_STORAGE_CLOSE', 'OnClosed')
end

function Vault:OnOpen()
	IsVoidStorageReady()
	Bagnon.Cache.AtVault = true
	Bagnon:ShowFrame('vault')
	
	if not CanUseVoidStorage() then
		if Bagnon.VAULT_COST > GetMoney() then
			StaticPopup_Show('BAGNON_CANNOT_PURCHASE_VAULT')
		else
			StaticPopup_Show('BAGNON_VAULT_PURCHASE')
		end
	end
end

function Vault:OnClosed()
	Bagnon.Cache.AtVault = nil
	Bagnon:HideFrame('vault')
end
