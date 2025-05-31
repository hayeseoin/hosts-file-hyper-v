# Hyper V Generatory from Hosts File

This repo
 - Updates the Windows host file with the IPs of any VMs running on the default switch of Hyper-V.
 - Ensures that the Windows Subsystem for Linux (WSL) Switch and Default Switche on Hyper-V are forwarding to each other (Credit for that: https://automatingops.com/allowing-windows-subsystem-for-linux-to-communicate-with-hyper-v-vms)

 Run .\\entrypoint.sh from Powershell to automatically update the hosts file with all the IPs on your Hyper-V VMs.  

## Description

There are two big frustrations with using Hyper-V to run VMs on Windows. 
1. WSL does not communicate by default with VMs on the default switch on Hyper-V.
2. The IPs assigned to VMs by the Default Switch are not static and change at startup. 

Alternate switch configurations in Hyper-V can be configured to allow default communication with WSL, and static IP assignment. However, if you're not comfortable with Hyper-V networking, this can seem daunting, and can get very complicated very fast.

Updating the hosts file manually when using VMs is an option, but this is obviously cumbersome and can become frustrating. 

This script can be set up as a scheduled task in Windows triggered by Hyper-V actions to automate this behaviour, allowing simple but robust VM usage on Hyper-V without needing to get too in depth on Hyper-V networking. 

## Usage

Ensure the config file is set up correctly. 

I suggest to place this in C:\utils-and-scripts\windows\hyper-v-hosts\

Set this up as a scheduled task in Windows. To run as a scheduled task you must run `run_hidden.vbs` otherwise an annoying Powershell popup comes up every time. 

In Windows task scheduler Actions:
 - Program/script: wscript.exe
 - Add arguments: ".\\run_hidden.vbs"
 - Start in: "C:\utils-and-scripts\windows\hyper-v-hosts"

For the trigger: 
 - Begin the task: On an event
 - Log: Microsoft-Windows-Hyper-V-Hypervisor/Operational
 - Source: Hyper-V-Hypervisor

![alt text](images/image.png)

`wslSwitch` and `defaultSwitch` must match the names of the corresponding switches in the Hyper-V Virtual Switch Manager. 

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
### ---notes---

The variable `new_vm_threshold` is disabled. Originally the idea of these scripts was to run a scheduled task every minute, but it makes more sense to have the scripts be triggered by Hyper-V actions. 