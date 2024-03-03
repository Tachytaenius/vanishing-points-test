local vec2 = require("lib.mathsies").vec2
local vec3 = require("lib.mathsies").vec3
local quat = require("lib.mathsies").quat
local mat4 = require("lib.mathsies").mat4

local loadObj = require("loadObj")

local tau = math.pi * 2

local meshShader

local camera, cube
local vfov

local translating, rotating, controllingCube -- Bools for display

function love.load()
	love.graphics.setFrontFaceWinding("ccw")

	camera = {
		position = vec3(0, 0, -4),
		orientation = quat()
	}
	cube = {
		position = vec3(),
		orientation = quat(),
		-- angularVelocity = vec3(0.125, 0.1875, 0.25) * 3,
		-- targetAngularVelocity = vec3(),
		-- targetAngularVelocityTimer = 0,
		-- targetAngularVelocityTimerLength = 10,
		mesh = loadObj("meshes/cube.obj")
	}
	vfov = 70

	meshShader = love.graphics.newShader("shaders/mesh.glsl")
end

function love.update(dt)
	controllingCube = love.keyboard.isDown("lshift")
	local object = controllingCube and cube or camera

	local speed = 4
	local translation = vec3()
	if love.keyboard.isDown("w") then translation.z = translation.z + speed end
	if love.keyboard.isDown("s") then translation.z = translation.z - speed end
	if love.keyboard.isDown("a") then translation.x = translation.x - speed end
	if love.keyboard.isDown("d") then translation.x = translation.x + speed end
	if love.keyboard.isDown("q") then translation.y = translation.y + speed end
	if love.keyboard.isDown("e") then translation.y = translation.y - speed end
	object.position = object.position + vec3.rotate(translation, object.orientation) * dt
	translating = translation ~= vec3()

	local angularSpeed = tau / 4
	local rotation = vec3()
	if love.keyboard.isDown("j") then rotation.y = rotation.y - angularSpeed end
	if love.keyboard.isDown("l") then rotation.y = rotation.y + angularSpeed end
	if love.keyboard.isDown("i") then rotation.x = rotation.x + angularSpeed end
	if love.keyboard.isDown("k") then rotation.x = rotation.x - angularSpeed end
	if love.keyboard.isDown("u") then rotation.z = rotation.z - angularSpeed end
	if love.keyboard.isDown("o") then rotation.z = rotation.z + angularSpeed end
	object.orientation = quat.normalise(object.orientation * quat.fromAxisAngle(rotation * dt))
	rotating = rotation ~= vec3()

	local fovChangeRate = 10
	local fovChange = 0
	if love.keyboard.isDown("r") then fovChange = fovChange + fovChangeRate end
	if love.keyboard.isDown("f") then fovChange = fovChange - fovChangeRate end
	vfov = vfov + fovChange * dt
end

local function edge(a, b, modelToScreenMatrix)
	local aProjectedVec3ScreenSpace = modelToScreenMatrix * a
	local bProjectedVec3ScreenSpace = modelToScreenMatrix * b

	local aProjectedVec2 = (vec2(aProjectedVec3ScreenSpace.x, aProjectedVec3ScreenSpace.y) / 2 + 0.5) * vec2(love.graphics.getDimensions())
	local bProjectedVec2 = (vec2(bProjectedVec3ScreenSpace.x, bProjectedVec3ScreenSpace.y) / 2 + 0.5) * vec2(love.graphics.getDimensions())

	love.graphics.setPointSize(4)
	love.graphics.points(aProjectedVec2.x, aProjectedVec2.y, bProjectedVec2.x, bProjectedVec2.y)

	local direction = vec2.normalise(bProjectedVec2 - aProjectedVec2)
	local origin = aProjectedVec2

	local endpoint1 = origin - direction * 10000
	local endpoint2 = origin + direction * 10000

	love.graphics.line(endpoint1.x, endpoint1.y, endpoint2.x, endpoint2.y)
end

