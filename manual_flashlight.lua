local metatable = (function()
    -- Metatable magic by Stracker

    local create_namespace
    local namespace_functions = {}

    ---@param self Namespace
    function namespace_functions.T(self)
        return function(ns) return ns._typedef end
    end

    ---@param self Namespace
    function namespace_functions.Instance(self)
        return sdk.get_managed_singleton(self._name)
    end

    local namespace_builder_metatable = {
        ---@param name string
        __index = function(self, name)
            -- Fallback for fields that can't be taken as symbols
            if namespace_functions[name] then
                return namespace_functions[name](self)
            end
            local typedef = rawget(self, "_typedef")
            if typedef then
                local field = typedef:get_field(name)
                if field then
                    if field:is_static() then
                        return field:get_data()
                    end
                    return field
                end

                local method = typedef:get_method(name)
                if method then
                    return method
                end
            end
            local force = false
            if name:sub(1, 2) == "__" then
                name  = name:sub(3)
                force = true
            end
            return create_namespace(rawget(self, "_name") .. "." .. name, force)
        end
    }

    create_namespace = function(basename, force_namespace)
        force_namespace = force_namespace or false

        ---@class Namespace
        local table = { _name = basename }
        if sdk.find_type_definition(basename) and not force_namespace then
            table = { _typedef = sdk.find_type_definition(basename), _name = basename }
        else
            table = { _name = basename }
        end
        return setmetatable(table, namespace_builder_metatable)
    end

    return setmetatable({}, { __index = function(self, name)
        return create_namespace(name)
    end })
end)()

local keyboard_singleton = sdk.get_native_singleton("via.hid.Keyboard")
local keyboard_type_def = sdk.find_type_definition("via.hid.Keyboard")
local lszm = sdk.get_managed_singleton("chainsaw.LightSwitchZoneManager")
local light_state = false
local do_change = false
local player_id = 100000

local function prevent_auto_switch(args)
    local id = sdk.to_int64(args[3])
    local nextCondition = (sdk.to_int64(args[4]) & 1) == 1
    
    if do_change then
        do_change = false
        return sdk.PreHookResult.CALL_ORIGINAL
    elseif id == player_id then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end

local function empty_post_func(retval)
    return retval
end

sdk.hook(
    metatable.chainsaw.LightSwitchZoneManager.notifyLightSwitch,
    prevent_auto_switch,
    empty_post_func
)

re.on_frame(function()
    local kb = sdk.call_native_func(keyboard_singleton, keyboard_type_def, "get_Device")
    local test = kb:call("isRelease", metatable.via.hid.KeyboardKey.X)

    if test then
        do_change = true
        light_state = not light_state
        lszm:notifyLightSwitch(player_id, light_state)
    end
end)
