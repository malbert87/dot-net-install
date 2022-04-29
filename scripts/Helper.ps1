$scriptDir = Split-Path -Path (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) -Parent
#$scriptDir= (Get-Item (Get-ScriptDirectory)).parent.parent.FullName
# Reading configs.ini file into variables
Get-Content "$scriptDir\configs.ini" | foreach-object -begin { $h = @{ } } -process { $k = [regex]::split($_, '='); if (($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True) -and ($k[0].StartsWith("#") -ne $True)) { $h.Add($k[0], $k[1]) } }
Write-Output (Get-Content "$scriptDir\scripts\banner.txt" -Raw)
Write-Output "----------------------------------------------------------------"
Write-Output "These are the settings that you have configured and will be used"
Write-Host ($h | Out-String)


function Get-XmlNamespaceManager([xml]$XmlDocument, [string]$NamespaceURI = "") {
    # If a Namespace URI was not given, use the Xml document's default namespace.
    if ([string]::IsNullOrEmpty($NamespaceURI)) { $NamespaceURI = $XmlDocument.DocumentElement.NamespaceURI }	
	
    # In order for SelectSingleNode() to actually work, we need to use the fully qualified node path along with an Xml Namespace Manager, so set them up.
    [System.Xml.XmlNamespaceManager]$xmlNsManager = New-Object System.Xml.XmlNamespaceManager($XmlDocument.NameTable)
    $xmlNsManager.AddNamespace("ns", $NamespaceURI)
    return , $xmlNsManager		# Need to put the comma before the variable name so that PowerShell doesn't convert it into an Object[].
}

function Get-FullyQualifiedXmlNodePath([string]$NodePath, [string]$NodeSeparatorCharacter = '.') {
    return "/ns:$($NodePath.Replace($($NodeSeparatorCharacter), '/ns:'))"
}

function Get-XmlNode([xml]$XmlDocument, [string]$NodePath, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    $xmlNsManager = Get-XmlNamespaceManager -XmlDocument $XmlDocument -NamespaceURI $NamespaceURI
    [string]$fullyQualifiedNodePath = Get-FullyQualifiedXmlNodePath -NodePath $NodePath -NodeSeparatorCharacter $NodeSeparatorCharacter
	
    # Try and get the node, then return it. Returns $null if the node was not found.
    $node = $XmlDocument.SelectSingleNode($fullyQualifiedNodePath, $xmlNsManager)
    return $node
}

function Get-XmlNodes([xml]$XmlDocument, [string]$NodePath, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    $xmlNsManager = Get-XmlNamespaceManager -XmlDocument $XmlDocument -NamespaceURI $NamespaceURI
    [string]$fullyQualifiedNodePath = Get-FullyQualifiedXmlNodePath -NodePath $NodePath -NodeSeparatorCharacter $NodeSeparatorCharacter

    # Try and get the nodes, then return them. Returns $null if no nodes were found.
    $nodes = $XmlDocument.SelectNodes($fullyQualifiedNodePath, $xmlNsManager)
    return $nodes
}

function Get-XmlElementsTextValue([xml]$XmlDocument, [string]$ElementPath, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    # Try and get the node.	
    $node = Get-XmlNode -XmlDocument $XmlDocument -NodePath $ElementPath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
	
    # If the node already exists, return its value, otherwise return null.
    if ($node) { return $node.InnerText } else { return $null }
}

function Set-XmlElementsTextValue([xml]$XmlDocument, [string]$ElementPath, [string]$TextValue, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    # Try and get the node.	
    $node = Get-XmlNode -XmlDocument $XmlDocument -NodePath $ElementPath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
	
    # If the node already exists, update its value.
    if ($node) { 
        $node.InnerText = $TextValue
    }
    # Else the node doesn't exist yet, so create it with the given value.
    else {
        # Create the new element with the given value.
        $elementName = $ElementPath.Substring($ElementPath.LastIndexOf($NodeSeparatorCharacter) + 1)
        $element = $XmlDocument.CreateElement($elementName, $XmlDocument.DocumentElement.NamespaceURI)		
        $textNode = $XmlDocument.CreateTextNode($TextValue)
        $element.AppendChild($textNode) > $null
		
        # Try and get the parent node.
        $parentNodePath = $ElementPath.Substring(0, $ElementPath.LastIndexOf($NodeSeparatorCharacter))
        $parentNode = Get-XmlNode -XmlDocument $XmlDocument -NodePath $parentNodePath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
		
        if ($parentNode) {
            $parentNode.AppendChild($element) > $null
        }
        else {
            throw "$parentNodePath does not exist in the xml."
        }
    }
}

