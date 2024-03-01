#!/bin/bash

# Update and install required packages  
sudo apt update  
sudo apt install -y iproute2 iptables net-tools iputils-ping

# Clear the terminal  
clear

# Create network namespaces and bridge  
sudo ip netns add red  
sudo ip netns add green  
sudo ip link add br0 type bridge  
sudo ip link set br0 up  
sudo ip addr add 192.168.0.1/16 dev br0

# Create veth pairs and assign to bridge  
sudo ip link add veth0 type veth peer name ceth0  
sudo ip link add veth1 type veth peer name ceth1  
sudo ip link set veth0 master br0  
sudo ip link set veth1 master br0

# Move veth pairs to network namespaces  
sudo ip link set ceth0 netns red  
sudo ip link set ceth1 netns green

# Bring up network interfaces  
sudo ip link set veth0 up  
sudo ip link set veth1 up  
sudo ip netns exec red ip link set ceth0 up  
sudo ip netns exec green ip link set ceth1 up  
sudo ip netns exec green ip link set lo up  
sudo ip netns exec red ip link set lo up

# Configure IP addresses  
sudo ip netns exec green ip addr add 192.168.0.3/16 dev ceth1  
sudo ip netns exec red ip addr add 192.168.0.2/16 dev ceth0

# Add Route to Default Gateway  
sudo ip netns exec red ip route add default via 192.168.0.1  
sudo ip netns exec green ip route add default via 192.168.0.1

# Ping From Red NS to Green NS & Vice-Versa  
sudo ip netns exec red ping 192.168.0.3 -c 5  
sudo ip netns exec green ping 192.168.0.2 -c 5

# Enable IP forwarding and set up NAT  
sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE

# Optional Packet Forwarding is needed  
sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT  
sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT

# Enter red namespace and ping external host  
sudo ip netns exec red ping 8.8.8.8 -c 5  
sudo ip netns exec green ping 8.8.8.8 -c 5
