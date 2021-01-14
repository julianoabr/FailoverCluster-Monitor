#Requires -RunAsAdministrator
#Requires -Version 4.0

#Generate All Clusters States
<#
.Synopsis
   Generate and send status of all MSCS in your environment
.DESCRIPTION
   Generate and send status of all MSCS in your environment.
   Will be sent 3 e-mails:
   1. If script can't ping the CAP
   2. If find any resource offline, failed or missing
   3. An e-mail with all html generated
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.AUTHOR
   Juliano Alves de Brito Ribeiro (Find me at jaribeiro@uoldiveo.com or julianoalvesbr@live.com or https://github.com/julianoabr)
.Version
   0.2
.UPDATES
   #Created Generic Function to Generate ClusterReport 
   #Include Function to SendMail

#REMOVED CLUSTERS
    

#>
function Generate-ClusterReport
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String]$mscsName,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [System.String]$mscsPath,
        
        
         [Parameter(Mandatory=$true,
                   Position=2)]
        [System.String]$mscsWebPath

    )

Clear-Host

Set-Location "$env:SystemDrive\Scripts\Generic"

.\GenericMSCSReport.ps1 -cluster_name $mscsName -path $mscsPath -web_path $mscsWebPath


}#End of Function


$mscsClusterList = @()

#CHANGE THIS LIST ACCORDING TO YOUR ENVIRONMENT
$mscsClusterList = ("CLUSTER01","CLUSTER02","CLUSTER03","CLUSTER04","CLUSTER05","CLUSTER06")

###############################################################################################

#Create Cluster Folder if does Not Exists

foreach ($mscsCluster in $mscsClusterList){

      [System.String]$mscsClusterName = $mscsCluster 

      [System.String]$MscsFolder = "$env:SystemDrive\SCRIPTS\FailoverCluster\" + "$mscsClusterName"


    if (Test-Path -Path $MscsFolder){
    
        Write-Host "Folder for Failover Cluster: $mscsCluster already exists" -ForegroundColor Green
            
    }#end of IF
    else{
    
        Write-Host "Path to generate Cluster Report of MSCS: $mscsCluster does not exist. I will create it" -ForegroundColor DarkBlue

        New-Item -Path "$env:SystemDrive\SCRIPTS\FailoverCluster\" -ItemType Directory -Name "$mscsClusterName" -Force -Verbose -ErrorAction Continue

        Copy-Item -Path "$env:SystemDrive\Scripts\GENERIC\Resources" -Destination "$env:SystemDrive\SCRIPTS\FailoverCluster\$mscsClusterName" -Recurse -Verbose
               

    }#end of Else



}#enf of Foreach


$mscsClusterList | Sort-Object

$totalClusterCount = $mscsClusterList.Count

Write-Host "I found $totalClusterCount Clusters Today to scan..." -ForegroundColor White -BackgroundColor Green

[System.Int64]$i = 0

foreach ($mscsCluster in $mscsClusterList){
    
    [System.String]$mscsClusterName = $mscsCluster

    Write-Progress -Activity "Scanning Failover Clusters" -Status "Progress: $mscsClusterName" -PercentComplete ($i/$totalClusterCount*100)
              
    [System.String]$tmpMscsPath = "$env:SystemDrive\SCRIPTS\FailoverCluster\" + "$mscsClusterName" + "\"

    [System.String]$tmpMscsWebPath = "$env:SystemDrive\SCRIPTS\Output\FailoverCluster\"

    Generate-ClusterReport -mscsName $mscsClusterName -mscsPath $tmpMscsPath -mscsWebPath $tmpMscsWebPath

    Start-Sleep -Milliseconds 300

    $i++
        
}

#WAIT ONE MINUTE TO SEND E-MAIL
Start-Sleep -Seconds 60

Clear-Host

$tmpSendDate = get-date -uformat "%d-%m-%Y-%H:%M" # To get a current date. 

$sendDate = $tmpSendDate.ToString()

Start-Sleep -Milliseconds 400

#Get files to input in e-mail
$fileLocation = "$env:SystemDrive\SCRIPTS\Output\FailoverCluster"

$tmpAttachs = @()

$fileAttachs = @()

$tmpAttachs = Get-ChildItem -Path $fileLocation | Where-Object -FilterScript {$_.Name -like "*.html"} | Select-Object -ExpandProperty Name

foreach ($attach in $tmpAttachs){
    $attachment = $fileLocation + '\' + $attach
    $fileAttachs += $attachment
}

$tmpHTML = Get-Content "$env:systemdrive\SCRIPTS\HTML\contentHCMSCS.html"

$finalHTML = $tmpHTML | Out-String


###########Define Variables to send mail ########

$fromaddress = "powershellrobot@yourdomain.com"
$toaddress = "list1@yourdomain.com","list2@yourdomain.com","list3@yourdomain.com"
#$bccaddress = "powershell@yourdomain.com"
$CCaddress = "youruser@yourdomain.com"
#$CRattachment = $attachments
$smtpserver = "fqdn.yourserver.yourdomain"
$HVSubject = "Report Windows MSCS - $sendDate"
$HVattachment = $fileAttachs

################################################

Send-MailMessage -SmtpServer $smtpserver -From $fromaddress -To $toaddress -Cc $CCaddress -Subject $HVSubject -Body $finalHTML -BodyAsHtml -Attachments $HVattachment -Priority Normal -Encoding UTF8


