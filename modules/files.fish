# ---------------------------------------------------------
# FILES & DIRECTORIES
# ---------------------------------------------------------

function !up
    # description: Go up one dir
    # category: FILES
    cd ..
end

function !up2
    # description: Go up two dirs
    # category: FILES
    cd ../..
end

function !mkcd
    # description: Create a directory and enter it
    # category: FILES

    if test (count $argv) -eq 0
        echo "Usage: !mkcd <directory>"
        return 1
    end

    mkdir -p -- $argv[1]; and cd -- $argv[1]
end
