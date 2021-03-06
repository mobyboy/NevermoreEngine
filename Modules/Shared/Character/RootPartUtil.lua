--- Utility functions involving the root part
-- @module RootPartUtil

local require = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))

local Promise = require("Promise")
local Maid = require("Maid")

local RootPartUtil = {}

local MAX_YIELD_TIME = 60

function RootPartUtil.promiseRootPart(humanoid)
	if humanoid.RootPart then
		return Promise.resolved(humanoid.RootPart)
	end

	-- humanoid:GetPropertyChangedSignal("RootPart") doesn't fire. :(

	local maid = Maid.new()
	local promise = Promise.new()

	spawn(function()
		while not humanoid.RootPart and promise:IsPending() do
			wait()
		end
		if humanoid.RootPart then
			promise:Resolve(humanoid.RootPart)
		else
			promise:Reject()
		end
	end)

	delay(MAX_YIELD_TIME, function()
		promise:Reject("Timed out")
	end)

	maid:GiveTask(humanoid.AncestryChanged:Connect(function()
		if not humanoid:IsDescendantOf(game) then
			promise:Reject("Humanoid removed from game")
		end
	end))

	maid:GiveTask(humanoid.Died:Connect(function()
		promise:Reject("Humanoid died")
	end))

	promise:Finally(function()
		maid:DoCleaning()
	end)

	return promise
end

return RootPartUtil