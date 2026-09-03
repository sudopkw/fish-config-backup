function !cobalt
    set -l cobalt_dir "$HOME/.local/share/cobalt"
    set -l compose "$cobalt_dir/docker-compose.yml"
    set -l tmpdir "$HOME/.cache/cobalt"

    function __cobalt_box
        set -l theme "$HOME/.local/state/omarchy/current/theme/colors.toml"
        set -l accent
        set -l foreground
        set -l error_color red

        if test -f "$theme"
            set accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < "$theme")[2]
            set foreground (string match -r '^foreground[[:space:]]*=[[:space:]]*"([^"]+)"' < "$theme")[2]
        end

        if test -z "$accent"
            set accent normal
        end

        if test -z "$foreground"
            set foreground normal
        end

        set -l title "$argv[1]"
        set -e argv[1]

        set -l max_length 0

        for msg in $argv
            set -l length (string length -- "$msg")
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

        set -l content_width $max_length
        set -l inner_width (math "$content_width + 2")
        set -l border (string repeat -n $inner_width "─")

        printf "\n"

        set_color $accent
        printf "╭%s╮\n" "$border"

        set_color $accent
        printf "│   ── %s" "$title"

        set -l title_padding (math "$inner_width - $title_length - 6")

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

        for msg in $argv
            set_color $accent
            printf "│ "

            if string match -q 'http://*' -- "$msg"
                set_color $error_color
            else if string match -q 'https://*' -- "$msg"
                set_color $error_color
            else
                set_color $foreground
            end

            printf "%-*s" $content_width "$msg"

            set_color $accent
            printf " │\n"
        end

        set_color $accent
        printf "╰%s╯\n" "$border"

        set_color normal
        printf "\n"
    end

    function __cobalt_command
        set -l title "$argv[1]"
        set -e argv[1]

        set -l output_dir "$HOME/.cache/cobalt"

        mkdir -p "$output_dir"

        if test $status -ne 0
            __cobalt_box ERROR \
                "Could not create temporary output directory." \
                "$output_dir"
            return 1
        end

        set -l output "$output_dir/output"

        rm -f "$output"

        command $argv >"$output" 2>&1
        set -l result $status

        set -l lines

        if test -f "$output"
            if test -s "$output"
                while read -l line
                    set -a lines "$line"
                end <"$output"
            end
        end

        rm -f "$output"

        if test (count $lines) -eq 0
            set lines "No output."
        end

        __cobalt_box "$title" $lines

        return $result
    end

    function __cobalt_error
        __cobalt_box ERROR $argv
    end

    function __cobalt_ok
        __cobalt_box COBALT $argv
    end

    if test "$argv[1]" = --help -o "$argv[1]" = help
        __cobalt_box COBALT \
            "!cobalt          Start and open Cobalt" \
            "!cobalt stop     Stop Cobalt" \
            "!cobalt restart  Restart Cobalt" \
            "!cobalt update   Update Cobalt" \
            "!cobalt logs     Show logs" \
            "!cobalt remove   Remove Cobalt"
        return
    end

    if test "$argv[1]" = stop
        if not test -f "$compose"
            __cobalt_error \
                "Cobalt is not installed." \
                "Nothing to stop."
            return 1
        end

        __cobalt_command "STOPPING COBALT" \
            docker compose -f "$compose" down

        if test $status -eq 0
            __cobalt_ok "Cobalt stopped."
        else
            __cobalt_error "Failed to stop Cobalt."
            return 1
        end

        return
    end

    if test "$argv[1]" = restart
        if not test -f "$compose"
            __cobalt_error "Cobalt is not installed."
            return 1
        end

        __cobalt_command "RESTARTING COBALT" \
            docker compose -f "$compose" restart

        if test $status -eq 0
            __cobalt_ok "Cobalt restarted."
        else
            __cobalt_error "Failed to restart Cobalt."
            return 1
        end

        return
    end

    if test "$argv[1]" = logs
        if not test -f "$compose"
            __cobalt_error "Cobalt is not installed."
            return 1
        end

        docker compose -f "$compose" logs -f
        return
    end

    if test "$argv[1]" = update
        if not test -d "$cobalt_dir/source/.git"
            __cobalt_error \
                "Cobalt is not installed." \
                "Run '!cobalt' first."
            return 1
        end

        __cobalt_command "UPDATING SOURCE" \
            git -C "$cobalt_dir/source" pull --ff-only

        if test $status -ne 0
            __cobalt_error \
                "Failed to update the Cobalt source." \
                "Your existing installation was left untouched."
            return 1
        end

        __cobalt_command "UPDATING API" \
            docker compose -f "$compose" pull cobalt-api

        if test $status -ne 0
            __cobalt_error \
                "Failed to update the Cobalt API image." \
                "Your existing installation was left untouched."
            return 1
        end

        __cobalt_command "BUILDING WEB" \
            docker compose -f "$compose" build --pull

        if test $status -ne 0
            __cobalt_error \
                "The Cobalt web image failed to build." \
                "Run '!cobalt logs' for more information."
            return 1
        end

        __cobalt_command "STARTING COBALT" \
            docker compose -f "$compose" up -d

        if test $status -ne 0
            __cobalt_error "Failed to restart Cobalt after updating."
            return 1
        end

        __cobalt_ok \
            "Cobalt has been updated." \
            "Run !cobalt to open it."

        return
    end

    if test "$argv[1]" = remove
        if not test -f "$compose"
            __cobalt_error "Cobalt is not installed."
            return 1
        end

        __cobalt_command "REMOVING COBALT" \
            docker compose -f "$compose" down --rmi local

        if test $status -ne 0
            __cobalt_error "Failed to remove Cobalt containers."
            return 1
        end

        rm -rf "$cobalt_dir"
        rm -rf "$tmpdir"

        __cobalt_ok "Cobalt has been completely removed."
        return
    end

    if not command -q docker
        __cobalt_error \
            "Docker is not installed." \
            "" \
            "Install it with:" \
            "sudo pacman -S docker docker-compose"
        return 1
    end

    if not docker info >/dev/null 2>&1
        __cobalt_error \
            "Docker is not accessible." \
            "" \
            "Start the Docker daemon with:" \
            "sudo systemctl enable --now docker" \
            "" \
            "If permission is denied:" \
            "sudo usermod -aG docker \$USER"
        return 1
    end

    if not test -d "$cobalt_dir/source/.git"
        mkdir -p "$cobalt_dir"

        __cobalt_command "INSTALLING COBALT" \
            git clone --depth 1 \
            https://github.com/imputnet/cobalt.git \
            "$cobalt_dir/source"

        if test $status -ne 0
            __cobalt_error \
                "Failed to download Cobalt." \
                "Check your internet connection and try again."
            return 1
        end
    end

    if not test -f "$cobalt_dir/Dockerfile.web"
        printf '%s\n' \
            'FROM node:24-alpine AS build' \
            '' \
            'WORKDIR /app' \
            '' \
            'RUN apk add --no-cache git' \
            'RUN corepack enable' \
            '' \
            'COPY source/.git ./.git' \
            'COPY source/package.json source/pnpm-lock.yaml source/pnpm-workspace.yaml ./' \
            'COPY source/packages ./packages' \
            'COPY source/web ./web' \
            '' \
            'RUN pnpm install --frozen-lockfile' \
            '' \
            'ENV WEB_DEFAULT_API=http://localhost:9000/' \
            '' \
            'RUN pnpm --filter=@imput/cobalt-web exec svelte-kit sync' \
            'RUN pnpm --filter=@imput/cobalt-web build' \
            '' \
            'FROM nginx:alpine' \
            '' \
            'COPY --from=build /app/web/build /usr/share/nginx/html' \
            'COPY nginx.conf /etc/nginx/nginx.conf' \
            '' \
            'EXPOSE 80' \
            '' \
            'CMD ["nginx", "-g", "daemon off;"]' >"$cobalt_dir/Dockerfile.web"
    end

    if not test -f "$cobalt_dir/nginx.conf"
        printf '%s\n' \
            'events {}' \
            '' \
            'http {' \
            '    include /etc/nginx/mime.types;' \
            '' \
            '    types {' \
            '        application/javascript mjs;' \
            '        application/wasm wasm;' \
            '    }' \
            '' \
            '    server {' \
            '        listen 80;' \
            '        server_name _;' \
            '' \
            '        root /usr/share/nginx/html;' \
            '        index index.html;' \
            '' \
            '        location / {' \
            '            try_files $uri $uri/ /index.html;' \
            '        }' \
            '    }' \
            '}' >"$cobalt_dir/nginx.conf"
    end

    if not test -f "$compose"
        printf '%s\n' \
            'services:' \
            '  cobalt-api:' \
            '    image: ghcr.io/imputnet/cobalt:11' \
            '    init: true' \
            '    read_only: true' \
            '    restart: unless-stopped' \
            '    container_name: cobalt-api' \
            '    ports:' \
            '      - "9000:9000"' \
            '    environment:' \
            '      API_URL: "http://localhost:9000/"' \
            '' \
            '  cobalt-web:' \
            '    build:' \
            '      context: .' \
            '      dockerfile: Dockerfile.web' \
            '    restart: unless-stopped' \
            '    container_name: cobalt-web' \
            '    ports:' \
            '      - "8787:80"' \
            '    depends_on:' \
            '      - cobalt-api' >"$compose"
    end

    set -l running (docker compose -f "$compose" ps --status running -q 2>/dev/null)

    if test -n "$running"
        if curl -fsS http://localhost:9000/ >/dev/null 2>&1
            __cobalt_ok \
                "Cobalt is already running." \
                "" \
                "Web interface: http://localhost:8787" \
                "API:            http://localhost:9000"

            xdg-open http://localhost:8787 >/dev/null 2>&1 &
            return
        end
    end

    set -l web_image (docker image inspect cobalt-web --format '{{.Id}}' 2>/dev/null)

    if test -n "$web_image"
        __cobalt_command "STARTING COBALT" \
            docker compose -f "$compose" up -d
    else
        __cobalt_command "INSTALLING COBALT" \
            docker compose -f "$compose" up -d --build
    end

    if test $status -ne 0
        __cobalt_error \
            "Failed to start Cobalt." \
            "" \
            "Run '!cobalt logs' for more information."
        return 1
    end

    set -l ready false

    for i in (seq 1 30)
        if curl -fsS http://localhost:9000/ >/dev/null 2>&1
            set ready true
            break
        end

        sleep 1
    end

    if not $ready
        __cobalt_error \
            "Cobalt API did not become ready." \
            "" \
            "Run '!cobalt logs' for more information."
        return 1
    end

    __cobalt_ok \
        "Cobalt is ready." \
        "" \
        "Web interface: http://localhost:8787" \
        "API:            http://localhost:9000"

    xdg-open http://localhost:8787 >/dev/null 2>&1 &
end
