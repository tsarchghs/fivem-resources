-- sql_setup.lua
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS bloggrs_characters (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            pos_x FLOAT DEFAULT 0,
            pos_y FLOAT DEFAULT 0,
            pos_z FLOAT DEFAULT 0,
            pos_heading FLOAT DEFAULT 0,
            skin LONGTEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES bloggrs_users(id) ON DELETE CASCADE
        )
    ]], {}, function(rowsChanged)
        print("[Bloggrs] bloggrs_characters table checked/created!")
    end)
end)
