<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.AUTHOR
   Juliano Alves de Brito Ribeiro (jaribeiro@uoldiveo.com or julianoalvesbr@live.com)
.Version
   0.3
.UPDATES
   #Send only e-mail of offline, failed or missing resources

. ORIGINAL SCRIPT 
#https://gallery.technet.microsoft.com/scriptcenter/Failover-Cluster-Report-b89d26b1#content
#REMOVED CLUSTERS

#>

Param($cluster_name, $path, $web_path); 

##### Add FailoverClusters Module
if(-not (Get-Module -Name FailoverClusters -ErrorAction SilentlyContinue)) 
     { 
    Import-Module -Name FailoverClusters -Verbose
} 


 
# Write & manages the cluster state text files 
function Write-ClusterState 
{ 
    param ($object, $name); 
    if(Test-Path -Path "$path$name.txt") 
    { 
        Move-Item -Path "$path$name.txt" $($path + "previous`_$name.txt") -Force; 
    } 
    $content = $object | ConvertTo-Html -Fragment; 
    $content | Set-Content -Path "$path$name.txt"; 
} 
 
# Runs various cmdlets against the cluster to get state info 
function Get-ClusterInfo 
{ 
    param ($cluster); 
    # Get information about one or more nodes (servers) in a failover cluster. - http://technet.microsoft.com/en-us/library/ee460990.aspx 
    $cluster_nodes= Get-Cluster -Name $cluster | Get-ClusterNode | Sort-Object -Property ID | Select-Object -Property Name,ID,State
    
    # Get information about one or more clustered services or applications (resource groups) in a failover cluster. - http://technet.microsoft.com/en-us/library/ee461017.aspx 
    $cluster_group = Get-Cluster -Name $cluster | Get-ClusterGroup | Select-Object -Property Name,OwnerNode,Cluster,State,IsCoreGroup,@{label='FailbackType';Expression={if($_.AutoFailbackType -eq "0"){"Prevent"}else{"Allow"}}} | Sort-Object -Property OwnerNode;

    # Get information about one or more resources in a failover cluster. - http://technet.microsoft.com/en-us/library/ee461004.aspx 
    $cluster_resources = Get-Cluster -Name $cluster | Get-ClusterResource | Select-Object -Property Name,State,OwnerNode,OwnerGroup,ResourceType | Sort-Object -Property OwnerNode;
    
    # Uses a few cmdlets to get details of possible owners for cluster resources - http://technet.microsoft.com/en-us/library/ee460989.aspx 
    # Expand Property used here to flatten array type data 
    $cluster_owner_node = Get-ClusterResource -Cluster $cluster | Get-ClusterOwnerNode | Select-Object -Property ClusterObject -ExpandProperty OwnerNodes | Sort-Object -Property Name | Select-Object -Property ClusterObject,Name;
    
    # Get information about one or more networks in a failover cluster. - http://technet.microsoft.com/en-us/library/ee461011.aspx 
    $cluster_network = Get-ClusterNetwork -Cluster $cluster | Select-Object -Property Name, Role, Address, State; 
    
    # Get information about one or more network adapters in a failover cluster. - http://technet.microsoft.com/en-us/library/ee460982.aspx 
    $cluster_network_interface = get-cluster -Name $cluster | Get-ClusterNetworkInterface | Sort-Object -Property Name | Select-Object -Property Name, Network, Node, State;
    
    # Get information about permissions that control access to a failover cluster. - http://technet.microsoft.com/en-us/library/ee460977.aspx 
    $cluster_access = Get-ClusterAccess -Cluster $cluster | Select-Object -Property @{label='Identity';Expression={$PSItem.IdentityReference}}, AccessControlType, ClusterRights; 
    
    # Get information about quorum types of a resource cluster. https://docs.microsoft.com/en-us/windows-server/failover-clustering/manage-cluster-quorum
    $cluster_quorum = Get-Cluster -Name $cluster | Get-ClusterQuorum | Select-Object -Property Cluster,QuorumResource,QuorumType;


    # write report files 
    Write-ClusterState $cluster_nodes "cluster_nodes"; 
    Write-ClusterState $cluster_group "cluster_group"; 
    Write-ClusterState $cluster_resources "cluster_resources"; 
    Write-ClusterState $cluster_owner_node "cluster_owner_node"; 
    Write-ClusterState $cluster_network "cluster_network"; 
    Write-ClusterState $cluster_network_interface "cluster_network_interface"; 
    Write-ClusterState $cluster_access "cluster_access"; 
    Write-ClusterState $cluster_quorum "cluster_quorum";
} 
 
