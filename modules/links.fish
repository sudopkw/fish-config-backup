source ~/.config/fish/personal.fish

function !pwd
    # description: Generates a random 16 character password
    # category: LINKS
    openssl rand -hex 16
end

function !urldash
    # description: Open the Syano dashboard
    # category: LINKS

    if not command -q xdg-open
        echo "ERROR: xdg-open is not installed."
        return 1
    end

    xdg-open "https://s.sudopkw.dev/dashboard" >/dev/null 2>&1 &
end

function !url
    # description: Shorten a URL using Syano
    # category: LINKS

    set -l api "https://s.sudopkw.dev/api/v1/links"
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
                    echo "ERROR: Slug requires a value."
                    return 1
                end
                set slug "$argv[$i]"

            case -p --password
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "ERROR: Password requires a value."
                    return 1
                end
                set password "$argv[$i]"

            case -e --expiry
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "ERROR: Expiry requires a value."
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
                    echo "ERROR: Title requires a value."
                    return 1
                end
                set title "$argv[$i]"

            case -d --desc --description
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "ERROR: Description requires a value."
                    return 1
                end
                set description "$argv[$i]"

            case -c --comment
                set i (math $i + 1)
                if test $i -gt (count $argv)
                    echo "ERROR: Comment requires a value."
                    return 1
                end
                set comment "$argv[$i]"

            case "*"
                if test -z "$target"
                    set target "$arg"
                else
                    echo "ERROR: Multiple URLs supplied."
                    return 1
                end
        end

        set i (math $i + 1)
    end

    if test -z "$target"
        echo "Usage: !url [options] <url>"
        echo
        echo "Options:"
        echo "  -v, --verbose             Detailed output"
        echo "  -s, --slug <value>        Custom slug"
        echo "  -p, --password <value>    Password-protect link"
        echo "  -e, --expiry <duration>   Expiry: 20m, 5h, 1d"
        echo "      --unsafe              Mark link as unsafe"
        echo "      --cloak               Enable cloaking"
        echo "  -t, --title <value>       Link title"
        echo "  -d, --desc <value>        Link description"
        echo "  -c, --comment <value>     Link comment"
        return 1
    end

    if not set -q URL_API_KEY
        printf "ERROR: URL_API_KEY is not set.\n"
        printf "Please contact me to provide you with an account.\n"
        printf "E-Mail: pkw@sudopkw.dev\n"
        printf "Discord: pkw.gov\n"
        return 1
    end

    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    set -l foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]

    test -n "$accent"; or set accent normal
    test -n "$foreground"; or set foreground normal

    set -l expiration_ms ""

    if test -n "$expiry"
        set -l match (string match -r '^([0-9]+)([mhd])$' "$expiry")

        if test (count $match) -ne 3
            set_color $accent
            printf "✘ "
            set_color $foreground
            printf "Invalid expiry. Use formats like 20m, 5h or 1d.\n"
            set_color normal
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
        set_color $accent
        printf "✘ "
        set_color $foreground
        printf "Failed to connect to Syano.\n"
        set_color normal
        return 1
    end

    set -l success (echo "$response" | jq -r '.success // false')
    set -l short_url (echo "$response" | jq -r '.data.short_url // empty')

    if test "$success" != true; or test -z "$short_url"
        set_color $accent
        printf "✘ "
        set_color $foreground
        printf "Failed to create short URL.\n"
        set_color normal
        return 1
    end

    if test "$verbose" = false
        set_color $foreground
        printf " ➜ "
        set_color $accent
        printf "%s\n" "$short_url"
        set_color normal
        return 0
    end

    set -l rows
    set -a rows "  SOURCE   $target"
    set -a rows "  SHORT    $short_url"

    test -n "$slug"; and set -a rows "  SLUG     $slug"
    test -n "$title"; and set -a rows "  TITLE    $title"
    test -n "$description"; and set -a rows "  DESC     $description"
    test -n "$comment"; and set -a rows "  COMMENT  $comment"
    test -n "$password"; and set -a rows "  PASSWORD protected"
    test -n "$expiry"; and set -a rows "  EXPIRY   $expiry"
    test "$unsafe" = true; and set -a rows "  UNSAFE   yes"
    test "$cloaking" = true; and set -a rows "  CLOAK    enabled"

    set -l width 0

    for row in $rows
        set -l length (string length -- $row)
        test $length -le $width; or set width $length
    end

    set -l header "  ── URL SHORTENER"
    set -l header_length (string length -- $header)

    test $header_length -le $width; or set width $header_length
    set width (math $width + 2)

    set -l border (string repeat -n $width "─")

    printf "\n"

    set_color $accent
    printf "╭%s╮\n" "$border"

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

    printf "│"
    set_color $foreground
    printf "%*s" $width ""
    set_color $accent
    printf "│\n"

    for row in $rows
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

    printf "│"
    set_color $foreground
    printf "%*s" $width ""
    set_color $accent
    printf "│\n"

    set_color $accent
    printf "╰%s╯\n" "$border"

    set_color normal
    printf "\n"
end

