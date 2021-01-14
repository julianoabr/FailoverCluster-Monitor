# FailoverCluster-Monitor
Powershell Script to Check all the Failover Clusters in your environment


## Start

To run the scripts you have to install or have already installed the following: 

- [.NET Framework 4.52 or above](https://www.microsoft.com/en-US/download/details.aspx?id=42642)
- [Windows Management Framework 4.5.2 or above](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
- [Powershell Module for Failover Clusters](https://www.oreilly.com/library/view/windows-server-2012/9780133116007/ch29lev2sec13.html)

## How to Use

I suggest that you create the following structure to run the script: 

* C:\Scripts (can be another volume)
  * GenerateMSCSReport.ps1 (main script)
  * FAILOVERCLUSTER (Folder where will be generated the files for each cluster, script will create a new folder for each cluster automatically
  * GENERIC (Folder where you put the files below)
      * GenericMSCSReport.ps1
      * Resources (folder, put the style.css inside)
          * style.css
  * HTML (Folder where stays the HTML file below)
    * contentHCMSCS.html (You have to edit this file with clusters in your environment, suggestion: Use Notepad ++)
  * OUTPUT (Folder where script copy the HTML files generated that will be attached to be sent by e-mail
  
  
  ## Features

This script can be scheduled to run once or twice a day to your IT TEAMs view the status of failover clusters. 
The script will sent an e-mail if following are true:

- [x] When it tries to "PING" a CAP and have no return
- [x] If found a resource offline
- [x] If found a resource missing
- [x] If found a resource failed
- [ ] Not send if found a failover (but you can activate this block of code if you wish)

## Test

To run the script, you can use Powershell ISE application or Powershell console application

```
.\GenerateMSCSReport.ps1 
```

## Links

- [My Linkedin](https://www.linkedin.com/in/julianoabr/)

## License

- [GPL 3](https://www.gnu.org/licenses/gpl-3.0.pt-br.html)





