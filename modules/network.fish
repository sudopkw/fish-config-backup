# ---------------------------------------------------------
# NETWORK
# ---------------------------------------------------------

function __network_check_deps
    set -l missing
    for cmd in curl traceroute
        if not command -q $cmd
            set -a missing $cmd
        end
    end
    if test (count $missing) -eq 0
        return 0
    end
    set_color $accent
    echo "Missing packages: "(string join ", " $missing)
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

function !ports
    # description: Show listening network ports
    # category: NET
    ss -tulpn
end

function !ip
    # description: Show public IP address
    # category: NET
    __network_check_deps; or return 1
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
    __network_check_deps; or return 1
    if test (count $argv) -eq 0
        echo "Usage: !trace <host>"
        return 1
    end

    traceroute $argv[1]
end
