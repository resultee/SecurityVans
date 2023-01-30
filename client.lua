-- Variables for the money truck properties
local moneyTruckHash = GetHashKey("stockade") -- Hash for the money truck model
local payOut = 10000 -- payout amount for completing the job
local respawnTime = 2000 * 60 * 1000 -- respawn time for the truck in milliseconds

-- Array of initial money truck locations, with their respective x, y, z, r, and breached status
local moneyTrucks = {
[0] = { ["x"] = -2469.812, ["y"] = 3792.616, ["z"] = 19.736, ["r"] = 168.889, ["breached"] = false},
[1] = { ["x"] = -628.790, ["y"] = 5258.434, ["z"] = 73.555, ["r"] = 116.800, ["breached"] = false},
[2] = { ["x"] = 322.723, ["y"] = 3418.192, ["z"] = 36.313, ["r"] = 256.886, ["breached"] = false},
[3] = { ["x"] = 1964.813, ["y"] = 3832.978, ["z"] = 31.689, ["r"] = 33.627, ["breached"] = false},
[4] = { ["x"] = -82.240, ["y"] = -2010.276, ["z"] = 17.695, ["r"] = 171.177, ["breached"] = false},
[5] = { ["x"] = -224.910, ["y"] = -2644.534, ["z"] = 5.678, ["r"] = 358.516, ["breached"] = false},
[6] = { ["x"] = 1407.299, ["y"] = -2056.321, ["z"] = 51.677, ["r"] = 111.545, ["breached"] = false}
}

-- Array of destinations for each money truck
local truckDests = {
[0] = {["x"] = -122.495, ["y"] = 6479.521, ["z"] = 31.047, ["r"] = 0},
[1] = {["x"] = -392.572, ["y"] = 6062.591, ["z"] = 31.104, ["r"] = 0},
[2] = {["x"] = 254.483, ["y"] = 190.450, ["z"] = 104.448, ["r"] = 0},
[3] = {["x"] = -343.565, ["y"] = -29.775, ["z"] = 47.089, ["r"] = 0},
[4] = {["x"] = -35.136, ["y"] = -699.135, ["z"] = 31.942, ["r"] = 0},
[5] = {["x"] = -34.552, ["y"] = -673.060, ["z"] = 31.944, ["r"] = 0},
[6] = {["x"] = -19.869, ["y"] = -670.819, ["z"] = 31.942, ["r"] = 90},
}

-- Arrays to store the spawned money truck, its driver, and its guard
local storedMoneyTrucks = {} 
local storedDrivers = {}
local storedGuards = {}

local storedDrivers = {}
local storedGuards = {}

-- Function to create the money truck and its driver and guard
function createMoneyTruck(index)
local moneyTruck = CreateVehicle(moneyTruckHash, moneyTrucks[index]["x"], moneyTrucks[index]["y"], moneyTrucks[index]["z"], moneyTrucks[index]["r"], true, false)
local driver = CreatePedInsideVehicle(moneyTruck, 4, GetHashKey("s_m_m_security_01"), -1, true, false)
local guard = CreatePedInsideVehicle(moneyTruck, 4, GetHashKey("s_m_m_security_01"), 0, true, false)
SetBlockingOfNonTemporaryEvents(driver, true)
SetBlockingOfNonTemporaryEvents(guard, true)
TaskVehicleDriveToCoord(driver, moneyTruck, truckDests[index]["x"], truckDests[index]["y"], truckDests[index]["z"], 30.0, 0, moneyTruckHash, 786603, 1.0, true)
storedMoneyTrucks[index] = moneyTruck
storedDrivers[index] = driver
storedGuards[index] = guard
end

