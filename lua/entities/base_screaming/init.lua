AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Helper to get or create a ConVar for this bot class
function ENT:GetBaseConVar(name, default)
    local className = self:GetClass()
    local cvarName = "gmod_screaming_" .. className .. "_" .. name
    if not ConVarExists(cvarName) then
        CreateConVar(cvarName, default, FCVAR_ARCHIVE + FCVAR_REPLICATED)
    end
    return GetConVar(cvarName)
end

function ENT:Initialize()
    -- Invisible placeholder model (hitbox only)
    self:SetModel("models/props_junk/watermelon01.mdl")
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetMoveType(MOVETYPE_NONE)
    self:PhysicsInitShadow(true, true)
    self:DrawShadow(false)

    -- Load custom settings from JSON
    local settings = ScreamingBase.LoadSettings(self)
    local hitbox = settings.hitbox or {}
    local shape = hitbox.shape or "cylinder"
    local hw = hitbox.width or 16
    local hh = hitbox.height or 72
    local spriteSize = self.SpriteSize or 90

    -- Clamp hitbox size to sprite size
    hw = math.min(hw, spriteSize / 2)
    hh = math.min(hh, spriteSize)

    -- Apply hitbox shape
    if shape == "sphere" then
        local r = math.min(hw, hh) / 2
        self:SetCollisionBounds(Vector(-r, -r, -r), Vector(r, r, r))
    elseif shape == "box" then
        self:SetCollisionBounds(Vector(-hw, -hw, 0), Vector(hw, hw, hh))
    else
        self:SetCollisionBounds(Vector(-hw, -hw, 0), Vector(hw, hw, hh))
    end

    -- Health
    local cv_max_hp = self:GetBaseConVar("hp", "999999")
    self:SetMaxHealth(cv_max_hp:GetInt())
    self:SetHealth(cv_max_hp:GetInt())

    -- Movement
    local cv_base_speed = self:GetBaseConVar("base_speed", "320")
    self.BaseSpeed = cv_base_speed:GetInt()
    self.CurrentSpeed = self.BaseSpeed
    self.NextAccelTime = 0
    self.NextTPCheckTime = 0

    -- Locomotion setup
    if self.loco then
        self.loco:SetStepHeight(26)
        self.loco:SetJumpHeight(85)
        self.loco:SetAcceleration(4000)
        self.loco:SetDeceleration(4000)
    end

    -- Chase music (looped manually)
    self.NextMusicTime = 0
    if self.ChaseMusic and self.ChaseMusic ~= "" then
        self.MusicLoop = CreateSound(self, self.ChaseMusic)
        if self.MusicLoop then
            self.MusicLoop:Play()
            self.NextMusicTime = CurTime() + 20
        end
    end
end

function ENT:OnTakeDamage(dmginfo)
    local cv_godmode = self:GetBaseConVar("godmode", "1")
    if cv_godmode:GetBool() then return 0 end

    local current_hp = self:Health() - dmginfo:GetDamage()
    self:SetHealth(current_hp)

    -- Clean death: stop everything before removing
    if current_hp <= 0 and not self.m_bRemoving then
        self.m_bRemoving = true
        if self.loco then
            self.loco:SetDesiredSpeed(0)
            self.loco:SetAcceleration(0)
            self.loco:SetDeceleration(0)
        end
        self:SetSolid(SOLID_NONE)
        self:SetNoDraw(true)
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        if self.Behavior then self.Behavior = nil end
        self:SetThink(nil)
        self:SetNextThink(nil)
        if self.MusicLoop then self.MusicLoop:Stop() self.MusicLoop = nil end
        SafeRemoveEntity(self)
    end
end

function ENT:PhysgunPickup(ply) return false end

-- Find the closest alive player or valid NPC
function ENT:GetClosestTarget()
    local targets = {}
    for _, pl in pairs(player.GetAll()) do
        if pl:Alive() then table.insert(targets, pl) end
    end
    for _, npc in pairs(ents.GetAll()) do
        if npc:IsNPC() and npc:Health() > 0 then
            if npc:GetClass() ~= self:GetClass() and not npc.IsNextBot then
                table.insert(targets, npc)
            end
        end
    end
    local closest, closestDist = nil, math.huge
    for _, t in pairs(targets) do
        local dist = self:GetPos():DistToSqr(t:GetPos())
        if dist < closestDist then closest, closestDist = t, dist end
    end
    return closest
end

