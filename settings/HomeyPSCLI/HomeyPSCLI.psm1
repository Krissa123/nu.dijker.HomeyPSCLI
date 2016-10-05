﻿### Internal 

function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

### Homey PS CLI 
function Export-HomeyAppsVar
{
    param (
    [string] $AppUri )
    $_HomeyUriGetAppVar = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/settings/app/$AppUri/variables"
    $_AppWR = Invoke-WebRequest -Uri "$_HomeyUriGetAppVar" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $_AppJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR, [System.Collections.Hashtable])
    # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    return $_AppJSON.result 
}

function Export-HomeySystemSettings
{
    param (
    [string] $AppUri )
    $_HomeyUriGetAppVar = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/$AppUri"
    $_AppWR = Invoke-WebRequest -Uri "$_HomeyUriGetAppVar" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $_AppJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR, [System.Collections.Hashtable])
    # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    return $_AppJSON.result 
}

function Import-HomeyAppsVar
{
    param (
    [string] $AppUri,
    [string] $JSONFile,
    [switch] $AddMissingVar
    )
    $_HomeyUriGetAppVar = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/settings/app/$AppUri/variables"
    If ($AppUri -eq 'nl.bevlogenheid.countdown' ) { 
        $_HomeyUriPutAppVar = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/settings/app/$AppUri/changedvariables" 
    }  Else { 
        $_HomeyUriPutAppVar = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/settings/app/$AppUri/variables" 
    }   

    If (Test-Path $JSONFile) {
        $NewAppsVar = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json 
        $_AppWR = try {
            Invoke-WebRequest -Uri "$_HomeyUriGetAppVar" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
        } catch { 
            $_.Exception.Response
            Write-Host "Warning: App does not Exists! " -ForegroundColor Yellow
        }
        If ($_AppWR.StatusCode -eq 200) {
            $_AllCurrentVars = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR.Content, [System.Collections.Hashtable]).result
            If ($AddMissingVar) {
                ## $_AllVarsNew | ForEach-Object { if ($_.name -notin ($_AllVars.name) ) { $_ ;$_AllVars += $_ } }
                $NewAppsVar | ForEach-Object { if ($_.name -notin ($_AllCurrentVars.name) ) { $_AllCurrentVars += $_ } }
                $NewAppsVar = $_AllCurrentVars 
            } 
            $CompressedJSONVar = $NewAppsVar | ConvertTo-Json -Depth 99  -Compress
            $CompressedJSONVarValue = "{""value"":$CompressedJSONVar}"
            $_AppWR = Invoke-WebRequest -Uri "$_HomeyUriPutAppVar" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -Method Put -Body $CompressedJSONVarValue
            $_AppJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR, [System.Collections.Hashtable])
            # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
            return $_AppJSON.result 
        }
    } Else {
        Write-Host "Error: File $JSONFile not found!" 
    }
}

### Homey PS CLI 
function Get-HomeyPendingUpdate
{
    param (
    [switch] $Verbose,
    [switch] $InstallPendingUpdate
    )
    $_HomeyUriPendingUpdate = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/updates/update/"

    $_AppWR = Invoke-WebRequest -Uri "$_HomeyUriPendingUpdate" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    $_AppJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR, [System.Collections.Hashtable])
    $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    If ($_AppJSON.result.size -gt 10) {
        If ($Verbose) {
        " Date    : {0}" -f $_AppJSON.result.date
        " Version : {0}" -f $_AppJSON.result.version
        " Size    : {0}" -f $_AppJSON.result.size
        $html = $_AppJSON.result.changelog.en
        @('br','/li' ) | % {$html = $html -replace "<$_[^>]*?>", "`n" }
        @('ul','li', '/ul' ) | % {$html = $html -replace "<$_[^>]*?>", "" }
        @('&amp;' ) | % {$html = $html -replace "$_", "&" }
        $html = $html -replace "`n`n", "`n"
        $html
        } Else { 
            return $_AppJSON.result 
        } 
        If ($InstallPendingUpdate) {
            $_HomeyUriPendingUpdate = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/updates/update/"
            $_AppWR = Invoke-WebRequest -Uri "$_HomeyUriPendingUpdate" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -Method Post
            Write-Host " Updating Homey Software, do not turn off the power! "
        } 
    } Else {
        If ($Verbose) {
        " No Updates available..."
        " Version : {0}" -f $Global:_HomeyVersion
        }
        return $_AppJSON.result 
        # return $false # No pending update 
    }
}