function Get-XmlElementsAttributeValue([ xml ]$XmlDocument, [string]$ElementPath, [string]$AttributeName, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    # Try and get the node. 
    $node = Get-XmlNode -XmlDocument $XmlDocument -NodePath $ElementPath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
     
    # If the node already exists, return its value, otherwise return null.
    if ($node -and $node.$AttributeName) { return $node.$AttributeName } else { return $null }
}

function Set-XmlElementsAttributeValue([ xml ]$XmlDocument, [string]$ElementPath, [string]$AttributeName, [string]$AttributeValue, [string]$NamespaceURI = "", [string]$NodeSeparatorCharacter = '.') {
    # Try and get the node. 
    $node = Get-XmlNode -XmlDocument $XmlDocument -NodePath $ElementPath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
     
    # If the node already exists, create/update its attribute's value.
    if ($node) { 
        $attribute = $XmlDocument.CreateNode([System.Xml.XmlNodeType]::Attribute, $AttributeName, $NamespaceURI)
        $attribute.Value = $AttributeValue
        $node.Attributes.SetNamedItem($attribute) > $null
    }
    # Else the node doesn't exist yet, so create it with the given attribute value.
    else {
        # Create the new element with the given value.
        $elementName = $ElementPath.SubString($ElementPath.LastIndexOf($NodeSeparatorCharacter) + 1)
        $element = $XmlDocument.CreateElement($elementName, $XmlDocument.DocumentElement.NamespaceURI)
        $element.SetAttribute($AttributeName, $NamespaceURI, $AttributeValue) > $null
         
        # Try and get the parent node.
        $parentNodePath = $ElementPath.SubString(0, $ElementPath.LastIndexOf($NodeSeparatorCharacter))
        $parentNode = Get-XmlNode -XmlDocument $XmlDocument -NodePath $parentNodePath -NamespaceURI $NamespaceURI -NodeSeparatorCharacter $NodeSeparatorCharacter
        
        if ($parentNode) {
            $parentNode.AppendChild($element) > $null
        }
        else {
            throw "$parentNodePath does not exist in the xml."
        }
    }
}

# Check if agent binary downloader file exists
$binary_downloader = "$scriptDir\scripts\appd-downloader.exe"
if ( -Not [System.IO.File]::Exists($binary_downloader)) {
    Invoke-WebRequest -Uri "https://github.com/malbert87/appd-agent-download/raw/master/cmd/appd-downloader/appd-downloader.exe" -OutFile "$binary_downloader"
}


# Check if binaries have been unzipped/renamed or not...
$machine_config = "$scriptDir\AppDynamics\machineagent\conf\controller-info.xml"
$machine_zip = "$scriptDir\AppDynamics\machineagent-bundle-64bit-windows-*.zip"
$java_config = "$scriptDir\AppDynamics\javaagent\conf\controller-info.xml"
# $java_zip = "$scriptDir\AppDynamics\AppServerAgent-*.zip"
# $NetViz_msi_path = "$scriptDir\AppDynamics\appd-netviz-agent.msi"
# $netviz_default_msi = "$scriptDir\AppDynamics\appd-netviz-agent-*.msi"
$dotnet_Installer = "$scriptDir\AppDynamics\dotNetAgentSetup.msi"
$dotnet_default_msi = "$scriptDir\AppDynamics\dotNetAgentSetup64*.msi"
IF ([System.IO.File]::Exists($machine_config)) {
    # Existing Machine Agent Installer Found
}
ELSE {
    Write-Output "No existing Machine Agent installer found, checking if zip is available locally..."
    IF (Test-Path $machine_zip) {
        Write-Output "Found locally, unzipping"
    }
    ELSE { 
        Write-Output "No local Machine Agent zip found..."
        if ([System.IO.File]::Exists($binary_downloader)) {
            Write-Output "Attempting to Download Machine Agent..."
            $params = "-automate -ma -o=$scriptDir\AppDynamics"
            Start-Process $binary_downloader -ArgumentList $params -Wait
            Write-Output "Downloaded and now unzipping"
        }
        else {
            Write-Output "Couldn't find binary downloader..."
        }
    }
    Expand-Archive -Path $machine_zip -DestinationPath "$scriptDir\AppDynamics\machineagent"
}

