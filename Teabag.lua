TEABAG_COLUMNS = 6
BINDING_HEADER_TEABAG = "Teabag"
BINDING_NAME_TEABAG_TOGGLE = "Toggle Teabag"

function Teabag_OnLoad()	
	print("Teabag loaded.")
	
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("BAG_CLOSED");
	this:RegisterEvent("BAG_OPEN");
	this:RegisterEvent("BAG_UPDATE_COOLDOWN");
	this:RegisterEvent("ITEM_LOCK_CHANGED");
	this:RegisterEvent("UPDATE_INVENTORY_ALERTS");
	
end

-- oldOpenAllBags = OpenAllBags
-- function OpenAllBags(forceOpen)
	-- if TeabagFrame:IsShown() then
		-- TeabagFrame:Hide()
	-- else
		-- TeabagFrame:Show()
	-- end
	-- oldOpenAllBags(forceOpen)
-- end

function TeabagToggle()
	if TeabagFrame:IsShown() then
		TeabagFrame:Hide()
	else
		TeabagFrame:Show()
	end
end

-- oldToggleBag = ToggleBag
-- function ToggleBag(id)
	-- TeabagFrame:Show()
	-- oldToggleBag(id)
-- end

-- oldToggleBackpack = ToggleBackpack
-- function ToggleBackpack()
	-- TeabagFrame:Show()
	-- oldToggleBackpack()
-- end

function Teabag_OnEvent()
	if ( event == "BAG_UPDATE" ) then
		if ( TeabagFrame:IsShown() ) then
 			Teabag_Update();
		end
	elseif ( event == "BAG_CLOSED" ) then
		TeabagFrame:Hide()
	elseif ( event == "BAG_OPEN" ) then
		TeabagFrame:Show()
	elseif ( event == "ITEM_LOCK_CHANGED" or event == "BAG_UPDATE_COOLDOWN" or event == "UPDATE_INVENTORY_ALERTS" ) then
		if ( TeabagFrame:IsShown() ) then			
			Teabag_Update();
		end
	end
end

function Teabag_Update()
	local totalHeight = ShowBag()
	TeabagFrame:SetID(1)
	TeabagFrame:SetWidth(41*TEABAG_COLUMNS+23)
	TeabagFrame:SetHeight(totalHeight)
end

function Teabag_OnShow()
	Teabag_Update()
end


function Teabag_OnHide()
	
end

function GetItemString(itemLink)	
	local _, _, itemString = string.find(itemLink, "^|%x+|H(.+)|h%[.+%]")
	return itemString
end

function GroupItems()
	local groupedItems = {}
	for bagId = 0, NUM_BAG_SLOTS do
		local size=GetContainerNumSlots(bagId)
		for index = 1, size do
			local itemLink = GetContainerItemLink(bagId, index)
			if itemLink ~= nil then
				local itemString = GetItemString(itemLink)
				local name, _, quality, minLevel, iType, iSubType, stackCount, equipLoc = GetItemInfo(itemString)
				if name ~= nil then
					local tbl = groupedItems[iSubType]
					if tbl == nil then
						tbl = {}
						groupedItems[iSubType] = tbl
					end					
					table.insert(tbl, {bagId, index})
				end
			end
		end
	end
	return groupedItems
end

--[[
	for subtype,items in pairs(groupedItems) do
		print(subtype)
		for _,item in pairs(items) do
			print(item[1]..":"..item[2])
		end
	end
]]

function ShowBag()
	local name="TeabagFrame"
	local btnId=1
	local groupedItems = GroupItems()
	local totalHeight = 43
	
	local groupIndex=1
	for subtype,items in pairs(groupedItems) do
		local groupName = name.."Group"..groupIndex
		local teaBagGroup = getglobal(groupName)
		
		if(teaBagGroup == nil) then
			teaBagGroup = CreateFrame("Frame", groupName, TeabagFrame, "TeabagFrameGroup")
		end
		
		local teaBagGroupText = getglobal(groupName.."Name")
		local groupRows = ceil(getn(items) / TEABAG_COLUMNS)
		local height = 42*groupRows+30
		teaBagGroup:SetHeight(height)
		teaBagGroupText:SetText(subtype)
		
		if groupIndex == 1 then
			teaBagGroup:SetPoint("TOPLEFT", name, "TOPLEFT", 4, -20)
		else
			teaBagGroup:SetPoint("TOPLEFT", name.."Group"..(groupIndex-1), "BOTTOMLEFT", 0, 0)
		end
		totalHeight = totalHeight + height
		
		local btnIndex = 1
		for _,item in pairs(items) do
			local bagId = item[1]
			local index = item[2]			
			local itemButton = getglobal(name.."Item"..btnId)
			
			if(itemButton == nil) then
				itemButton = CreateFrame("Button", name.."Item"..btnId, teaBagGroup, "TeabagFrameItemButtonTemplate")
			end
			
			itemButton:SetParent(teaBagGroup)
			itemButton:SetID(index)
			itemButton.bagId = bagId
			
			-- Set first button
			if ( btnIndex == 1 ) then
				itemButton:SetPoint("TOPLEFT", groupName, "TOPLEFT", 10, -34)	
			else
				if ( mod((btnIndex-1), TEABAG_COLUMNS) == 0 ) then
					itemButton:SetPoint("TOPLEFT", name.."Item"..(btnId - TEABAG_COLUMNS), "BOTTOMLEFT", 0, -4)
				else
					itemButton:SetPoint("TOPLEFT", name.."Item"..(btnId - 1), "TOPRIGHT", 4, 0)
				end
			end

			local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bagId, index);
			SetItemButtonTexture(itemButton, texture);
			SetItemButtonCount(itemButton, itemCount);
			SetItemButtonDesaturated(itemButton, locked, 0.5, 0.5, 0.5);

			if ( texture ) then
				ContainerFrame_UpdateCooldown(bagId, itemButton);
				itemButton.hasItem = 1;
			else
				getglobal(name.."Item"..btnId.."Cooldown"):Hide();
				itemButton.hasItem = nil;
			end
			
			itemButton.readable = readable;
			itemButton:Show();
			btnId = btnId +1 
			btnIndex = btnIndex + 1
		end
		groupIndex = groupIndex + 1
	end
	return totalHeight
