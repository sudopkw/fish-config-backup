# ---------------------------------------------------------
# GIT
# ---------------------------------------------------------

function !gs
    # description: Show Git repository status
    # category: GIT
    git status
end

function !ga
    # description: Shorter git add command
    # category: GIT

    if test (count $argv) -eq 0
        echo "Usage: !ga <file, directory, or .>"
        return 1
    end

    git add $argv[1]
end

function !gc
    # description: Create a Git commit
    # category: GIT

    if test (count $argv) -eq 0
        echo "Usage: !gc <commit message>"
        return 1
    end

    git commit -m $argv[1]
end

function !gp
    # description: Push Git changes
    # category: GIT
    git push
end

function !gd
    # description: Show Git changes
    # category: GIT
    git diff
end

function !gclone
    # description: Clone a Git repository
    # category: GIT

    if test (count $argv) -eq 0
        echo "Usage: !gclone <repository-url>"
        return 1
    end

    git clone $argv[1]
end
