AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.Author = "$creaming Eagle"
SWEP.PrintName = "Debugger"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Category = "$creaming Base"

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }
SWEP.Secondary = { ClipSize = -1, DefaultClip = -1, Automatic = false, Ammo = "none" }

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetClip1(0)
    self:SetClip2(0)
    self:SetNextPrimaryFire(CurTime() + 999999)
    self:SetNextSecondaryFire(CurTime() + 999999)
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end
function SWEP:Reload() return false end
function SWEP:Deploy()
    self:SetNextPrimaryFire(CurTime() + 999999)
    self:SetNextSecondaryFire(CurTime() + 999999)
    return true
end

if CLIENT then
    local botTrails = {}
    local nextLogTime = 0

    hook.Add("Think", "SB_Debugger_Think", function()
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "sb_debugger" then
            botTrails = {}
            nextLogTime = 0
            return
        end

        if nextLogTime == 0 then
            print("[DEBUGGER] Map: " .. game.GetMap())
            print("[DEBUGGER] Recording started...")
            nextLogTime = CurTime() + 1
        end

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent.Base == "base_screaming" then
                local id = ent:EntIndex()
                if not botTrails[id] then botTrails[id] = {} end
                table.insert(botTrails[id], ent:GetPos() + Vector(0, 0, 10))
                if #botTrails[id] > 500 then table.remove(botTrails[id], 1) end

                if CurTime() >= nextLogTime then
                    local bp = ent:GetPos()
                    local pp = ply:GetPos()
                    local dist = bp:Distance(pp)
                    print(string.format("[DEBUGGER] %s | Bot: %.0f %.0f %.0f | Player: %.0f %.0f %.0f | Distance: %.0f",
                        ent.PrintName or ent:GetClass(),
                        bp.x, bp.y, bp.z,
                        pp.x, pp.y, pp.z,
                        dist))
                end
            end
        end

        if CurTime() >= nextLogTime then
            nextLogTime = CurTime() + 1
        end
    end)

    hook.Add("PostDrawOpaqueRenderables", "SB_Debugger_Draw", function()
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "sb_debugger" then return end

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent.Base == "base_screaming" then
                local id = ent:EntIndex()
                local trail = botTrails[id]
                if trail and #trail > 1 then
                    for i = 2, #trail do
                        local alpha = (i / #trail) * 200
                        render.DrawLine(trail[i-1], trail[i], Color(0, 255, 0, alpha), true)
                    end
                end
                local forward = ent:GetForward() * 60
                render.DrawLine(ent:GetPos() + Vector(0, 0, 40), ent:GetPos() + Vector(0, 0, 40) + forward, Color(255, 0, 0, 255), true)
                if IsValid(ent.CurrentTarget) then
                    render.DrawLine(ent:GetPos() + Vector(0, 0, 40), ent.CurrentTarget:GetPos() + Vector(0, 0, 40), Color(0, 255, 0, 100), true)
                end
            end
        end
    end)
end

list.Set("Weapon", "sb_debugger", {
    PrintName = "Debugger",
    Category = "$creaming Base",
    Spawnable = true
})