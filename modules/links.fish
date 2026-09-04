# ---------------------------------------------------------
# LINKS
# ---------------------------------------------------------

source ~/.config/fish/personal.fish

function !pwd
    # description: Generates a random 16 character password
    # category: LINKS
    openssl rand -hex 16
end

function !url
    # description: Shorten a URL using Syano
    # category: LINKS

    set -l api "https://s.sudopkw.dev/api/v1/links"
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

    function __url_box --inherit-variable accent --inherit-variable foreground
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

    function __url_error
        __url_box ERROR $argv
    end

    function __url_help
        __url_box "URL COMMANDS" \
            "!url <url>                         Shorten a URL" \
            "!url dash                          Open dashboard" \
            "!url check <slug>                  Check a short URL" \
            "!url info <slug>                   Show URL information" \
            "!url stats <slug> [start] [end]    Show analytics" \
            "!url list [options]                List shortened URLs" \
            "!url find <query>                  Search shortened URLs" \
            "!url rm <slug>                     Delete shortened URL" \
            "!url valid <url>                    Check URL reachability"
    end

    set -l subcommand "$argv[1]"

    switch "$subcommand"
        case help --help
            __url_help
            return 0

        case dash dashboard
            if not command -q xdg-open
                __url_error "xdg-open is not installed."
                return 1
            end

            xdg-open "https://s.sudopkw.dev/dashboard" >/dev/null 2>&1 &
            __url_box "URL DASHBOARD" \
                "Opening Syano dashboard..." \
                "https://s.sudopkw.dev/dashboard"
            return 0

        case check
            if test (count $argv) -ne 2
                __url_error "Usage: !url check <slug>"
                return 1
            end

            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l slug $argv[2]

            set -l response (curl -fsS \
                -H "X-API-Key: $URL_API_KEY" \
                "$api/$slug" 2>/dev/null)

            if test $status -ne 0
                __url_error "Link not found or request failed."
                return 1
            end

            set -l url (echo "$response" | jq -r '.data.url // empty')
            set -l short (echo "$response" | jq -r '.data.short_url // empty')

            if test -z "$url"
                __url_error "Link not found."
                return 1
            end

            __url_box "URL CHECK" \
                "SHORT    $short" \
                "TARGET   $url"

            return 0

        case info
            if test (count $argv) -ne 2
                __url_error "Usage: !url info <slug>"
                return 1
            end

            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l response (curl -fsS \
                -H "X-API-Key: $URL_API_KEY" \
                "$api/$argv[2]" 2>/dev/null)

            if test $status -ne 0
                __url_error "Failed to fetch link."
                return 1
            end

            set -l data (echo "$response" | jq -r '
                .data |
                "SLUG        \(.slug)",
                "URL         \(.url)",
                "SHORT       \(.short_url)",
                "TITLE       \(.title // "-")",
                "DESCRIPTION \(.description // "-")",
                "COMMENT     \(.comment // "-")",
                "EXPIRATION  \(.expiration // "never")",
                "CLOAKING    \(.cloaking)",
                "QUERY       \(.redirect_with_query)",
                "CREATED     \(.created_at)",
                "UPDATED     \(.updated_at)"
            ')

            __url_box "URL INFORMATION" $data
            return 0

        case stats
            if test (count $argv) -lt 2; or test (count $argv) -gt 4
                __url_error "Usage: !url stats <slug> [start_date] [end_date]"
                return 1
            end

            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l endpoint "https://s.sudopkw.dev/api/v1/analytics/$argv[2]"

            if test (count $argv) -ge 3
                set endpoint "$endpoint?start_date="(string escape --style=url "$argv[3]")
            end

            if test (count $argv) -eq 4
                set endpoint "$endpoint&end_date="(string escape --style=url "$argv[4]")
            end

            set -l response (curl -fsS \
                -H "X-API-Key: $URL_API_KEY" \
                "$endpoint" 2>/dev/null)

            if test $status -ne 0
                __url_error "Failed to fetch analytics."
                return 1
            end

            set -l rows

            set -a rows "LINK          "(echo "$response" | jq -r '.data.link.short_url // .data.link.slug')
            set -a rows ""
            set -a rows "TOTAL CLICKS  "(echo "$response" | jq -r '.data.summary.total_clicks')
            set -a rows ""
            set -a rows "BY DATE"

            for row in (echo "$response" | jq -r '.data.clicks_by_date[] | "  \(.date): \(.clicks)"')
                set -a rows "$row"
            end

            set -a rows ""
            set -a rows "BY COUNTRY"

            for row in (echo "$response" | jq -r '.data.clicks_by_country[] | "  \(.country // "Unknown"): \(.clicks)"')
                set -a rows "$row"
            end

            set -a rows ""
            set -a rows "BY DEVICE"

            for row in (echo "$response" | jq -r '.data.clicks_by_device[] | "  \(.device // "Unknown"): \(.clicks)"')
                set -a rows "$row"
            end

            set -a rows ""
            set -a rows "BY BROWSER"

            for row in (echo "$response" | jq -r '.data.clicks_by_browser[] | "  \(.browser // "Unknown"): \(.clicks)"')
                set -a rows "$row"
            end

            __url_box "URL ANALYTICS" $rows
            return 0

        case list
            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l limit 50
            set -l search ""

            set -l i 2

            while test $i -le (count $argv)
                switch $argv[$i]
                    case -n --limit
                        set i (math $i + 1)

                        if test $i -gt (count $argv)
                            __url_error "Limit requires a value."
                            return 1
                        end

                        set limit $argv[$i]

                    case -s --search
                        set i (math $i + 1)

                        if test $i -gt (count $argv)
                            __url_error "Search requires a value."
                            return 1
                        end

                        set search $argv[$i]

                    case "*"
                        __url_error \
                            "Usage: !url list [-n|--limit <number>] [-s|--search <query>]"
                        return 1
                end

                set i (math $i + 1)
            end

            set -l endpoint "$api?limit=$limit"

            if test -n "$search"
                set endpoint "$endpoint&search="(string escape --style=url "$search")
            end

            set -l response (curl -fsS \
                -H "X-API-Key: $URL_API_KEY" \
                "$endpoint" 2>/dev/null)

            if test $status -ne 0
                __url_error "Failed to fetch links."
                return 1
            end

            set -l rows

            for row in (echo "$response" | jq -r '
                .data[] |
                "\(.slug)    \(.short_url)    \(.click_count) clicks"
            ')
                set -a rows "$row"
            end

            if test (count $rows) -eq 0
                set -a rows "No shortened URLs found."
            end

            __url_box "SHORTENED URLS" $rows
            return 0

        case find
            if test (count $argv) -lt 2
                __url_error "Usage: !url find <query>"
                return 1
            end

            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l query (string join " " -- $argv[2..-1])
            set -l encoded (string escape --style=url "$query")

            set -l response (curl -fsS \
                -H "X-API-Key: $URL_API_KEY" \
                "https://s.sudopkw.dev/api/v1/links/search?q=$encoded&limit=50" 2>/dev/null)

            if test $status -ne 0
                __url_error "Search failed."
                return 1
            end

            set -l rows

            for row in (echo "$response" | jq -r '
                .data[] |
                "\(.slug)    \(.url)"
            ')
                set -a rows "$row"
            end

            if test (count $rows) -eq 0
                set -a rows "No matching URLs found."
            end

            __url_box "URL SEARCH" \
                "QUERY  $query" \
                "" \
                $rows

            return 0

        case rm remove delete
            if test (count $argv) -ne 2
                __url_error "Usage: !url rm <slug>"
                return 1
            end

            if not set -q URL_API_KEY
                __url_error "URL_API_KEY is not set."
                return 1
            end

            set -l slug $argv[2]

            __url_box "DELETE URL" \
                "You are about to delete:" \
                "" \
                "SLUG  $slug"

            printf "Delete '%s'? [y/N] " "$slug"
            read -l confirm

            if not string match -qi y -- "$confirm"
                __url_box "DELETE URL" \
                    "Cancelled." \
                    "Nothing was deleted."
                return 0
            end

            set -l response (curl -fsS \
                -X DELETE \
                -H "X-API-Key: $URL_API_KEY" \
                "$api/$slug" 2>/dev/null)

            if test $status -ne 0
                __url_error "Failed to delete link."
                return 1
            end

            set -l message (echo "$response" | jq -r '.message // "Link deleted."')

            __url_box "URL DELETED" "$message"
            return 0

        case valid
            if test (count $argv) -ne 2
                __url_error "Usage: !url valid <url>"
                return 1
            end

            set -l target $argv[2]

            if not string match -rq '^https?://' -- "$target"
                __url_error \
                    "Invalid URL format." \
                    "$target"
                return 1
            end

            set -l status_code (curl -o /dev/null \
                -s \
                -L \
                --max-time 10 \
                -w '%{http_code}' \
                "$target")

            if test $status_code -ge 200; and test $status_code -lt 400
                __url_box "URL VALID" \
                    "STATUS  $status_code" \
                    "URL     $target"
                return 0
            end

            if test "$status_code" = 000
                __url_error \
                    "URL is unreachable." \
                    "$target"
                return 1
            end

            __url_error \
                "HTTP $status_code" \
                "$target"

            return 1
    end

    set -l verbose false
    set -l target ""
    set -l slug ""
    set -l password ""
    set -l expiry ""
    set -l unsafe false
    set -l cloaking false
    set -l title ""
    set -l description ""
    set -l comment ""

    set -l i 1

    while test $i -le (count $argv)
        set -l arg $argv[$i]

        switch $arg
            case -v --verbose
                set verbose true

            case -s --slug
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Slug requires a value."
                    return 1
                end

                set slug "$argv[$i]"

            case -p --password
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Password requires a value."
                    return 1
                end

                set password "$argv[$i]"

            case -e --expiry
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Expiry requires a value."
                    return 1
                end

                set expiry "$argv[$i]"

            case --unsafe -unsafe
                set unsafe true

            case --cloak --cloaking
                set cloaking true

            case -t --title
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Title requires a value."
                    return 1
                end

                set title "$argv[$i]"

            case -d --desc --description
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Description requires a value."
                    return 1
                end

                set description "$argv[$i]"

            case -c --comment
                set i (math $i + 1)

                if test $i -gt (count $argv)
                    __url_error "Comment requires a value."
                    return 1
                end

                set comment "$argv[$i]"

            case "*"
                if test -z "$target"
                    set target "$arg"
                else
                    __url_error "Multiple URLs supplied."
                    return 1
                end
        end

        set i (math $i + 1)
    end

    if test -z "$target"
        __url_help
        return 1
    end

    if not set -q URL_API_KEY
        __url_error \
            "URL_API_KEY is not set." \
            "" \
            "Please contact me to provide you with an account." \
            "E-Mail: pkw@sudopkw.dev" \
            "Discord: pkw.gov"
        return 1
    end

    set -l expiration_ms ""

    if test -n "$expiry"
        set -l match (string match -r '^([0-9]+)([mhd])$' "$expiry")

        if test (count $match) -ne 3
            __url_error \
                "Invalid expiry." \
                "Use formats like 20m, 5h or 1d."
            return 1
        end

        set -l amount $match[2]
        set -l unit $match[3]
        set -l multiplier 0

        switch $unit
            case m
                set multiplier 60000
            case h
                set multiplier 3600000
            case d
                set multiplier 86400000
        end

        set -l now (date +%s)
        set expiration_ms (math "$amount * $multiplier + $now * 1000")
    end

    set -l json (jq -cn \
        --arg url "$target" \
        --arg slug "$slug" \
        --arg password "$password" \
        --arg title "$title" \
        --arg description "$description" \
        --arg comment "$comment" \
        --argjson unsafe "$unsafe" \
        --argjson cloaking "$cloaking" \
        --argjson expiration (test -n "$expiration_ms"; and echo "$expiration_ms"; or echo null) \
        '{
            url: $url,
            slug: (if $slug == "" then null else $slug end),
            password: (if $password == "" then null else $password end),
            title: (if $title == "" then null else $title end),
            description: (if $description == "" then null else $description end),
            comment: (if $comment == "" then null else $comment end),
            unsafe: $unsafe,
            cloaking: $cloaking,
            expiration: $expiration
        }')

    set -l response (curl -fsS \
        --connect-timeout 10 \
        --max-time 30 \
        -X POST \
        -H "X-API-Key: $URL_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json" \
        "$api" 2>/dev/null)

    if test $status -ne 0
        __url_error "Failed to connect to Syano."
        return 1
    end

    set -l success (echo "$response" | jq -r '.success // false')
    set -l short_url (echo "$response" | jq -r '.data.short_url // empty')

    if test "$success" != true; or test -z "$short_url"
        __url_error "Failed to create short URL."
        return 1
    end

    if test "$verbose" = false
        __url_box "URL SHORTENER" \
            "SOURCE  $target" \
            "SHORT   $short_url"
        return 0
    end

    set -l rows

    set -a rows "SOURCE   $target"
    set -a rows "SHORT    $short_url"

    test -n "$slug"; and set -a rows "SLUG     $slug"
    test -n "$title"; and set -a rows "TITLE    $title"
    test -n "$description"; and set -a rows "DESC     $description"
    test -n "$comment"; and set -a rows "COMMENT  $comment"
    test -n "$password"; and set -a rows "PASSWORD protected"
    test -n "$expiry"; and set -a rows "EXPIRY   $expiry"
    test "$unsafe" = true; and set -a rows "UNSAFE   yes"
    test "$cloaking" = true; and set -a rows "CLOAK    enabled"

    __url_box "URL SHORTENER" $rows
end
