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
    end
    self:setHeight(preHeight + y)
end




local original_ISItemEditorUI_prerender = ISItemEditorUI.prerender
function ISItemEditorUI:prerender()
    original_ISItemEditorUI_prerender(self);
    local splitPt = 100;
    local dy = self.dy or (FONT_HGT_SMALL + 2 * 2)
    local y = 20;

    y = y + 30; -- Titolo
    y = y + 30; -- Tipo di oggetto

    y = y + dy; -- Nome
    y = y + dy; -- Peso
    y = y + dy; -- Condizione

    if self.color:isVisible() then
        y = y + dy; -- Colore
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
        y = y + dy; -- usedDelta
    end
    
    if self.isDrainable then
        self:drawText(getText("IGUI_ItemEditor_UseDelta") .. ":", 5, y, 1,1,1,1, UIFont.Small);
        self.useDelta:setY(y);
        if splitPt < getTextManager():MeasureStringX(UIFont.Small, getText  ("IGUI_ItemEditor_UseDelta")) + 10 then
            splitPt = getTextManager():MeasureStringX(UIFont.Small, getText ("IGUI_ItemEditor_UseDelta")) + 10;
        end
        self.useDelta:setX(splitPt);
    end
end


local original_ISItemEditorUI_onOptionMouseDown = ISItemEditorUI.onOptionMouseDown
function ISItemEditorUI:onOptionMouseDown(button, x, y)
    original_ISItemEditorUI_onOptionMouseDown(self, button, x, y)
    if button.internal == "SAVE" then
        if self.isDrainable then
            if isAdminLogs then
                sendClientCommand(getPlayer(), 'ISLogSystem', 'writeLog', {loggerName = "itemEdits", logText = "[Buffy Logs] ITEM EDITED! "..getOnlineUsername().." changed useDelta "..luautils.round(self.item:getUseDelta(),3).." -> "..self.useDelta:getInternalText()})
            end
            self.item:setUseDelta(tonumber(string.trim(self.useDelta:getInternalText())));
        end
    end
end