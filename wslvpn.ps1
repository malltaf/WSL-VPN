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
