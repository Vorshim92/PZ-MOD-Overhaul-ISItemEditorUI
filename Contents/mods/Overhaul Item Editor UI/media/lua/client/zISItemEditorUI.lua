local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

-- if mod buffy's admin logs exists.
local isAdminLogs = getActivatedMods():contains("AdminLogs")

local original_ISItemEditorUI_create = ISItemEditorUI.create
function ISItemEditorUI:create()
    original_ISItemEditorUI_create(self);
    local preHeight = self:getHeight()
    local entryHgt = FONT_HGT_SMALL + 2 * 2
    local btnHgt = FONT_HGT_SMALL + 2 * 4
    local numberWidth = 50;
    -- local y = (self:getHeight()-150)+self.dy
    local dy = self.dy or entryHgt
    local maxY = 0

    for _, child in ipairs(self.children) do
        if child ~= self.save and child ~= self.cancel then
            local childMaxY = child:getY() + child:getHeight()
            if childMaxY > maxY then
                maxY = childMaxY
            end
        end
    end
    local y = maxY + dy
    if self.isDrainable then
        self.useDelta = ISTextEntryBox:new(luautils.round(self.item:getUseDelta(),3) .. "", 10, y, numberWidth, entryHgt);
        self.useDelta.tooltip = getText("IGUI_ItemEditor_UseDeltaTooltip");
        self.useDelta:initialise();
        self.useDelta:instantiate();
        self.useDelta.min = 0;
        self.useDelta.max = 1;
        self.useDelta:setOnlyNumbers(true);
        self:addChild(self.useDelta);

        -- y = y + entryHgt;

        self.remainingUses = ISTextEntryBox:new(self.item:getRemainingUses() .. "", 10, y, numberWidth, entryHgt);
        self.remainingUses.tooltip = getText("IGUI_ItemEditor_remainingUsesTooltip");
        self.remainingUses:initialise();
        self.remainingUses:instantiate();
        self.useDelta.min = 0;
        self.useDelta.max = luautils.round(1/self.item:getUseDelta());
        self.remainingUses:setOnlyNumbers(true)
        self:addChild(self.remainingUses);

        self.totalUses = ISTextEntryBox:new(luautils.round(1/self.item:getUseDelta()) .. "", 10, y, numberWidth, entryHgt);
        self.totalUses.tooltip = getText("IGUI_ItemEditor_TotalUsesTooltip");
        self.totalUses:initialise();
        self.totalUses:instantiate();
        self.totalUses:setOnlyNumbers(true)
        self:addChild(self.totalUses);
    end
    self:setHeight(preHeight + y)
end