-- Function to check if the truck has reached its destination
function checkMoneyTruckArrival(index)
local moneyTruck = storedMoneyTrucks[index]
local driver = storedDrivers[index]
local guard = storedGuards[index]
local truckCoords = GetEntityCoords(moneyTruck)
local destCoords = {x = truckDests[index]["x"], y = truckDests[index]["y"], z = truckDests[index]["z"]}
local distance = Vdist(truckCoords["x"], truckCoords["y"], truckCoords["z"], destCoords["x"], destCoords["y"], destCoords["z"])
if distance <= 50.0 then
-- Give player the payout
TriggerServerEvent("givePlayerMoney", payOut)
-- Remove the truck, driver, and guard
DeleteVehicle(moneyTruck)
DeletePed(driver)
DeletePed(guard)
storedMoneyTrucks[index] = nil
storedDrivers[index] = nil
storedGuards[index] = nil
-- Wait for the set respawn time before creating the money truck again
SetTimeout(respawnTime, function()
createMoneyTruck(index)
end)
end
end

-- Initial call to create the money trucks
for i = 0, 6 do
createMoneyTruck(i)
end

-- Check for truck arrival every 10 seconds
Citizen.CreateThread(function()
while true do
Citizen.Wait(10000)
for i, truck in ipairs(storedMoneyTrucks) do
if truck ~= nil and DoesEntityExist(truck) then
local truckCoords = GetEntityCoords(truck, true)
local destCoords = truckDests[i]
if Vdist(truckCoords.x, truckCoords.y, truckCoords.z, destCoords.x, destCoords.y, destCoords.z) < 1.0 then
-- Give player money and delete truck
GivePlayerMoney(payOut)
DeleteVehicle(truck)
storedMoneyTrucks[i] = nil
end
end
end
end
end)

-- Function to spawn the money truck
function SpawnMoneyTruck(index)
-- Check if the money truck has been breached
if moneyTrucks[index]["breached"] then
print("Money truck has been breached, cannot spawn")
return
end
-- Load model and create the money truck
RequestModel(moneyTruckHash)
while not HasModelLoaded(moneyTruckHash) do
    Citizen.Wait(0)
end
local moneyTruck = CreateVehicle(moneyTruckHash, moneyTrucks[index]["x"], moneyTrucks[index]["y"], moneyTrucks[index]["z"], moneyTrucks[index]["r"], true, false)

-- Create the driver and guard for the truck
local driver = CreatePedInsideVehicle(moneyTruck, 26, GetHashKey("s_m_y_pilot_01"), -1, true, false)
local guard = CreatePedInsideVehicle(moneyTruck, 26, GetHashKey("s_m_m_security_01"), 0, true, false)

-- Store the truck, driver, and guard in the array
storedMoneyTrucks[index] = {["truck"] = moneyTruck, ["driver"] = driver, ["guard"] = guard}

-- Set the truck as mission entity and driver as controlled entity
SetEntityAsMissionEntity(moneyTruck, true, true)
SetEntityAsMissionEntity(driver, true, true)
SetEntityAsMissionEntity(guard, true, true)

-- Task the driver to drive the truck to the destination
TaskVehicleDriveToCoord(driver, moneyTruck, truckDests[index]["x"], truckDests[index]["y"], truckDests[index]["z"], 20.0, 0, moneyTruckHash, 786603, 1.0, true)
end

-- Function to breach the money truck
function BreachMoneyTruck(index)
-- Check if the money truck has already been breached
if moneyTrucks[index]["breached"] then
print("Money truck has already been breached")
return
end
-- Set the breached status to true
moneyTrucks[index]["breached"] = true

-- Delete the truck, driver, and guard
local truck = storedMoneyTrucks[index]["truck"]
local driver = storedMoneyTrucks[index]["driver"]
local guard = storedMoneyTrucks[index]["guard"]
DeleteVehicle(truck)
DeletePed(driver)
DeletePed(guard)

