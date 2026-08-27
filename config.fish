# ---------------------------------------------------------
# GREETING
# ---------------------------------------------------------

function __core_check_deps
    set -l core curl jq fzf bat
    set -l missing

    for cmd in $core
        if not command -q $cmd
            set -a missing $cmd
        end
    end

    if test (count $missing) -eq 0
        return 0
    end

    set_color $accent
    echo "Missing core packages: "(string join ", " $missing)
    set_color normal
    read -P "Install them now with pacman? [y/N] " answer
    if string match -qr '^[yY]' -- $answer
        sudo pacman -S --needed --noconfirm $missing
        or return 1
    else
        return 1
    end
    return 0
end

function fish_greeting

    __core_check_deps
    or return 1

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    test -n "$accent"; or set accent normal
    test -n "$foreground"; or set foreground normal

    set -l cache_dir ~/.cache/pkw
    set -l cache_age 1800
    mkdir -p $cache_dir

    set -l info_cache $cache_dir/ipinfo
    set -l info

    if test -f $info_cache
        set -l cache_time (stat -c %Y $info_cache)
        set -l current_time (date +%s)

        if test (math $current_time - $cache_time) -lt $cache_age
            set info (cat $info_cache)
        end
    end

    if test -z "$info"
        set info (curl -s --max-time 2 ipinfo.io/json)

        if test $status -eq 0; and test -n "$info"
            printf "%s" "$info" >$info_cache
        else if test -f $info_cache
            set info (cat $info_cache)
        end
    end

    set -l ip (echo $info | jq -r '.ip // "Unknown"')
    set -l country (echo $info | jq -r '.country // "Unknown"')
    set -l city (echo $info | jq -r '.city // "Unknown"')
    set -l vpn_status (echo $info | jq -r '.privacy.vpn // "false"')

    set -l today (date "+%A, %B %d")

    set -l weather_cache $cache_dir/weather
    set -l weather

    if test -f $weather_cache
        set -l cache_time (stat -c %Y $weather_cache)
        set -l current_time (date +%s)

        if test (math $current_time - $cache_time) -lt $cache_age
            set weather (cat $weather_cache)
        end
    end

    if test -z "$weather"
        set weather (curl -s --max-time 2 'wttr.in/?format=%C+%t' 2>/dev/null)

        if test $status -eq 0; and test -n "$weather"
            printf "%s" "$weather" >$weather_cache
        else if test -f $weather_cache
            set weather (cat $weather_cache)
        else
            set weather Unavailable
        end
    end

    set -l tor_cache $cache_dir/tor
    set -l tor_status

    if test -f $tor_cache
        set -l cache_time (stat -c %Y $tor_cache)
        set -l current_time (date +%s)

        if test (math $current_time - $cache_time) -lt $cache_age
            set tor_status (cat $tor_cache)
        end
    end

    if test -z "$tor_status"
        set tor_status (curl -s --max-time 2 \
            --socks5 127.0.0.1:1337 \
            https://check.torproject.org/api/ip 2>/dev/null |
            jq -r '.IsTor // "false"')

        if test $status -eq 0; and test -n "$tor_status"
            printf "%s" "$tor_status" >$tor_cache
        else
            set tor_status false
        end
    end

    set -l cache_times

    for cache_file in $info_cache $weather_cache $tor_cache
        if test -f $cache_file
            set -a cache_times (stat -c %Y $cache_file)
        end
    end

    set -l cached_text "Cached: 0m ago"

    if test (count $cache_times) -gt 0
        set -l oldest_cache $cache_times[1]

        for cache_time in $cache_times
            if test $cache_time -lt $oldest_cache
                set oldest_cache $cache_time
            end
        end

        set -l elapsed (math (date +%s) - $oldest_cache)
        set -l cached_minutes (math "floor($elapsed / 60)")
        set cached_text "Cached: "$cached_minutes"m ago"
    end

    set -l greetings \
        "HACK THE PLANET! $USER!" \
        "$USER! $USER! you should totally write 'rm -rf ~/*' in your terminal or something!!11!!!!1" \
        "GIVE ME THAT DISTORTION! $USER!" \
        "Greetings, $USER!" \
        "Well well well, If it isn't $USER!" \
        "Ready to break the whole system again, $USER?" \
        "LEEENUX! I USE LEEEEEEEEEENUX! WAAAAAAAAAAAAH! | powered by: $USER" \
        "Formal_Greeting.txt, $USER!" \
        "Please stop torturing me, $USER" \
        "Here we go again.... What now, $USER?" \
        "With great power comes great responsibility, $USER." \
        "Please remember to save this config, $USER. It's very cool!!!!!" \
        "When will you actually remember your own commands, $USER?" \
        "Welcome, $USER!" \
        "Hello again, $USER!" \
        "Logged in as: $USER" \
        "THATS UBER BASED, $USER!" \
        "Thank you for using fishware, $USER!" \
        "$USER UBER ALLES!" \
        "$USER? Is that you?" \
        "1337 4 3/3|2, $USER!" \
        "No way! Is that $USER??!!11!!11!!" \
        "Remember to update your config, $USER!" \
        "Access Authorized! Welcome back, $USER."

    set -l quote $greetings[(random 1 (count $greetings))]

    set -l info_rows \
        "🗓  Date: $today" \
        "🏚  Currently in: $country, $city" \
        "☁  Weather: $weather"

    if test "$vpn_status" = true
        set -a info_rows "🕶 VPN: TRUE"
    else
        set -a info_rows "👁  VPN: FALSE"
    end

    if test "$tor_status" = true
        set -a info_rows "🗝  TOR: TRUE"
    else
        set -a info_rows "🗝  TOR: FALSE"
    end

    if test -f ~/.config/fish/personal.fish
        set -a info_rows "♥︎  Personal.fish: TRUE"
    else
        set -a info_rows "♥︎  Personal.fish: FALSE"
    end

    set -a info_rows "🕰  $cached_text"

    set -l content_width 0

    for row in $info_rows
        set -l length (string length --visible -- "$row")

        if string match -q "*☁ *" -- "$row"
            set length (math $length + 1)
        end

        if test $length -gt $content_width
            set content_width $length
        end
    end

    set -l quote_length (string length --visible -- "$quote")

    if test $quote_length -gt $content_width
        set content_width $quote_length
    end

    set -l info_category_length (string length --visible -- "── INFO")
    set -l greeting_category_length (string length --visible -- "── GREETING")

    test $info_category_length -le $content_width; or set content_width $info_category_length
    test $greeting_category_length -le $content_width; or set content_width $greeting_category_length

    set -l box_width (math $content_width + 4)
    set -l border (string repeat -n $box_width "─")

    printf "\n"

    set_color $accent
    printf "╭%s╮\n" "$border"
    printf "│  ── INFO"

    set -l padding (math $content_width - 7)

    if test $padding -gt 0
        set_color $foreground
        printf "%*s" $padding ""
    end

    set_color $accent
    printf "  │\n"

    for row in $info_rows
        set -l length (string length --visible -- "$row")

        if string match -q "*☁️*" -- "$row"
            set length (math $length + 1)
        end

        set padding (math $content_width - $length)

        set_color $accent
        printf "│  "
        set_color $foreground
        printf "%s" "$row"

        if test $padding -gt 0
            printf "%*s" $padding ""
        end

        set_color $accent
        printf "  │\n"
    end

    set_color $accent
    printf "│"
    set_color $foreground
    printf "%*s" $box_width ""
    set_color $accent
    printf "│\n"

    printf "│  ── GREETING"

    set padding (math $content_width - 11)

    if test $padding -gt 0
        set_color $foreground
        printf "%*s" $padding ""
    end

    set_color $accent
    printf "  │\n"

    set -l quote_length (string length --visible -- "$quote")
    set padding (math $content_width - $quote_length)

    set_color $accent
    printf "│  "
    set_color $foreground
    printf "%s" "$quote"

    if test $padding -gt 0
        printf "%*s" $padding ""
    end

    set_color $accent
    printf "  │\n"
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
    echo " 🛈  For a list of commands, type '!help' or '!h'"
