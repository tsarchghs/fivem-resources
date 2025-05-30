Config = {}

-- Database tables
Config.PlayerTable = 'bloggrs_players'
Config.InventoryTable = 'bloggrs_inventory'

-- Starting values
Config.StartingCash = 500
Config.StartingBank = 1000

-- Courier job settings
Config.CheckpointReward = 2 -- Amount of weed in grams per checkpoint
Config.CompletionBonus = 1000 -- Bonus weed in grams for completing all deliveries
Config.CheckpointRadius = 2.0
Config.CheckpointColor = {r = 255, g = 204, b = 0, a = 200} -- Yellow color for checkpoints

-- Delivery locations (x, y, z coordinates)
Config.DeliveryLocations = {
    {1240.32, -3168.76, 5.86},
    {2329.12, 2571.86, 46.68},
    {2487.53, 4961.27, 44.83},
    {1386.15, 3659.71, 34.92},
    {-1166.83, -1566.05, 4.41},
    {-3157.04, 1126.23, 20.85},
    {1531.45, 1728.91, 109.92},
    {-1171.54, -1572.05, 4.66},
    {91.95, 181.62, 104.55},
    {2352.28, 3037.87, 48.15}
}

-- Vehicle settings
Config.CourierVehicle = "burrito3" -- Van for courier job
Config.VehicleSpawnDistance = 5.0 -- Distance from player to spawn vehicle

-- Messages
Config.Messages = {
    NotLoggedIn = "You need to be logged in to use this feature. Use /login or /register.",
    JobStarted = "Courier job started. Follow the yellow marker to deliver the packages.",
    JobCancelled = "Courier job cancelled.",
    JobCompleted = "Job completed! Final bonus: %sg weed! Total earned this run: %sg weed!",
    CheckpointReached = "Package delivered! Received %sg weed! Proceed to the next location.",
    AlreadyOnJob = "You are already on a courier job.",
    VehicleSpawned = "Your delivery vehicle has been spawned. Get in and follow the yellow marker."
}
