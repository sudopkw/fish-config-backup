# ---------------------------------------------------------
# GIT
# ---------------------------------------------------------

function __git_check_deps
    set -l theme ~/.local/state/omarchy/current/theme/colors.toml
    set -l accent (string match -r '^accent[[:space:]]*=[[:space:]]*"([^"]+)"' < $theme)[2]
    test -n "$accent"; or set accent normal
    if not command -q git
        set_color $accent
        echo " 🛈: Missing package: git"
        set_color normal
        read -P " ➜ Install it now with pacman? [y/N] " answer
        if string match -qr '^[yY]' -- $answer
            sudo pacman -S --needed --noconfirm git
            or return 1
        else
            return 1
        end
    end
    return 0
end

function !gs
    # description: Show Git repository status
    # category: GIT
    __git_check_deps; or return 1
    git status
end

function !ga
    # description: Shorter git add command
    # category: GIT
    __git_check_deps; or return 1
    if test (count $argv) -eq 0
        echo "Usage: !ga <file, directory, or .>"
        return 1
    end

    git add $argv[1]
end

function !gc
    # description: Create a Git commit
    # category: GIT
    __git_check_deps; or return 1
    if test (count $argv) -eq 0
        echo "Usage: !gc <commit message>"
        return 1
    end

    git commit -m $argv[1]
end

function !gp
    # description: Push Git changes
    # category: GIT
    __git_check_deps; or return 1
    git push
end

function !gundo
    # description: Undo git changes
    # category: GIT
    __git_check_deps; or return 1
    git reset --soft HEAD-1
end

function !glog
    __git_check_deps; or return 1
    git log --oneline --decorate --graph --all
end

function !gd
    # description: Show Git changes
    # category: GIT
    __git_check_deps; or return 1
    git diff
end

function !gclone
    # description: Clone a Git repository
    # category: GIT
    __git_check_deps; or return 1
    if test (count $argv) -eq 0
        echo "Usage: !gclone <repository-url>"
        return 1
    end

    git clone $argv[1]
end
