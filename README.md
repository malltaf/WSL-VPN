# WSL-VPN
Solving the problem of the availability of the Internet and work resources in WSL2 with a VPN connected (CheckPoint)

## Problem
When connecting a VPN on Windows OC (using Check Point Virtual Network Adapter in my case) in WSL2 (Ubuntu 20.04.3), access to the Internet and to the workspace via VPN was lost. Other recommendations didn't help (neither at the Windows level, nor at the WSL level).

## Solution
First, perform all actions with a VPN connected.

We need to set MTU 1350 inside WSL on eth0:
```Shell
sudo ifconfig eth0 mtu 1350
```
Or in any other way that suits you. Can be added to yours .bashrc.

Then execute the script in PowerShell:
```PowerShell
# Get WSL and VPN adapters
$WSL = Get-NetAdapter -IncludeHidden -Name "vEthernet (WSL)" | where status -eq 'up'
$VPN = Get-NetAdapter -InterfaceDescription "Check Point Virtual Network Adapter*" | where status -eq 'up' 

# Get pattern to use in route deletion (VPN activation adds some shit in route table and we need to clean that shit ...)
$WSLNetIpAddr = $WSL | Get-NetIPAddress -AddressFamily IPv4 | Select-Object IPAddress | Select -ExpandProperty IPAddress
$IpAddrArray = $WSLNetIpAddr -split "\."
$WSLNetIpAddrFirstTwoOctets = $IpAddrArray[0,1] -join "."
$RouteDeletionPattern = $WSLNetIpAddrFirstTwoOctets -replace '$','*'

# Lets do it
Get-NetRoute | where { $_.ifIndex -eq $VPNifIndex -and $_.DestinationPrefix -like $RouteDeletionPattern -and  $_.DestinationPrefix -notlike "172.16.0.0/16*"} | Remove-NetRoute -Confirm:$false

# Get WSL ip, cuz we need to ping WSL to make magic work
$WSLIpAddr = wsl hostname -I
Test-Connection -ComputerName $WSLIpAddr.trim() -Quiet -Count 1
```
After that, everything works.

You can add these scripts to startup.

For example, create a trigger in the task scheduler for a vpn connection event:  
Microsoft-Windows-NetworkProfile/Operational  
event code 10000  
And the condition is to run only when connected to your network (select the name of the vpn network on the Conditions tab).

