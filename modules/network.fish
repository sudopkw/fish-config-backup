# ---------------------------------------------------------
# NETWORK
# ---------------------------------------------------------

function !ports
    # description: Show listening network ports
    # category: NET
    ss -tulpn
end

function !ip
    # description: Show public IP address
    # category: NET
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

    if test (count $argv) -eq 0
        echo "Usage: !trace <host>"
        return 1
    end

    traceroute $argv[1]
end
