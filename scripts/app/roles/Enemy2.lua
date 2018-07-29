local Progress = import("..ui.Progress")
local PhysicsManager = import("..scenes.PhysicsManager")

local Enemy2 = class("Enemy2", function()
    return display.newSprite("#enemy2-1-1.png")
end)

function Enemy2:ctor()

    self.attack = 20
    self.blood = 99

    local world = PhysicsManager:getInstance()
    self.body = world:createBoxBody(1, self:getContentSize().width/3, self:getContentSize().height*3/4)
--    self.body:bind(self)
    self.body:setCollisionType(CollisionType.kCollisionTypeEnemy)
    self.body:setPosition(self:getPosition())
    self.body:setIsSensor(true)
    self.body.isCanAttack = false

    self:scheduleUpdate();
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT,
            function()
                if self.body then self.body:setPosition(self:getPosition()) end
            end)

    local function onTouch()
        CCNotificationCenter:sharedNotificationCenter():postNotification("CLICK_ENEMY", self)
        return false
    end

    self:addAnimation()
    self:setTouchEnabled(true)
    self:setTouchSwallowEnabled(false)--触摸事件吞噬
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        if (self:getPositionX()-self:getContentSize().width/6 <event.x and event.x< self:getPositionX()+self:getContentSize().width/6)
        then return onTouch()
        else return false end
    end)

    self:addUI()
    self:addStateMachine()
    self:setAnchorPoint(cc.p(0.65,0.5))--图片偏移 改锚点来适配
end

function Enemy2:addUI()
    self.progress = Progress.new("#small-enemy-progress-bg.png", "#small-enemy-progress-fill.png")
    local size = self:getContentSize()
    self.progress:setPosition(size.width*2/3, size.height + self.progress:getContentSize().height/2)
    self:addChild(self.progress)
end

function Enemy2:addAnimation()
    local animationNames = {"walk", "attack", "dead", "hit"}
    local animationFrameNum = {3, 3, 3, 2}

    for i = 1, #animationNames do
        local frames = display.newFrames("enemy2-" .. i .. "-%d.png", 1, animationFrameNum[i])
        local animate = display.newAnimation(frames, 0.2)
        animate:setRestoreOriginalFrame(true)
        display.setAnimationCache("enemy2-" .. animationNames[i], animate)
    end

    local idle=display.newAnimation(display.newFrames("enemy2-1-%d.png",1,1),0.1)
    display.setAnimationCache("enemy2-stop",idle)
end

function Enemy2:getCanAttack()
    -- 是否能够被攻击，默认不可以
    print('Enemy2:getCanAttack = ' .. tostring(self.body.isCanAttack))
    return self.body.isCanAttack or false
end

function Enemy2:idle()
    if self.moveAction then
        self:stopAction(self.moveAction)
        self.moveAction = nil  
    end
    transition.stopTarget(self)
    transition.playAnimationOnce(self,display.getAnimationCache("enemy2-stop"))

end

function Enemy2:walkTo(pos, callback)

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
    local destPos = CCPoint(pos.x+40, pos.y)
    -- 转向 并且图片偏移 两个方向都改锚点来适配
    if pos.x < currentPos.x then
        self:setFlipX(false)
        self:setAnchorPoint(cc.p(0.65,0.5))
        local size = self:getContentSize()
        self.progress:setPosition(size.width*2/3, size.height + self.progress:getContentSize().height/2)
    else
        self:setFlipX(true)
        self:setAnchorPoint(cc.p(0.35,0.5))
        local size = self:getContentSize()
        self.progress:setPosition(size.width*1/3, size.height + self.progress:getContentSize().height/2)
    end
    --距离
    local posDiff = cc.PointDistance(currentPos, destPos)
    --移动动作序列
    self.moveAction = transition.sequence({CCMoveTo:create(5 * posDiff / display.width, CCPoint(pos.x+40,pos.y)), CCCallFunc:create(moveStop)})
    transition.playAnimationForever(self, display.getAnimationCache("enemy2-walk"))
    self:runAction(self.moveAction)
    return true
end

function Enemy2:attack()
    local function attackEnd()
        self:doEvent("stop")
    end

    transition.playAnimationOnce(self, display.getAnimationCache("enemy2-attack"), false, attackEnd)
end

function Enemy2:hit(attack)

    --先血量处理
    self.blood = self.blood - attack
    if self.blood <= 0 then self.blood = 0 end
    self.progress:setProgress(self.blood/1.5)

    --受击结束后进行死亡判断
    local function hitEnd()
        if self.blood<=0 then 
            self:doEvent("beKilled")
            return
        else
        self:doEvent("stop")
        end
    end

    transition.playAnimationOnce(self, display.getAnimationCache("enemy2-hit"), false, hitEnd)
end

function Enemy2:dead()
    local world = PhysicsManager:getInstance()
    world:removeBody(self.body, true)
    self.body = nil

    local function remove()
        self:removeFromParentAndCleanup()
        CCNotificationCenter:sharedNotificationCenter():postNotification("ENEMY_DEAD", self)
    end
    transition.playAnimationOnce(self, display.getAnimationCache("enemy2-dead"), true, remove)

end

function Enemy2:doEvent(event, ...)
    self.fsm_:doEvent(event, ...)
end

function Enemy2:getState()
    return self.fsm_:getState()
end

function Enemy2:addStateMachine()
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
            {name = "clickScreen", from = {"idle", "attack"},   to = "walk" },
            {name = "atk",  from = {"idle", "walk"},  to = "attack"},
            {name = "beKilled", from = {"hit"},  to = "dead"},
            {name = "beHit", from = {"idle", "walk", "attack"}, to = "hit"},
            {name = "stop", from = {"walk", "attack", "hit"}, to = "idle"},
        },

        -- 状态转变后的回调
        callbacks = {
            onidle = function (event) self:idle() end,
            onattack = function (event) self:attack() end,
            onhit = function (event) self:hit(event.args[1].attack) end,
            ondead = function (event) self:dead() end
        },
    })

end

function Enemy2:onExit()
    self:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)
    self:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
end

return Enemy2
