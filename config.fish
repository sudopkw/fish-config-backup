function fish_greeting

    set -l info (curl -s ipinfo.io/json)
    set -l ip (echo $info | jq -r '.ip')
    set -l country (echo $info | jq -r '.country')
    set -l city (echo $info | jq -r '.city')

    set -l today (date "+%A, %B %d")
    set -l weather (curl -s 'wttr.in/?format=%C+%t' 2>/dev/null)


    set -l vpn_status (echo $info | jq -r '.privacy.vpn // "false"')
    set -l tor_status (curl -s --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip 2>/dev/null | jq -r '.IsTor // "false"')
    set -l greetings \
        "HACK THE PLANET! $USER!" \
        "$USER! $USER! you should totally write 'rm -rf ~/*' in your termianl or something!!11!!!!1" \
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
        "1337 4 3\/3|2, $USER!" \
        "No way! Is that $USER??!!11!!11!!" \
        "Access Authorized, Welcome back, $USER!" \
        "🌐 $ip <--- your ip, $USER. GET TROLLED BY YOUR OWN TERMINAL!!! :trollface:"

    echo "🗓 Date: $today"
    echo "🌍 Currently in: $country, $city"
    echo "☁️  Weather: $weather"

    if test "$vpn_status" = true
        echo "👓 VPN: TRUE"
    else
        echo "👁  VPN: FALSE"
    end

    if test "$tor_status" = true
        echo "🩸 TOR: TRUE"
    else
        echo "💉 TOR: FALSE"
    end


    echo $greetings[(random 1 (count $greetings))]
end

alias ff='fzf --preview "bat --style=numbers --color=always {}"'

function !tor --description 'Start the TOR service'
    sudo systemctl start tor
    if test $status -eq 0
        echo "✔️ TOR Started! [ SOCKSPort:1337 ]"
    else
        echo "❌ Failed to start TOR!"
    end
end

function !ktor --description "Kill TOR Service"
    sudo systemctl stop tor
    if test $status -eq 0
        echo "✔️ TOR Killed!"
    else
        echo "❌ The TOR Service never dies!"
    end
end

function !rtor --description "Restarts TOR Service"
    sudo systemctl restart tor
    echo "✔️ TOR Restarted!"
end

function !torstatus --description 'Show TOR status'
    systemctl status tor --no-pager -l
end

function !torcheck --description 'Check if TOR is connected'
    curl -s --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip
end

function !w --description "Weather info / Provided by wttr.in"
    curl https://wttr.in
end

function fish_prompt
    if test $status -ne 0
        set_color red
        echo -n "✘ "
        set_color normal
    else
        set_color normal
        echo -n "➜ "
    end
end

function vesktor --description 'runs vesktop trough TOR ( i have no clue if this even works -- torsocks package needed )'
    torsocks vesktop &
end
