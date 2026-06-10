-- Right-click context menu (C-menu) for ScreamingBase NextBots
-- Opens a popup settings window when right-clicking a spawned NextBot
properties.Add("screaming_base_custom_settings", {
    MenuLabel = "Configure Character Settings",
    Order = 10,
    MenuIcon = "icon16/cog.png",

    -- Only show for entities using ScreamingBase
    Filter = function(self, ent, ply)
        if not IsValid(ent) or not IsValid(ply) then return false end
        return ent.Base == "base_screaming"
    end,

    -- Build the settings popup window
    Action = function(self, ent)
        if not IsValid(ent) then return end

        local class = ent:GetClass()
        local npcName = ent.PrintName or class

        -- Create the popup frame
        local frame = vgui.Create("DFrame")
        frame:SetSize(420, 480)
        frame:SetTitle("Parameters: " .. npcName .. " [" .. class .. "]")
        frame:Center()
        frame:MakePopup()

        -- Dark purple themed background
        frame.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 20, 40, 240))
            draw.RoundedBox(0, 0, 0, w, 24, Color(180, 0, 255, 255))
        end

        -- Scrollable panel for all controls
        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(5, 5, 5, 5)

        -- Collapsible category "AI, Physics & Teleportation"
        local category = scroll:Add("DCollapsibleCategory")
        category:Dock(TOP)
        category:SetLabel("AI, Physics & Teleportation")
        category:SetExpanded(true)

        local catList = vgui.Create("DListLayout", category)
        category:SetContents(catList)

        -- Godmode checkbox
        local god = catList:Add("DCheckBoxLabel")
        god:Dock(TOP)
        god:DockMargin(10, 10, 10, 5)
        god:SetText("Godmode (Invincible)")
        god:SetConVar("gmod_screaming_" .. class .. "_godmode")

        -- Health slider
        local hp = catList:Add("DNumSlider")
        hp:Dock(TOP)
        hp:DockMargin(10, 5, 10, 5)
        hp:SetText("Spawn Health")
        hp:SetMinMax(1, 999999)
        hp:SetDecimals(0)
        hp:SetConVar("gmod_screaming_" .. class .. "_hp")

        -- Damage slider
        local dmg = catList:Add("DNumSlider")
        dmg:Dock(TOP)
        dmg:DockMargin(10, 5, 10, 5)
        dmg:SetText("Damage on Touch")
        dmg:SetMinMax(0, 500)
        dmg:SetDecimals(0)
        dmg:SetConVar("gmod_screaming_" .. class .. "_damage")

        -- Starting speed slider
        local bspeed = catList:Add("DNumSlider")
        bspeed:Dock(TOP)
        bspeed:DockMargin(10, 5, 10, 5)
        bspeed:SetText("Starting Speed")
        bspeed:SetMinMax(100, 1000)
        bspeed:SetDecimals(0)
        bspeed:SetConVar("gmod_screaming_" .. class .. "_base_speed")

        -- Max speed slider
        local mspeed = catList:Add("DNumSlider")
        mspeed:Dock(TOP)
        mspeed:DockMargin(10, 5, 10, 5)
        mspeed:SetText("Max Speed")
        mspeed:SetMinMax(200, 2000)
        mspeed:SetDecimals(0)
        mspeed:SetConVar("gmod_screaming_" .. class .. "_max_speed")

        -- Drift (inertia) slider
        local drift = catList:Add("DNumSlider")
        drift:Dock(TOP)
        drift:DockMargin(10, 5, 10, 5)
        drift:SetText("Inertia Force (Drift)")
        drift:SetMinMax(50, 4000)
        drift:SetDecimals(0)
        drift:SetConVar("gmod_screaming_" .. class .. "_drift_force")

        -- Teleportation toggle
        local tp = catList:Add("DCheckBoxLabel")
        tp:Dock(TOP)
        tp:DockMargin(10, 10, 10, 5)
        tp:SetText("Enable Horror Teleportation")
        tp:SetConVar("gmod_screaming_" .. class .. "_teleport_enable")

        -- Teleport distance slider
        local tpdist = catList:Add("DNumSlider")
        tpdist:Dock(TOP)
        tpdist:DockMargin(10, 5, 10, 10)
        tpdist:SetText("Teleport Distance")
        tpdist:SetMinMax(500, 8000)
        tpdist:SetDecimals(0)
        tpdist:SetConVar("gmod_screaming_" .. class .. "_teleport_dist")

        -- Reset to defaults button
        local button = scroll:Add("DButton")
        button:Dock(TOP)
        button:DockMargin(10, 15, 10, 5)
        button:SetText("Reset " .. npcName .. " to Defaults")
        button.DoClick = function()
            RunConsoleCommand("gmod_screaming_" .. class .. "_godmode", "1")
            RunConsoleCommand("gmod_screaming_" .. class .. "_hp", "999999")
            RunConsoleCommand("gmod_screaming_" .. class .. "_damage", "100")
            RunConsoleCommand("gmod_screaming_" .. class .. "_base_speed", "320")
            RunConsoleCommand("gmod_screaming_" .. class .. "_max_speed", "550")
            RunConsoleCommand("gmod_screaming_" .. class .. "_accel_step", "15")
            RunConsoleCommand("gmod_screaming_" .. class .. "_drift_force", "600")
            RunConsoleCommand("gmod_screaming_" .. class .. "_teleport_enable", "0")
            RunConsoleCommand("gmod_screaming_" .. class .. "_teleport_dist", "2500")
            LocalPlayer():EmitSound("buttons/button14.wav", 70, 100)
            if IsValid(frame) then frame:Close() end
        end
    end
})