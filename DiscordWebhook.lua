type EmbedData = {
	Player: Player,
	
	title: string,
	description: string,
	url: string,
	color: Color3,
	footer: {
		text: string,
		icon_url: string
	},
	image: {
		url: string,
		height: number,
		width: number
	},
	fields: {
		{
			name: string,
			value: number,
			inline: boolean
		}
	}
}

local Webhook = {}
local Roblox_Users = 'https://www.roblox.com/users/%s/profile'
local Discord_Proxy = 'https://roblox-2-discord.herokuapp.com/%s/%s'
local Thumbnail_Proxy = 'https://thumbnail-roblox.herokuapp.com/getthumbnail/%s'
local tRGB = {'r','g','b'};
local NAME_COLORS = {Color3.new(253/255, 41/255, 67/255),Color3.new(1/255, 162/255, 255/255),Color3.new(2/255, 184/255, 87/255),BrickColor.new("Bright violet").Color,BrickColor.new("Bright orange").Color,BrickColor.new("Bright yellow").Color,BrickColor.new("Light reddish violet").Color,BrickColor.new("Brick yellow").Color}
local HttpService = game:GetService 'HttpService'

function Webhook:PostData(Data)
	HttpService:PostAsync(
		string.format(Discord_Proxy, self.ID, self.Token),
		HttpService:JSONEncode(Data)
	)
end

function Webhook:GetNameColor(pName: string)
	local value, cValue, reverseIndex = 0, nil, nil
	for index = 1, #pName do
		cValue = string.byte(string.sub(pName, index, index))
		reverseIndex = #pName - index + 1
		if #pName%2 == 1 then
			reverseIndex = reverseIndex - 1
		end
		if reverseIndex%4 >= 2 then
			cValue = -cValue
		end
		value += cValue
	end
	return value
end

function Webhook:GetPlayerChatColor(pName: string)
	local Retorn, real = NAME_COLORS[((self:GetNameColor(pName)) % #NAME_COLORS) + 1], table.create(3)
	for i, v in pairs(tRGB) do
		table.insert(real, i, Retorn[v]*255)
	end
	return Color3.new(unpack(real))
end

function Webhook:Color3ToHex(color: Color3)
	return tonumber(string.format("0x%02X%02X%02X", color.R,  color.G, color.B))
end

function Webhook:Embed(EmbedData: EmbedData)
	if EmbedData.color and typeof(EmbedData.color)=='Color3' then
		EmbedData.color = self:Color3ToHex( EmbedData.color )
	end
	if EmbedData.Player then
		EmbedData.author = {
			name = EmbedData.Player.Name,
			url = string.format(Roblox_Users, EmbedData.Player.UserId),
			icon_url = HttpService:GetAsync( string.format(Thumbnail_Proxy, EmbedData.Player.UserId) )
		}
		if not EmbedData.color then
			EmbedData.color = self:Color3ToHex( self:GetPlayerChatColor(EmbedData.Player.Name) )
		end
		EmbedData.Player = nil
	end
	self:PostData({
		embeds = {EmbedData}
	})
end

function Webhook:Message(Text: string)
	self:PostData({
		content = Text
	})
end

function Webhook:Delete()
	self'Message''Being to be Deleted'
	HttpService:RequestAsync({
		Url = string.format(Discord_Proxy, self.ID, self.Token),
		Method = 'DELETE',
		Headers = {
			["Content-Type"] = "application/x-www-form-urlencoded"
		},
	})
end

function Webhook:Modify(Data)
	HttpService:RequestAsync({
		Url = string.format(Discord_Proxy, self.ID, self.Token),
		Method = 'PATCH',
		Headers = {
			["Content-Type"] = "application/json"
		},
		Body = HttpService:JSONEncode(Data)
	})
end

local _Module = {}

function _Module.new(ID, Token)
	local self = {}
	self.__index, self.ID, self.Token = self, ID, Token
	
	self.__call = function(t, fName)
		return function(...)
			local args = ...
			local Succes, Error = pcall(function()
				t[fName](t, args)
			end)
			if not Succes then
				error(Error)
			end
		end
	end
	
	return setmetatable( Webhook, self )
end

return _Module
