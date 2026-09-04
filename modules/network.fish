# ---------------------------------------------------------
# NETWORK
# ---------------------------------------------------------

function __network_check_deps
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
    printf "╭────────────────────────────────────────╮\n"

    set_color $foreground
    printf "│   🛈  MISSING NETWORK DEPENDENCIES     │\n"
    printf "│                                        │\n"
    printf "│ Missing: %-29s │\n" (string join ", " $missing)

    set_color $accent
    printf "╰────────────────────────────────────────╯\n"

    set_color $foreground
    read -P " ➜ Install them now with pacman? [y/N] " answer

    if string match -qr '^[yY]' -- $answer
        sudo pacman -S --needed --noconfirm $missing
        or return 1
    else
        return 1
    end

    return 0
end

function !net
    # description: Network utilities
    # category: NET

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

    function __net_box --inherit-variable accent --inherit-variable foreground
        set -l title "$argv[1]"
        set -e argv[1]

        set -l rows $argv
        set -l max_length 0

        for row in $rows
            set -l length (string length -- "$row")
            if test $length -gt $max_length
                set max_length $length
            end
        end

        set -l title_length (string length -- "$title")

        if test $title_length -gt $max_length
            set max_length $title_length
        end

        if test $max_length -lt 38
            set max_length 38
        end

        set -l width $max_length
        set -l inner_width (math "$width + 2")
        set -l border (string repeat -n $inner_width "─")

        printf "\n"

        set_color $accent
        printf "╭%s╮\n" "$border"

        set_color $accent
        printf "│   ── %s" "$title"

        set -l padding (math "$inner_width - $title_length - 6")

        if test $padding -gt 0
            set_color $foreground
            printf "%*s" $padding ""
        end

        set_color $accent
        printf "│\n"

        set_color $accent
        printf "│"
        set_color $foreground
        printf "%*s" $inner_width ""
        set_color $accent
        printf "│\n"

        for row in $rows
            set_color $accent
            printf "│ "

            set_color $foreground
            printf "%-*s" $width "$row"

            set_color $accent
            printf " │\n"
        end

        set_color $accent
        printf "╰%s╯\n" "$border"

        set_color normal
        printf "\n"
    end

    function __net_error
        __net_box ERROR $argv
    end

    function __net_help
        __net_box "NETWORK HELP" \
            "!net              Show network interfaces" \
            "!net help         Show this help" \
            "!net ports        Show listening network ports" \
            "!net ip           Show public IP address" \
            "!net route        Show network routing table" \
            "!net ping         Test internet connectivity" \
            "!net trace <host> Trace the route to a host"
    end

    set -l subcommand "$argv[1]"

    switch "$subcommand"

        case help --help
            __net_help

        case ports
            __net_box "LISTENING PORTS" \
                "Showing TCP/UDP listening ports..."
            ss -tulpn

        case ip
            __network_check_deps; or return 1

            set -l public_ip (curl -s https://api.ipify.org)

            __net_box "PUBLIC IP" \
                "Address: $public_ip"

        case route
            __net_box "ROUTING TABLE" \
                "Showing current network routes..."
            ip route

        case ping
            __net_box "INTERNET CONNECTIVITY" \
                "Pinging 1.1.1.1..." \
                "4 packets"
            ping -c 4 1.1.1.1

        case trace
            if test (count $argv) -lt 2
                __net_error \
                    "Usage: !net trace <host>"
                return 1
            end

            __network_check_deps; or return 1

            __net_box TRACEROUTE \
                "Tracing route to: $argv[2]"

            traceroute $argv[2]

        case ""
            __net_box "NETWORK INTERFACES" \
                "Showing active network interfaces..."
            ip -br addr

        case "*"
            __net_error \
                "Unknown command: $subcommand" \
                "Use '!net help' to see available commands."
            return 1
    end
end
