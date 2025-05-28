# Hyper V Generatory from Hosts File

This repo
 - Updates the Windows host file with the IPs of any VMs running on the default switch of Hyper-V.
 - Ensures that the Windows Subsystem for Linux (WSL) Switch and Default Switche on Hyper-V are forwarding to each other (Credit for that: https://automatingops.com/allowing-windows-subsystem-for-linux-to-communicate-with-hyper-v-vms)

 Run .\\entrypoint.sh from Powershell to automatically update the hosts file with all the IPs on your Hyper-V VMs.  

 Set up as a scheduled task to automatically poll Hyper-V for updates.

## Description

There are two big frustrations with using Hyper-V to run VMs on Windows. 
1. WSL does not communicate by default with VMs on the default switch on Hyper-V.
2. The IPs assigned to VMs by the Default Switch are not static and change at startup. 

Alternate switch configurations in Hyper-V can be configured to allow default communication with WSL, and static IP assignment. However, if you're not comfortable with Hyper-V networking, this can seem daunting, and can get very complicated very fast.

Updating the hosts file manually when using VMs is an option, but this is obviously cumbersome and can become frustrating. 

This script can be set up as a scheduled task in Windows to automate this behaviour, allowing simple but robust VM usage on Hyper-V without needing to get too in depth on Hyper-V networking. 

## Usage

Ensure the config file is set up correctly. 

Set this up as a scheduled task in Windows. To run as a scheduled task you must run `run_hidden.vbs` otherwise an annoying Powershell popup comes up every time. 

In Windows task scheduler Actions:
 - Program/script: wscript.exe
 - Add arguments: "C:\path\to\script\run_hidden.vbs"
 - Start in: "C:\path\to\script\"


`wslSwitch` and `defaultSwitch` must match the names of the corresponding switches in the Hyper-V Virtual Switch Manager. 

`new_vm_threshold` - If a VM comes online and its running time is below this number, the host file will be updated. 

This tool works by comparing the current state of Hyper-V to a cached state. The cache should rebuild at every startup. Running Hyper-V commands in powershell to investigate the current state is not terribly light. If you want to run this as a frequest scheduled task (~once per minute) then ideally we will need a fast way to check the state of Hyper-V. 

It turns out that the best tradeoff between speed and reliability for checking the current state is to check on the current Running Time of the VMs. If we check for VMs with a running time below a certain threshold, we can be resonably sure those are new VMs, and it will be worthwhile to update the cache. This is controlled by `new_vm_threshold`. In my setup, I run this task once per minute. Then `new_vm_threshold` is set to 90 seconds, which means that any time a new VM comes online, it will be noticed and added to the hosts file. 


```json 
#./config.json example
{
  "hypervHostsCache": ".\\cache.json",
  "logsDir": ".\\logs",
  "wslSwitch": "vEthernet (WSL (Hyper-V firewall))",
  "defaultSwitch": "vEthernet (Default Switch)",
  "hosts_file_path": "C:\\Windows\\System32\\drivers\\etc\\hosts",
  "new_vm_threshold": 90000
}
```