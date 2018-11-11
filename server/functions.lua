ESX.Trace = function(str)
	if Config.EnableDebug then
		print('ESX> ' .. str)
	end
end

ESX.SetTimeout = function(msec, cb)
	local id = ESX.TimeoutCount + 1

	SetTimeout(msec, function()
		if ESX.CancelledTimeouts[id] then
			ESX.CancelledTimeouts[id] = nil
		else
			cb()
		end
	end)

	ESX.TimeoutCount = id

	return id
end

ESX.ClearTimeout = function(id)
	ESX.CancelledTimeouts[id] = true
end

ESX.RegisterServerCallback = function(name, cb)
	ESX.ServerCallbacks[name] = cb
end

ESX.TriggerServerCallback = function(name, requestId, source, cb, ...)
	if ESX.ServerCallbacks[name] ~= nil then
		ESX.ServerCallbacks[name](source, cb, ...)
	else
		print('es_extended: TriggerServerCallback => [' .. name .. '] does not exist')
	end
end

ESX.SavePlayer = function(xPlayer, cb)
	local asyncTasks     = {}
	xPlayer.lastPosition = xPlayer.get('coords')

	-- User accounts
	for i=1, #xPlayer.accounts, 1 do

		if ESX.LastPlayerData[xPlayer.source].accounts[xPlayer.accounts[i].name] ~= xPlayer.accounts[i].money then

			table.insert(asyncTasks, function(cb)
				MySQL.Async.execute('UPDATE user_accounts SET `money` = @money WHERE identifier = @identifier AND name = @name',
				{
					['@money']      = xPlayer.accounts[i].money,
					['@identifier'] = xPlayer.identifier,
					['@name']       = xPlayer.accounts[i].name
				}, function(rowsChanged)
					cb()
				end)
			end)

			ESX.LastPlayerData[xPlayer.source].accounts[xPlayer.accounts[i].name] = xPlayer.accounts[i].money

		end

	end

	-- Inventory items
	for i=1, #xPlayer.inventory, 1 do

		if ESX.LastPlayerData[xPlayer.source].items[xPlayer.inventory[i].name] ~= xPlayer.inventory[i].count then

			table.insert(asyncTasks, function(cb)
				MySQL.Async.fetchAll('SELECT active_char_id FROM users WHERE identifier = @identifier', {
					['@identifier'] = xPlayer.identifier
				}, function(user)
					active_char_id = user[1].active_char_id

					MySQL.Async.execute('UPDATE character_inventory SET `count` = @count WHERE identifier = @identifier AND item = @item AND skin_id = @skin_id',
					{
						['@count']      = xPlayer.inventory[i].count,
						['@identifier'] = xPlayer.identifier,
						['@item']       = xPlayer.inventory[i].name,
						['@item']       = xPlayer.inventory[i].name,
						['@skin_id']       = active_char_id

					}, function(rowsChanged)
						cb()
					end)

			    end)
			end)

			ESX.LastPlayerData[xPlayer.source].items[xPlayer.inventory[i].name] = xPlayer.inventory[i].count

		end

	end

	-- Job, loadout and position
	table.insert(asyncTasks, function(cb)
		MySQL.Async.execute('UPDATE users SET `job` = @job, `job_grade` = @job_grade, `loadout` = @loadout, `position` = @position WHERE identifier = @identifier',
		{
			['@job']        = xPlayer.job.name,
			['@job_grade']  = xPlayer.job.grade,
			['@loadout']    = json.encode(xPlayer.loadout),
			['@position']   = json.encode(xPlayer.lastPosition),
			['@identifier'] = xPlayer.identifier
		}, function(rowsChanged)
			cb()
		end)
	end)

	Async.parallel(asyncTasks, function(results)
		RconPrint('[SAVED] ' .. xPlayer.name .. "\n")

		if cb ~= nil then
			cb()
		end
	end)

end

ESX.SavePlayers = function(cb)
	local asyncTasks = {}
	local xPlayers   = ESX.GetPlayers()

	for i=1, #xPlayers, 1 do
		table.insert(asyncTasks, function(cb)
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
			ESX.SavePlayer(xPlayer, cb)
		end)
	end

	Async.parallelLimit(asyncTasks, 8, function(results)
		RconPrint('[SAVED] All players' .. "\n")

		if cb ~= nil then
			cb()
		end
	end)
end

ESX.StartDBSync = function()
	function saveData()
		ESX.SavePlayers()
		SetTimeout(10 * 60 * 1000, saveData)
	end

	SetTimeout(10 * 60 * 1000, saveData)
end

ESX.GetPlayers = function()
	local sources = {}

	for k,v in pairs(ESX.Players) do
		table.insert(sources, k)
	end

	return sources
end


ESX.GetPlayerFromId = function(source)
	return ESX.Players[tonumber(source)]
end

ESX.GetPlayerFromIdentifier = function(identifier)
	for k,v in pairs(ESX.Players) do
		if v.identifier == identifier then
			return v
		end
	end
end

ESX.RegisterUsableItem = function(item, cb)
	ESX.UsableItemsCallbacks[item] = cb
end

ESX.UseItem = function(source, item)
	ESX.UsableItemsCallbacks[item](source)
end

ESX.GetItemLabel = function(item)
	if ESX.Items[item] ~= nil then
		return ESX.Items[item].label
	end
end

ESX.GetWeaponList = function()
	return Config.Weapons
end

ESX.GetWeaponLabel = function(name)
	name          = string.upper(name)
	local weapons = ESX.GetWeaponList()

	for i=1, #weapons, 1 do
		if weapons[i].name == name then
			return weapons[i].label
		end
	end
end

ESX.CreatePickup = function(type, name, count, label, player)
	local pickupId = (ESX.PickupId == 65635 and 0 or ESX.PickupId + 1)

	ESX.Pickups[pickupId] = {
		type  = type,
		name  = name,
		count = count
	}

	TriggerClientEvent('esx:pickup', -1, pickupId, label, player)
	ESX.PickupId = pickupId
end