function love.draw()
	love.graphics.setDepthMode("always", false)
	love.graphics.setColor(0.25, 0.25, 0.25)
	love.graphics.line(0, love.graphics.getHeight() / 2, love.graphics.getWidth(), love.graphics.getHeight() / 2)
	love.graphics.line(love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight())
	love.graphics.setColor(1, 1, 1)

	love.graphics.setDepthMode("lequal", true)
	love.graphics.setShader(meshShader)
	local projectionMatrix = mat4.perspectiveLeftHanded(love.graphics.getWidth() / love.graphics.getHeight(), math.rad(vfov), 100, 0.01)
	local cameraMatrix = mat4.camera(camera.position, camera.orientation)
	local modelMatrix = mat4.transform(cube.position, cube.orientation)
	local modelToScreenMatrix = projectionMatrix * cameraMatrix * modelMatrix
	meshShader:send("modelToScreen", {mat4.components(modelToScreenMatrix)})
	love.graphics.draw(cube.mesh)
	love.graphics.setShader()

	love.graphics.setDepthMode("always", false)
	love.graphics.setColor(1, 0, 0)
	edge(vec3(1, 1, 1), vec3(-1, 1, 1), modelToScreenMatrix)
	edge(vec3(1, -1, 1), vec3(-1, -1, 1), modelToScreenMatrix)
	edge(vec3(1, 1, -1), vec3(-1, 1, -1), modelToScreenMatrix)
	edge(vec3(1, -1, -1), vec3(-1, -1, -1), modelToScreenMatrix)

	love.graphics.setColor(0, 1, 0)
	edge(vec3(1, 1, 1), vec3(1, -1, 1), modelToScreenMatrix)
	edge(vec3(-1, 1, 1), vec3(-1, -1, 1), modelToScreenMatrix)
	edge(vec3(1, 1, -1), vec3(1, -1, -1), modelToScreenMatrix)
	edge(vec3(-1, 1, -1), vec3(-1, -1, -1), modelToScreenMatrix)

	love.graphics.setColor(0, 0, 1)
	edge(vec3(1, 1, 1), vec3(1, 1, -1), modelToScreenMatrix)
	edge(vec3(-1, 1, 1), vec3(-1, 1, -1), modelToScreenMatrix)
	edge(vec3(1, -1, 1), vec3(1, -1, -1), modelToScreenMatrix)
	edge(vec3(-1, -1, 1), vec3(-1, -1, -1), modelToScreenMatrix)

	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.circle("line", love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, love.graphics.getHeight() / 2)

	love.graphics.setColor(1, 1, 1)
	love.graphics.setPointSize(8)
	local forwardVector = vec3(0, 0, 1)
	local upVector = vec3(0, -1, 0)
	local cameraMatrixStationary = mat4.camera(vec3(), camera.orientation)
	local forwardVectorProjected = projectionMatrix * cameraMatrixStationary * forwardVector
	local forwardVectorScreen = (vec2(forwardVectorProjected.x, forwardVectorProjected.y) * 0.5 + 0.5) * vec2(love.graphics.getDimensions())
	local offVectorProjected = projectionMatrix * cameraMatrixStationary * vec3.rotate(forwardVector, quat.fromAxisAngle(upVector * 0.1))
	local offVectorScreen = (vec2(offVectorProjected.x, offVectorProjected.y) * 0.5 + 0.5) * vec2(love.graphics.getDimensions())
	if forwardVectorProjected.z < 0 then
		love.graphics.points(forwardVectorScreen.x, forwardVectorScreen.y)
	end
	local direction = vec2.normalise(offVectorScreen - forwardVectorScreen)
	local origin = forwardVectorScreen
	local endpoint1 = origin - direction * 10000
	local endpoint2 = origin + direction * 10000
	love.graphics.line(endpoint1.x, endpoint1.y, endpoint2.x, endpoint2.y)

	love.graphics.print(
		(translating and "translating" or "") .. "\n" ..
		(rotating and "rotating" or "") .. "\n" ..
		(controllingCube and "controlling cube" or "controlling camera") .. "\n" ..
		"Vertical FOV: " .. vfov
	)
end
