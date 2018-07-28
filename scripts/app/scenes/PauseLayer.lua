
local PauseLayer = class("PauseLayer", function ()
    return display.newColorLayer(ccc4(162,162,162,128))--添加白色透明底层
end)

function PauseLayer:ctor()
    self:addUI()
    self:addTouch()
end

function PauseLayer:addUI()
    --背景
    local background = display.newSprite("#pause-bg.png")
    background:setPosition(display.cx, display.cy)--放在中心位置
    self:addChild(background)

    --menu的两个item与点击触发的函数
    local home = ui.newImageMenuItem({
        image = "#home-1.png",
        imageSelected = "#home-2.png",
        listener = function()
            self:home()
        end
    })

    local resume = ui.newImageMenuItem({
        image = "#continue-1.png",
        imageSelected = "#continue-2.png",
        listener = function()
            self:resume()
        end
    })

    local backgroundSize = background:getContentSize()
    --item的位置
    home:setPosition(backgroundSize.width/3, backgroundSize.height/2)
    resume:setPosition(backgroundSize.width*2/3, backgroundSize.height/2)

    local menu = ui.newMenu({home, resume})
    menu:setPosition(display.left, display.bottom)

    background:addChild(menu)
end

function PauseLayer:addTouch()--拦截游戏内的触摸事件
    local function onTouch(name, x, y)
        print("PauseLayer:addTouch")
    end

    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return onTouch(event.name, event.x, event.y)
    end)

    self:setTouchEnabled(true)
end

function PauseLayer:resume()--回到游戏
    self:removeFromParentAndCleanup(true)--清除本层
    display.resume()--游戏主线程继续运行
end

function PauseLayer:home()--回到主界面
    display.resume()
    self:removeNodeEventListenersByEvent(cc.NODE_TOUCH_EVENT)--清除触摸拦截
    self:removeFromParentAndCleanup(true)
    display.replaceScene(require("app.scenes.StartScene").new())--切换界面
end

return PauseLayer
