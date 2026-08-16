# ---------------------------------------------------------
# FISH-GREETING
# ---------------------------------------------------------

function fish_greeting
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    if test -z "$accent"
        set accent normal
    end

    if test -z "$foreground"
        set foreground normal
    end

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

    set -l ip (echo $info | jq -r '.ip')
    set -l country (echo $info | jq -r '.country')
    set -l city (echo $info | jq -r '.city')

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

    set -l vpn_status (echo $info | jq -r '.privacy.vpn // "false"')

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
        set tor_status (curl -s --max-time 2 --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip 2>/dev/null | jq -r '.IsTor // "false"')

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
        "1337 4 3/3|2, $USER!" \
        "No way! Is that $USER??!!11!!11!!" \
        "Remember to update your config, $USER!" \
        "Access Authorized! Welcome back, $USER."

    set -l quote ""$greetings[(random 1 (count $greetings))]

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

    if test $info_category_length -gt $content_width
        set content_width $info_category_length
    end

    if test $greeting_category_length -gt $content_width
        set content_width $greeting_category_length
    end

    set -l box_width (math $content_width + 4)
    set -l border (string repeat -n $box_width "─")

    printf "\n"

    set_color $accent
    printf "╭%s╮\n" "$border"

    printf "│  "
    set_color $accent
    printf "── INFO"

    set -l category_padding (math $content_width - 7)

    if test $category_padding -gt 0
        set_color $foreground
        printf "%*s" $category_padding ""
    end

    set_color $accent
    printf "  │\n"

    for row in $info_rows
        set -l length (string length --visible -- "$row")

        if string match -q "*☁️*" -- "$row"
            set length (math $length + 1)
        end

        set -l padding (math $content_width - $length)

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
    printf "%*s" (math $box_width) ""

    set_color $accent
    printf "│\n"

    set_color $accent
    printf "│  ── GREETING"

    set -l category_padding (math $content_width - 11)

    if test $category_padding -gt 0
        set_color $foreground
        printf "%*s" $category_padding ""
    end

    set_color $accent
    printf "  │\n"

    set -l quote_length (string length --visible -- "$quote")
    set -l quote_padding (math $content_width - $quote_length)

    set_color $accent
    printf "│  "

    set_color $foreground
    printf "%s" "$quote"

    if test $quote_padding -gt 0
        printf "%*s" $quote_padding ""
    end

    set_color $accent
    printf "  │\n"

    set_color $accent
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
    echo " 🛈  For a list of commands, type '!help' or '!h'"
end

# ---------------------------------------------------------
# TOR
# ---------------------------------------------------------

function !tor
    # description: Start the TOR service
    # category: TOR
    sudo systemctl start tor
    if test $status -eq 0
        echo "✔️ TOR Started! [ SOCKSPort:1337 ]"
    else
        echo "❌ Failed to start TOR!"
    end
end

function !ktor
    # description: Kill TOR Service
    # category: TOR
    sudo systemctl stop tor
    if test $status -eq 0
        echo "✔️ TOR Killed!"
    else
        echo "❌ The TOR Service never dies!"
    end
end

function !rtor
    # description: Restarts TOR Service
    # category: TOR
    sudo systemctl restart tor
    echo "✔️ TOR Restarted!"
end

function !torstatus
    # description: Show TOR status
    # category: TOR
    systemctl status tor --no-pager -l
end

function !torcheck
    # description: Check if TOR is connected
    # category: TOR
    curl -s --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip
end

function !ventor
    # description: runs vencord trough TOR
    # category: TOR
    torsocks discord &
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
    # description: Clean up package cache and remove orphan packages
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
    # description: Show failed systemd services (EW SYSTEMD!!!!!1111!!!11)
    # category: SYS
    systemctl --failed
end

function !ucfg
    # description: Updates the config to the latest version!
    # category: SYS
    curl -fsSL https://raw.githubusercontent.com/sudopkw/fish-config-backup/main/config.fish \
        -o ~/.config/fish/config.fish
end