function New-HomeyFlow
{
    # http://10.1.13.107/api/manager/flow/flow/?_=1475505453284
    $Global:_HomeyUriFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/" 
    $_FlowWR = Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -Method Post
    $_FlowJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FlowWR, [System.Collections.Hashtable])
    # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    return $_FlowJSON.result
}

function Remove-HomeyFlow
{
    param (
    [string] $ID
    )
    # http://10.1.13.107/api/manager/flow/flow/02467ac6-74e6-493a-80ad-869e2a7ef562
    $Global:_HomeyUriFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/$ID" 
    $_FlowWR = try {
        Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
    } catch { 
        $_.Exception.Response
    }

    If ($_FlowWR.StatusCode -eq 200 ) {
        $_FlowWR = Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -Method Delete
        $_FlowJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_AppWR, [System.Collections.Hashtable])
        # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    } Else {
        Write-Host "Error finding Flow ID: $ID" -ForegroundColor Yellow 
    }
    return $_FlowJSON.result
}

function Get-HomeyFoldersStructure
{
    # $_FolderArray = @()
    $_ExportPathFolders =  "$_HomeysExportPath\Folders"
    $_FoldersWR = Invoke-WebRequest -Uri "$_HomeyGetFoldersApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $_FoldersJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FoldersWR , [System.Collections.Hashtable])
    $Global:_HomeyVersion = $_FoldersWR.Headers.'X-Homey-Version'

    # Write-Host "-=-=- Folders "
    $_FoldersJSON.result.keys | ForEach-Object {
        If( $_FoldersJSON.result.$_.folder -eq $False ) {
            $_FolderRelPath = "$($_FoldersJSON.result.$_.title)" 
        } else { # Secondlevel Folders ## Third levvel NOT yet supported!!
            $_FolderRelPath = "$($_FoldersJSON.result.$($_FoldersJSON.result.$_.folder).title)\$($_FoldersJSON.result.$_.title)"
        }
        # $_FolderArray += ,($_,"$_FolderRelPath")
        # Write-Host "$_FolderRelPath : $($_) : $($_FoldersJSON.result.$_.folder)"
        If (!(Test-Path $_ExportPathFolders\$_FolderRelPath)) { New-Item $_ExportPathFolders\$_FolderRelPath -ItemType Directory } 
    } 
    return $_FoldersJSON.result
}

function Get-HomeyFlows
{
    $_FlowsWR = Invoke-WebRequest -Uri "$_HomeyGetFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    $_FlowsJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FlowsWR, [System.Collections.Hashtable])
    return $_FlowsJSON.result.Values
}

function Get-HomeyFlow
{
    param (
    [string] $ID
    )
    $Global:_HomeyUriFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/$ID" 
    $_FlowWR = try {
        Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
    } catch { 
        $_.Exception.Response
    }
    If ($_FlowWR.StatusCode -eq 200 ) {
        $_FlowWR = Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
        $_FlowJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FlowWR, [System.Collections.Hashtable])
    } Else {
        Write-Host "Error finding Flow ID: $ID" -ForegroundColor Yellow 
    }
    return $_FlowJSON.result
}

function Set-HomeyFlow
{
    param (
    [string] $ID,
    [string] $CompressedJSONFlow
    )
    $Global:_HomeyUriFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/$ID" 
    $_FlowWR = try {
        Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
    } catch { 
        $_.Exception.Response
    }
    If ($_FlowWR.StatusCode -eq 200 ) {
        $_FlowWR = Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -Method Put -Body $CompressedJSONFlow 
        $_FlowJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FlowWR, [System.Collections.Hashtable])
        # $Global:_HomeyVersion = $_AppWR.Headers.'X-Homey-Version'
    } Else {
        Write-Host "Error finding Flow ID: $ID" -ForegroundColor Yellow 
    }
    return $_FlowJSON.result
}