end

# ---------------------------------------------------------
# PROMPT
# ---------------------------------------------------------

function fish_prompt
    if test $status -ne 0
        set_color red
        echo -n " ✘ "
        set_color normal
    else
        set_color normal
        echo -n " ➜ "
    end
end

# ---------------------------------------------------------
# SYSTEM
# ---------------------------------------------------------

function !upd
    # description: Update Arch Linux and installed packages
    # category: SYS
    sudo pacman -Syu --noconfirm
end

function !clean
    # description: Clean package cache and remove orphan packages
    # category: SYS

    echo "Removing orphan packages..."

    set -l orphans (pacman -Qtdq 2>/dev/null)

    if test (count $orphans) -gt 0
        sudo pacman -Rns $orphans
    else
        echo "No orphan packages found."
    end

    echo "Cleaning package cache..."
    sudo pacman -Sc
end

function !fs
    # description: Show failed systemd services
    # category: SYS
    systemctl --failed
end

function !ucfg
    # description: Update config from GitHub
    # category: SYS

    curl -fsSL \
        https://raw.githubusercontent.com/sudopkw/pkw-fishware/main/config.fish \
        -o ~/.config/fish/config.fish
end

function !cfgsource
    # description: Open config source
    # category: SYS
    xdg-open "https://github.com/sudopkw/pkw-fishware"
