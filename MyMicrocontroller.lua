-- 説明
--[[
	ビーコンの信号を受信して、そのビーコンの位置座標を計算します。
]]

-- グローバル変数
-- プロパティ
P2P_DISTANCE = property.getNumber("Point 2 Point Distance")


OUT_CORD_X = 0
OUT_CORD_Z = 0

-- パルス化用
PRS_BEACON = false
PRS_RESET = false

-- メイン関数
function onTick()
	--初期化
	local isBeaconSignal, isResetSignal =
		input.getBool(1),
		input.getBool(2)
	---パルス化
	local isBeaconPulse = isBeaconSignal and not PRS_BEACON
	local isResetPulse = isResetSignal and not PRS_RESET

	local x, z, timestamp, prsTimestamp =
		input.getNumber(1),
		input.getNumber(2),
		input.getNumber(3),
		input.getNumber(4)


	---座標と距離の取得
	local detectionPoints = {}
	for i = 1, 3 do
		local detectionPoint = {}
		detectionPoint.x = input.getNumber(2 + i * 3)
		detectionPoint.z = input.getNumber(3 + i * 3)
		detectionPoint.distance = input.getNumber(4 + i * 3)
		detectionPoints[i] = detectionPoint
	end

	--処理

	if isBeaconPulse then
		if detectionPoints[1].x ~= 0 and detectionPoints[2].x ~= 0 and detectionPoints[3].x ~= 0 then
			--交点を求める
			local cpData = {}
			for i = 1, 2 do
				local cp = {}
				cp.x1, cp.z1, cp.x2, cp.z2, cp.hasAnswer, cp.isDuplicateAnswer =
					solveCircleCrossPoint(
					detectionPoints[i].x,
					detectionPoints[i].z,
					detectionPoints[i].distance,
					detectionPoints[i % 3 + 1].x,
					detectionPoints[i % 3 + 1].z,
					detectionPoints[i % 3 + 1].distance
				)
				cpData[i] = cp
			end

			--交点がある場合は、交点同士の距離を求めて、最も距離の短い組み合わせを採用する
			if cpData[1].hasAnswer and cpData[2].hasAnswer then
				local delta = {}
				delta[1] = math.sqrt((cpData[1].x1 - cpData[2].x1) ^ 2 + (cpData[1].z1 - cpData[2].z1) ^ 2)
				delta[2] = math.sqrt((cpData[1].x1 - cpData[2].x2) ^ 2 + (cpData[1].z1 - cpData[2].z2) ^ 2)
				delta[3] = math.sqrt((cpData[1].x2 - cpData[2].x1) ^ 2 + (cpData[1].z2 - cpData[2].z1) ^ 2)
				delta[4] = math.sqrt((cpData[1].x2 - cpData[2].x2) ^ 2 + (cpData[1].z2 - cpData[2].z2) ^ 2)

				local minDelta = delta[1]
				local minDeltaIndex = 1
				for i = 2, 4 do
					if delta[i] < minDelta then
						minDelta = delta[i]
						minDeltaIndex = i
					end
				end

				if minDeltaIndex == 1 then
					OUT_CORD_X = cpData[1].x1
					OUT_CORD_Z = cpData[1].z1
				elseif minDeltaIndex == 2 then
					OUT_CORD_X = cpData[1].x1
					OUT_CORD_Z = cpData[1].z1
				elseif minDeltaIndex == 3 then
					OUT_CORD_X = cpData[1].x2
					OUT_CORD_Z = cpData[1].z2
				elseif minDeltaIndex == 4 then
					OUT_CORD_X = cpData[1].x2
					OUT_CORD_Z = cpData[1].z2
				end
				
			end
		end

		--[[
		debug.log("TST||: timestamp: " .. timestamp)
		debug.log("TST||: prsTimestamp: " .. prsTimestamp)
		]]
		if prsTimestamp ~= 0 then
			local distance = 50 * (timestamp - prsTimestamp) - 250
			if detectionPoints[1].x == 0 then
				detectionPoints[1].x = x
				detectionPoints[1].z = z
				detectionPoints[1].distance = distance
			elseif detectionPoints[2].x == 0 then
				local distanceOf2Points = math.sqrt((detectionPoints[1].x - x) ^ 2 + (detectionPoints[1].z - z) ^ 2)
				if distanceOf2Points > P2P_DISTANCE then
					detectionPoints[2].x = x
					detectionPoints[2].z = z
					detectionPoints[2].distance = distance
				end
			elseif detectionPoints[3].x == 0 then
				local distanceOf2Points_1, distanceOf2Points_2 =
					math.sqrt((detectionPoints[1].x - x) ^ 2 + (detectionPoints[1].z - z) ^ 2),
					math.sqrt((detectionPoints[2].x - x) ^ 2 + (detectionPoints[2].z - z) ^ 2)

				if distanceOf2Points_1 > P2P_DISTANCE and distanceOf2Points_2 > P2P_DISTANCE then
					detectionPoints[3].x = x
					detectionPoints[3].z = z
					detectionPoints[3].distance = distance
				end
			end
		end
		--[[
		debug.log("TST||: 1: " .. detectionPoints[1].distance)
		debug.log("TST||: 2: " .. detectionPoints[2].distance)
		debug.log("TST||: 3: " .. detectionPoints[3].distance)
		]]
	end

	if isResetPulse then
		OUT_CORD_X = 0
		OUT_CORD_Z = 0
		for i, v in ipairs(detectionPoints) do
			v.x = 0
			v.z = 0
			v.distance = 0
		end
	end


	--出力
	output.setNumber(1, OUT_CORD_X)
	output.setNumber(2, OUT_CORD_Z)

	output.setBool(32, isBeaconPulse or isResetPulse)
	output.setNumber(23, isResetPulse and 0 or timestamp)
	for i, v in ipairs(detectionPoints) do
		output.setNumber(21 + i * 3, v.x)
		output.setNumber(22 + i * 3, v.z)
		output.setNumber(23 + i * 3, v.distance)
	end

	--値の保存
	PRS_BEACON = isBeaconSignal
	PRS_RESET = isResetSignal

	--デバッグ