function ENT:Think()
    -- Loop music
    if self.MusicLoop and CurTime() >= self.NextMusicTime then
        self.MusicLoop:Stop()
        self.MusicLoop:Play()
        self.NextMusicTime = CurTime() + 20
    end

    -- Read ConVars
    local cv_base_speed  = self:GetBaseConVar("base_speed", "320")
    local cv_max_speed   = self:GetBaseConVar("max_speed", "550")
    local cv_accel       = self:GetBaseConVar("accel_step", "15")
    local cv_damage      = self:GetBaseConVar("damage", "100")
    local cv_tp_enable   = self:GetBaseConVar("teleport_enable", "0")
    local cv_tp_dist     = self:GetBaseConVar("teleport_dist", "2500")
    local cv_drift_limit = self:GetBaseConVar("drift_force", "600")

    self.BaseSpeed = cv_base_speed:GetInt()
    local maxSpeedLimit = cv_max_speed:GetInt()
    local target = self:GetClosestTarget()

    if IsValid(target) then
        local botCenter = self:GetPos() + Vector(0, 0, 40)
        local targetCenter = target:GetPos() + Vector(0, 0, 40)
        local currentDist = botCenter:Distance(targetCenter)

        -- Melee attack
        if currentDist <= 65 then
            if (target:IsPlayer() and target:Alive()) or target:IsNPC() then
                local dmg = DamageInfo()
                dmg:SetDamage(cv_damage:GetInt())
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
                target:TakeDamageInfo(dmg)
                if self.AttackSound and self.AttackSound ~= "" then
                    self:EmitSound(self.AttackSound, 100, 100)
                end
                self.CurrentSpeed = self.BaseSpeed
            end
        else
            -- Acceleration over time
            if CurTime() >= self.NextAccelTime then
                if self.CurrentSpeed < maxSpeedLimit then
                    self.CurrentSpeed = self.CurrentSpeed + cv_accel:GetInt()
                end
                self.NextAccelTime = CurTime() + 1.0
            end
        end

        -- Teleportation
        if cv_tp_enable:GetBool() and CurTime() >= self.NextTPCheckTime then
            if currentDist > cv_tp_dist:GetInt() then
                local randomAngle = math.random(0, 360)
                local rad = math.rad(randomAngle)
                local offset = Vector(math.cos(rad) * 550, math.sin(rad) * 550, 10)
                local newSpawnPos = target:GetPos() + offset
                local tr = util.TraceHull({
                    start = newSpawnPos + Vector(0, 0, 10),
                    endpos = newSpawnPos,
                    mins = Vector(-16, -16, 0),
                    maxs = Vector(16, 16, 72),
                    filter = self
                })
                if not tr.Hit then
                    self:SetPos(newSpawnPos)
                    self.loco:ClearStuck()
                    self.CurrentSpeed = self.BaseSpeed
                    self.NextTPCheckTime = CurTime() + 5.0
                end
            end
        end

        -- Speed reset on big height difference
        if math.abs(target:GetPos().z - self:GetPos().z) > 55 then
            if self.CurrentSpeed > self.BaseSpeed + 20 then
                self.CurrentSpeed = self.BaseSpeed
            end
        end
    else
        self.CurrentSpeed = self.BaseSpeed
    end

    -- Locomotion: acceleration always high, deceleration = drift
    if self.loco then
        self.loco:SetDesiredSpeed(self.CurrentSpeed)
        local driftLimit = cv_drift_limit:GetInt()
        self.loco:SetAcceleration(4000)
        self.loco:SetDeceleration(driftLimit)
    end

    self:NextThink(CurTime() + 0.05)
    return true
end

function ENT:RunBehaviour()
    while true do
        local target = self:GetClosestTarget()
        if IsValid(target) then
            local path = Path("Follow")
            path:SetMinLookAheadDistance(300)
            path:SetGoalTolerance(20)
            path:Compute(self, target:GetPos())
            while (path:IsValid() and IsValid(target) and (not target:IsPlayer() or target:Alive())) do
                if path:GetAge() > 0.1 then path:Compute(self, target:GetPos()) end
                path:Update(self)
                -- Smash props and doors in the way
                local faceEnts = ents.FindInSphere(self:GetPos() + Vector(0,0,40), 35)
                for _, ent in pairs(faceEnts) do
                    if IsValid(ent) then
                        local class = ent:GetClass()
                        if class == "prop_physics" or class == "func_door" or class == "prop_door_rotating" then
                            local phys = ent:GetPhysicsObject()
                            if IsValid(phys) then phys:Wake() phys:ApplyForceCenter(self:GetForward() * 35000) end
                            ent:Fire("open", "", 0)
                            ent:TakeDamage(50, self, self)
                        end
                    end
                end
                coroutine.yield()
            end
        else
            coroutine.wait(0.2)
        end
        coroutine.yield()
    end
end

function ENT:OnStuck()
    self.loco:ClearStuck()
    if self:IsOnGround() then self.loco:Jump() end
end

function ENT:OnRemove()
    if self.MusicLoop then self.MusicLoop:Stop() end
end