function Export-HomeyFlows
{
    # $_HomeyFlowFoldersArray[0]
    $_FlowArray = @()
    $Global:_ExportDTSt = "{0:yyyyMMddHHmmss}" -f (get-date)

    $_ExportPathFolders =  "$_HomeysExportPath\Folders"
    $_FlowsWR = Invoke-WebRequest -Uri "$_HomeyGetFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    $_FlowsJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_FlowsWR, [System.Collections.Hashtable])
    $Global:_HomeyVersion = $_FlowsWR.Headers.'X-Homey-Version'
    # $_FlowsJSON.result | ConvertTo-Json -depth 99 | Out-File -FilePath "$_ExportPathFolders$_FlowFolder\$_FlowsTitle-$_FlowsFolderID-$_HomeyVersion-$_ExportDTSt.json" 
    # Write-Host "-=-=- Flows "
    $_HomeyFlowFolders = Get-HomeyFoldersStructure 

    $_FlowsJSON.result.keys | ForEach-Object {
        $_FlowsFolderID = $_FlowsJSON.result.$_.folder
        $_FlowsID = $_FlowsJSON.result.$_.id
        $_FlowsTitle = $_FlowsJSON.result.$_.title
        # Dowsn't Work !! $Pos = [array]::IndexOf($_HomeyFlowFoldersArray,$_FlowsFolderID,0)
        # $_HomeyFlowFoldersArray[$Pos][1]
        $_FlowFolder = "\"
        If ($_FlowsFolderID -ne $false) {
            $_FlowFolder = "\"+$_HomeyFlowFolders.$_FlowsFolderID.title 
            # Second Level 
            If ($_HomeyFlowFolders.$_FlowsFolderID.folder -ne $false ) {
                    $__FlowsFolderID = $_HomeyFlowFolders.$_FlowsFolderID.folder
                    $_FlowFolder = "\"+$_HomeyFlowFolders.$__FlowsFolderID.title+$_FlowFolder 
            }
        } 

        $_FlowsJSON.result.$_ | ConvertTo-Json -depth 99 | Out-File -FilePath "$_ExportPathFolders$_FlowFolder\$_FlowsTitle-$_FlowsID-v$_HomeyVersion-$_ExportDTSt.json" 
        $_FlowArray += ,($_,"$_FlowFolder","$_FlowsTitle")

    } 
    return $_FlowsJSON.result.Values # , $_FlowArray
}