# This function adds additional information to  
# the cluster headers so we know a little more about 
# what it's showing us 
function AddLinkFor-Header 
{ 
    param ($header); 
    switch ($header) 
    { 
        "Cluster Nodes" {"Get information about one or more nodes (servers) in a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee460990.aspx'>info</a>"} 
        "Cluster Group" {"Get information about one or more clustered services or applications (resource groups) in a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee461017.aspx'>info</a>"} 
        "Cluster Resources" {"Get information about one or more resources in a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee461004.aspx'>info</a>"} 
        "Cluster Owner Node" {"Uses a few cmdlets to get details of possible owners for cluster resources - <a href='http://technet.microsoft.com/en-us/library/ee460989.aspx'>info</a>"} 
        "Cluster Network" {"Get information about one or more networks in a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee461011.aspx'>info</a>"} 
        "Cluster Network Interface" {"Get information about one or more network adapters in a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee460982.aspx'>info</a>"} 
        "Cluster Access" {"Get information about permissions that control access to a failover cluster. - <a href='http://technet.microsoft.com/en-us/library/ee460977.aspx'>info</a>"} 
        "Cluster Quorum" {"Get information about quorum in a failover cluster. - <a href='https://docs.microsoft.com/en-us/windows-server/failover-clustering/manage-cluster-quorum'>info</a>"}
        default {"No additional info available."} 
    } 
} 
 
function Build-ClusterReport  
{ 
    param ($location, $cluster_name); 
    $state_changed = $false; 
    $css = Get-Content -Path $($path + "resources\style.css"); 
    $generated = Get-Date -Uformat "%d-%m-%Y %H:%M"; 
    $html_report = "<html><head>$css</head><body><h1>Cluster Report: $cluster_name</h1><h4>Generated at: $generated</h4>"; 
    # each cluster report file 
    $files = Get-ChildItem "$location\cluster_*.txt"; 
    foreach($file in $files) 
    { 
        # If the previous_cluster_*.txt files exists  
        # we compare the contents of each so we can 
        # tell if the state of the cluster has changed 
        $file_name = $file.Name; 
        $header = Do-Captialize $file_name.Replace("_", " ").Replace(".txt", ""); 
        if(Test-Path -Path "$location\previous`_$file_name") 
        { 
            [string]$current = Get-Content -Path $file; 
            [string]$previous = Get-Content -Path "$location\previous`_$file_name"; 
            $compare = Compare-Object $current $previous; 
            $info = AddLinkFor-Header $header; 
            if($compare.Length -gt 0) 
            { 
                $state_changed = $true; 
                $html_report += "<p><h1>$header</h1>  - $info</p>" + "<h3>Change in cluster state!</h3>" + "<table><tr><td><h2>Current state</h2>" + $current + "</td><td>" + "<h2>Previous state</h2>" + $previous + "</td></tr></table>"; 
            } 
            else 
            { 
                $html_report += "<p><h1>$header</h1> - $info</p>" + $current; 
            } 
        } 
    } 
    $html_report += "</body></html>"; 
    return $html_report; 
} 
 
# Upcase Code from http://www.thejohnsonblog.com/2010/11/25/capitalizing-first-letter-of-every-word-with-powershell-2/ 
function Do-Captialize 
{ 
    param ($name); 
    $name = [Regex]::Replace($name, '\b(\w)', { param($m) $m.Value.ToUpper() }); 
    return $name; 
} 
 
Get-ClusterInfo $cluster_name; 
$datetime = Get-Date -Format "dd_MM_yyyy_hh_mm"; 
# archive old report RC Too many files written! 
#Rename-Item $($path + "$cluster_name.html") "$datetime`_$cluster_name.html"; 
#Move-Item $($path + "$datetime`_$cluster_name.html") $($path + "archive"); 
$rpt = Build-ClusterReport $path $cluster_name; 
$rpt | Set-Content -Path $($path + "$cluster_name.html"); 
 
# Move the report onto a web server 
Copy-Item "$path\$cluster_name.html" "$web_path" -Force; 
 
