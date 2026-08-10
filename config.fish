function fish_greeting
set -l theme ~/.config/omarchy/current/theme/colors.toml
set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

if test -z "$accent"
    set accent normal
end

if test -z "$foreground"
    set foreground normal
end

# ---------------------------------------------------------
# CACHE
# ---------------------------------------------------------

set -l cache_dir ~/.cache/pkw
set -l cache_age 600

mkdir -p $cache_dir

# ---------------------------------------------------------
# IPINFO
# ---------------------------------------------------------

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
        printf "%s" "$info" > $info_cache
    else if test -f $info_cache
        set info (cat $info_cache)
    end
end

set -l ip (echo $info | jq -r '.ip')
set -l country (echo $info | jq -r '.country')
set -l city (echo $info | jq -r '.city')

set -l today (date "+%A, %B %d")

# ---------------------------------------------------------
# WEATHER
# ---------------------------------------------------------

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
        printf "%s" "$weather" > $weather_cache
    else if test -f $weather_cache
        set weather (cat $weather_cache)
    else
        set weather "Unavailable"
    end
end

set -l vpn_status (echo $info | jq -r '.privacy.vpn // "false"')

# ---------------------------------------------------------
# TOR
# ---------------------------------------------------------

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
        printf "%s" "$tor_status" > $tor_cache
    else if test -f $tor_cache
        set tor_status (cat $tor_cache)
    else
        set tor_status false
    end
end

# ---------------------------------------------------------
# ORIGINAL GREETING
# ---------------------------------------------------------

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
    "Access Authorized, Welcome back, $USER?"

set -l quote ""$greetings[(random 1 (count $greetings))]

set -l info_rows \
    "🗓  Date: $today" \
    "🌍 Currently in: $country, $city" \
    "☁  Weather: $weather"

if test "$vpn_status" = true
    set -a info_rows "👓 VPN: TRUE"
else
    set -a info_rows "👁  VPN: FALSE"
end

if test "$tor_status" = true
    set -a info_rows "🩸 TOR: TRUE"
else
    set -a info_rows "💉 TOR: FALSE"
end

set -l content_width 0

for row in $info_rows
    set -l length (string length --visible -- "$row")

    if string match -q "*☁️*" -- "$row"
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
