local PhysicsManager = import("..scenes.PhysicsManager")

local Player = class("Player", function()
    local sprite = display.newSprite("#player1-1-1.png", SpriteEx)
    return sprite
end)

function Player:ctor()

    self.attack = 50
    self.blood = 500

    local world = PhysicsManager:getInstance()
    --碰撞盒子
    self.body = world:createBoxBody(1, self:getContentSize().width/3, self:getContentSize().height*2/3)
--    self.body:bind(self)
    self.body:setCollisionType(CollisionType.kCollisionTypePlayer)
    self.body:setIsSensor(true)

    --监听帧事件 开启update定时器 用于绑定碰撞盒子
    self:scheduleUpdate();
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function() self.body:setPosition(self:getPosition()) end)

    -- 缓存动画数据
    self:addAnimation()
    self:addStateMachine()
    self:setAnchorPoint(cc.p(0.35,0.5))--图片偏移 改锚点来适配
end

function Player:addAnimation()
    local animationNames = {"walk", "attack", "dead", "hit", "skill"}
    local animationFrameNum = {4, 4, 4, 2, 4}

    for i = 1, #animationNames do --角色-动作-动作帧.png
        --新建一个精灵帧
        local frames = display.newFrames("player1-" .. i .. "-%d.png", 1, animationFrameNum[i])
        local animation = nil
        if animationNames[i] == "attack" then
            --通过SpriteFrames创建一个Animation，时间间隔为0.1s
            animation = display.newAnimation(frames, 0.1)
        else
            animation = display.newAnimation(frames, 0.2)
        end

        animation:setRestoreOriginalFrame(true)
        display.setAnimationCache("player1-" .. animationNames[i], animation)--存入缓存
    end

    --用于静止状态的缓存
    local idle=display.newAnimation(display.newFrames("player1-1-%d.png",1,1),0.1)
    display.setAnimationCache("player1-stop",idle)
end

function Player:idle()
    transition.stopTarget(self)
    transition.playAnimationOnce(self,display.getAnimationCache("player1-stop"))
end

function Player:walkTo(pos, callback)

    local function moveStop()--结束的回调
        self:doEvent("stop")
        if callback then
            callback()
        end
    end

    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil
        transition.stopTarget(self)
    end
    --当前位置
    local currentPos = CCPoint(self:getPosition())
    --目标位置    
    local destPos = CCPoint(pos.x, pos.y)
    -- 转向 并且图片偏移 两个方向都改锚点来适配
    if pos.x < currentPos.x then
        self:setFlipX(true)
        self:setAnchorPoint(cc.p(0.65,0.5))
    else
        self:setFlipX(false)
        self:setAnchorPoint(cc.p(0.35,0.5))
    end
    --距离
    local posDiff = cc.PointDistance(currentPos, destPos)
    --移动动作序列
    self.moveAction = transition.sequence({CCMoveTo:create(5 * posDiff / display.width, CCPoint(pos.x,pos.y)), CCCallFunc:create(moveStop)})
    transition.playAnimationForever(self, display.getAnimationCache("player1-walk"))
    self:runAction(self.moveAction)
    return true
end

function Player:attackEnemy()

    local function attackEnd()
        self:doEvent("stop")
    end

    local animation = display.getAnimationCache("player1-attack")
    transition.playAnimationOnce(self, animation, false, attackEnd)
end

function Player:hit()

    local function hitEnd()
        self:doEvent("stop")
    end
    transition.playAnimationOnce(self, display.getAnimationCache("player1-hit"), false, hitEnd)
end

function Player:dead()
    local world = PhysicsManager:getInstance()
    world:removeBody(self.body, true)
    self.body = nil
    transition.playAnimationOnce(self, display.getAnimationCache("player1-dead"))
end

function Player:doEvent(event, ...)
    self.fsm_:doEvent(event, ...)
end

function Player:getState()
    return self.fsm_:getState()
end

function Player:addStateMachine() --状态机
    self.fsm_ = {}
    cc.GameObject.extend(self.fsm_)
    :addComponent("components.behavior.StateMachine")
    :exportMethods()

    self.fsm_:setupState({
        -- 初始状态
        initial = "idle",

        -- 事件和状态转换
        events = {
            -- t1:clickScreen; t2:clickEnemy; t3:beKilled; t4:stop
            {name = "clickScreen", from = {"idle"},   to = "walk" },
            {name = "clickEnemy",  from = {"idle", "walk"},  to = "attack"},
            {name = "beKilled", from = {"idle", "walk", "attack", "hit"},  to = "dead"},
            {name = "beHit", from = {"idle", "walk", "attack"}, to = "hit"},
            {name = "stop", from = {"walk", "attack", "hit"}, to = "idle"},
        },

        -- 状态转变后的回调
        callbacks = {
            onidle = function (event) self:idle() end,
            onattack = function (event) self:attackEnemy() end,
            onhit = function (event) self:hit() end,
            ondead = function (event) self:dead() end
        },
    })

end

function Player:onExit()
    self.fsm_:doEventForce("stop")
    self:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

return Player