function !cfgsource
    # description: Opens the config source code
    # category: SYS
    xdg-open "https://github.com/sudopkw/fish-config-backup"
end

function !src
    # description: Sources newest fish edits 
    # category: SYS
    source ~/.config/fish/config.fish
end

function !cc
    # description: Clears cache
    # category: SYS
    rm -rf ~/.cache/pkw
    echo "Cache cleared."
end
# ---------------------------------------------------------
# NETWORK
# ---------------------------------------------------------

function !ports
    # description: Show listening network ports
    # category: NET
    ss -tulpn
end

function !ip
    # description: Show public IP address
    # category: NET
    curl -s https://api.ipify.org
end

function !net
    # description: Show network inferfaces
    # category: NET
    ip -br addr
end

function !route
    # description: Show network routing table
    # category: NET
    ip route
end

function !ping
    # description: Test internet connectivity
    # category: NET
    ping -c 4 1.1.1.1
end

function !trace
    # description: Trace the route to a host
    # category: NET

    if test (count $argv) -eq 0
        echo "Usage: !trace <host>"
        return 1
    end

    traceroute $argv[1]
end

# ---------------------------------------------------------
# GIT
# ---------------------------------------------------------

function !gs
    # description: Show Git repository status
    # category: GIT
    git status
end

function !ga
    # description: Shorter git add command
    # category: GIT
    if test (count $argv) -eq 0
        echo "Usage: !ga <file, directory, or .>"
        return 1
    end

    git add $argv[1]
end

function !gc
    # description: Create a Git commit
    # category: GIT
    if test (count $argv) -eq 0
        echo "Usage: !gc <commit message>"
        return 1
    end
    git commit -m $argv[1]
end

function !gp
    # description: Push Git changes
    # category: GIT
    git push
end

function !gd
    # description: Show Git changes
    # category: GIT
    git diff
end

function !gclone
    # description: Clone a Git repository
    # category: GIT

    if test (count $argv) -eq 0
        echo "Usage: !gclone <repository-url>"
        return 1
    end

    git clone $argv[1]
end

# ---------------------------------------------------------
# FILES & DIRECTORIES
# ---------------------------------------------------------

function !up
    # description: Go up one dir
    # category: FILES
    cd ..
end

function !up2
    # description: Go up two dirs
    # category: FILES
    cd ../..
end

function !mkcd
    # description: Create a directory and enter it
    # category: FILES
    if test (count $argv) -eq 0
        echo "Usage: !mkcd <directory>"
        return 1
    end

    mkdir -p -- $argv[1]; and cd -- $argv[1]
end

# ---------------------------------------------------------
# MISC
# ---------------------------------------------------------
function !vencord
    # description: Vencord installer! NOTE: DISCORD NEEDS TO BE INSTALLED VIA FLATHUB!
    # category: MISC
    sh -c "$(curl -sS https://vencord.dev/install.sh)"
end

#----------------------------------------------------------
# LOG
#----------------------------------------------------------

function !log
    # description: Show the remote update log
    # category: MISC

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    set -l log_url "https://raw.githubusercontent.com/sudopkw/fish-config-backup/main/update.log?$(date +%s)"
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
        set -l first_line 1

        while test (string length -- "$line") -gt $max_width
            set -l chunk (string sub -s 1 -l $max_width -- "$line")
            set wrapped_logs $wrapped_logs "$chunk"
            set line (string sub -s (math $max_width + 1) -- "$line")
            set first_line 0
        end

        if test $first_line -eq 0
            set wrapped_logs $wrapped_logs " $line"
        else
            set wrapped_logs $wrapped_logs "$line"
        end
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

    printf "│  "
    set_color $accent
    printf "── LOG"

    set -l header_padding (math $content_width - 6)

    if test $header_padding -gt 0
        set_color $foreground
        printf "%*s" $header_padding ""
    end

    set_color $accent
    printf "  │\n"

    for line in $wrapped_logs
        set -l length (string length -- "$line")
        set -l padding (math $content_width - $length)

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

    set_color $accent
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
end

# ---------------------------------------------------------
# WEATHER
# ---------------------------------------------------------

