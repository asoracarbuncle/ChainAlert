-- Addon information
_addon.name = 'ChainAlert'
_addon.author = 'Asora'
_addon.version = '0.2.2'
_addon.commands = {'ca','chainalert'}

-- Included libraries
config = require('config')
packets = require('packets')
texts = require('texts')

-- Setup defaults
defaults = {}
defaults.text_box = {}
defaults.text_box.text = {}
defaults.text_box.text.color = {}
defaults.text_box.text.color.r = 255
defaults.text_box.text.color.g = 255
defaults.text_box.text.color.b = 255
defaults.text_box.text.size = 11
defaults.text_box.alpha = 255
defaults.text_box.pos = {}
defaults.text_box.pos.x = 256
defaults.text_box.pos.y = 256
settings = config.load(defaults)

-- Initialize some global variables
alert_gearswap = false
text_box_header = _addon.name.." v".._addon.version.."\n"
text_box_body = "Listening...\n"

-- Initialize the textbox
text_box = texts.new(text_box_header..text_box_body)
texts.color(text_box, defaults.text_box.text.color.r, defaults.text_box.text.color.g, defaults.text_box.text.color.b)
texts.size(text_box, defaults.text_box.text.size)
texts.size(text_box, defaults.text_box.text.size)
texts.pos_x(text_box, defaults.text_box.pos.x)
texts.pos_y(text_box, defaults.text_box.pos.y)
texts.bg_alpha(text_box, defaults.text_box.alpha)
text_box:show()


----------------------------------------------------------------------
-- Refresh the plaque
----------------------------------------------------------------------
function refresh_text_box(body)
    texts.text(text_box,text_box_header..body)
end


----------------------------------------------------------------------
-- Add Command Listener
----------------------------------------------------------------------
windower.register_event('addon command', function(...)
    local args = T{...}
    if args ~= nil then
        local comm = table.remove(args,1):lower()
        if comm == 'gearswap' then
            if alert_gearswap == true then
                alert_gearswap = false
                windower.add_to_chat(207, "ChainAlert: Gearswap alert OFF")
            else
                alert_gearswap = true
                windower.add_to_chat(207, "ChainAlert: Gearswap alert ON")
            end
        elseif comm == 'help' then
            local helptext = [[ChainAlert - Command List:
1. gearswap - Allows the addon to alert gearswap that a burst is occurring.
2. help --Shows this menu.]]
            for _, line in ipairs(helptext:split('\n')) do
                windower.add_to_chat(207, line)
            end
        end
    end
end)


----------------------------------------------------------------------
-- Skillchain table
----------------------------------------------------------------------
skillchains = {
    [288] = 'Light',
    [289] = 'Darkness',
    [290] = 'Gravitation',
    [291] = 'Fragmentation',
    [292] = 'Distortion',
    [293] = 'Fusion',
    [294] = 'Compression',
    [295] = 'Liquefaction',
    [296] = 'Induration',
    [297] = 'Reverberation',
    [298] = 'Transfixion',
    [299] = 'Scission',
    [300] = 'Detonation',
    [301] = 'Impaction',
    [385] = 'Light',
    [386] = 'Darkness',
    [387] = 'Gravitation',
    [388] = 'Fragmentation',
    [389] = 'Distortion',
    [390] = 'Fusion',
    [391] = 'Compression',
    [392] = 'Liquefaction',
    [393] = 'Induration',
    [394] = 'Reverberation',
    [395] = 'Transfixion',
    [396] = 'Scission',
    [397] = 'Detonation',
    [398] = 'Impaction',
    [767] = 'Radiance',
    [768] = 'Umbra',
    [769] = 'Radiance',
    [770] = 'Umbra',
}

