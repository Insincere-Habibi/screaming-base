hook.Add("EntityTakeDamage", "ScreamingBase_MineFix", function(target, dmginfo)
    if target:GetClass() == "prop_lasermine" then
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) and attacker:IsNPC() and attacker.Base == "base_screaming" then
            target:TakeDamage(100, attacker, attacker)
        end
    end
end)

ScreamingBase.Info("Mine fix module loaded! Laser mines now react to NextBots.")