function !cw
    # description: Weateher info, But clears your terminal beforehand. *For screenies*
    # category: MISC
    clear
    !w
end

function !w
    # description: Weather info / Provided by wttr.in
    # category: MISC

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml

    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    if test -z "$accent"
        set accent normal
    end

    if test -z "$foreground"
        set foreground normal
    end

    if not command -q curl
        printf "curl is required.\n"
        return 1
    end

    if not command -q jq
        printf "jq is required: sudo pacman -S jq\n"
        return 1
    end

    set -l json (curl -sS --fail --max-time 10 'https://wttr.in/?format=j1' 2>/dev/null)

    if test $status -ne 0 -o -z "$json"
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"

        set_color $foreground
        printf "│ Unable to retrieve weather data.              "

        set_color $accent
        printf "│\n"
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"
        return 1
    end

    set -l location (printf '%s\n' $json | jq -r '.nearest_area[0].areaName[0].value // "Unknown"')

    function __weather_icon --argument-names code
        switch $code
            case 113
                echo "☀"
            case 116
                echo "⛅"
            case 119 122
                echo "☁"
            case 143 248 260
                echo "≋"
            case 176 263 266 293 296 299 302 305 308 311 314 317 350 353 356 359
                echo "☂"
            case 179 182 185 281 284 320 323 326 329 332 335 338 362 365 368 371 374 377
                echo "❄"
            case 200 386 389 392 395
                echo "⚡"
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

    if test $status -ne 0 -o (count $forecast) -eq 0
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"

        set_color $foreground
        printf "│ Failed to parse weather forecast.             "

        set_color $accent
        printf "│\n"
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"
        return 1
    end

    set -l rows

    for entry in $forecast
        set -l parts (string split "|" -- $entry)

        if test "$parts[1]" = DAY
            set -l day_name (__weather_day $parts[2])

            if test -z "$day_name"
                set day_name $parts[2]
            end

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

        set -l line (printf "  %-9s %s  %3s°C  %-18s  Feels %3s°C  Rain %3s%%  Hum %3s%%  Wind %3s %s" \
            "$period" \
            "$icon" \
            "$temp" \
            "$condition" \
            "$feels" \
            "$rain" \
            "$humidity" \
            "$wind" \
            "$direction")

        set -a rows "ROW|$line"
    end

    set -l max_length 0

    for entry in $rows
        set -l parts (string split "|" -- $entry)
        set -l content $parts[2]
        set -l length (string length -- $content)

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

    # Weather header
    set_color $accent
    printf "│"

    set_color $accent
    printf "%s" "$header"
    set_color $foreground

    set -l header_padding (math $inner_width - (string length -- $header))

    if test $header_padding -gt 0
        printf "%*s" $header_padding ""
    end

    set_color $accent
    printf "│\n"

    set_color $accent
    printf "│"

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
        set -l padding (math $inner_width - $content_length - 1)

        if string match -q "*⛅*" -- $content
            set padding (math $padding - 1)
        end

        if test $padding -lt 0
            set padding 0
        end

        set_color $accent
        printf "│"

        set_color $foreground
        printf " "

        if test "$type" = DAY
            set_color $accent
        else
            set_color $foreground
        end

        printf "%s" "$content"

        set_color $foreground
        printf "%*s" $padding ""

        set_color $accent
        printf "│\n"

        set previous_type $type
    end

    set_color $accent
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
end

# ---------------------------------------------------------
# ALIASES
# ---------------------------------------------------------
alias ff='fzf --preview "bat --style=numbers --color=always {}"'

alias !ff='fzf --preview "bat --style=numbers --color=always {}"'
# description: FileFinder / Provided by OMARCHY / NOTE; just "ff" works as-well
# category: ALIASES

alias !h='!help'
# description: Shorter way to get here!
# category: ALIASES

alias !cmds='!help'
# description: Alternative command alias to '!help'
# category: ALIASES

alias !l='!log'
# description: Shortcut for accessing the logs
# category: ALIASES

alias !vi="!vencord"
# description: Shortcut for the '!vencord' command
# category: ALIASES