###########Send Mail Variables ########
$fromaddress = "powershellrobot@yourdomain.com"
$toaddress = "list1@yourdomain.com","list2@yourdomain.com","list3@yourdomain.com"
#$bccaddress = "powershell@yourdomain.com"
$CCaddress = "youruser@yourdomain.com"
#$CRattachment = $attachments
$smtpserver = "fqdn.yourserver.yourdomain"

####################################

$Offline = $rpt.Contains("Offline")

$Failed = $rpt.Contains("Failed")

$Missing = $rpt.Contains("Missing")


if($Offline -or $Failed -or $Missing)
{ 
    
    #GENERATE ANOTHER REPORT WITH ONLY OFFLINE, FAILED OR MISSING RESOURCES

    #CSS HEADER
    $ofmHeader = @"
<style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }

    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
	
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }

        #CreationDate {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }
    
    .OfflineStatus {
    color: #ff0000;
    }

    .FailedStatus {
    color: #ff0000;
    }

    .MissingStatus {
    color: #ff0000;
    }


</style>
"@

      
     #Construct TimeStamp
     $d1 = (get-date -Format 'dd-MM-yyyy').ToString()
 
     $d2 = (get-date -Format 'HH.mm.ss.fffffff').ToString()

     $d3 = (get-date -UFormat %Z).ToString()
    
     [System.String]$timestamp = $d1 + 'T' + $d2 + $d3 + '.00'

     $clName = $cluster_Name.ToUpper()
     
     $preData = failoverclusters\get-cluster -Name $cluster_Name | Get-ClusterResource | Where-Object -FilterScript {$psitem.state -eq 'offline' -or $psitem.state -eq 'failed' -or $psitem.state -eq 'Missing'}       
         
    #ONLY SEND MAIL IF EXISTS RESOURCES WITH CONDITIONS SPECIFIED
    if ($preData -eq $null)
    {
        
        Write-Output "Nothing to do" | Out-Null

    }#End of If
    else{
        
        #The command below will get the name of the computer
        $htmlCLName = "<h1>MSCS: $clName</h1>"
            
        $dataToInvestigate = failoverclusters\get-cluster -Name $cluster_Name | Get-ClusterResource | Where-Object -FilterScript {$psitem.state -eq 'offline' -or $psitem.state -eq 'failed' -or $psitem.state -eq 'Missing'} | 
        ConvertTo-Html -As List -Property Cluster,Name,State,OwnerGroup,ResourceType,MaintenanceMode,IsCoreResource,IsNetworkClassResource,IsStorageClassResource -Fragment -PreContent "<h2>Offline - Missing or Failed Resources</h2>" 

        $dataToInvestigate = $dataToInvestigate -replace '<td>Offline</td>','<td class="OfflineStatus">Offline</td>'

        $dataToInvestigate = $dataToInvestigate -replace '<td>Failed</td>','<td class="FailedStatus">Offline</td>'

        $dataToInvestigate = $dataToInvestigate -replace '<td>Missing</td>','<td class="MissingStatus">Offline</td>'

        #The command below will combine all the information gathered into a single HTML report
        $ofmReport = ConvertTo-HTML -Body "$htmlCLName $dataToInvestigate" -Title "$cluster_Name - Offline - Missing or Failed Resources" -Head $ofmHeader -PostContent "<p id='CreationDate'>Creation Date: $($timestamp)</p>"
        
        $ofmHTML = $ofmReport | Out-String
        
        # send an email alert 
        $FCRsubject = "$clName - I Found Resources Offline, Failed or Missing. Please Investigate !"; 
    
        Send-MailMessage -SmtpServer $smtpserver -From $fromaddress -To $toaddress -Cc $CCaddress -Subject $FCRSubject -Body $ofmHTML -BodyAsHtml -Priority High -Encoding UTF8
    
    }#end of Else
    
  
}#end of Main If


<#
ORIGINAL CODE
if($rpt.Contains("Change in cluster state")) 
{ 
    # send an email alert 
    $FCRsubject = "$cluster_name - There has been a change in the Cluster State !"; 
    $report = $rpt; 
    Send-MailMessage -SmtpServer $smtpserver -From $fromaddress -To $toaddress -Cc $CCaddress -Subject $FCRSubject -Body $report -BodyAsHtml -Priority High -Encoding UTF8
}
#>
