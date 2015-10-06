<#
    .Synopsis
        Manually Run Quick IR
    .DESCRIPTION
        Manually Run Quick IR
    .EXAMPLE
        RUN-IR -computername okclpt07403991
#>

function Run-IR {

    Param (
    $computername
    )

    $creds = Get-Credential

    Invoke-Command -ComputerName $computername -ScriptBlock {IEX (New-Object System.Net.Webclient).DownloadString('http://[change me]/quickIR.ps1')}
}

