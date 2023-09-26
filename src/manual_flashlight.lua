local keyboard_key_name = "X"
local gamepad_key_name = "RStickPush"


local keyboard_singleton = sdk.get_native_singleton("via.hid.Keyboard")
local keyboard_typedef = sdk.find_type_definition("via.hid.Keyboard")
local keyboardkey_typedef = sdk.find_type_definition("via.hid.KeyboardKey")
local gamepad_singleton = sdk.get_native_singleton("via.hid.GamePad")
local gamepad_typedef = sdk.find_type_definition("via.hid.GamePad")
local gamepadbutton_typedef = sdk.find_type_definition("via.hid.GamePadButton")

local kb_button_data = keyboardkey_typedef:get_field(keyboard_key_name):get_data(nil)
local gp_button_data = gamepadbutton_typedef:get_field(gamepad_key_name):get_data(nil)
local kb = sdk.call_native_func(keyboard_singleton, keyboard_typedef, "get_Device")
local gp = sdk.call_native_func(gamepad_singleton, gamepad_typedef, "get_Device")

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
    local kb_button_release = kb:call("isRelease", kb_button_data)
    local gb_button_release = gp:call("isRelease", gp_button_data)

    if kb_button_release or gb_button_release then
        id = get_player_id()
        if id == -1 then
            return
        end
        allow_change = true
        light_state = not light_state
        light_switch_zone_manager:notifyLightSwitch(id, light_state)
    end
end)
