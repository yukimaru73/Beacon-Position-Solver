require("LifeBoatAPI.Utils.LBCopy")
--require("Libs.LBCopy")
require("Libs.Quaternion")
require("Libs.Vector3")

---@section PhysicsSensorLib 1 PhysicsSensorLib
---@class PhysicsSensorLib
---@field GPS Vector3[X, Y, Z] in m
---@field euler Vector3[X, Y, Z] in rad
---@field velocity Vector3[X, Y, Z] in m/tick
---@field angularSpeed Vector3[X, Y, Z] in rad/tick
---@field absVelocity number in m/tick
---@field absAngularSpeed number in rad/tick
PhysicsSensorLib = {
	---@param cls PhysicsSensorLib
	---@overload fun(cls:PhysicsSensorLib):PhysicsSensorLib creates a new zero-initialized PhysicsSensorLib
	---@return PhysicsSensorLib
	new = function(cls, GPS, euler, velocity, anglerSpeed, absVelocity, absAnglerSpeed)
		return LifeBoatAPI.lb_copy(cls, {
			GPS = Vector3:new(GPS),
			euler = Vector3:new(euler),
			velocity = Vector3:new(velocity),
			angularSpeed = Vector3:new(anglerSpeed),
			absVelocity = absVelocity or 0,
			absAngularSpeed = absAnglerSpeed or 0
		})
	end,
	---@section update
	---@param self PhysicsSensorLib
	---@param startChannel number
	---@return nil
	update = function(self, startChannel)
		for i = 1, 3 do
			self.GPS[i] = input.getNumber(startChannel + i - 1)
			self.euler[i] = input.getNumber(startChannel + i + 2)
			self.velocity[i] = input.getNumber(startChannel + i + 5) / 60
			self.angularSpeed[i] = input.getNumber(startChannel + i + 8) * math.pi / 30
		end
		self.absVelocity = input.getNumber(startChannel + 12) / 60
		self.absAnglerSpeed = input.getNumber(startChannel + 13) * math.pi / 30
	end,
	---@endsection

	---@section getFuturePosition
	---@param self PhysicsSensorLib
	---@param ticks number
	---@return Vector3
	getFuturePosition = function(self, ticks)
		return self.GPS:add(self.velocity:mul(ticks))
	end,
	---@endsection

	---@section _getQuaternion
	---@param self PhysicsSensorLib
	---@param ticks number
	---@return Quaternion
	_getQuaternion = function(self, ticks)
		return Quaternion:newFromEuler(
			self.euler[1] + ticks * self.angularSpeed[1],
			self.euler[2] + ticks * self.angularSpeed[2],
			self.euler[3] + ticks * self.angularSpeed[3])
	end,
	---@endsection

	---@section rotateVecL2W
	---@param self PhysicsSensorLib
	---@param ticks number
	---@param vector table[X, Y, Z]
	---@return Vector3
	rotateVecL2W = function(self, vector, ticks)
		return self:_getQuaternion(ticks):rotateVector(vector)
	end,
	---@endsection

	---@section rotateVecW2L
	---@param self PhysicsSensorLib
	---@param vector table[X, Y, Z]
	---@param ticks number
	---@return Vector3
	rotateVecW2L = function(self, vector, ticks)
		return self:_getQuaternion(ticks):getConjugateQuaternion():rotateVector(vector)
	end,
	---@endsection



}
