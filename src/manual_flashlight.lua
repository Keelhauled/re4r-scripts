local key_name = "X"

local keyboard_singleton = sdk.get_native_singleton("via.hid.Keyboard")
local keyboard_typedef = sdk.find_type_definition("via.hid.Keyboard")
local keyboardkey_typedef = sdk.find_type_definition("via.hid.KeyboardKey")
local light_switch_zone_manager = sdk.get_managed_singleton("chainsaw.LightSwitchZoneManager")
local character_manager = sdk.get_managed_singleton("chainsaw.CharacterManager")

local light_state = false
local allow_change = false

local function get_player_id()
    player = character_manager:call("getPlayerContextRef")
    if player ~= nil then
        return player:get_field("<KindID>k__BackingField")
    end
    return -1
end

local function prevent_auto_switch(args)
    local id = sdk.to_int64(args[3])
    if not allow_change and id == get_player_id() then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    allow_change = false
end

sdk.hook(
    light_switch_zone_manager.notifyLightSwitch,
    prevent_auto_switch,
    function(x) return x end
)

re.on_frame(function()
    local kb = sdk.call_native_func(keyboard_singleton, keyboard_typedef, "get_Device")
    local isButtonRelease = kb:call("isRelease", keyboardkey_typedef:get_field(key_name):get_data(nil))

    if isButtonRelease then
        id = get_player_id()
        if id == -1 then
            return
        end
        allow_change = true
        light_state = not light_state
        light_switch_zone_manager:notifyLightSwitch(id, light_state)
    end
end)