end

-- 2つ円の交点を2つ求める。重解の場合は、isDuplicateAnswerがtrueになる。
-- 交点がない場合は、hasAnswerがfalseになる。
---@pram x1 number
---@pram y1 number
---@pram r1 number
---@pram x2 number
---@pram y2 number
---@pram r2 number
---@return number x1, number y1, number x2, number y2, boolean hasAnswer, boolean isDuplicateAnswer
function solveCircleCrossPoint(x1, y1, r1, x2, y2, r2)
	--[[
	debug.log("TST||: x1: " .. x1)
	debug.log("TST||: y1: " .. y1)
	debug.log("TST||: r1: " .. r1)
	debug.log("TST||: x2: " .. x2)
	debug.log("TST||: y2: " .. y2)
	debug.log("TST||: r2: " .. r2)
	]]

	local ax1, ay1, ax2, ay2, hasAnswer, isDuplicateAnswer = 0, 0, 0, 0, false, false

	local dx, dy = x2 - x1, y2 - y1
	local d = math.sqrt(dx * dx + dy * dy)

	if d > r1 + r2 or d == 0 then
		hasAnswer = false
	else
		hasAnswer = true
		local a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
		local h = math.sqrt(r1 * r1 - a * a)
		ax1 = x1 + (a * dx + h * dy) / d
		ay1 = y1 + (a * dy - h * dx) / d
		ax2 = x1 + (a * dx - h * dy) / d
		ay2 = y1 + (a * dy + h * dx) / d
		isDuplicateAnswer = ax1 == ax2 and ay1 == ay2
	end
	--[[
	debug.log("TST||: x1: " .. ax1)
	debug.log("TST||: y1: " .. ay1)
	debug.log("TST||: x2: " .. ax2)
	debug.log("TST||: y2: " .. ay2)
	debug.log("TST||: hasAnswer: " .. (hasAnswer and "true" or "false"))
	debug.log("TST||: isDuplicateAnswer: " .. (isDuplicateAnswer and "true" or "false"))
	]]
	return ax1, ay1, ax2, ay2, hasAnswer, isDuplicateAnswer
end

--[[
X1, Y1, X2, Y2, h, d = solveCircleCrossPoint(0, 10000-1, 10000, 0, -10000, 10000)
print("P1: ("..X1..", "..Y1..")")
print("P2: ("..X2..", "..Y2..")")
print("h: ".. (h and "true" or "false"))
print("d: ".. (d and "true" or "false"))
]]
