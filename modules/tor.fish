# ---------------------------------------------------------
# TOR
# ---------------------------------------------------------

function __tor_check_deps
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    test -n "$accent"; or set accent normal
    set -l missing
    for cmd in tor torsocks curl
        if not command -q $cmd
            set -a missing $cmd
        end
    end
    if test (count $missing) -eq 0
        return 0
    end
    set_color $accent
    printf " 🛈  Missing packages: "
    set_color $error_color
    printf"%s" (string join ", " $missing)
    set_color normal
    read -P " ➜ Install them now with pacman? [y/N] " answer
    if string match -qr '^[yY]' -- $answer
        sudo pacman -S --needed --noconfirm $missing
        or return 1
    else
        return 1
    end
    return 0
end

function !tor
    # description: Start the TOR service
    # category: TOR
    __tor_check_deps; or return 1
    sudo systemctl start tor
    if test $status -eq 0
        echo "ꪜ TOR Started! [ SOCKSPort:1337 ]"
    else
        echo "✘ Failed to start TOR!"
    end
end

function !ktor
    # description: Kill TOR Service
    # category: TOR
    __tor_check_deps; or return 1
    sudo systemctl stop tor
    if test $status -eq 0
        echo "ꪜ TOR Killed!"
    else
        echo "✘ The TOR Service never dies!"
    end
end

function !rtor
    # description: Restarts TOR Service
    # category: TOR
    __tor_check_deps; or return 1
    sudo systemctl restart tor
    echo "ꪜ TOR Restarted!"
end

function !torstatus
    # description: Show TOR status
    # category: TOR
    __tor_check_deps; or return 1
    systemctl status tor --no-pager -l
end

function !torcheck
    # description: Check if TOR is connected
    # category: TOR
    __tor_check_deps; or return 1
    curl -s --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip
end

function !ventor
    # description: runs vencord trough TOR
    # category: TOR
    __tor_check_deps; or return 1
    torsocks discord &
end
