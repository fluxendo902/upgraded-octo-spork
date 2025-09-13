getgenv().filtergc = function(filterType, filterOptions, returnOne)
	local matches = {}

    if typeof(filterType) == "function" then
        local matches = {}
        
        for i, v in getgc(true) do
            local success, passed = pcall(filterType, v)
            if success and passed then
				if returnOne then
					return v
				else
                	table.insert(matches, v)
				end
            end
        end

	elseif filterType == "table" then
        for i, v in getgc(true) do
            if typeof(v) ~= "table" then
                continue
            end
            
            local passed = true
            
            if filterOptions.Keys and typeof(filterOptions.Keys) == "table" and passed then
                for _, key in filterOptions.Keys do
                    if rawget(v, key) == nil then
                        passed = false
                        break
                    end
                end
            end
            
            if filterOptions.Values and typeof(filterOptions.Values) == "table" and passed then
                local tableVals = {}
                for _, value in next, v do
                    table.insert(tableVals, value)
                end
                for _, value in filterOptions.Values do
                    if not table.find(tableVals, value) then
                        passed = false
                        break
                    end
                end
            end
            if filterOptions.KeyValuePairs and typeof(filterOptions.KeyValuePairs) == "table" and passed then
                for key, value in filterOptions.KeyValuePairs do
                    if rawget(v, key) ~= value then
                        passed = false
                        break
                    end
                end
            end
            
            if filterOptions.Metatable and passed then
                local success, mt = pcall(getrawmetatable, v)
                if success then
                    passed = filterOptions.Metatable == mt
                else
                    passed = false
                end
            end
            
            if passed then
                if returnOne then
                    return v
                else
                    table.insert(matches, v)
                end
            end
        end
        
    elseif filterType == "function" then
        if filterOptions.IgnoreExecutor == nil then
            filterOptions.IgnoreExecutor = true
        end
        
        for i, v in getgc(false) do
            if typeof(v) ~= "function" then
                continue
            end
            
            local passed = true
            local isCClosure = iscclosure(v)

            if filterOptions.Name and passed then
                local success, funcName = pcall(function()
                    return debug.info(v, "n")
                end)

                if success and funcName then
                    passed = funcName == filterOptions.Name
                else
                    local success2, funcString = pcall(function()
                        return tostring(v)
                    end)
                    if success2 and funcString then
                        passed = string.find(funcString, filterOptions.Name) ~= nil
                    else
                        passed = false
                    end
                end
            end
            
            if filterOptions.IgnoreExecutor == true and passed then
                local success, isExec = pcall(function() return isexecutorclosure(v) end)
                if success then
                    passed = not isExec
                else
                    passed = true
                end
            end

            if isCClosure and (filterOptions.Hash or filterOptions.Constants or filterOptions.Upvalues) then
                passed = false
            end

            if not isCClosure and passed then
                if filterOptions.Hash and passed then
                    local success, hash = pcall(function()
                        return getfunctionhash(v) or ""
                    end)
                    if success and hash then
                        passed = hash == filterOptions.Hash
                    else
                        passed = false
                    end
                end
                
                if filterOptions.Constants and typeof(filterOptions.Constants) == "table" and passed then
                    local success, constants = pcall(function()
                        return debug.getconstants(v) or {}
                    end)

                    if success and constants then
                        local funcConsts = {}
                        for idx, constant in constants do
                            if constant ~= nil then
                                table.insert(funcConsts, constant)
                            end
                        end
                        for _, constant in filterOptions.Constants do
                            if not table.find(funcConsts, constant) then
                                passed = false
                                break
                            end
                        end
                    else
                        passed = false
                    end
                end
                
                if filterOptions.Upvalues and typeof(filterOptions.Upvalues) == "table" and passed then
                    local success, upvalues = pcall(function()
                        return debug.getupvalues(v) or {}
                    end)

                    if success and upvalues then
                        local funcUpvals = {}
                        for idx, upval in upvalues do
                            if upval ~= nil then
                                table.insert(funcUpvals, upval)
                            end
                        end
                        for _, upval in filterOptions.Upvalues do
                            if not table.find(funcUpvals, upval) then
                                passed = false
                                break
                            end
                        end
                    else
                        passed = false
                    end
                end
            end
            
            if passed then
                if returnOne then
                    return v
                else
                    table.insert(matches, v)
                end
            end
        end
        
    else
        error("Expected type 'function' or 'table', got '" .. tostring(filterType) .. "'")
    end
    
    return returnOne and nil or matches
end