IF (Test-Path $dotnet_Installer) {
    # Existing dotNet Agent Installer Found
}
ELSE {
    Write-Output "No existing DotNet Agent installer found, checking if msi is available locally to rename..."
    IF (Test-Path $dotnet_default_msi) {
        Write-Output "Found locally, renaming"
    }
    ELSE { 
        Write-Output "No local DotNet Agent msi found..."
        if ([System.IO.File]::Exists($binary_downloader)) {
            Write-Output "Attempting to Download DotNet Agent..."
            $params = "-automate -dotnet -o=$scriptDir\AppDynamics"
            Start-Process $binary_downloader -ArgumentList $params -Wait
            Write-Output "Downloaded and now renaming"
        }
        else {
            Write-Output "Couldn't find binary downloader..."
        }
    }
    $dotnet_default_msi = Resolve-Path $dotnet_default_msi
    Rename-Item -Path $dotnet_default_msi -NewName "dotNetAgentSetup.msi"

}

# Modifying the files before the installations
Write-Output "Modifying files before installations..."
$contHost = $h.Get_Item("controller-host")
$contPort = $h.Get_Item("controller-port")
$contSSLEnabled = $h.Get_Item("controller-ssl-enabled")
$accAccessKey = $h.Get_Item("account-access-key")
$accName = $h.Get_Item("account-name")
$globalAccName = $h.Get_Item("global-account-name")
$appName = $h.Get_Item("application-name")
$tierName = $h.Get_Item("tier-name")
$nodeName = $h.Get_Item("node-name")
$simEnabled = $h.Get_Item("sim-enabled")
$dotnetMode = $h.Get_Item("dotnet-compatibility-mode")
$machinePath = $h.Get_Item("machine-hierarchy")
$analyticsEnabled = $h.Get_Item("analytics-enabled")
$analyticsName = 'ad.agent.name=' + $h.Get_Item("ad.agent.name")

[System.Xml.XmlWriterSettings] $XmlSettings = New-Object System.Xml.XmlWriterSettings
$XmlSettings.OmitXmlDeclaration = $true
$XmlSettings.Encoding = New-Object System.Text.UTF8Encoding($false)

# Modifying the machine agent conf settings
IF ([System.IO.File]::Exists($machine_config)) {
    $machine_xml = New-Object System.Xml.XmlDocument
    $machine_xml.PreserveWhitespace = $true
    $machine_xml.Load($machine_config)
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.account-name" -TextValue $accName
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.controller-host" -TextValue $contHost
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.controller-port" -TextValue $contPort
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.controller-ssl-enabled" -TextValue $contSSLEnabled
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.account-access-key" -TextValue $accAccessKey
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.application-name" -TextValue $appName
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.sim-enabled" -TextValue $simEnabled
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.dotnet-compatibility-mode" -TextValue $dotnetMode
    Set-XmlElementsTextValue -XmlDocument $machine_xml -ElementPath "controller-info.machine-path" -TextValue $machinePath
    [System.Xml.XmlWriter] $XmlWriter = [System.Xml.XmlWriter]::Create($machine_config, $XmlSettings)
    $machine_xml.Save($XmlWriter)
    $XmlWriter.Flush()
    $XmlWriter.Close()
}


