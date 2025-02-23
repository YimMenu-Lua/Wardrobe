local outfit_editor_tab = gui.get_tab("GUI_TAB_OUTFIT_EDITOR")

local WARDROBE_DATA = 185 -- 3A ? 33 2C + 1

local is_started_by_us = false

is_safe_to_run_wardrobe_patch      = scr_patch:new("wardrobe_mp", "ISTRWP", "2C 01 00 40 2C 05 02 69 06 56 1C 07", 0, {0x72, 0x2E, 0x05, 0x01})
should_trigger_wardrobe_menu_patch = scr_patch:new("wardrobe_mp", "STWMP", "56 22 00 71", 0, {0x2B, 0x00, 0x00})
does_player_own_item_patch         = scr_patch:new("wardrobe_mp", "DPOIP", "57 D2 00 38 08", 0, {0x55}) -- Make all the clothes available

is_safe_to_run_wardrobe_patch:disable_patch()
should_trigger_wardrobe_menu_patch:disable_patch()
does_player_own_item_patch:disable_patch()

local function CLEANUP_WARDROBE_SCRIPT()
    is_safe_to_run_wardrobe_patch:disable_patch()
    should_trigger_wardrobe_menu_patch:disable_patch()
    does_player_own_item_patch:disable_patch()

    local data = locals.get_pointer("wardrobe_mp", WARDROBE_DATA)
    scr_function.call_script_function("wardrobe_mp", "CWS", "2D 01 03 00 00 38 00 41 E3", "void", {
        { "ptr", data }
    })
end

event.register_handler(menu_event.ScriptsReloaded, function()
    is_safe_to_run_wardrobe_patch:disable_patch()
    should_trigger_wardrobe_menu_patch:disable_patch()
    does_player_own_item_patch:disable_patch()
end)

script.register_looped("Wardrobe", function()
    if not script.is_active("wardrobe_mp") then
        is_started_by_us = false
        return
    end

    if is_started_by_us and locals.get_int("wardrobe_mp", WARDROBE_DATA + 46 + 9) == 4 then
        CLEANUP_WARDROBE_SCRIPT()
        is_started_by_us = false
    end
end)

outfit_editor_tab:add_button("Open Wardrobe", function()
    script.run_in_fiber(function(sc)
        if network.is_session_started() and not script.is_active("wardrobe_mp") and MISC.GET_NUMBER_OF_FREE_STACKS_OF_THIS_SIZE(2324) > 0 then
            repeat
                SCRIPT.REQUEST_SCRIPT("wardrobe_mp")
                sc:yield()
            until SCRIPT.HAS_SCRIPT_LOADED("wardrobe_mp")
            local wardrobe_launcher      = memory.allocate(32)
            local wardrobe_launcher_addr = wardrobe_launcher:get_address()
            wardrobe_launcher:set_qword(7) -- Wardrobe type online
            wardrobe_launcher = wardrobe_launcher:add(8)
            wardrobe_launcher:set_float(self.get_pos().x) -- Wardrobe pos X
            wardrobe_launcher = wardrobe_launcher:add(8)
            wardrobe_launcher:set_float(self.get_pos().y) -- Wardrobe pos Y
            wardrobe_launcher = wardrobe_launcher:add(8)
            wardrobe_launcher:set_float(self.get_pos().z) -- Wardrobe pos Z
            wardrobe_launcher = wardrobe_launcher:add(8)
            wardrobe_launcher:set_float(0.0) -- Wardrobe pos heading
            local thread = SYSTEM.START_NEW_SCRIPT_WITH_ARGS("wardrobe_mp", wardrobe_launcher_addr, 5, 2324)
            SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("wardrobe_mp")
            --memory.free(wardrobe_launcher)
            if thread > 0 then
                sc:sleep(1000) 
                is_safe_to_run_wardrobe_patch:enable_patch()
                should_trigger_wardrobe_menu_patch:enable_patch()
                does_player_own_item_patch:enable_patch()
                is_started_by_us = true
            else
                gui.show_error("Wardrobe", "Failed to start the wardrobe.")
            end
        else
            gui.show_error("Wardrobe", "Not safe to start the wardrobe at the moment.")
        end
    end)
end)