-- Core framework: logging, registration, fallbacks, hooks
if not ScreamingBase then ScreamingBase = {} end

-- Versioning for compatibility checks
SCREAMING_BASE_VERSION = {
    major = 1,
    minor = 0,
    patch = 0,
    string = "1.0.0"
}

-- Brand colors for console output
ScreamingBase.CLR_BRAND  = Color(255, 0, 128)
ScreamingBase.CLR_INFO   = Color(0, 255, 128)
ScreamingBase.CLR_WARN   = Color(255, 200, 0)
ScreamingBase.CLR_ERROR  = Color(255, 50, 50)

-- Base logging function
function ScreamingBase.Log(level, levelColor, msg)
    MsgC(ScreamingBase.CLR_BRAND, "[$creaming Base] ", levelColor, "[" .. level .. "] ", Color(255, 255, 255), msg, "\n")
end

function ScreamingBase.Info(msg)
    ScreamingBase.Log("INFO", ScreamingBase.CLR_INFO, msg)
end

function ScreamingBase.Warn(msg)
    ScreamingBase.Log("WARNING", ScreamingBase.CLR_WARN, msg)
end

function ScreamingBase.Error(msg)
    ScreamingBase.Log("ERROR", ScreamingBase.CLR_ERROR, msg)
end

-- Safe module loader, errors are non-fatal
function ScreamingBase.SafeIncludeModule(modulePath)
    local fullPath = "screaming_modules/" .. modulePath
    if file.Exists(fullPath, "LUA") then
        local success, err = pcall(function() include(fullPath) end)
        if not success then
            ScreamingBase.Error("Failed to load module '" .. modulePath .. "': " .. tostring(err))
        end
    end
end

ScreamingBase.SafeIncludeModule("sh_colors.lua")
ScreamingBase.SafeIncludeModule("sh_icons.lua")

-- Get a named color from the database, fallback to white
function ScreamingBase.GetColor(name)
    if not ScreamingBase.Colors then
        ScreamingBase.Error("Color module is not loaded! Addon tried to use '" .. (name or "nil") .. "'. Using default color.")
        return Color(255, 255, 255)
    end
    if not name or name == "" then return Color(255, 255, 255) end
    name = string.lower(name)
    local col = ScreamingBase.Colors[name]
    if not col then
        ScreamingBase.Warn("Color '" .. name .. "' not found in database. Using default color.")
        return Color(255, 255, 255)
    end
    return col
end

-- Get a named icon path from the database, fallback to folder icon
function ScreamingBase.GetIcon(name)
    if not ScreamingBase.Icons then
        ScreamingBase.Error("Icon module is not loaded! Addon tried to use '" .. (name or "nil") .. "'. Using default icon.")
        return "icon16/folder.png"
    end
    if not name or name == "" then return "icon16/folder.png" end
    name = string.lower(name)
    local icon = ScreamingBase.Icons[name]
    if not icon then
        ScreamingBase.Warn("Icon '" .. name .. "' not found in database. Using default icon.")
        return "icon16/folder.png"
    end
    return icon
end

-- Custom icon registration with validation
function ScreamingBase.RegisterIcon(name, path)
    if not name or name == "" then
        ScreamingBase.Error("RegisterIcon: icon name is empty! Icon registration rejected (not the nextbot).")
        return false
    end
    if not path or path == "" then
        ScreamingBase.Error("RegisterIcon: path is empty for icon '" .. name .. "'. Icon registration rejected (not the nextbot).")
        return false
    end
    local fullPath = "materials/" .. path
    if not file.Exists(fullPath, "GAME") then
        ScreamingBase.Error("RegisterIcon: file '" .. fullPath .. "' not found! Icon '" .. name .. "' registration rejected (not the nextbot).")
        return false
    end
    if not string.EndsWith(string.lower(path), ".png") then
        ScreamingBase.Error("RegisterIcon: '" .. name .. "' must be .png format! Icon registration rejected (not the nextbot).")
        return false
    end
    local function isPowerOfTwo(n)
        return n > 0 and bit.band(n, n - 1) == 0
    end
    local w, h = ScreamingBase.GetPNGDimensions(fullPath)
    if w and h then
        if not isPowerOfTwo(w) or not isPowerOfTwo(h) then
            ScreamingBase.Error("RegisterIcon: '" .. name .. "' dimensions must be power of two! Got " .. w .. "x" .. h .. ". Icon registration rejected (not the nextbot).")
            return false
        end
        if w ~= h then
            ScreamingBase.Error("RegisterIcon: '" .. name .. "' must be square! Got " .. w .. "x" .. h .. ". Icon registration rejected (not the nextbot).")
            return false
        end
    end
    name = string.lower(name)
    if ScreamingBase.Icons and ScreamingBase.Icons[name] then
        ScreamingBase.Error("RegisterIcon: '" .. name .. "' already exists in database! Icon registration rejected (not the nextbot).")
        return false
    end
    ScreamingBase.Icons = ScreamingBase.Icons or {}
    ScreamingBase.Icons[name] = path
    ScreamingBase.Info("Custom icon '" .. name .. "' registered successfully: " .. path)
    return true
