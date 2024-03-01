# Network Namespace Setup Script

This Bash script is designed to set up a basic network environment using network namespaces on a Linux system. The script creates two network namespaces (red and green), a bridge (br0), and connects them using virtual Ethernet pairs (veth). Additionally, it configures IP addresses, sets up routing, and enables packet forwarding to allow communication between the namespaces. Custom namespaces also allows egress traffic.

## Prerequisites

Before running the script, ensure that the following packages are installed on your system:

```bash
sudo apt update
sudo apt install -y iproute2 iptables net-tools iputils-ping
```

## Script Overview

1. **Clear Terminal:**
   ```bash
   clear
   ```
   Clears the terminal for better visibility. It removes the package update and installation related clutters from screen.

2. **Create Network Namespaces and Bridge:**
   ```bash
   sudo ip netns add red
   sudo ip netns add green
   sudo ip link add br0 type bridge
   sudo ip link set br0 up
   sudo ip addr add 192.168.0.1/16 dev br0
   ```
   Creates two network namespaces (red and green), a bridge (br0). Also assigning an IP address to the bridge.

3. **Create Veth Pairs and Assign to Bridge:**
   ```bash
   sudo ip link add veth0 type veth peer name ceth0
   sudo ip link add veth1 type veth peer name ceth1
   sudo ip link set veth0 master br0
   sudo ip link set veth1 master br0
   ```
   Creates two pairs of virtual Ethernet devices (veth) and assigns them to the bridge.

4. **Assign Veth Pairs to Network Namespaces:**
   ```bash
   sudo ip link set ceth0 netns red
   sudo ip link set ceth1 netns green
   ```
   Moves one end of each veth(ceth0 & ceth1) pair to the respective network namespace.

5. **Bring Up Network Interfaces:**
   ```bash
   sudo ip link set veth0 up
   sudo ip link set veth1 up
   sudo ip netns exec red ip link set ceth0 up
   sudo ip netns exec green ip link set ceth1 up
   sudo ip netns exec green ip link set lo up
   sudo ip netns exec red ip link set lo up
   ```
   Brings up the network interfaces in the bridge and network namespaces. `lo` interface is optional. However, for future usage keeping it up.

6. **Configure IP Addresses:**
   ```bash
   sudo ip netns exec green ip addr add 192.168.0.3/16 dev ceth1
   sudo ip netns exec red ip addr add 192.168.0.2/16 dev ceth0
   ```
   Assigns IP addresses to the interfaces in the custom network namespaces.

7. **Add Route to Default Gateway:**
   ```bash
   sudo ip netns exec red ip route add default via 192.168.0.1
   sudo ip netns exec green ip route add default via 192.168.0.1
   ```
   Sets up routing for default gateways in both network namespaces.

8. **Ping Between Network Namespaces:**
   ```bash
   sudo ip netns exec red ping 192.168.0.3 -c 5
   sudo ip netns exec green ping 192.168.0.2 -c 5
   ```
   Tests connectivity between the red and green network namespaces. It Works! 🕺🕺🕺

9. **Enable IP Forwarding and Set Up NAT:**
   ```bash
   sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE
   ```
   We are doing this to because even though our packets can reach outside. Due to having a private network address public ip will not return anything to us. With this configration we are allowing our private ip to act like and public ip. Basically, this command enables IP forwarding and sets up Network Address Translation (NAT) for internet access.

10. **Optional Packet Forwarding:**
    ```bash
    sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
    sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT
    ```
    Optional: Enables packet forwarding between interfaces on the bridge.

11. **Ping External Hosts From Network Namespace:**
    ```bash
    sudo ip netns exec red ping 8.8.8.8 -c 5
    sudo ip netns exec green ping 8.8.8.8 -c 5
    ```
    Tests connectivity from the red and green network namespaces to an external host (e.g., Google DNS).

## Notes
- This script assumes that the script user has sufficient privileges to run sudo commands.
- Adjust IP addresses, routes, and other configurations according to your specific network requirements.
- Ensure that the kernel has support for network namespaces and bridge interfaces.

Feel free to modify the script to suit your network setup and requirements. ciao! 👋
