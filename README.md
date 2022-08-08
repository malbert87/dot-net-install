# AppDynamics Windows Agent Installer AIO Standalone

## What this Does


- Downloads / Installs .NET Agent
- Downloads / Installs Machine Agent with Analytics Enabled


## What you should do

Modify This File
 .\configs.ini

Modify these files if you need to change anything additional outside of configs.ini (you should modify if you have custom configs for Java or Machine Agent as this will overwrite anything in output dir)
 AppDynamics\dotnet-config.xml (this is your winston dotnet agent config)
 AppDynamics\javaagent\conf\controller-info.xml
 AppDynamics\machineagent\monitors\analytics-agent\conf\analytics-agent.properties
 AppDynamics\machineagent\conf\controller-info.xml

## Execution

Right-click Installer.bat 'Run as Administrator'

NOTE - Machine Agent will be copied to C:\Program Files\AppDynamics\machineagent where all other installations are defaulted.


Validate 2 Services are installed

- AppDynamics Agent Coordinator
- AppDynamics Machine Agent

Restart applications

Validate traffic is reporting to Controller and agents are healthy (server / analytics)