function Connect-Homey
<#
.Synopsis
   Connect-Homey (Homey by Athom http://www.athom.com)
   Beta 0.0.1
.DESCRIPTION
   Set IP Address and Bearer for your LOCAL Homey to store in a PowerShell variable Windows computer

.EXAMPLE
    Connect-Homey -IP 1.2.3.4 -Bearer abcdefg -ExportPath C:\HomeyBackup -WriteConfig

.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
   Beta beta beta.... 

.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://forum.athom.com/',
                  ConfirmImpact='Medium')]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   #Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        # [Alias("ip")] 
        [string]
        $IP,

        #Parameter 2 Bearer token for Homey
        [Parameter(ParameterSetName='Parameter Set 1')]
        [ValidatePattern("[0-9][a-f]*")]
        [ValidateLength(0,40)]
        [string]
        $Bearer, 

        # Param3 help description
        [Parameter(ParameterSetName='Parameter Set 1')]
        # [AllowNull()]
        # [AllowEmptyCollection()]
        # [AllowEmptyString()]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$true})]
        #[ValidateRange(0,5)]
        [string]
        $ExportPath,

        [string]
        $CloudID, 
        [switch]
        $WriteConfig
    )

    $ScriptDirectory = Get-ScriptDirectory
    # Write-Host "ScriptDirectory : $ScriptDirectory"
    If (Test-Path "$ScriptDirectory\Config-HomeyPSCLI.ps1" ) {
            . $ScriptDirectory\Config-HomeyPSCLI.ps1
        } 
    If ($ExportPath -ne "") { $Global:_HomeysExportPath = $ExportPath }
    If ($IP -ne "") { $Global:_HomeysIP = $IP }
    If ($Bearer -ne "") { $Global:_HomeysBearer= $Bearer }

    $Global:_HomeysProtocol = "https"

    $Global:_HomeysHeaders = @{"Authorization"="Bearer $_HomeysBearer"} 
    $Global:_HomeysContentType = "application/json"
    $Global:_HomeysCloudID = "$CloudID"
    $Global:_HomeysCloudHostname = "$CloudID.homey.athom.com"
    $Global:_HomeysCloudLocalHostname = "$CloudID.homeylocal.com"
    If ($CloudID -ne "" ) {    
        $_HomeysResolvedLocalIP =  ([System.Net.Dns]::GetHostAddresses($_HomeysCloudLocalHostname)).IPAddressToString
    }

    $_SystemWR = $null
    $Global:_HomeysConnectHost = $null

    If (Test-NetConnection $_HomeysCloudLocalHostname -InformationLevel Quiet) { 
        "$_HomeysCloudLocalHostname ICMP Response OK" 
        $Global:_HomeysProtocol = "http"
        $Global:_HomeysConnectHost = $_HomeysCloudLocalHostname
    } else { 
        If (Test-NetConnection $_HomeysIP -InformationLevel Quiet) {
            "$_HomeysIP ICMP Response OK" 
            $Global:_HomeysProtocol = "http"
            $Global:_HomeysConnectHost = $_HomeysIP
        } else {
            $_SystemWR = try {
                $Global:_HomeysCloudHostname = "$CloudID.homey.athom.com"
                $Global:_HomeyGetSystemApi = "$_HomeysProtocol`://$_HomeysCloudHostname/api/manager/system"
                Invoke-WebRequest -Uri "$_HomeyGetSystemApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
            } catch { 
                $_.Exception.Response
                Write-Host "Warning: Homey local and Cloud presentation not found! " -ForegroundColor Yellow
            }
            If ($_SystemWR -ne $null ) { 
                $Global:_HomeysConnectHost = $_HomeysCloudHostname
            } 
        }
    } 
    $Global:_HomeyGetFoldersApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/Folder/" 
    $Global:_HomeyGetFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/" 
    $Global:_HomeyGetSystemApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/system"

    $_SystemWR = Invoke-WebRequest -Uri "$_HomeyGetSystemApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType
    # $_SystemJSON = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Deserialize($_SystemWR , [System.Collections.Hashtable])
    IF ( $_SystemWR.StatusCode -eq 200 ) { 
        "$_HomeysConnectHost HTTP Response OK" 
        $Global:_HomeyVersion = $_SystemWR.Headers.'X-Homey-Version'
        "Homey version $Global:_HomeyVersion "
    }
    If ($WriteConfig) {
        "`$Global:_HomeysBearer = ""$_HomeysBearer""" | Out-File -FilePath $ScriptDirectory\Config-HomeyPSCLI.ps1
        "`$Global:_HomeysCloudID = ""$_HomeysCloudID""" | Out-File -FilePath $ScriptDirectory\Config-HomeyPSCLI.ps1 -Append
        "`$Global:_HomeysExportPath = ""$_HomeysExportPath""" | Out-File -FilePath $ScriptDirectory\Config-HomeyPSCLI.ps1 -Append
        "`$Global:_HomeysIP = ""$_HomeysIP""" | Out-File -FilePath $ScriptDirectory\Config-HomeyPSCLI.ps1 -Append
    }
}

