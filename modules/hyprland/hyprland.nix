{ config, pkgs, lib, ... }:

let
  cfg = config.hyprland;
  terminal = "ghostty";

  flameshot = config.services.flameshot.package;

  # Mirrors the quickshell wallpaper restore: saved wallpaper first, default as a fallback.
  startWallpaper = pkgs.writeShellScript "hyprland-start-wallpaper" ''
    stateFile="${config.home.homeDirectory}/.config/quickshell/wallpaper-state"
    defaultWallpaper="${config.home.homeDirectory}/Pictures/Wallpapers/wallhaven-6llkol.png"

    ${pkgs.awww}/bin/awww-daemon &
    sleep 1

    if [ -r "$stateFile" ]; then
      IFS= read -r wallpaper < "$stateFile"
    fi
    [ -f "$wallpaper" ] || wallpaper="$defaultWallpaper"

    exec set-wallpaper "$wallpaper"
  '';

  startQuickshell = pkgs.writeShellScript "hyprland-start-quickshell" ''
    export XDG_CONFIG_HOME="$HOME/.config"
    export QT_PLUGIN_PATH="${pkgs.qt6.qtimageformats}/lib/qt-6/plugins"
    exec ${pkgs.quickshell}/bin/quickshell --config desktop-shell
  '';
in
{
  options.hyprland.extraConfig = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host specific Lua appended to hyprland.lua (monitors, env, workspaces, startup).";
  };

  config = {
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # The compositor itself comes from the NixOS module (programs.hyprland); this only writes
  # the config. Autostart goes through hyprland.start instead of systemd units so the
  # session can run next to Sway without touching its sway-session.target services.
  xdg.configFile."hypr/hyprland.lua".text = ''
    local terminal = "${terminal}"
    local mod = "SUPER"

    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
    hl.env("XCURSOR_THEME", "Adwaita")
    hl.env("XCURSOR_SIZE", "24")

    -- AUTOSTART --
    hl.on("hyprland.start", function()
        hl.exec_cmd("${startWallpaper}")
        hl.exec_cmd("${startQuickshell}")
        hl.exec_cmd("vicinae server")
    end)

    -- LOOK AND FEEL --
    hl.config({
        general = {
            gaps_in = 4,
            gaps_out = 8,
            border_size = 1,
            col = {
                active_border = "rgb(774c81)",
                inactive_border = "rgb(392a48)",
            },
            layout = "dwindle",
        },

        decoration = {
            rounding = 8,
            shadow = { enabled = false },
            blur = { enabled = false },
        },

        animations = { enabled = false },

        dwindle = { preserve_split = true },

        misc = {
            disable_hyprland_logo = true,
            force_default_wallpaper = 0,
            vrr = 1,
        },

        cursor = { no_hardware_cursors = true },

        input = {
            kb_layout = "us",
            kb_variant = "intl",
            kb_options = "caps:escape,escape:none",
            follow_mouse = 1,
        },
    })

    -- FULLSCREEN --
    -- Apps asking for fullscreen are maximized below the bar and told they are fullscreen
    -- (so browsers still hide their chrome). Videos, games and players keep covering the bar.
    local coverClasses = { "^mpv$", "^vlc$", "^steam_app_", "^gamescope", "^Minecraft", "flameshot" }
    local forcedCover = {}

    local function coversBar(w)
        if forcedCover[w.address] then return true end
        if w.content_type == "video" or w.content_type == "game" then return true end
        for _, pattern in ipairs(coverClasses) do
            if string.find(w.class, pattern) then return true end
        end
        return false
    end

    hl.on("window.fullscreen", function(w)
        if w == nil then return end
        if w.fullscreen == 0 then
            forcedCover[w.address] = nil
            return
        end
        if w.fullscreen == 2 and not coversBar(w) then
            hl.dispatch(hl.dsp.window.fullscreen_state({
                window = "address:" .. w.address,
                internal = 1,
                client = 2,
            }))
        end
    end)

    -- KEYBINDINGS --
    hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
    hl.bind(mod .. " + D", hl.dsp.exec_cmd("vicinae toggle"))
    hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("${flameshot}/bin/flameshot gui"))
    hl.bind("ALT + SHIFT + Q", hl.dsp.window.close())
    hl.bind("ALT + L", hl.dsp.exec_cmd("qs ipc call session lock"))
    hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))

    -- Windows that asked for fullscreen sit in the maximized state (see above), so a plain
    -- toggle would re-enter fullscreen instead of leaving it. Leave explicitly when not normal.
    local function toggleFullscreen(forceCover)
        local w = hl.get_active_window()
        if w == nil then return end
        if w.fullscreen ~= 0 then
            hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
            return
        end
        if forceCover then forcedCover[w.address] = true end
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen" }))
    end

    hl.bind(mod .. " + F", function() toggleFullscreen(false) end)
    hl.bind(mod .. " + SHIFT + F", function() toggleFullscreen(true) end)
    hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + V", hl.dsp.layout("togglesplit"))

    local directions = { H = "left", J = "down", K = "up", L = "right" }
    for key, direction in pairs(directions) do
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
    end

    local resizes = {
        H = { x = -40, y = 0 }, L = { x = 40, y = 0 },
        K = { x = 0, y = -40 }, J = { x = 0, y = 40 },
    }
    for key, delta in pairs(resizes) do
        hl.bind(mod .. " + CTRL + " .. key,
            hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true }),
            { repeating = true })
    end

    for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +10%"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

    -- WINDOW RULES --
    hl.window_rule({
        name = "flameshot-fullscreen",
        match = { class = "[Ff]lameshot" },
        float = true,
        fullscreen = true,
    })

    hl.window_rule({
        name = "suppress-maximize-events",
        match = { class = ".*" },
        suppress_event = "maximize",
    })

    ${cfg.extraConfig}
  '';
  };
}