end

function !src
    # description: Source config
    # category: SYS
    source ~/.config/fish/config.fish
end

function !cc
    # description: Clear PKW cache
    # category: SYS

    rm -rf ~/.cache/pkw
    echo "Cache cleared."
end

# ---------------------------------------------------------
# MODULE MANAGER
# ---------------------------------------------------------

function !modules
    # description: Install, remove and manage Fish modules
    # category: SYS

    set -l repo sudopkw/pkw-fishware
    set -l api "https://api.github.com/repos/$repo/contents/modules"
    set -l module_dir ~/.config/fish/modules
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml

    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    if test -z "$accent"
        set accent normal
    end

    if test -z "$foreground"
        set foreground normal
    end

    set -l error_color red

    mkdir -p $module_dir

    if not command -q curl
        printf "curl is required.\n"
        return 1
    end

    if not command -q jq
        printf "jq is required: sudo pacman -S jq\n"
        return 1
    end

    set -l response (curl -fsSL "$api" 2>&1)

    if test $status -ne 0
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"

        set_color $foreground
        printf "│ Failed to retrieve module list. │\n"

        set_color $accent
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"

        return 1
    end

    set -l available (printf '%s\n' "$response" |
jq -r '  .[] | select(.type == "file") | select(.name | endswith(".fish")) | .name' 2>/dev/null)

    if test $status -ne 0
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"

        set_color $foreground
        printf "│ GitHub returned invalid module data. │\n"

        set_color $accent
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"

        return 1
    end

    if test (count $available) -eq 0
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"

        set_color $foreground
        printf "│ No modules are currently available. │\n"

        set_color $accent
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"

        return 0
    end

    while true
        set -l installed
        set -l uninstalled

        for module in $available
            if test -f "$module_dir/$module"
                set -a installed $module
            else
                set -a uninstalled $module
            end
        end

        set -l max_name_width 0

        for module in $installed $uninstalled
            set -l name (string replace '.fish' '' -- $module)
            set -l length (string length -- "$name")

            if test $length -gt $max_name_width
                set max_name_width $length
            end
        end

        set -l title " ── MODULES"
        set -l content_width (math $max_name_width + 20)

        if test $content_width -lt 38
            set content_width 38
        end

        set -l title_length (string length -- "$title")

        if test $title_length -gt $content_width
            set content_width $title_length
        end

        set -l inner_width (math $content_width + 2)
        set -l border (string repeat -n $inner_width "─")

        printf "\n"

        set_color $accent
        printf "╭%s╮\n" "$border"

        set_color $accent
        printf "│  ── MODULES"
        set -l title_padding (math $inner_width - 12)
        if test $title_padding -gt 0
            set_color $foreground
            printf "%*s" $title_padding ""
        end
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│"
        set_color $foreground
        printf "%*s" $inner_width ""
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│   ── INSTALLED"
        set -l header_padding (math $inner_width - 15)
        if test $header_padding -gt 0
            set_color $foreground
            printf "%*s" $header_padding ""
        end
        set_color $accent
        printf "│\n"

        if test (count $installed) -eq 0
            set_color $accent
            printf "│"
            set_color $foreground
            printf "   None installed"
            set -l padding (math $inner_width - 17)
            if test $padding -gt 0
                printf "%*s" $padding ""
            end
            set_color $accent
            printf "│\n"
        else
            set -l index 0

            for module in $installed
                set index (math $index + 1)

                set -l name (string replace '.fish' '' -- $module)

                set_color $accent
                printf "│   ["
                set_color $error_color
                printf "%s" "$index"
                set_color $accent
                printf "]"
                set_color $foreground
                printf " %-*s" $max_name_width "$name"

                set -l content_length (math 6 + (string length -- "$index") + $max_name_width)
                set -l padding (math $inner_width - $content_length)
                if test $padding -gt 0
                    printf "%*s" $padding ""
                end

                set_color $accent
                printf "│\n"
            end
        end

        set_color $accent
        printf "│"
        set_color $foreground
        printf "%*s" $inner_width ""
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│   ── AVAILABLE"
        set -l header_padding (math $inner_width - 15)
        if test $header_padding -gt 0
            set_color $foreground
            printf "%*s" $header_padding ""
        end
        set_color $accent
        printf "│\n"

        if test (count $uninstalled) -eq 0
            set_color $accent
            printf "│"
            set_color $foreground
            printf "   All modules installed"
            set -l padding (math $inner_width - 24)
            if test $padding -gt 0
                printf "%*s" $padding ""
            end
            set_color $accent
            printf "│\n"
        else
            set -l index (count $installed)

            for module in $uninstalled
                set index (math $index + 1)

                set -l name (string replace '.fish' '' -- $module)

                set_color $accent
                printf "│   ["
                set_color $error_color
                printf "%s" "$index"
                set_color $accent
                printf "]"
                set_color $foreground
                printf " %-*s" $max_name_width "$name"

                set -l content_length (math 6 + (string length -- "$index") + $max_name_width)
                set -l padding (math $inner_width - $content_length)
                if test $padding -gt 0
                    printf "%*s" $padding ""
                end

                set_color $accent
                printf "│\n"
            end
        end

        set_color $accent
        printf "│"
        set_color $foreground
        printf "%*s" $inner_width ""
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│ ["
        set_color $error_color
        printf i
        set_color $accent
        printf "]"
        set_color $foreground
        printf " Install module"
        set -l padding (math $inner_width - 19)
        if test $padding -gt 0
            printf "%*s" $padding ""
        end
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│ ["
        set_color $error_color
        printf r
        set_color $accent
        printf "]"
        set_color $foreground
        printf " Remove module"
        set -l padding (math $inner_width - 18)
        if test $padding -gt 0
            printf "%*s" $padding ""
        end
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│ ["
        set_color $error_color
        printf q
        set_color $accent
        printf "]"
        set_color $foreground
        printf " Quit"
        set -l padding (math $inner_width - 9)
        if test $padding -gt 0
            printf "%*s" $padding ""
        end
        set_color $accent
        printf "│\n"

        set_color $accent
        printf "╰%s╯\n" "$border"

        set_color $foreground
        read -P " Select: " choice

        switch $choice
            case q Q
                break
            case i I
                printf "\n"
                read -P " Module name or number: " input
                set -l name ""
                if string match -qr '^[0-9]+$' -- $input
                    set -l all $installed $uninstalled
                    set -l idx (math $input)
                    if test $idx -ge 1 -a $idx -le (count $all)
                        set name $all[$idx]
                    else
                        set_color $error_color
                        echo " Invalid number."
                        set_color normal
                        continue
                    end
                else
                    set name $input
                    if not string match -q "*.fish" -- $name
                        set name "$name.fish"
                    end
                end
                if not contains -- $name $available
                    set_color $error_color
                    echo " Module does not exist."
                    set_color normal
                    continue
                end
                if test -f "$module_dir/$name"
                    set_color $error_color
                    echo " Already installed: $name"
                    set_color normal
                    continue
                end
                set -l url "https://raw.githubusercontent.com/$repo/main/modules/$name"
                if curl -fsSL "$url" -o "$module_dir/$name"
                    set_color $accent
                    echo " Installed: $name"
                    set_color normal
                else
                    set_color $error_color
                    echo " Failed to download: $name"
                    set_color normal
                    rm -f "$module_dir/$name"
                end
            case r R
                printf "\n"
                read -P " Module name or number: " input
                set -l name ""
                if string match -qr '^[0-9]+$' -- $input
                    set -l all $installed $uninstalled
                    set -l idx (math $input)
                    if test $idx -ge 1 -a $idx -le (count $all)
                        set name $all[$idx]
                    else
                        set_color $error_color
                        echo " Invalid number."
                        set_color normal
                        continue
                    end
                else
                    set name $input
                    if not string match -q "*.fish" -- $name
                        set name "$name.fish"
                    end
                end
                if test -f "$module_dir/$name"
                    rm "$module_dir/$name"
                    set_color $accent
                    echo " Removed: $name"
                    set_color normal
                else
                    set_color $error_color
                    echo " Module is not installed."
                    set_color normal
                end

            case '*'
                set_color $error_color
                echo " Invalid selection."
                set_color normal
        end
    end
end

# ---------------------------------------------------------
# MISC
# ---------------------------------------------------------

function !vencord
    # description: Vencord installer
    # category: MISC
    sh -c "$(curl -sS https://vencord.dev/install.sh)"
end

# ---------------------------------------------------------
# LOG
# ---------------------------------------------------------

function !log
    # description: Show remote update log
    # category: MISC

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    test -n "$accent"; or set accent normal
    test -n "$foreground"; or set foreground normal

    set -l log_url "https://raw.githubusercontent.com/sudopkw/pkw-fishware/main/update.log?$(date +%s)"
    set -l logs (curl -fsSL --max-time 5 "$log_url" 2>/dev/null)

    if test $status -ne 0 -o (count $logs) -eq 0
        set_color $accent
        printf "╭──────────────────────────────────────╮\n"
        set_color $foreground
        printf "│  ── LOG                              │\n"
        printf "│  Unable to retrieve update log.      │\n"
        set_color $accent
        printf "╰──────────────────────────────────────╯\n"
        set_color normal
        return 1
    end

    set -l max_width 95
    set -l wrapped_logs

    for line in $logs
        while test (string length -- "$line") -gt $max_width
            set -a wrapped_logs (string sub -s 1 -l $max_width -- "$line")
            set line (string sub -s (math $max_width + 1) -- "$line")
        end

        set -a wrapped_logs "$line"
    end

    set -l content_width 6

    for line in $wrapped_logs
        set -l length (string length -- "$line")

        if test $length -gt $content_width
            set content_width $length
        end
    end

    set -l box_width (math $content_width + 4)
    set -l border (string repeat -n $box_width "─")

    printf "\n"
    set_color $accent
    printf "╭%s╮\n" "$border"
    printf "│  ── LOG"

    set -l padding (math $content_width - 6)

    if test $padding -gt 0
        set_color $foreground
        printf "%*s" $padding ""
    end

    set_color $accent
    printf "  │\n"

    for line in $wrapped_logs
        set -l length (string length -- "$line")
        set padding (math $content_width - $length)

        set_color $accent
        printf "│  "
        set_color $foreground
        printf "%s" "$line"

        if test $padding -gt 0
            printf "%*s" $padding ""
        end

        set_color $accent
        printf "  │\n"
    end

    printf "╰%s╯\n" "$border"
    set_color normal
    printf "\n"
end

# ---------------------------------------------------------
# WEATHER
# ---------------------------------------------------------

function !cw
    # description: Clear terminal and show weather
    # category: MISC
    clear
    !w
end

function !w
    # description: Weather information from wttr.in
    # category: MISC

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    test -n "$accent"; or set accent normal
    test -n "$foreground"; or set foreground normal

    if not command -q curl
        echo "curl is required."
        return 1
    end

    if not command -q jq
        echo "jq is required: sudo pacman -S jq"
        return 1
    end

    set -l json (curl -sS --fail --max-time 10 \
        'https://wttr.in/?format=j1' 2>/dev/null)

    if test $status -ne 0 -o -z "$json"
        echo "Unable to retrieve weather data."
        return 1
    end

    set -l location (printf '%s\n' $json |
        jq -r '.nearest_area[0].areaName[0].value // "Unknown"')

    function __weather_icon --argument-names code
        switch $code
            case 113
                echo "☀"
            case 116
                echo "🌤"
            case 119 122
                echo "☁"
            case 143 248 260
                echo "≋"
            case 176 263 266 293 296 299 302 305 308 311 314 317 350 353 356 359
                echo "☂"
            case 179 182 185 281 284 320 323 326 329 332 335 338 362 365 368 371 374 377
                echo "❄"
            case 200 386 389 392 395
                echo "⚡︎"
            case '*'
                echo "?"
        end
    end

    function __weather_day --argument-names date_string
        date -d "$date_string" '+%A' 2>/dev/null
    end

    set -l forecast (printf '%s\n' $json | jq -r '
        .weather[0:3][] |
        "DAY|\(.date)",
        "Morning|09:00|\(.hourly[2].weatherCode)|\(.hourly[2].tempC)|\(.hourly[2].FeelsLikeC)|\(.hourly[2].weatherDesc[0].value)|\(.hourly[2].chanceofrain)|\(.hourly[2].humidity)|\(.hourly[2].windspeedKmph)|\(.hourly[2].winddir16Point)",
        "Noon|12:00|\(.hourly[4].weatherCode)|\(.hourly[4].tempC)|\(.hourly[4].FeelsLikeC)|\(.hourly[4].weatherDesc[0].value)|\(.hourly[4].chanceofrain)|\(.hourly[4].humidity)|\(.hourly[4].windspeedKmph)|\(.hourly[4].winddir16Point)",
        "Evening|18:00|\(.hourly[6].weatherCode)|\(.hourly[6].tempC)|\(.hourly[6].FeelsLikeC)|\(.hourly[6].weatherDesc[0].value)|\(.hourly[6].chanceofrain)|\(.hourly[6].humidity)|\(.hourly[6].windspeedKmph)|\(.hourly[6].winddir16Point)",
        "Night|21:00|\(.hourly[7].weatherCode)|\(.hourly[7].tempC)|\(.hourly[7].FeelsLikeC)|\(.hourly[7].weatherDesc[0].value)|\(.hourly[7].chanceofrain)|\(.hourly[7].humidity)|\(.hourly[7].windspeedKmph)|\(.hourly[7].winddir16Point)"
    ' 2>/dev/null)

    set -l rows

    for entry in $forecast
        set -l parts (string split "|" -- $entry)

        if test "$parts[1]" = DAY
            set -l day_name (__weather_day $parts[2])
            test -n "$day_name"; or set day_name $parts[2]
            set -a rows "DAY|  ── $day_name"
            continue
        end

        set -l period $parts[1]
        set -l code $parts[3]
        set -l temp $parts[4]
        set -l feels $parts[5]
        set -l condition $parts[6]
        set -l rain $parts[7]
        set -l humidity $parts[8]
        set -l wind $parts[9]
        set -l direction $parts[10]

        set -l icon (__weather_icon $code)

        if test (string length -- $condition) -gt 18
            set condition (string sub -l 18 -- $condition)
        end

        set -l line (printf \
            "  %-9s %s  %3s°C  %-18s  Feels %3s°C  Rain %3s%%  Hum %3s%%  Wind %3s %s" \
            "$period" "$icon" "$temp" "$condition" "$feels" "$rain" \
            "$humidity" "$wind" "$direction")

        set -a rows "ROW|$line"
    end

    set -l max_length 0

    for entry in $rows
        set -l parts (string split "|" -- $entry)
        set -l length (string length -- $parts[2])

        if test $length -gt $max_length
            set max_length $length
        end
    end

    set -l header "  ── WEATHER | $location "
    set -l header_length (string length -- $header)

    if test $header_length -gt $max_length
        set max_length $header_length
    end

    set -l inner_width (math $max_length + 4)
    set -l border (string repeat -n $inner_width "─")

    printf "\n"
    set_color $accent
    printf "╭%s╮\n" "$border"
    printf "│%s" "$header"

    set_color $foreground
    set -l padding (math $inner_width - $header_length)

    if test $padding -gt 0
        printf "%*s" $padding ""
    end

    set_color $accent
    printf "│\n│"

    set_color $foreground
    printf "%*s" $inner_width ""

    set_color $accent
    printf "│\n"

    set -l previous_type ""

    for entry in $rows
        set -l parts (string split "|" -- $entry)
        set -l type $parts[1]
        set -l content $parts[2]

        if test "$type" = DAY -a "$previous_type" = ROW
            set_color $accent
            printf "│"

            set_color $foreground
            printf "%*s" $inner_width ""

            set_color $accent
            printf "│\n"
        end

        set -l content_length (string length -- $content)
        set padding (math $inner_width - $content_length - 1)

        if string match -q "*🌤*" -- $content
            set padding (math $padding - 0)
        end

        test $padding -ge 0; or set padding 0

        set_color $accent
        printf "│ "
        set_color $foreground

        if test "$type" = DAY
            set_color $accent
        end

        printf "%s" "$content"

        set_color $foreground

        if test $padding -gt 0
            printf "%*s" $padding ""
        end

        set_color $accent
        printf "│\n"

        set previous_type $type
    end

    printf "╰%s╯\n" "$border"
    set_color normal
    printf "\n"
end

# ---------------------------------------------------------
# ALIASES
# ---------------------------------------------------------

alias ff='fzf --preview "bat --style=numbers --color=always {}"'
alias !ff='fzf --preview "bat --style=numbers --color=always {}"'
# description: File finder
# category: ALIASES

alias !h='!help'
# description: Short form of !help
# category: ALIASES

alias !cmds='!help'
# description: Alternative !help alias
# category: ALIASES

alias !l='!log'
# description: Shortcut for !log
# category: ALIASES

alias !vi='!vencord'
# description: Shortcut for !vencord
# category: ALIASES

alias !cfgs='!cfgsource'
# description: Shortcut for !cfgsource
# category: ALIASES

alias !md="!modules"
# description: Modules Shortcut
# category: ALIASES

# ---------------------------------------------------------
# YAY
# ---------------------------------------------------------

function yay
    # description: Replace yay -y with --noconfirm
    # category: MISC

    set -l args $argv

    for i in (seq (count $args))
        if test "$args[$i]" = -y
            set args[$i] --noconfirm
        end
    end

    command yay $args
end

# ---------------------------------------------------------
# HELP
# ---------------------------------------------------------

function !help
    # description: Show custom commands and descriptions
    # category: SYS
    set -l configs ~/.config/fish/config.fish ~/.config/fish/personal.fish
    set -l module_dir ~/.config/fish/modules
    if test -d $module_dir
        for module in $module_dir/*.fish
            test -f $module; and set -a configs $module
        end
    end
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    test -n "$accent"; or set accent normal
    test -n "$foreground"; or set foreground normal
    set -l commands
    for config in $configs
        test -f $config; or continue
        set -l is_module false
        set -l module_name ""
        if string match -q "$module_dir/*" -- $config
            set is_module true
            set module_name (path basename $config | string replace '.fish' '')
        end
        set -l current_name ""
        set -l current_description ""
        while read -l line
            set -l match (string match -r '^function[[:space:]]+(![^[:space:]]+)' -- $line)
            if test (count $match) -eq 2
                set current_name $match[2]
                set current_description ""
                continue
            end
            if test -n "$current_name"
                set -l description_match \
                    (string match -r '^[[:space:]]*#[[:space:]]*description:[[:space:]]*(.+)$' -- $line)
                if test (count $description_match) -eq 2
                    set current_description $description_match[2]
                    continue
                end
            end
            set -l alias_match \
                (string match -r '^[[:space:]]*alias[[:space:]]+(!?[^=[:space:]]+)=' -- $line)
            if test (count $alias_match) -eq 2
                set current_name $alias_match[2]
                set current_description alias
                continue
            end
            if test -n "$current_name"
                set -l category_match \
                    (string match -r '^[[:space:]]*#[[:space:]]*category:[[:space:]]*(.+)$' -- $line)
                if test (count $category_match) -eq 2
                    if test -n "$current_description"
                        set -l cat $category_match[2]
                        if test $is_module = true
                            set cat "MODULES/$module_name"
                        end
                        set -a commands "$cat|$current_name|$current_description"
                    end
                    set current_name ""
                    set current_description ""
                end
            end
        end <$config
    end
    if test (count $commands) -eq 0
        echo "No custom commands found."
        return
    end
    set -l name_width 18
    set -l desc_width 20
    for command in $commands
        set -l parts (string split "|" -- $command)
        set -l name_len (string length -- $parts[2])
        set -l desc_len (string length -- $parts[3])
        test $name_len -le $name_width; or set name_width $name_len
        test $desc_len -le $desc_width; or set desc_width $desc_len
    end
    # Build hierarchical rows
    set -l rows
    set -l top_categories
    set -l seen_subcats
    for command in $commands
        set -l parts (string split "|" -- $command)
        set -l full_cat $parts[1]
        set -l name $parts[2]
        set -l description $parts[3]
        if string match -q "MODULES/*" -- $full_cat
            set -l sub (string replace "MODULES/" "" -- $full_cat)
            if not contains -- MODULES $top_categories
                set -a top_categories MODULES
                if test (count $top_categories) -gt 1
                    set -a rows ""
                end
                set -a rows "CATEGORY|MODULES"
            end
            set -l subkey "MODULES/$sub"
            if not contains -- $subkey $seen_subcats
                set -a seen_subcats $subkey
                set -a rows "SUBCATEGORY|$sub"
            end
            set -a rows (printf "    %-*s   %-*s " \
                $name_width "$name" \
                $desc_width "$description")
        else
            if not contains -- $full_cat $top_categories
                set -a top_categories $full_cat
                if test (count $top_categories) -gt 1
                    set -a rows ""
                end
                set -a rows "CATEGORY|$full_cat"
            end
            set -a rows (printf "  %-*s   %-*s " \
                $name_width "$name" \
                $desc_width "$description")
        end
    end
    set -l width 0
    for row in $rows
        if string match -q "CATEGORY|*" -- $row
            set -l category (string replace "CATEGORY|" "" -- $row)
            set -l length (string length -- "  ── $category")
            test $length -le $width; or set width $length
        else if string match -q "SUBCATEGORY|*" -- $row
            set -l sub (string replace "SUBCATEGORY|" "" -- $row)
            set -l length (string length -- "    ── $sub")
            test $length -le $width; or set width $length
        else
            set -l length (string length -- $row)
            test $length -le $width; or set width $length
        end
    end
    set width (math $width + 2)
    set -l border (string repeat -n $width "─")
    printf "\n"
    set_color $accent
    printf "╭%s╮\n" "$border"
    for row in $rows
        if test -z "$row"
            printf "│"
            set_color $foreground
            printf "%*s" $width ""
            set_color $accent
            printf "│\n"
            continue
        end
        if string match -q "CATEGORY|*" -- $row
            set -l category (string replace "CATEGORY|" "" -- $row)
            set -l header "  ── $category"
            set -l length (string length -- $header)
            set -l padding (math $width - $length - 1)
            set_color $accent
            printf "│ %s" "$header"
            if test $padding -gt 0
                set_color $foreground
                printf "%*s" $padding ""
            end
            set_color $accent
            printf "│\n"
        else if string match -q "SUBCATEGORY|*" -- $row
            set -l sub (string replace "SUBCATEGORY|" "" -- $row)
            set -l header "    ── $sub"
            set -l length (string length -- $header)
            set -l padding (math $width - $length - 1)
            set_color $accent
            printf "│ %s" "$header"
            if test $padding -gt 0
                set_color $foreground
                printf "%*s" $padding ""
            end
            set_color $accent
            printf "│\n"
        else
            set -l length (string length -- $row)
            set -l padding (math $width - $length)
            if test $padding -gt 0
                set row "$row"(string repeat -n $padding " ")
            end
            set_color $accent
            printf "│"
            set_color $foreground
            printf "%s" "$row"
            set_color $accent
            printf "│\n"
        end
    end
    printf "╰%s╯\n" "$border"
    set_color normal
    printf "\n"
end

# ---------------------------------------------------------
# MODULE LOADER
# ---------------------------------------------------------

set -l module_dir ~/.config/fish/modules

if test -d $module_dir
    for module in $module_dir/*.fish
        if test -f $module
            source $module
        end
    end
end

# ---------------------------------------------------------
# PERSONAL CONFIG
# ---------------------------------------------------------

if test -f ~/.config/fish/personal.fish
    source ~/.config/fish/personal.fish
end