-- Start the timer for truck respawn
Citizen.SetTimeout(respawnTime, function()
-- Spawn a new truck at the original location
local newTruck = CreateVehicle(moneyTruckHash, moneyTrucks[index]["x"], moneyTrucks[index]["y"], moneyTrucks[index]["z"], moneyTrucks[index]["r"], true, false)
local newDriver = CreatePedInsideVehicle(newTruck, 26, "s_m_y_cop_01", -1, true, false)
local newGuard = CreatePedInsideVehicle(newTruck, 26, "s_m_y_cop_01", 0, true, false)

-- Store the new truck, driver, and guard
storedMoneyTrucks[index] = { ["truck"] = newTruck, ["driver"] = newDriver, ["guard"] = newGuard }

-- Reset the breached status
moneyTrucks[index]["breached"] = false
end)

-- Give the player the payout
TriggerEvent("givePlayerMoney", payOut)
end)

-- Check for truck arrival every 10 seconds
Citizen.CreateThread(function()
while true do
Citizen.Wait(10 * 1000)
for i, truck in ipairs(storedMoneyTrucks) do
if IsVehicleStopped(truck["truck"]) and not moneyTrucks[i]["breached"] then
TriggerEvent("arrivalEvent", i)
end
end
end
end)

-- Initial spawn of money trucks and their drivers/guards
Citizen.CreateThread(function()
for i, location in ipairs(moneyTrucks) do
local truck = CreateVehicle(moneyTruckHash, location["x"], location["y"], location["z"], location["r"], true, false)
local driver = CreatePedInsideVehicle(truck, 26, "s_m_y_cop_01", -1, true, false)
local guard = CreatePedInsideVehicle(truck, 26, "s_m_y_cop_01", 0, true, false)
	-- Store the truck, driver, and guard
	storedMoneyTrucks[i] = { ["truck"] = truck, ["driver"] = driver, ["guard"] = guard }
end
	-- Store the truck, driver, and guard
	storedMoneyTrucks[i] = { ["truck"] = truck, ["driver"] = driver, ["guard"] = guard }
end

local guard = storedMoneyTrucks[index]["guard"]

if DoesEntityExist(truck) then
DeleteEntity(truck)
end
if DoesEntityExist(driver) then
DeleteEntity(driver)
end
if DoesEntityExist(guard) then
DeleteEntity(guard)
end

-- Remove the truck from the storedMoneyTrucks array
storedMoneyTrucks[index] = nil

-- Wait for the respawn time to pass
Citizen.Wait(respawnTime)

-- Spawn the truck at the next location
local nextIndex = index + 1
if nextIndex > #moneyTrucks then
nextIndex = 0
end
spawnMoneyTruck(nextIndex)
end
end

-- Function to check if a player is near the truck
function isPlayerCloseToTruck(truck)
local player = PlayerId()
local plyPed = GetPlayerPed(player)
local plyPos = GetEntityCoords(plyPed, false)
local truckPos = GetEntityCoords(truck, false)
local distance = GetDistanceBetweenCoords(plyPos.x, plyPos.y, plyPos.z, truckPos.x, truckPos.y, truckPos.z, true)
return distance <= 10.0
end

-- Function to display a message when the truck is breached
function displayTruckBreachMessage(index)
SetNotificationTextEntry("STRING")
AddTextComponentString("rTruck Breach:w The money truck has been breached!")
DrawNotification(false, false)
end

-- Function to start the script
function startMoneyTruckJob()
-- Spawn the first truck
spawnMoneyTruck(0)
end
-- Start the script
startMoneyTruckJob()
if DoesEntityExist(driver) then
DeleteEntity(driver)
end
if DoesEntityExist(guard) then
DeleteEntity(guard)
end
DeleteVehicle(truck)
storedMoneyTrucks[index] = nil

-- Respawn the truck after the set respawn time
Citizen.Wait(respawnTime)
CreateMoneyTruck(index)
end
end)
end
end
end

-- Create the money truck at the initial location
function CreateMoneyTruck(index)
local moneyTruck = GetHashKey("stockade")
RequestModel(moneyTruck)
while not HasModelLoaded(moneyTruck) do
Wait(1)
end