end

-- Read PNG dimensions from binary header
function ScreamingBase.GetPNGDimensions(pngPath)
    local f = file.Open(pngPath, "rb", "GAME")
    if not f then return nil, nil end
    f:Seek(16)
    local function readBigEndianLong(fileObj)
        local b1 = fileObj:ReadByte() or 0
        local b2 = fileObj:ReadByte() or 0
        local b3 = fileObj:ReadByte() or 0
        local b4 = fileObj:ReadByte() or 0
        return bit.bor(bit.lshift(b1, 24), bit.lshift(b2, 16), bit.lshift(b3, 8), b4)
    end
    local width = readBigEndianLong(f)
    local height = readBigEndianLong(f)
    f:Close()
    return width, height
end

-- Check if VTF has multiple frames
function ScreamingBase.IsAnimatedVTF(vtfPath)
    local fullPath = "materials/" .. vtfPath .. ".vtf"
    if not file.Exists(fullPath, "GAME") then return false end
    local f = file.Open(fullPath, "rb", "GAME")
    if not f then return false end
    f:Seek(24)
    local frameCount = f:ReadShort() or 1
    f:Close()
    return frameCount > 1
end

-- Get or create sprite material with animation support
function ScreamingBase.GetSpriteMaterial(ent)
    local spritePath = ent.SpriteMaterial or ""
    if spritePath == "" then
        ScreamingBase.Warn("Nextbot has no sprite! Using default sprite.")
        return Material("screaming_base/default_square")
    end
    spritePath = string.StripExtension(spritePath)
    local mat = Material(spritePath)
    if mat and not mat:IsError() then
        return mat
    end
    local isAnimated = ent.SpriteAnimated
    if isAnimated == nil then
        isAnimated = ScreamingBase.IsAnimatedVTF(spritePath)
    end
    local params = {
        ["$basetexture"] = spritePath,
        ["$translucent"] = 1,
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = 1,
        ["$ignorez"] = 0
    }
    if isAnimated then
        params["Proxies"] = {
            ["AnimatedTexture"] = {
                ["animatedtexturevar"] = "$basetexture",
                ["animatedtextureframenumvar"] = "$frame",
                ["animatedtextureframerate"] = 15
            }
        }
        ScreamingBase.Info("Creating animated material for " .. spritePath .. " (15 FPS)")
    end
    local matName = "screaming_auto_" .. ent:EntIndex()
    return CreateMaterial(matName, "UnlitGeneric", params)
end

-- Load settings.json for the given entity
function ScreamingBase.LoadSettings(ent)
    local class = ent:GetClass()
    local paths = {
        "settings/" .. class .. ".json",
        class .. "/settings/settings.json",
        "settings/settings.json"
    }
    for _, path in ipairs(paths) do
        if file.Exists(path, "GAME") then
            local jsonData = file.Read(path, "GAME")
            if jsonData then
                local settings = util.JSONToTable(jsonData)
                if settings then
                    ScreamingBase.Info("Settings loaded for " .. class)
                    return settings
                end
            end
        end
    end
    return {}
end

-- Precache sounds ConVar
local cv_precache_sounds = CreateConVar("gmod_screaming_precache_sounds", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED})