local original_ISItemEditorUI_prerender = ISItemEditorUI.prerender
function ISItemEditorUI:prerender()
    original_ISItemEditorUI_prerender(self);
    local splitPt = 100;
    local dy = self.dy or (FONT_HGT_SMALL + 2 * 2)
    local y = 20;

    y = y + 30; -- Title
    y = y + 30; -- Object type

    y = y + dy; -- Name
    y = y + dy; -- Weight
    y = y + dy; -- Condition

    if self.color:isVisible() then
        y = y + dy; -- Color
    end

    if self.isWeapon then
        local weaponAttributes = {'minDmg', 'maxDmg', 'minAngle', 'minRange', 'maxRange', 'aimingTime', 'recoilDelay', 'reloadTime', 'clipSize'}
        for _, attr in ipairs(weaponAttributes) do
            y = y + dy
        end
    end

    if self.isFood then
        local foodAttributes = {'age', 'hunger', 'unhappy', 'boredom', 'poisonPower', 'offAge', 'offAgeMax', 'calories', 'proteins', 'lipids', 'carbs'}
        for _, attr in ipairs(foodAttributes) do
            y = y + dy
        end
    end
    if self.isDrainable then
        local x = self.usedDelta:getX()+55
        self:drawText("--> " .. getText("IGUI_ItemEditor_RemainingUses") .. ":", x, y, 1,1,1,1, UIFont.Small);
        local newx = x + getTextManager():MeasureStringX(UIFont.Small, "--> " .. getText("IGUI_ItemEditor_RemainingUses") .. ":") + 10
        self.remainingUses:setY(y);
        self.remainingUses:setX(newx);

        y = y + dy; -- usedDelta

        self:drawText(getText("IGUI_ItemEditor_UseDelta") .. ":", 5, y, 1,1,1,1, UIFont.Small);
        self.useDelta:setY(y);
        if splitPt < getTextManager():MeasureStringX(UIFont.Small, getText  ("IGUI_ItemEditor_UseDelta")) + 10 then
            splitPt = getTextManager():MeasureStringX(UIFont.Small, getText ("IGUI_ItemEditor_UseDelta")) + 10;
        end
        self.useDelta:setX(splitPt);

        x = self.useDelta:getX()+55
        self:drawText("--> " .. getText("IGUI_ItemEditor_TotalUses") .. ":", x, y, 1,1,1,1, UIFont.Small);
        newx = x + getTextManager():MeasureStringX(UIFont.Small, "--> " .. getText("IGUI_ItemEditor_TotalUses") .. ":") + 10
        self.totalUses:setY(y);
        self.totalUses:setX(newx);

        -- y = y + dy;

        
    end
end


local original_ISItemEditorUI_onOptionMouseDown = ISItemEditorUI.onOptionMouseDown
function ISItemEditorUI:onOptionMouseDown(button, x, y)
    original_ISItemEditorUI_onOptionMouseDown(self, button, x, y)
    if button.internal == "SAVE" then
        if self.isDrainable then
            local totalUsesInput = tonumber(string.trim(self.totalUses:getInternalText()))
            local useDeltaInput = tonumber(string.trim(self.useDelta:getInternalText()))
            local remainingUsesInput = tonumber(string.trim(self.remainingUses:getInternalText()))
            local currentUseDelta = self.item:getUseDelta()

            -- if you changed totalUses or useDelta inputs fields, TotalUses has the priority over UseDelta, just to avoid overwrite problems.
            if totalUsesInput and luautils.round(1 / currentUseDelta) ~= totalUsesInput then
                currentUseDelta = 1 / totalUsesInput
                if isAdminLogs then
                    sendClientCommand(getPlayer(), 'ISLogSystem', 'writeLog', {loggerName = "itemEdits", logText = "[Buffy Logs] ITEM EDITED! "..getOnlineUsername().." changed totalUses " .. luautils.round(1 / currentUseDelta) .. " -> " .. totalUsesInput})
                    self.item:setUseDelta(currentUseDelta)
                    useDeltaInput = currentUseDelta
                end
            elseif useDeltaInput and luautils.round(currentUseDelta, 3) ~= useDeltaInput then
                if isAdminLogs then
                    sendClientCommand(getPlayer(), 'ISLogSystem', 'writeLog', {loggerName = "itemEdits", logText = "[Buffy Logs] ITEM EDITED! "..getOnlineUsername().." changed useDelta " .. luautils.round(currentUseDelta, 3) .. " -> " .. useDeltaInput})
                end
                currentUseDelta = useDeltaInput
                self.item:setUseDelta(currentUseDelta)
            end

            
            -- Handle 'RemainingUses'
            if remainingUsesInput and self.item:getRemainingUses() ~= remainingUsesInput then
                if isAdminLogs then
                    sendClientCommand(getPlayer(), 'ISLogSystem', 'writeLog', {loggerName = "itemEdits", logText = "[Buffy Logs] ITEM EDITED! "..getOnlineUsername().." changed remainingUses "..self.item:getRemainingUses().." -> "..remainingUsesInput})
                end
                self.item:setUsedDelta(currentUseDelta * remainingUsesInput)
            end
        end
    end
end