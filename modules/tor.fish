# ---------------------------------------------------------
# TOR
# ---------------------------------------------------------

function __tor_check_deps
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

    for cmd in tor torsocks curl
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
    printf "│   🛈  MISSING TOR DEPENDENCIES          │\n"
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

function !tor
    # description: Manage the TOR service 
    # category: TOR

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

    function __tor_box --inherit-variable accent --inherit-variable foreground
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

    function __tor_error --inherit-variable accent --inherit-variable foreground
        __tor_box ERROR $argv
    end

    function __tor_help --inherit-variable accent --inherit-variable foreground
        __tor_box "TOR COMMANDS" \
            "!tor                              Start TOR" \
            "!tor help                         Show this help" \
            "!tor stop                         Stop TOR" \
            "!tor restart                      Restart TOR" \
            "!tor status                       Show TOR status" \
            "!tor check                        Check TOR connection" \
            "!ventor                           Run Vencord through TOR"
    end

    function __tor_check_deps --inherit-variable accent --inherit-variable foreground
        set -l missing

        for cmd in tor torsocks curl
            if not command -q $cmd
                set -a missing $cmd
            end
        end

        if test (count $missing) -eq 0
            return 0
        end

        __tor_box "MISSING PACKAGES" \
            "Missing: "(string join ", " $missing)

        read -P " ➜ Install them now with pacman? [y/N] " answer

        if string match -qr '^[yY]' -- $answer
            sudo pacman -S --needed --noconfirm $missing
            or return 1
        else
            return 1
        end

        return 0
    end

    set -l subcommand "$argv[1]"

    switch "$subcommand"
        case help --help
            __tor_help
            return 0

        case "" start
            __tor_check_deps; or return 1

            sudo systemctl start tor

            if test $status -eq 0
                __tor_box "TOR STARTED" \
                    "SOCKSPort  1337"
            else
                __tor_error "Failed to start TOR!"
                return 1
            end

            return 0

        case stop
            __tor_check_deps; or return 1

            sudo systemctl stop tor

            if test $status -eq 0
                __tor_box "TOR KILLED"
            else
                __tor_error "The TOR Service never dies!"
                return 1
            end

            return 0

        case restart
            __tor_check_deps; or return 1

            sudo systemctl restart tor

            if test $status -eq 0
                __tor_box "TOR RESTARTED"
            else
                __tor_error "Failed to restart TOR!"
                return 1
            end

            return 0

        case status
            __tor_check_deps; or return 1

            systemctl status tor --no-pager -l
            return $status

        case check
            __tor_check_deps; or return 1

            curl -s --socks5 127.0.0.1:1337 \
                https://check.torproject.org/api/ip
            return $status

        case "*"
            __tor_error \
                "Unknown command: $subcommand" \
                "" \
                "Use '!tor help' for available commands."
            return 1
    end
end

function !ventor
    # description: Run Vencord through TOR
    # category: TOR

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    if test -z "$accent"
        set accent normal
    end

    if test -z "$foreground"
        set foreground normal
    end

    function __ventor_box --inherit-variable accent --inherit-variable foreground
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

    set -l missing

    for cmd in tor torsocks curl
        if not command -q $cmd
            set -a missing $cmd
        end
    end

    if test (count $missing) -ne 0
        __ventor_box "MISSING PACKAGES" \
            "Missing: "(string join ", " $missing)

        read -P " ➜ Install them now with pacman? [y/N] " answer

        if string match -qr '^[yY]' -- $answer
            sudo pacman -S --needed --noconfirm $missing
            or return 1
        else
            return 1
        end
    end

    __ventor_box "VENCORD THROUGH TOR" \
        "SOCKSPort  1337" \
        "Starting Discord..."

    torsocks discord &
end