-- Register a NextBot addon into the framework
function ScreamingBase.RegisterNextbot(ENT)
    local class = string.Replace(ENT.Folder, "entities/", "")
    if not ENT.PrintName or ENT.PrintName == "" then
        ScreamingBase.Error("Nextbot from '" .. (ENT.Folder or "unknown") .. "' has no PrintName! Nextbot registration aborted.")
        return false
    end
    if not ENT.Category or ENT.Category == "" then
        ScreamingBase.Error("Nextbot '" .. ENT.PrintName .. "' has no Category! Nextbot registration aborted.")
        return false
    end
    if not ENT.SpriteMaterial or ENT.SpriteMaterial == "" then
        ScreamingBase.Warn("Nextbot '" .. ENT.PrintName .. "' has no sprite! Using default sprite.")
    end
    if not ENT.ChaseMusic or ENT.ChaseMusic == "" then
        ScreamingBase.Warn("Nextbot '" .. ENT.PrintName .. "' has no chase music! Using default sound.")
    end
    if not ENT.AttackSound or ENT.AttackSound == "" then
        ScreamingBase.Warn("Nextbot '" .. ENT.PrintName .. "' has no attack sound! Using default sound.")
    end
    if cv_precache_sounds:GetBool() and ENT.ChaseMusic and ENT.ChaseMusic ~= "" then
        Sound(ENT.ChaseMusic)
    end
    if cv_precache_sounds:GetBool() and ENT.AttackSound and ENT.AttackSound ~= "" then
        Sound(ENT.AttackSound)
    end
    if CLIENT then
        language.Add(class, ENT.PrintName)
        if ENT.KillIconMaterial and ENT.KillIconMaterial ~= "" then
            killicon.Add(class, ENT.KillIconMaterial, Color(255, 255, 255, 255))
        end
    end
    local nextbotData = {
        Name       = ENT.PrintName,
        Class      = class,
        Category   = ENT.Category,
        AddonName  = ENT.AddonName or "",
        AddonIcon  = ScreamingBase.GetIcon(ENT.AddonIcon),
        AddonColor = ScreamingBase.GetColor(ENT.AddonColor),
        SubType    = ENT.SubType or "",
        TreeIcon   = ScreamingBase.GetIcon(ENT.TreeIcon),
        Color      = ScreamingBase.GetColor(ENT.Color)
    }
    hook.Run("ScreamingBase_OnNextbotPreCreate", class, nextbotData)
    list.Set("ScreamingBasePool", class, nextbotData)
    list.Set("SpawnableEntities", class, {
        PrintName = ENT.PrintName,
        ClassName = class,
        Category  = ENT.Category,
        Spawnable = true
    })
    hook.Run("ScreamingBase_OnNextbotPostCreate", class, nextbotData)
    ScreamingBase.Info("Nextbot '" .. ENT.PrintName .. "' [" .. class .. "] loaded successfully!")
    return true
end

-- Include file depending on realm
function ScreamingBase.IncludeFile(fileName)
    local explode = string.Explode("[/\\]", fileName, true)
    local last = explode[#explode]
    if string.StartWith(last, "sv_") then
        if SERVER then return include(fileName) end
    elseif string.StartWith(last, "cl_") then
        if CLIENT then return include(fileName) end
    else
        AddCSLuaFile(fileName)
        return include(fileName)
    end
end

-- Recursively include all .lua files in folder
function ScreamingBase.IncludeFolder(folder)
    local files, _ = file.Find(folder .. "/*.lua", "LUA")
    for _, fileName in ipairs(files) do
        ScreamingBase.IncludeFile(folder .. "/" .. fileName)
    end
    local _, subFolders = file.Find(folder .. "/*", "LUA")
    for _, folderName in ipairs(subFolders) do
        ScreamingBase.IncludeFolder(folder .. "/" .. folderName)
    end
end

-- Startup message
if SERVER then
    ScreamingBase.Info("Core Module initialized on SERVER.")
else
    hook.Add("Initialize", "ScreamingBaseHello", function()
        ScreamingBase.Info("Core Module initialized on CLIENT. Welcome back, $creaming Eagle!")
    end)
end

ScreamingBase.IncludeFolder("screaming_modules")