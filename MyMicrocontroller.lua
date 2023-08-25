-- 説明
--[[
    ビーコンの信号を受信して、そのビーコンの位置座標を計算します。
]]

-- I/O情報
--[[ Input
    
    [Number]
    Not in use

    [Bool]
    Ch.1 : Beacon Signal
    Ch.2 : Reset Signal
]]
--[[ Output
    
    [Number]
    Ch.1 : X Coordinate
    Ch.2 : Y Coordinate
]]

-- ライブラリ
--require "Libs.LightMatrix"

-- グローバル変数
OUT_CORD_X = 0
OUT_CORD_Z = 0

TARGET_PARAMS = {}

PRS_RESET = false

-- メイン関数
function onTick()
    --入力
    local beaconSignal, resetSignal = input.getBool(1), input.getBool(2)
    local resetPulse = resetSignal and not PRS_RESET

    --処理

    --出力
    output.setNumber(1, OUT_CORD_X)
    output.setNumber(2, OUT_CORD_Z)

    --保存
    PRS_RESET = resetSignal
end

-- 円と円の交点を2つ求める。重解の場合は、isDuplicateAnswerがtrueになる。
-- 交点がない場合は、hasAnswerがfalseになる。
---@pram x1 number
---@pram y1 number
---@pram r1 number
---@pram x2 number
---@pram y2 number
---@pram r2 number
---@return number x1, number y1, number x2, number y2, boolean hasAnswer, boolean isDuplicateAnswer
function solveCircleCrossPoint(x1, y1, r1, x2, y2, r2)

    local ax1, ay1, ax2, ay2, hasAnswer, isDuplicateAnswer = 0, 0, 0, 0, false, false

    local dx = x2 - x1
    local dy = y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)

    if d > r1 + r2 then
        hasAnswer, isDuplicateAnswer = false, false
    elseif d < math.abs(r1 - r2) then
        hasAnswer, isDuplicateAnswer = false, false
    elseif d == 0 and r1 == r2 then
        hasAnswer, isDuplicateAnswer = false, true
    else
        local a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
        local h = math.sqrt(r1 * r1 - a * a)
        ax1 = x1 + (a * dx + h * dy) / d
        ay1 = y1 + (a * dy - h * dx) / d
        ax2 = x1 + (a * dx - h * dy) / d
        ay2 = y1 + (a * dy + h * dx) / d
        hasAnswer, isDuplicateAnswer = true, false
    end

    return ax1, ay1, ax2, ay2, hasAnswer, isDuplicateAnswer
end

X1, Y1, X2, Y2, h, d = solveCircleCrossPoint(0, 0, 1, 1, 0, 1)
print("P1: ("..X1..", "..Y1..")")
print("P2: ("..X2..", "..Y2..")")