function Export-HomeyConfig
<#
.Synopsis
   Get Export config from Homey (by Athom http://www.athom.com)
   Beta 0.0.1
.DESCRIPTION
   Get Export information from your LOCAL connected Homey to store on a Windows computer

.EXAMPLE
   Export-HomeyConfig  **** tbd -Scope [All,Flows,Devices]

.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
   Beta beta beta.... 

.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
{
    $Global:_HomeyGetFoldersApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/Folder/" 
    $Global:_HomeyGetFlowsApi = "$_HomeysProtocol`://$_HomeysConnectHost/api/manager/flow/flow/" 
    $Global:_HomeysHeaders = @{"Authorization"="Bearer $_HomeysBearer"}
    $Global:_HomeysContentType = "application/json"
    $Global:_ExportDTSt = "{0:yyyymmddHHmmss}" -f (get-date)
    $Global:_HomeyVersion =""
  
    $_FoldersJSON = Get-HomeyFoldersStructure 
    # Export to Folders.json
    $_FoldersJSON | ConvertTo-Json -depth 99 | Out-File -FilePath "$_HomeysExportPath\Folders-v$_HomeyVersion-$_ExportDTSt.json"

    $_FlowsJSON = Export-HomeyFlows 
    $_FlowsJSON | ConvertTo-Json -depth 99 | Out-File -FilePath "$_HomeysExportPath\Flows-v$_HomeyVersion-$_ExportDTSt.json" 

    # Maybe Get these dynamic 
    # Test is App enabed ?
    @('net.i-dev.betterlogic','nl.bevlogenheid.countdown') | ForEach-Object {
        $_ExportPathAppsVar =  "$_HomeysExportPath\Apps\$_"
        If (!(Test-Path $_ExportPathAppsVar)) { New-Item $_ExportPathAppsVar -ItemType Directory } 
        $return = Export-HomeyAppsVar $_ 
        $return  | ConvertTo-Json -depth 99 | Out-File -FilePath "$_ExportPathAppsVar\Vars-$_-$_HomeyVersion-$_ExportDTSt.json" 
    
        }

    # Manager/ System default Homeys settings 
    @('apps/app', 'speech-input/settings', 'speech-output/settings', 'speech-output/voice', 'ledring/brightness', 'ledring/screensaver' ,
       'speaker/settings', 'geolocation' ,  'zwave/state' , 'users/user', 'updates/settings', 'system' ) | ForEach-Object {
        $_ExportPathAppsVar =  "$_HomeysExportPath\Settings\$_"
        If (!(Test-Path $_ExportPathAppsVar)) { New-Item $_ExportPathAppsVar -ItemType Directory } 
        $return = Export-HomeySystemSettings -AppUri $_
        $n= $_ -replace "/", "-" 
        $return  | ConvertTo-Json -depth 99 | Out-File -FilePath "$_ExportPathAppsVar\Vars-$n-$_HomeyVersion-$_ExportDTSt.json" 
    }

}

function Import-HomeyFlow 
{
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   #Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        # [Alias("ip")] 
        [string] $JSONFile,
        [switch] $OverwriteFlow,
        [switch] $NewFlowID,
        [switch] $RestoreToRoot
    )
    If (Test-Path $JSONFile)     {
        $FlowObject = Get-Content -Raw -Path $JSONFile | ConvertFrom-Json 
        $FlowID = $FlowObject.id
        $_FlowWR = try {
            Invoke-WebRequest -Uri "$_HomeyUriFlowsApi" -Headers $_HomeysHeaders  -ContentType $_HomeysContentType -ErrorAction Ignore 
        } catch { 
            $_.Exception.Response
            Write-Host "Warning: Flow does not Exists! use -NewFlowID " -ForegroundColor Yellow
        }
        If ($RestoreToRoot) {$FlowObject.folder = $false}
        If ($NewFlowID) {
            $NewFlow = New-HomeyFlow
            $FlowObject.id = $NewFlow.id
            $FlowID = $FlowObject.id
            If ($_FlowWR.StatusCode -eq 200) { 
                $FlowObject.title += " (2)" 
                $FlowObject.enabled = $false
            }
        }

        If (($_FlowWR.StatusCode -eq 200) -or $NewFlowID) {
            # Flow Exists
            If ($OverwriteFlow -or $NewFlowID) {
                $CompressedJSONFlow = $FlowObject | ConvertTo-Json -Depth 99  -Compress
                Set-HomeyFlow -ID $FlowID -CompressedJSONFlow $CompressedJSONFlow 
            } Else { Write-Host "Warning: Flow already Exists! use -OverwriteFlow " -ForegroundColor Yellow }
        }
    } Else {
        Write-Host "Error: File $JSONFile not found!" 
    }
 
}

# Base code when loadeing Module 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$ScriptDirectory = Get-ScriptDirectory
Get-Command -Module HomeyPSCLI | Select-Object -Property Name, Version | FT -HideTableHeaders | Out-File -FilePath $ScriptDirectory\HomeyPSCLI-functions.txt
$HomeyPSCLIfunctions = Get-Content $ScriptDirectory\HomeyPSCLI-functions.txt -Raw
Write-Host " HomeyPSCLI Loaded!..." -ForegroundColor Green 
Write-Host "" 
Write-Host " Use Connect-Homey to configure and Test connection:" 
Write-Host "     Connect-Homey [-IP <string>] [-Bearer <string>] [-ExportPath <string>] [-WriteConfig] " -ForegroundColor Green 
Write-Host "" 
Write-Host $HomeyPSCLIfunctions
Write-Host " Have Phun with Homey from your PowerShell !" -ForegroundColor Green 

# Export-ModuleMember -Function Update-Something -Alias *