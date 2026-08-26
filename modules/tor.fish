# ---------------------------------------------------------
# TOR
# ---------------------------------------------------------

function !tor
    # description: Start the TOR service
    # category: TOR
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
    sudo systemctl restart tor
    echo "ꪜ TOR Restarted!"
end

function !torstatus
    # description: Show TOR status
    # category: TOR
    systemctl status tor --no-pager -l
end

function !torcheck
    # description: Check if TOR is connected
    # category: TOR
    curl -s --socks5 127.0.0.1:1337 https://check.torproject.org/api/ip
end

function !ventor
    # description: runs vencord trough TOR
    # category: TOR
    torsocks discord &
end
