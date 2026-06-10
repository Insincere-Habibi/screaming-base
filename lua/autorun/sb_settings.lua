-- Client-side settings panel (sliders) for ScreamingBase NextBots
if CLIENT then
    -- =========================================================================
    -- 1. Create the tool tab and category in the right-side panel
    -- =========================================================================
    hook.Add("AddToolMenuTabs", "ScreamingBaseToolTab", function()
        spawnmenu.AddToolTab("ScreamingBaseTab", "$creaming Base", "icon16/screaming_wrench.png")
    end)

    hook.Add("AddToolMenuCategories", "ScreamingBaseToolCategory", function()
        spawnmenu.AddToolCategory("ScreamingBaseTab", "ScreamingSettingsCategory", "Configurations")
    end)

    -- =========================================================================
    -- 2. Build the settings form for one NextBot class
    -- =========================================================================
    local function CreateNextbotSettingsForm(class, npcName, panel)
        panel:ClearControls()

        -- Try to load settings.json (author defaults)
        local settings = {}
        local paths = {
            "settings/" .. class .. ".json",
            class .. "/settings/settings.json",
            "settings/settings.json"
        }
        for _, path in ipairs(paths) do
            if file.Exists(path, "GAME") then
                local jsonData = file.Read(path, "GAME")
                if jsonData then
                    settings = util.JSONToTable(jsonData) or {}
                    break
                end
            end
        end

        local isLocked = settings.LockSettings or false

        if isLocked then
            panel:Help("⚠ Settings are locked by author. Cannot modify.")
        end

        panel:Help("Configure AI and Physics parameters for " .. npcName)

        -- List of ConVars and their factory defaults
        local cvars_to_check = {"godmode", "hp", "damage", "base_speed", "max_speed", "accel_step", "drift_force", "teleport_enable", "teleport_dist"}
        local default_values = {
            godmode = "1", hp = "999999", damage = "100",
            base_speed = "320", max_speed = "550", accel_step = "15",
            drift_force = "600", teleport_enable = "0", teleport_dist = "2500"
        }

        -- Create ConVars if they don't exist yet
        for _, v in ipairs(cvars_to_check) do
            local fullCvarName = "gmod_screaming_" .. class .. "_" .. v
            if not ConVarExists(fullCvarName) then
                CreateConVar(fullCvarName, default_values[v], FCVAR_ARCHIVE + FCVAR_REPLICATED)
            end
        end

        -- Build UI controls
        local ctrl_godmode    = panel:CheckBox("Godmode (Invincible)", "gmod_screaming_" .. class .. "_godmode")
        local ctrl_hp         = panel:NumSlider("Spawn Health", "gmod_screaming_" .. class .. "_hp", 1, 999999, 0)
        local ctrl_damage     = panel:NumSlider("Damage on Touch", "gmod_screaming_" .. class .. "_damage", 0, 500, 0)
        local ctrl_base_speed = panel:NumSlider("Starting Speed", "gmod_screaming_" .. class .. "_base_speed", 100, 1000, 0)
        local ctrl_max_speed  = panel:NumSlider("Max Speed", "gmod_screaming_" .. class .. "_max_speed", 200, 2000, 0)
        local ctrl_accel      = panel:NumSlider("Speed Increase / sec", "gmod_screaming_" .. class .. "_accel_step", 0, 200, 0)
        local ctrl_drift      = panel:NumSlider("Inertia Force (Drift)", "gmod_screaming_" .. class .. "_drift_force", 50, 4000, 0)
        local ctrl_tp         = panel:CheckBox("Enable Teleportation", "gmod_screaming_" .. class .. "_teleport_enable")
        local ctrl_tpdist     = panel:NumSlider("Teleport Distance", "gmod_screaming_" .. class .. "_teleport_dist", 500, 8000, 0)

        local allControls = {ctrl_godmode, ctrl_hp, ctrl_damage, ctrl_base_speed, ctrl_max_speed, ctrl_accel, ctrl_drift, ctrl_tp, ctrl_tpdist}

        -- =========================================================================
        -- 3. Reset buttons
        -- =========================================================================
        local btnAuthor = panel:Button("Reset to Author Settings")
        btnAuthor.DoClick = function()
            for _, v in ipairs(cvars_to_check) do
                local authorVal = settings[v] or default_values[v]
                RunConsoleCommand("gmod_screaming_" .. class .. "_" .. v, tostring(authorVal))
            end
            LocalPlayer():EmitSound("buttons/button14.wav", 70, 100)
        end

        local btnDefault = panel:Button("Reset to Base Defaults")
        btnDefault.DoClick = function()
            for _, v in ipairs(cvars_to_check) do
                RunConsoleCommand("gmod_screaming_" .. class .. "_" .. v, default_values[v])
            end
            LocalPlayer():EmitSound("buttons/button14.wav", 70, 100)
        end

        -- =========================================================================
        -- 4. Lock controls if author locked settings
        -- =========================================================================
        if isLocked then
            for _, ctrl in ipairs(allControls) do
                if IsValid(ctrl) then
                    ctrl:SetEnabled(false)
                end
            end
            btnAuthor:SetEnabled(false)
            btnDefault:SetEnabled(false)
            timer.Simple(0.05, function()
                if IsValid(panel) then
                    panel:SetAlpha(150) -- gray out the whole panel
                end
            end)
        end
    end

    -- =========================================================================
    -- 5. Register settings forms for all registered NextBots
    -- =========================================================================
    hook.Add("PopulateToolMenu", "ScreamingBaseToolOptions", function()
        local customList = list.Get("ScreamingBasePool") or {}
        for class, npcData in pairs(customList) do
            spawnmenu.AddToolMenuOption(
                "ScreamingBaseTab",
                "ScreamingSettingsCategory",
                "screaming_cfg_" .. class,
                npcData.Name or class,
                "",
                "",
                function(panel)
                    CreateNextbotSettingsForm(class, npcData.Name or class, panel)
                end
            )
        end
    end)
end