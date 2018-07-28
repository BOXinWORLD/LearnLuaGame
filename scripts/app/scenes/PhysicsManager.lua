
    local world = nil

    local PhysicsManager = class("PhysicsManager", function()
        -- 创建物理引擎单例对象
        return CCPhysicsWorld:create(0, 0)
    end)

    CollisionType = {}
    CollisionType.kCollisionTypePlayer = 1
    CollisionType.kCollisionTypeEnemy = 2

    function PhysicsManager:getInstance()--获取单例对象
        if world == nil or tolua.isnull(world) then
            world = PhysicsManager.new()
        end

        return world
    end

    function PhysicsManager:purgeInstance()--删除
        if world ~= nil then
            world:removeAllCollisionListeners()
            world:removeAllBodies(true)
            world = nil
        end
    end

    return PhysicsManager