skillchain_info = {
    ["Light"] = "Tier: III\nAlignment: Fire, Wind, Thunder & Light\nFollow With: Light",
    ["Darkness"] = "Tier: III\nAlignment: Ice, Stone, Water & Dark\nFollow With: Darkness",
    ["Gravitation"] = "Tier: II\nAlignment: Stone & Dark\nFollow With: Distortion or Fragmentation",
    ["Fragmentation"] = "Tier: II\nAlignment: Thunder & Wind\nFollow With: Distortion or Fusion",
    ["Distortion"] = "Tier: II\nAlignment: Ice & Water\nFollow With: Fusion or Gravitation",
    ["Fusion"] = "Tier: II\nAlignment: Fire & Light\nFollow With: Fragmentation or Gravitation",
    ["Compression"] = "Tier: I\nAlignment: Dark\nFollow With: Detonation or Transfixion",
    ["Liquefaction"] = "Tier: I\nAlignment: Fire\nFollow With: Impaction or Scission",
    ["Induration"] = "Tier: I\nAlignment: Ice\nFollow With: Compression, Impaction, or Reverberation",
    ["Reverberation"] = "Tier: I\nAlignment: Water\nFollow With: Induration or Impaction",
    ["Transfixion"] = "Tier: I\nAlignment: Light\nFollow With: Compression, Reverberation or Scission",
    ["Scission"] = "Tier: I\nAlignment: Earth\nFollow With: Detonation, Liquefaction or Reverberation",
    ["Detonation"] = "Tier: I\nAlignment: Wind\nFollow With: Compression or Scission",
    ["Impaction"] = "Tier: I\nAlignment: Thunder\nFollow With: Liquefaction or Detonation",
    ["Radiance"] = "Tier: IV\nAlignment: Fire, Wind, Thunder & Light\nFollow With: None",
    ["Umbra"] = "Tier: IV\nAlignment: Ice, Stone, Water & Dark\nFollow With: None",
}


----------------------------------------------------------------------
-- Add Incoming Chunk Event Listener
----------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    -- Trim down the list of packets to filter
    if id == 0x028 then
        -- Attempt to get the currently targeted mob id
        local target = windower.ffxi.get_mob_by_target('t')
        -- Check if there is a current target
        if target then
            -- Parse the incoming packet
            local packet = packets.parse('incoming', original)
            -- Make sure we only continue if our target matches the packet target
            if target.id == packet['Target 1 ID'] then
                -- Ensure the packet action is something that can cause a chain
                if packet['Category'] == 3 or packet['Category'] == 4 then
                    -- Check if the added effect message is a skillchain
                    local added_effect_message_id = packet['Target 1 Action 1 Added Effect Message']
                    if skillchains[added_effect_message_id] then
                        local last_skillchain = skillchains[added_effect_message_id]
                        refresh_text_box("Skillchain: "..last_skillchain.."\n"..skillchain_info[last_skillchain])
                        if alert_gearswap == true then
                            windower.send_command('gs c toggle burst mode on')
                        end
                        coroutine.sleep(9)
                        refresh_text_box(text_box_body)
                        if alert_gearswap == true then
                            windower.send_command('gs c toggle burst mode off')
                        end
                    end
                end
            end
        end
    end
end)


----------------------------------------------------------------------
-- Add Command Listener
----------------------------------------------------------------------
windower.register_event('addon command', function(...)
    local args = T{...}
    if args ~= nil then
        local comm = table.remove(args,1):lower()
        if comm == 'gearswap' then
            if alert_gearswap == true then
                alert_gearswap = false
                windower.add_to_chat(207, "ChainAlert: Gearswap alert OFF")
            else
                alert_gearswap = true
                windower.add_to_chat(207, "ChainAlert: Gearswap alert ON")
            end
        elseif comm == 'help' then
            local helptext = [[ChainAlert - Command List:
1. gearswap - Allows the addon to alert gearswap that a burst is occurring.
2. help --Shows this menu.]]
            for _, line in ipairs(helptext:split('\n')) do
                windower.add_to_chat(207, line)
            end
        end
    end
end)
