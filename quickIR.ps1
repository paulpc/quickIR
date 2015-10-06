# IP address of server running logstash tcp listner
$serverIP = "[the IP of this VM]"
# port to tcp connection
$port = 1514
# Get Current Logged In User
$me = Get-WMIObject -class Win32_ComputerSystem | select username
# Get Hostname
$hostname=hostname

# From Ryan Ries http://serverfault.com/users/104624/ryan-ries
Function Send-StringOverTcp ( 
    [Parameter(Mandatory=$True)][String]$DataToSend,
    [Parameter(Mandatory=$True)][IPAddress]$Hostname, 
    [Parameter(Mandatory=$True)][UInt16]$Port)
{
    Try
    {
        $ErrorActionPreference = "Stop"
        $TCPClient  = New-Object Net.Sockets.TcpClient
        $IPEndpoint = New-Object Net.IPEndPoint($Hostname, $Port)
        $TCPClient.Connect($IPEndpoint)
        $NetStream  = $TCPClient.GetStream()
        [Byte[]]$Buffer = [Text.Encoding]::ASCII.GetBytes($DataToSend+"`n")
        $NetStream.Write($Buffer, 0, $Buffer.Length)
        $NetStream.Flush()
    }
    Finally
    {
        If ($NetStream) { $NetStream.Dispose() }
        If ($TCPClient) { $TCPClient.Dispose() }
    }
}

Function Set-MetaData ( 
    [Parameter(Mandatory=$True)][String]$user,
    [Parameter(Mandatory=$True)][Object]$object,
    [Parameter(Mandatory=$True)][String]$hostname, 
    [Parameter(Mandatory=$True)][String]$type)
{
 Add-Member -InputObject $object username $user
 Add-Member -InputObject $object hostname $hostname
 Add-Member -InputObject $object type $type
}


# Processes
foreach($proc in Get-WmiObject -class Win32_Process | Select-Object -property ExecutablePath,CommandLine,Caption, ProcessName, Description, sessionid, processid) {
 Set-MetaData -u $me.username -hostname $hostname -type "process" -object $proc
 $proc.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
 $out_json = $proc | ConvertTo-Json -Compress
 Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Services
foreach($serv in Get-WmiObject -class Win32_Service | Select-Object -property Name, Status, PathName, ServiceType, StartMode,DisplayName, Description) {
 Set-MetaData -u $me.username -hostname $hostname -type "service" -object $serv
 $serv.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
 $out_json = $serv | ConvertTo-Json -Compress
 Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Startup
foreach($startup in Get-WmiObject -class Win32_StartupCommand | Select-Object -Property Name, User, Command, Path, Location) {
 Set-MetaData -u $me.username -hostname $hostname -type "startup" -object $startup
 $startup.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
 $out_json = $startup | ConvertTo-Json -Compress
 Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Get local groups
foreach($group in Get-WmiObject -class Win32_Group -Filter {localaccount = "True"} | Select-Object -Property Name,Scope,Caption,Description)   {
 Set-MetaData -u $me.username -hostname $hostname -type "group" -object $group
 $group.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
 $out_json = $group | ConvertTo-Json -Compress
 Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Get local useraccounts
foreach($useraccount in Get-WmiObject -class Win32_Useraccount -Filter {localaccount= "True"} | Select-Object -Property Name,Description,Disabled,Status) {
 Set-MetaData -u $me.username -hostname $hostname -type "useraccount" -object $useraccount
 $useraccount.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
 $out_json = $useraccount | ConvertTo-Json -Compress
 Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Get prefetch
foreach($prefetch in Get-ChildItem -path C:\windows\prefetch\*.pf | select Name, Length, FullName, CreationTime){
    Set-MetaData -u $me.username -hostname $hostname -type "prefetch" -object $prefetch
    $prefetch.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
    $out_json = $prefetch | ConvertTo-Json -Compress
    Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

# Nic List
foreach($nic in Get-WmiObject -class Win32_NetworkAdapter | select Name, ServiceName)
{
    Set-MetaData -u $me.username -hostname $hostname -type "nic" -object $nic
    $nic.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
    $out_json = $nic | select Name, ServiceName, username, hostname, type | ConvertTo-Json -Compress
    Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

#Software inventory
foreach($software in Get-WmiObject -class Win32_Product | select *)
{
    Set-MetaData -u $me.username -hostname $hostname -type "software" -object $software
    $software.psobject.properties | % {if($_.Value -eq $null){$_.Value = "empty"}}
    $out_json = $software | select Name, Version, Vendor, InstallDate, InstallSource, PackageName, username, hostname, type | ConvertTo-Json -Compress
    Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
}

#md5
foreach($loc in Get-WmiObject win32_userprofile | where {$_.special -eq $false} | select localpath, sid)
{
   $path = @() # create empty array then add paths we want to check.
   $path += $Env:ProgramData
   $path += $loc.localpath + "\AppData\"
   $path += $Env:windir + "\temp\"
   
   foreach ($folder in $path){
       $file = Get-ChildItem $folder -Recurse -Include *.exe,*.dll -ErrorAction SilentlyContinue
       foreach($f in $file)
       {
            $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
            try
            {
                $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($f.FullName)))
            }
            catch
            {
                #catching errors but we don't need to display them.
            }
            $hash = $hash -replace "-", ""
            Add-Member -InputObject $f hash $hash
            Set-MetaData -u $me.username -hostname $hostname -type "md5" -object $f
            $out_json = $f | select Name, FullName, hash, username, hostname, type | ConvertTo-Json -Compress
            Send-StringOverTcp -DataToSend $out_json -Hostname $serverIP -Port $port
       }
   }

}