function !urlcheck
    # description: Check a short URL
    # category: LINKS

    if test (count $argv) -ne 1
        echo "Usage: !urlcheck <slug>"
        return 1
    end

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l slug $argv[1]
    set -l response (curl -fsS \
        -H "X-API-Key: $URL_API_KEY" \
        "https://s.sudopkw.dev/api/v1/links/$slug" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Link not found or request failed."
        return 1
    end

    set -l url (echo "$response" | jq -r '.data.url // empty')
    set -l short (echo "$response" | jq -r '.data.short_url // empty')

    if test -z "$url"
        echo "ERROR: Link not found."
        return 1
    end

    set_color (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < ~/.local/state/omarchy/current/theme/colors.toml)[2]
    printf " ➜ "
    printf "%s\n" "$short"
    set_color normal
    printf "   %s\n" "$url"
end

function !urlinfo
    # description: Show information about a short URL
    # category: LINKS

    if test (count $argv) -ne 1
        echo "Usage: !urlinfo <slug>"
        return 1
    end

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l response (curl -fsS \
        -H "X-API-Key: $URL_API_KEY" \
        "https://s.sudopkw.dev/api/v1/links/$argv[1]" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Failed to fetch link."
        return 1
    end

    echo "$response" | jq -r '
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
    '
end

function !urlstats
    # description: Show analytics for a short URL
    # category: LINKS

    if test (count $argv) -lt 1; or test (count $argv) -gt 3
        echo "Usage: !urlstats <slug> [start_date] [end_date]"
        return 1
    end

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l endpoint "https://s.sudopkw.dev/api/v1/analytics/$argv[1]"

    if test (count $argv) -ge 2
        set endpoint "$endpoint?start_date="(string escape --style=url "$argv[2]")
    end

    if test (count $argv) -eq 3
        set endpoint "$endpoint&end_date="(string escape --style=url "$argv[3]")
    end

    set -l response (curl -fsS \
        -H "X-API-Key: $URL_API_KEY" \
        "$endpoint" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Failed to fetch analytics."
        return 1
    end

    echo "$response" | jq -r '
        .data |
        "LINK: \(.link.short_url // .link.slug)",
        "",
        "TOTAL CLICKS: \(.summary.total_clicks)",
        "",
        "BY DATE",
        (.clicks_by_date[] | "  \(.date): \(.clicks)"),
        "",
        "BY COUNTRY",
        (.clicks_by_country[] | "  \(.country // "Unknown"): \(.clicks)"),
        "",
        "BY DEVICE",
        (.clicks_by_device[] | "  \(.device // "Unknown"): \(.clicks)"),
        "",
        "BY BROWSER",
        (.clicks_by_browser[] | "  \(.browser // "Unknown"): \(.clicks)")
    '
end

function !urllist
    # description: List your shortened URLs
    # category: LINKS

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l limit 50
    set -l search ""

    for arg in $argv
        switch $arg
            case -n --limit
                set limit $argv[(contains -i -- $arg $argv) + 1]
            case -s --search
                set search $argv[(contains -i -- $arg $argv) + 1]
            case "*"
                echo "Usage: !urllist [-n|--limit <number>] [-s|--search <query>]"
                return 1
        end
    end

    set -l endpoint "https://s.sudopkw.dev/api/v1/links?limit=$limit"

    if test -n "$search"
        set endpoint "$endpoint&search="(string escape --style=url "$search")
    end

    set -l response (curl -fsS \
        -H "X-API-Key: $URL_API_KEY" \
        "$endpoint" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Failed to fetch links."
        return 1
    end

    echo "$response" | jq -r '
        .data[] |
        "\(.slug)\t\(.short_url)\t\(.click_count) clicks"
    ' | column -t -s (printf '\t')
end

function !urlfind
    # description: Search shortened URLs
    # category: LINKS

    if test (count $argv) -lt 1
        echo "Usage: !urlfind <query>"
        return 1
    end

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l query (string join " " -- $argv)
    set -l encoded (string escape --style=url "$query")

    set -l response (curl -fsS \
        -H "X-API-Key: $URL_API_KEY" \
        "https://s.sudopkw.dev/api/v1/links/search?q=$encoded&limit=50" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Search failed."
        return 1
    end

    echo "$response" | jq -r '
        .data[] |
        "\(.slug)\t\(.url)"
    ' | column -t -s (printf '\t')
end

function !rmurl
    # description: Delete a shortened URL
    # category: LINKS

    if test (count $argv) -ne 1
        echo "Usage: !rmurl <slug>"
        return 1
    end

    if not set -q URL_API_KEY
        echo "ERROR: URL_API_KEY is not set."
        return 1
    end

    set -l slug $argv[1]

    printf "Delete '%s'? [y/N] " "$slug"
    read -l confirm

    if not string match -qi y -- "$confirm"
        echo "Cancelled."
        return 0
    end

    set -l response (curl -fsS \
        -X DELETE \
        -H "X-API-Key: $URL_API_KEY" \
        "https://s.sudopkw.dev/api/v1/links/$slug" 2>/dev/null)

    if test $status -ne 0
        echo "ERROR: Failed to delete link."
        return 1
    end

    echo "$response" | jq -r '.message // "Link deleted."'
end

function !urlvalid
    # description: Check whether a URL is reachable
    # category: LINKS

    if test (count $argv) -ne 1
        echo "Usage: !urlvalid <url>"
        return 1
    end

    set -l target $argv[1]

    if not string match -rq '^https?://' -- "$target"
        echo "✘ Invalid URL format."
        return 1
    end

    set -l status_code (curl -o /dev/null \
        -s \
        -L \
        --max-time 10 \
        -w '%{http_code}' \
        "$target")

    if test $status_code -ge 200; and test $status_code -lt 400
        echo "➜ Valid [$status_code] $target"
        return 0
    end

    if test "$status_code" = 000
        echo "✘ Unreachable $target"
        return 1
    end

    echo "✘ HTTP $status_code $target"
    return 1
end
