include("shared.lua")

-- Cache the sprite material once on spawn
function ENT:Initialize()
    self._cachedMaterial = ScreamingBase.GetSpriteMaterial(self)
    if not self._cachedMaterial then
        self._noSpriteWarned = true
    end
end

-- Draw the 2D sprite every frame
function ENT:Draw()
    if not self._cachedMaterial then
        if not self._noSpriteWarned then
            ScreamingBase.Warn("Nextbot has no sprite! Using default sprite.")
            self._noSpriteWarned = true
        end
        return
    end

    local size = self.SpriteSize or 90
    local pos = self:GetPos() + Vector(0, 0, size / 2)
    local normal = EyePos() - pos
    normal.z = 0
    normal:Normalize()

    render.SetMaterial(self._cachedMaterial)
    render.DrawQuadEasy(pos, normal, size, size, Color(255, 255, 255, 255), 180)
end