-- Client-side spawnmenu tab for all ScreamingBase NextBots
if CLIENT then
    local BASE_TAB_NAME = "$creaming Base"
    local BASE_TAB_ICON = "icon16/screaming_base.png"
    local HOOK_POPULATE = "PopulateScreamingBaseNextbots"

    -- =========================================================================
    -- 1. Create the root spawn tab in Q-menu (next to NPC, Weapons, etc.)
    -- =========================================================================
    hook.Add("AddGamemodeToolMenuTabs", "ScreamingBase_CreateRootTab", function()
        spawnmenu.AddCreationTab(BASE_TAB_NAME, function()
            local ctrl = vgui.Create("SpawnmenuContentPanel")
            ctrl:EnableSearch("entities", HOOK_POPULATE)
            ctrl:CallPopulateHook(HOOK_POPULATE)
            return ctrl
        end, BASE_TAB_ICON, 65)
    end)

    -- Fallback: re-create tab after cleanup / map change
    local function AddScreamingBaseTabFallback()
        if not spawnmenu.AddCreationTab then timer.Simple(0.5, AddScreamingBaseTabFallback) return end
        if spawnmenu.GetCreationTab and spawnmenu.GetCreationTab(BASE_TAB_NAME) then return end
        spawnmenu.AddCreationTab(BASE_TAB_NAME, function()
            local ctrl = vgui.Create("SpawnmenuContentPanel")
            ctrl:EnableSearch("entities", HOOK_POPULATE)
            ctrl:CallPopulateHook(HOOK_POPULATE)
            return ctrl
        end, BASE_TAB_ICON, 65)
    end
    timer.Simple(0.1, AddScreamingBaseTabFallback)
    hook.Add("PostCleanupMap", "ScreamingBaseReAddTab", AddScreamingBaseTabFallback)

    -- =========================================================================
    -- 2. Fill the tab with addon folders, subtypes, NPCs and tools
    -- =========================================================================
    hook.Add(HOOK_POPULATE, "ScreamingBase_FillContent", function(pnlContent, tree, node)
        local customList = list.Get("ScreamingBasePool") or {}
        local addonGroups = {}
        local noAddonNPCs = {}

        -- Separate NPCs by addon name
        for class, ent in pairs(customList) do
            local addonName = ent.AddonName or ""
            if addonName == "" then
                table.insert(noAddonNPCs, ent)
            else
                addonGroups[addonName] = addonGroups[addonName] or {
                    icon = ent.AddonIcon or "icon16/folder.png",
                    subtypes = {}
                }
                local subType = ent.SubType or ""
                addonGroups[addonName].subtypes[subType] = addonGroups[addonName].subtypes[subType] or {}
                table.insert(addonGroups[addonName].subtypes[subType], ent)
            end
        end

        -- Sort addon folders alphabetically
        local sortedAddons = {}
        for name, data in pairs(addonGroups) do
            table.insert(sortedAddons, {name = name, data = data})
        end
        table.sort(sortedAddons, function(a, b) return a.name < b.name end)

        -- Build tree nodes and content containers
        for _, addon in ipairs(sortedAddons) do
            local addonNode = tree:AddNode(addon.name, addon.data.icon)
            local addonContainer = vgui.Create("ContentContainer", pnlContent)
            addonContainer:SetVisible(false)
            local allAddonBots = {}

            for subType, bots in pairs(addon.data.subtypes) do
                if #bots > 0 then
                    local targetNode = addonNode
                    local targetContainer = addonContainer

                    -- Create subfolder if needed
                    if subType ~= "" then
                        local subNode = addonNode:AddNode(subType, "icon16/folder.png")
                        targetNode = subNode
                        targetContainer = vgui.Create("ContentContainer", pnlContent)
                        targetContainer:SetVisible(false)
                    end

                    -- Add spawn icons and tree entries for each bot
                    for _, bot in ipairs(bots) do
                        spawnmenu.CreateContentIcon("entity", targetContainer, {
                            nicename  = bot.Name or bot.Class,
                            spawnname = bot.Class,
                            material  = "entities/" .. bot.Class .. ".png",
                            admin     = false
                        })
                        table.insert(allAddonBots, bot)
                        targetNode:AddNode(bot.Name or bot.Class, bot.TreeIcon or "icon16/monkey.png")
                    end

                    if subType ~= "" then
                        targetNode.DoClick = function() pnlContent:SwitchPanel(targetContainer) end
                    end
                elseif subType ~= "" then
                    ScreamingBase.Error("SubType '" .. subType .. "' in addon '" .. addon.name .. "' has no nextbots! Folder not created.")
                end
            end

            -- Click on addon folder shows ALL bots from all subtypes
            addonNode.DoClick = function()
                addonContainer:Clear()
                for _, bot in ipairs(allAddonBots) do
                    spawnmenu.CreateContentIcon("entity", addonContainer, {
                        nicename  = bot.Name or bot.Class,
                        spawnname = bot.Class,
                        material  = "entities/" .. bot.Class .. ".png",
                        admin     = false
                    })
                end
                pnlContent:SwitchPanel(addonContainer)
            end
        end

        -- =========================================================================
        -- 3. NonFolder: NPCs without AddonName go here (always last)
        -- =========================================================================
        if #noAddonNPCs > 0 then
            local nfNode = tree:AddNode("NonFolder", "icon16/monkey.png")
            local nfContainer = vgui.Create("ContentContainer", pnlContent)
            nfContainer:SetVisible(false)

            for _, bot in ipairs(noAddonNPCs) do
                spawnmenu.CreateContentIcon("entity", nfContainer, {
                    nicename  = bot.Name or bot.Class,
                    spawnname = bot.Class,
                    material  = "entities/" .. bot.Class .. ".png",
                    admin     = false
                })
                nfNode:AddNode(bot.Name or bot.Class, bot.TreeIcon or "icon16/monkey.png")
            end

            nfNode.DoClick = function() pnlContent:SwitchPanel(nfContainer) end
        end

        -- =========================================================================
        -- 4. Tools folder: Debugger SWEP
        -- =========================================================================
        local toolsNode = tree:AddNode("Tools", "icon16/wrench.png")
        local toolsContainer = vgui.Create("ContentContainer", pnlContent)
        toolsContainer:SetVisible(false)

        spawnmenu.CreateContentIcon("weapon", toolsContainer, {
            nicename  = "Debugger",
            spawnname = "sb_debugger",
            material  = "icon16/wrench.png",
            admin     = false
        })

        toolsNode:AddNode("Debugger", "icon16/wrench.png")
        toolsNode.DoClick = function() pnlContent:SwitchPanel(toolsContainer) end

        -- =========================================================================
        -- 5. Empty state
        -- =========================================================================
        if #sortedAddons == 0 and #noAddonNPCs == 0 then
            tree:AddNode("No nextbots registered", "icon16/cross.png")
        end
    end)

    -- =========================================================================
    -- 6. Remove "Delete" from right-click menu on our spawn icons
    -- =========================================================================
    hook.Add("SpawnmenuIconMenuOpen", "ScreamingBase_RemoveDelete", function(menu, icon)
        local spawnname = icon:GetSpawnName()
        if not spawnname then return end
        local pool = list.Get("ScreamingBasePool") or {}
        if not pool[spawnname] then return end
        if not IsValid(menu) or not menu.GetCanvas then return end

        local items = menu:GetCanvas():GetChildren()
        local deletePhrase = language.GetPhrase("spawnmenu.menu.delete")

        for _, item in pairs(items) do
            if IsValid(item) and item.GetText then
                local text = item:GetText()
                if text == deletePhrase or text == "#spawnmenu.menu.delete" then
                    item:Remove()
                end
            end
        end
    end)
end