alias !cfgs="!cfgsource"
# description: Shortcut for the '!cfgsource' command
# category: ALIASES

function yay
    # description: Turns the '--noconfirm' argument into a much simpler '-y'
    set args $argv

    for i in (seq (count $args))
        if test "$args[$i]" = -y
            set args[$i] --noconfirm
        end
    end

    command yay $args
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
# HELP
# ---------------------------------------------------------

function !help
    # description: Show custom Fish commands and descriptions

    set -l config ~/.config/fish/config.fish
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l commands

    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    if test -z "$accent"
        set accent normal
    end

    if test -z "$foreground"
        set foreground normal
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
            set -l description_match (string match -r '^[[:space:]]*#[[:space:]]*description:[[:space:]]*(.+)$' -- $line)

            if test (count $description_match) -eq 2
                set current_description $description_match[2]
                continue
            end
        end

        set -l alias_match (string match -r '^[[:space:]]*alias[[:space:]]+(!?[^=[:space:]]+)=' -- $line)

        if test (count $alias_match) -eq 2
            set current_name $alias_match[2]
            set current_description alias
            continue
        end

        if test -n "$current_name"
            set -l category_match (string match -r '^[[:space:]]*#[[:space:]]*category:[[:space:]]*(.+)$' -- $line)

            if test (count $category_match) -eq 2
                set -l category $category_match[2]

                if test -n "$current_description"
                    set -a commands "$category|$current_name|$current_description"

                    set current_name ""
                    set current_description ""
                end
            end
        end
    end <$config

    if test (count $commands) -eq 0
        printf "\n"

        set_color $accent
        printf "╭───────────────────────────────────────────────╮\n"
        printf "│"

        set_color $foreground
        printf " No custom commands found.                     "

        set_color $accent
        printf "│\n"
        printf "╰───────────────────────────────────────────────╯\n"

        set_color normal
        printf "\n"
        return
    end

    set -l name_width 18
    set -l desc_width 20

    for command in $commands
        set -l parts (string split "|" -- $command)
        set -l name $parts[2]
        set -l description $parts[3]

        set -l name_len (string length -- $name)
        set -l desc_len (string length -- $description)

        if test $name_len -gt $name_width
            set name_width $name_len
        end

        if test $desc_len -gt $desc_width
            set desc_width $desc_len
        end
    end

    set -l rows
    set -l categories

    for command in $commands
        set -l parts (string split "|" -- $command)
        set -l category $parts[1]
        set -l name $parts[2]
        set -l description $parts[3]

        if not contains -- $category $categories
            set -a categories $category

            if test (count $categories) -gt 1
                set -a rows ""
            end

            set -a rows "CATEGORY|$category"
        end

        set -l row (printf "  %-*s   %-*s " \
            $name_width "$name" \
            $desc_width "$description")

        set -a rows "$row"
    end

    set -l width 0

    for row in $rows
        if string match -q "CATEGORY|*" -- $row
            set -l category (string replace "CATEGORY|" "" -- $row)
            set -l header_length (string length -- "  ── $category")

            if test $header_length -gt $width
                set width $header_length
            end
        else
            set -l row_length (string length -- $row)

            if test $row_length -gt $width
                set width $row_length
            end
        end
    end

    set width (math $width + 2)

    set -l border (string repeat -n $width "─")

    printf "\n"

    set_color $accent
    printf "╭%s╮\n" "$border"

    for row in $rows

        if test -z "$row"
            set_color $accent
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
            set -l header_length (string length -- $header)
            set -l padding (math $width - $header_length - 1)

            if test $padding -lt 0
                set padding 0
            end

            set_color $accent
            printf "│"

            printf " %s" "$header"

            if test $padding -gt 0
                set_color $foreground
                printf "%*s" $padding ""
            end

            set_color $accent
            printf "│\n"

        else
            set -l row_length (string length -- $row)
            set -l padding (math $width - $row_length)

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

    set_color $accent
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
end

if test -f ~/.config/fish/personal.fish
    source ~/.config/fish/personal.fish
end