# Modifying the dotnet agent conf file settings
$dotnet_config = "$scriptDir\AppDynamics\dotnet-config.xml"
IF ([System.IO.File]::Exists($dotnet_config)) {
    $dotnet_xml = New-Object System.Xml.XmlDocument
    $dotnet_xml.PreserveWhitespace = $true
    $dotnet_xml.Load($dotnet_config)
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller" -AttributeName "host" -AttributeValue $contHost
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller" -AttributeName "port" -AttributeValue $contPort
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller" -AttributeName "ssl" -AttributeValue $contSSLEnabled
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller.account" -AttributeName "name" -AttributeValue $accName
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller.account" -AttributeName "password" -AttributeValue $accAccessKey
    Set-XmlElementsAttributeValue -XmlDocument $dotnet_xml -ElementPath "winston.appdynamics-agent.controller.applications.application" -AttributeName "name" -AttributeValue $appName
    [System.Xml.XmlWriter] $XmlWriter = [System.Xml.XmlWriter]::Create($dotnet_config, $XmlSettings)
    $dotnet_xml.Save($XmlWriter)
    $XmlWriter.Flush()
    $XmlWriter.Close()
}

# Modifying the analytics agent monitor file settings
$monitor_file = "$scriptDir\AppDynamics\machineagent\monitors\analytics-agent\monitor.xml"
IF ([System.IO.File]::Exists($monitor_file)) {
    [xml] $monitor_xml = Get-Content $monitor_file -Raw
    Set-XmlElementsTextValue -XmlDocument $monitor_xml -ElementPath "monitor.enabled" -TextValue $analyticsEnabled
    $monitor_xml.Save($monitor_file)
    $XmlWriter.Flush()
    $XmlWriter.Close()
}

# Modifying the analytics agent properties file settings
$analytics_config = "$scriptDir\AppDynamics\machineagent\monitors\analytics-agent\conf\analytics-agent.properties"
IF ([System.IO.File]::Exists($analytics_config)) {
    IF ($contSSLEnabled -eq "true") {
        $analyticsCont = 'ad.controller.url=https://' + $contHost + ':' + $contPort
    }
    ELSE {
        $analyticsCont = 'ad.controller.url=http://' + $contHost + ':' + $contPort
    }
    $analyticsEndPoint = 'http.event.endpoint=' + $h.Get_Item("http.event.endpoint")
    $analyticsAccName = 'http.event.name=' + $accName
    $analyticsGlob = 'http.event.accountName=' + $globalAccName
    $analyticsAccKey = 'http.event.accessKey=' + $accAccessKey
    ((Get-Content -Path $analytics_config -Raw) -replace 'ad.agent.name=(.*)', $analyticsName) | Set-Content -Path $analytics_config
    ((Get-Content -Path $analytics_config -Raw) -replace 'ad.controller.url=(.*)', $analyticsCont) | Set-Content -Path $analytics_config
    ((Get-Content -Path $analytics_config -Raw) -replace 'http.event.endpoint=(.*)', $analyticsEndPoint) | Set-Content -Path $analytics_config
    ((Get-Content -Path $analytics_config -Raw) -replace 'http.event.name=(.*)', $analyticsAccName) | Set-Content -Path $analytics_config
    ((Get-Content -Path $analytics_config -Raw) -replace 'http.event.accountName=(.*)', $analyticsGlob) | Set-Content -Path $analytics_config
    ((Get-Content -Path $analytics_config -Raw) -replace 'http.event.accessKey=(.*)', $analyticsAccKey) | Set-Content -Path $analytics_config
}

Write-Output "--- Finished modifying the files ---"
Write-Output "------ Starting Installations ------"


