-- QuickMenu: BookOrbit companion.
--
-- Adds BookOrbit's menu-bar item to QuickMenu's Actions section as a
-- toggleable, QuickMenu-styled button:
--   tap  -> show/hide BookOrbit's icon in KOReader's menu bar
--   hold -> open BookOrbit (same as tapping the menu-bar icon)
-- The button highlights while the menu-bar icon is visible.
-- Remove/re-add it any time in QuickMenu's settings (Actions section),
-- or from Tools -> QuickMenu: BookOrbit.
--
-- Why this exists instead of a manual custom action: it reuses BookOrbit's
-- own icon, state and open behavior, and stays in sync automatically.
-- NOTE: quickmenu.koplugin's main.lua on this device carries a small local
-- patch (config name-collision fix); re-apply it after a QuickMenu update.
-- This companion needs no patch: it only wraps ActionDefs.get.

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local Companion = WidgetContainer:extend{
    name = "quickmenu_bookorbit",
}

local ACTION_ID = "bookorbit"

local function liveUI()
    local rd = package.loaded["apps/reader/readerui"]
    if rd and rd.instance then return rd.instance end
    local fm = package.loaded["apps/filemanager/filemanager"]
    return fm and fm.instance or nil
end

local function bookorbitInstance()
    local ui = liveUI()
    local mod = ui and ui[ACTION_ID]
    if type(mod) == "table" then return mod end
    return nil
end

local function hasBookOrbit()
    return bookorbitInstance() ~= nil
end

-- Tap target: in a book, BookOrbit's "This book" overlay (position, Sync
-- now, Jump/Stay); in the browser, the dashboard. Hold target: sync
-- (this book in the reader, everything in the browser).
local function bookorbitTap(in_reader)
    local ok, Dispatcher = pcall(require, "dispatcher")
    if not ok or not Dispatcher then return false end
    local action = in_reader and { bookorbit_this_book = true }
        or { bookorbit_open_dashboard = true }
    local ran, err = pcall(Dispatcher.execute, Dispatcher, action)
    if not ran then
        logger.warn("[quickmenu_bookorbit] open failed:", err)
    end
    return ran
end

local function bookorbitHold(in_reader)
    local ok, Dispatcher = pcall(require, "dispatcher")
    if not ok or not Dispatcher then return false end
    local action = in_reader and { bookorbit_sync_book = true }
        or { bookorbit_sync_now = true }
    local ran, err = pcall(Dispatcher.execute, Dispatcher, action)
    if not ran then
        logger.warn("[quickmenu_bookorbit] sync failed:", err)
    end
    return ran
end

local function bookorbitIcon()
    local inst = bookorbitInstance()
    if inst and type(inst.menuBarIconName) == "function" then
        local ok, name = pcall(inst.menuBarIconName, inst)
        if ok and type(name) == "string" and name ~= "" then
            return "[icon=" .. name .. "]"
        end
    end
    return "appbar.menu"
end

local function makeDef()
    local Utils = require("common/utils")
    local UIManager = require("ui/uimanager")
    return {
        icon = bookorbitIcon(),
        label = _("BookOrbit"),
        category = "shortcut",
        help_text = _("Tap: BookOrbit (this book in reader, library in browser)\nHold: sync"),
        callback = function(ctx)
            local in_reader = ctx and ctx.reader ~= nil
            Utils.closeMenu(ctx.touch_menu)
            UIManager:nextTick(function()
                bookorbitTap(in_reader)
            end)
        end,
        hold_callback = function(ctx)
            local in_reader = ctx and ctx.reader ~= nil
            Utils.closeMenu(ctx.touch_menu)
            UIManager:nextTick(function()
                bookorbitHold(in_reader)
            end)
        end,
    }
end

local function injectDef()
    local ok, AD = pcall(require, "action_defs")
    if not ok or type(AD) ~= "table" or type(AD.get) ~= "function" then
        return false
    end
    if AD._qm_bookorbit_wrapped then return true end
    AD._qm_bookorbit_wrapped = true
    local orig_get = AD.get
    AD.get = function(...)
        local defs = orig_get(...)
        if type(defs) == "table" and hasBookOrbit() then
            defs[ACTION_ID] = makeDef()
            -- First sight of a live BookOrbit: claim the section slot once.
            -- Afterwards the user owns it (remove/re-add in settings).
            if not AD._qm_bookorbit_seeded then
                AD._qm_bookorbit_seeded = true
                pcall(ensureSectionItem, true)
            end
        end
        return defs
    end
    return true
end

local function settingsStore()
    local DataStorage = require("datastorage")
    local LuaSettings = require("luasettings")
    return LuaSettings:open(DataStorage:getSettingsDir() .. "/quick_menu_settings.lua")
end

local function ensureSectionItem(present)
    local store = settingsStore()
    local cfg = store:readSetting("quick_menu_settings") or {}
    cfg.sections = cfg.sections or {}
    cfg.sections.actions = cfg.sections.actions or {}
    local items = cfg.sections.actions.items or {}
    local at = nil
    for i, id in ipairs(items) do
        if id == ACTION_ID then at = i break end
    end
    if present and not at then
        table.insert(items, ACTION_ID)
    elseif not present and at then
        table.remove(items, at)
    else
        return at ~= nil
    end
    cfg.sections.actions.items = items
    store:saveSetting("quick_menu_settings", cfg)
    store:flush()
    return present
end

function Companion:init()
    if not injectDef() then
        logger.warn("[quickmenu_bookorbit] QuickMenu action registry not found; staying dormant")
        return
    end
    self.ui.menu:registerToMainMenu(self)
    logger.info("[quickmenu_bookorbit] initialized")
end

function Companion:addToMainMenu(menu_items)
    menu_items.quickmenu_bookorbit = {
        text = _("BookOrbit in QuickMenu"),
        checked_func = function()
            local store = settingsStore()
            local cfg = store:readSetting("quick_menu_settings") or {}
            local items = cfg.sections and cfg.sections.actions
                and cfg.sections.actions.items or {}
            for _, id in ipairs(items) do
                if id == ACTION_ID then return true end
            end
            return false
        end,
        callback = function()
            ensureSectionItem(not self:_isShown())
        end,
    }
end

function Companion:_isShown()
    local store = settingsStore()
    local cfg = store:readSetting("quick_menu_settings") or {}
    local items = cfg.sections and cfg.sections.actions
        and cfg.sections.actions.items or {}
    for _, id in ipairs(items) do
        if id == ACTION_ID then return true end
    end
    return false
end

return Companion