-- Spawn the truck and its driver and guard
local truck = CreateVehicle(moneyTruck, moneyTrucks[index]["x"], moneyTrucks[index]["y"], moneyTrucks[index]["z"], moneyTrucks[index]["r"], true, false)
local driver = CreatePedInsideVehicle(truck, 4, GetHashKey("s_m_y_cop_01"), -1, true, false)
local guard = CreatePedInsideVehicle(truck, 4, GetHashKey("s_m_y_cop_01"), 0, true, false)

-- Store the truck, driver, and guard in the array
storedMoneyTrucks[index] = {["truck"] = truck, ["driver"] = driver, ["guard"] = guard}

-- Start the truck's journey to the destination
TaskVehicleDriveToCoord(driver, truck, truckDests[index]["x"], truckDests[index]["y"], truckDests[index]["z"], 20.0, 0, moneyTruckHash, 786603, 1.0, true)

-- Check for truck arrival every 10 seconds
while not IsVehicleStoppedAtCoord(truck, truckDests[index]["x"], truckDests[index]["y"], truckDests[index]["z"], 10.0) do
Citizen.Wait(10 * 1000)
end

-- Set the driver and guard as on duty
SetDriverAbility(driver, 1.0)
SetDriverAggressiveness(driver, 0.0)
SetPedCanBeTargetted(driver, false)
SetPedCanBeTargetted(guard, false)
end

-- Initialize the script
for i = 0, #moneyTrucks do
CreateMoneyTruck(i)
end
end)
-- Initialize the script
Citizen.CreateThread(function()
while true do
Citizen.Wait(0)


-- Loop through all money truck locations
for index, moneyTruck in pairs(moneyTrucks) do
  -- Check if the truck has been breached
  if moneyTrucks[index]["breached"] then
    -- Check if the respawn time has passed
    if GetGameTimer() > moneyTrucks[index]["respawnTime"] then
      -- Spawn the money truck, driver, and guard
      local truck = CreateVehicle(moneyTruckHash, moneyTruck["x"], moneyTruck["y"], moneyTruck["z"], moneyTruck["r"], true, false)
      local driver = CreatePedInsideVehicle(truck, 4, GetHashKey("s_m_y_armymech_01"), -1, true, false)
      local guard = CreatePedInsideVehicle(truck, 4, GetHashKey("s_m_y_swat_01"), 0, true, false)
      
      -- Store the spawned money truck, driver, and guard in the storedMoneyTrucks array
      storedMoneyTrucks[index] = {["truck"] = truck, ["driver"] = driver, ["guard"] = guard}

      -- Set the breached status to false
      moneyTrucks[index]["breached"] = false

      -- Start driving the truck to the destination
      TaskVehicleDriveToCoord(driver, truck, truckDests[index]["x"], truckDests[index]["y"], truckDests[index]["z"], 40.0, 0, moneyTruckHash, 786603, 1.0, true)
    end
  else
    -- Check if the money truck has arrived at the destination
    local truck = storedMoneyTrucks[index]["truck"]
    local driver = storedMoneyTrucks[index]["driver"]
    local guard = storedMoneyTrucks[index]["guard"]
    local dest = truckDests[index]
    local distance = GetDistanceBetweenCoords(GetEntityCoords(truck), dest["x"], dest["y"], dest["z"], true)

    if distance < 5.0 then
      -- Pay the player for completing the job
      TriggerServerEvent("givePlayerMoney", payOut)

      -- Delete the truck, driver, and guard
      DeleteVehicle(truck)
      DeletePed(driver)
      DeletePed(guard)

      -- Set the breached status to true
      moneyTrucks[index]["breached"] = true

      -- Set the respawn time for the truck
      moneyTrucks[index]["respawnTime"] = GetGameTimer() + respawnTime
    end
  end
end