# Installing the machine agent
IF ([System.IO.File]::Exists($machine_config)) {
    $machine_service = Get-Service -Name "AppDynamics Machine Agent" -ErrorAction SilentlyContinue
    if ($machine_service.Length -gt 0) {
        Write-Output "Existing Service Found... Stopping Machine Agent Service before installation..."
        Stop-Service $machine_service
    }
    $machine_home = "$env:ProgramFiles\AppDynamics\machineagent"
    Write-Output "Copying Machine Agent to $machine_home"
    Robocopy $scriptDir\AppDynamics\machineagent $machine_home /E /NFL /NDL /NJH /NP /NS /NC
    
    if ($machine_service.Length -gt 0) {
        Write-Output "Existing Service Found... Restarting Machine Agent Service..."
        Restart-Service $machine_service
    }
    else {
        $install_machine_service = "$env:ProgramFiles\AppDynamics\machineagent\InstallService.vbs"
        IF ([System.IO.File]::Exists($install_machine_service)) {
            Write-Output "Installing machine agent as service"
            # make it not require input
            ((Get-Content -Path $install_machine_service -Raw) -replace 'WScript.StdIn.Read\(1\)', "' WScript.StdIn.Read(1)") | Set-Content -Path $install_machine_service
            Start-Process -Wait $install_machine_service
        }
        ELSE {
            Write-Output "Install Machine Service not found here - $install_machine_service"
        }
    }
}
ELSE {
    Write-Output "Machine config file not found in AppDynamics directory - not installing machine agent"
}


# Installing the dotnet agent
# Gets the specified registry value or $null if it is missing
function Get-RegistryValue($path, $name) {
    $key = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($key) {
        $key.GetValue($name, $null)
    }
}

IF ([System.IO.File]::Exists($dotnet_Installer)) {

    IF (Test-Path env:COR_PROFILER) {
        IF ($env:COR_PROFILER -eq "AppDynamics.AgentProfiler") {
            Write-Output "EXISTING DOTNET AGENT FOUND - UNINSTALLING BEFORE NEW INSTALL..."
            $dotNetAgentApp = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "AppDynamics .NET Agent" }
            $dotNetAgentApp.Uninstall()
            Remove-Item env:COR_PROFILER
        }
    }

    Write-Output "Installing the dotnet agent"

    IF (Test-Path env:COR_PROFILER) {
        IF ($env:COR_PROFILER -eq "AppDynamics.AgentProfiler") {
            Write-Output "EXISTING DOTNET AGENT FOUND - PLEASE UNINSTALL AND REINSTALL"
        }
        ELSE {
            Write-Output "Existing profiler found - this may cause conflicts. Not installing dotnet agent..."
        }
    }
    ELSE {
        $REGKEY = "hklm:\Software\AppDynamics\dotNet Agent"
        $REGVALNAME = "DotNetAgentFolder"
        IF (Test-Path $REGKEY) {
            $DOTNET_FOLDER = Get-RegistryValue $REGKEY $REGVALNAME
        }
        ELSE {
            $DOTNET_FOLDER = "$env:ProgramData\AppDynamics\DotNetAgent\"
        }
        IF ([System.IO.File]::Exists("${DOTNET_FOLDER}Config\config.xml")) {
            Write-Output "Installing dotnet agent using existing configuration: ${DOTNET_FOLDER}Config\config.xml"
            $params = '/I ' + $dotnet_Installer + ' /q /norestart /lv "' + $scriptDir + '\_Agent-dotnet-Installer.log"'
            Start-Process  msiexec.exe -ArgumentList $params -Wait -PassThru
        }
        ELSE {
            Write-Output "Installing dotnet agent using NEW configruation"
            $params = '/I ' + $dotnet_Installer + ' /q /norestart /lv ' + $scriptDir + '\_Agent-dotnet-Installer.log AD_SetupFile="' + $scriptDir + '\AppDynamics\dotnet-config.xml"'
            Start-Process  msiexec.exe -ArgumentList $params -Wait -PassThru
        }
        Write-Output "Finished running the dotnet Installer"
        Write-Output "Restarting Agent Coordinator Service"
        $appd_coord = "AppDynamics.Agent.Coordinator"
        $appd_coord_status = Get-Service $appd_coord
        "$appd_coord is now " + $appd_coord_status.Status
        Restart-Service $appd_coord
    }
}

Write-Output "Finished running installations"
Write-Output "Please restart IIS and/or any other applications you have configured to monitor"
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