end


function TeabagFrameItemButton_OnLoad()
	this:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	this:RegisterForDrag("LeftButton");

	this.SplitStack = function(button, split)
		SplitContainerItem(button.bagId, button:GetID(), split);
	end
end

function TeabagFrameItemButton_OnClick(button, ignoreModifiers)
	if ( button == "LeftButton" ) then
		if ( IsControlKeyDown() and not ignoreModifiers ) then
			DressUpItemLink(GetContainerItemLink(this.bagId, this:GetID()));
		elseif ( IsShiftKeyDown() and not ignoreModifiers ) then
			if ( ChatFrameEditBox:IsShown() ) then
				ChatFrameEditBox:Insert(GetContainerItemLink(this.bagId, this:GetID()));
			else
				local texture, itemCount, locked = GetContainerItemInfo(this.bagId, this:GetID());
				if ( not locked ) then
					this.SplitStack = function(button, split)
						SplitContainerItem(this.bagId, button:GetID(), split);
					end
					OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
				end
			end
		else
			PickupContainerItem(this.bagId, this:GetID());
			StackSplitFrame:Hide();
		end
	else
		if ( IsControlKeyDown() and not ignoreModifiers ) then
			return;
		elseif ( IsShiftKeyDown() and MerchantFrame:IsShown() and not ignoreModifiers ) then
			this.SplitStack = function(button, split)
				SplitContainerItem(button.bagId, button:GetID(), split);
				MerchantItemButton_OnClick("LeftButton");
			end
			OpenStackSplitFrame(this.count, this, "BOTTOMRIGHT", "TOPRIGHT");
		elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 2 ) then
			-- Don't sell the item if the buyback tab is selected
			return;
		else
			UseContainerItem(this.bagId, this:GetID());
			StackSplitFrame:Hide();
		end
	end
end

function TeabagFrameItemButton_OnEnter(button)
	if ( not button ) then
		button = this;
	end

	local x;
	x = button:GetRight();
	if ( x >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	else
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
	end

	-- Keyring specific code
	if ( this.bagId == KEYRING_CONTAINER ) then
		GameTooltip:SetInventoryItem("player", KeyRingButtonIDToInvSlotID(this:GetID()));
		CursorUpdate();
		return;
	end

	local hasCooldown, repairCost = GameTooltip:SetBagItem(button.bagId,button:GetID());
	
	--[[
	Commented out to make dressup cursor work.
	if ( hasCooldown ) then
		button.updateTooltip = TOOLTIP_UPDATE_TIME;
	else
		button.updateTooltip = nil;
	end
	]]
	if ( InRepairMode() and (repairCost and repairCost > 0) ) then
		GameTooltip:AddLine(TEXT(REPAIR_COST), "", 1, 1, 1);
		SetTooltipMoney(GameTooltip, repairCost);
		GameTooltip:Show();
	elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
		ShowContainerSellCursor(button.bagId,button:GetID());
	elseif ( this.readable or (IsControlKeyDown() and button.hasItem) ) then
		ShowInspectCursor();
	else
		ResetCursor();
	end
end

function TeabagFrameItemButton_OnUpdate(elapsed)
	--[[
	Might hurt performance, but need to always update the cursor now
	if ( not this.updateTooltip ) then
		return;
	end
	this.updateTooltip = this.updateTooltip - elapsed;
	if ( this.updateTooltip > 0 ) then
		return;
	end
	]]
	if ( GameTooltip:IsOwned(this) ) then
		TeabagFrameItemButton_OnEnter();
	end
end