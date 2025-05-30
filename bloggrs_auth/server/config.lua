Config = {}

-- Database configuration
Config.DatabaseTable = 'bloggrs_users'

-- Authentication settings
Config.MinUsernameLength = 3
Config.MinPasswordLength = 6
Config.SessionTimeout = 60 -- minutes

-- Messages
Config.Messages = {
    RegisterSuccess = "Account created successfully!",
    LoginSuccess = "Login successful!",
    UserExists = "Username already exists!",
    UserNotFound = "Username not found!",
    IncorrectPassword = "Incorrect password!",
    InvalidUsername = "Username must be at least " .. Config.MinUsernameLength .. " characters!",
    InvalidPassword = "Password must be at least " .. Config.MinPasswordLength .. " characters!",
    UsageRegister = "Usage: /register [username] [password]",
    UsageLogin = "Usage: /login [username] [password]"
}
