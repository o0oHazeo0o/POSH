################################################
# Description:
# This script automates the creation of multiple reports across many Zerto Virtual Managers and vCenters
################################################
# Requirements:
# 1. Run PowerShell as administrator with command "Set-ExecutionPolcity unrestricted"
# 2. Verify script server has connectivity to all vCenters, ZVMs and an SMTP server
# 3. Install VMware PowerCLI 6.0
# 4. Configure variables in “Set Credentials for all vCenters & ZVMs”, “SMTP Email Profile Settings” and set “Creating vCenter & ZVM Mappings to report on”
# 5. Credentials configured have read access to vCenter and view/edit VPG permissions in ZVM
# 6. To store credentials securely consider using:
# https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Encryption-45709b87
# 7. The password needs to be decrypted for use by the Zerto API which sends it over HTTPs to keep it secure
# 8. Add additional email lists if required and increment the number
# 9. Each combination of a vCenters and ZVM is referred to as a POD, add your PODs into the Create-vCenterArray function on line 24 and remove eisting
# 10. Start with default reports and customize from line 2500
# 11. Run the script manually or schedule using windows task scheduler
# 12. Recommended to run for the first time in PowerShell ISE for troubleshooting
# 13. The script isn’t configured to use transcription for logging of exceptions
################################################
# Set Credentials for all vCenters & ZVMs
################################################
$Username = "zerto@domain.ext"
$Password = "Zerto1234!"
$CSVDirectory = "C:\ZVRReports\"
# Configure target ZVM resource report sampling rate, by default daily, if left as daily then set the below to false and all ZVMs should be configured to the same setting
$ResourceReportHourlySample = "TRUE"
################################################
# SMTP Email Profile Settings
################################################
$EmailList1 = "recipient1@domain.ext"
$EmailFrom = "sender@domain.ext"
$SMTPServer = "localhost"
$SMTPPort = "25"
$SMTPUser = "username"
$SMTPPassword = "password"
$SMTPSSLEnabled = "FALSE"
# Creating SMTP Profiles
$SMTPProfile1 = @("$EmailFrom",“$SMTPServer”,”$SMTPPort”,”$SMTPUser”,”$SMTPPassword”,”$SMTPSSLEnabled”)
################################################
# Creating vCenter & ZVM Mappings to report on - change this to match environment
################################################
Function Create-vCenterArray{
$vCenterArray = @()
# Zerto Demo LAB 1
$vCenterArrayLine = new-object PSObject
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value "ZVRPRODPOD1"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourcevCenter" -Value "192.168.0.81"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourceZVM" -Value "192.168.0.31"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetPOD" -Value "ZVRDRPOD1"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetvCenter" -Value "192.168.0.82"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetZVM" -Value "192.168.0.32"
$vCenterArray += $vCenterArrayLine
# Zerto Demo LAB 2
$vCenterArrayLine = new-object PSObject
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value "ZVRPRODPOD2"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourcevCenter" -Value "192.168.0.81"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "SourceZVM" -Value "192.168.0.31"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetPOD" -Value "ZVRDRPOD2"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetvCenter" -Value "192.168.0.82"
$vCenterArrayLine | Add-Member -MemberType NoteProperty -Name "TargetZVM" -Value "192.168.0.32"
$vCenterArray += $vCenterArrayLine
# Outputting array to function
$vCenterArray
}
# Running function created
$vCenterArray = Create-vCenterArray
################################################################################################################################################
# Nothing to configure below this line to receive the default reports
################################################################################################################################################
################################################
# Building HTML settings for Email reports
################################################
$TableFont = "#FFFFFF"
$TableBackground = "#B20000"
$TableBorder = "#e60000"
$ReportHTMLTableStyle = @"
<style type="text/css">
.tg {border-collapse:collapse;border-spacing:0;border-color:#aaa;}
.tg td{font-family:Arial, sans-serif;font-size:10px;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#aaa;color:#333;background-color:#ffffff;border-top-width:1px;border-bottom-width:1px;}
.tg th{font-family:Arial, sans-serif;font-size:10px;font-weight:bold;padding:10px 5px;border-style:solid;border-width:0px;overflow:hidden;word-break:normal;border-color:#aaa;color:$TableFont ;background-color:$TableBorder;border-top-width:1px;border-bottom-width:1px;}
.tg .tg-foxd{background-color:$TableBackground;vertical-align:top;text-align:left}
.tg .tg-yw4l{vertical-align:top}
.caption {font-family:Arial, sans-serif;font-size:11px;font-weight:bold;color:$TableFont;}
</style>
"@
################################################
# Creating CSV Save Function
################################################
Function Save-CSV{
Param($Array,$CSVFileName,$CSVDirectory)
# Saving file to directory specified then returning file name to use for email
$Timestamp = get-date
$Now = $TimeStamp.ToString("yyyy-MM-dd HH-mm-ss")
$CSVName = $Now + $CSVFileName
$CSVFile = $CSVDirectory + $CSVName + ".csv"
$Array | Export-CSV -NoTypeInformation $CSVFile
$CSVFile
}
################################################
# Creating Time function
################################################
Function Get-Time{
$Timestamp = get-date
$Now = $TimeStamp.ToString("yyyy-MM-dd HH-mm-ss")
$Now
}
################################################
# Creating Email Function
################################################
Function Email-ZVRReport{
Param($EmailTo,$Subject,$Body,$Attachment,$SMTPProfile)
# Getting SMTP Profile Settings
$EmailFrom = $SMTPProfile[0]
$SMTPServer = $SMTPProfile[1]
$SMTPPort = $SMTPProfile[2]
$SMTPUser = $SMTPProfile[3]
$SMTPPassword = $SMTPProfile[4]
$SMTPSSLEnabled = $SMTPProfile[5]
# Building SMTP settings based on settings
$emailsetting = New-Object System.Net.Mail.MailMessage
$emailsetting.to.add($EmailTo)
$emailsetting.from = $EmailFrom
$emailsetting.IsBodyHTML = "TRUE"
$emailsetting.subject = $Subject
$emailsetting.body = $Body
# Adding attachments
if ($Attachment -ne $null)
{
# Performing for each to support multiple attachments
foreach($_ in $Attachment)
{
$emailattachmentsetting = new-object System.Net.Mail.Attachment $_
$emailsetting.attachments.add($emailattachmentsetting)
# invoke-expression $AttachmentCommand
# End of for each attachment below
}
# End of for each attachment above
}
# Creating SMTP object
$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
# Enabling SSL if set
if ($SMTPSSLEnabled -eq "TRUE")
{
$smtp.EnableSSL = "TRUE"
}
# Setting credentials
$smtp.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPassword);
# Sending the Email
Try
{
$smtp.send($emailsetting)
}
Catch [system.exception]
{
# Trying email again
$smtp.send($emailsetting)
}
# End of email function
}
################################################
# Creating Report arrays
################################################
$ProtectedVPGArray = @()
$ProtectedVMArray = @()
$TargetVRAArray = @()
$UnprotectedVMArray = @()
$TargetDatastoreArray = @()
$VPGArray = @()
$VMArray = @()
$VMVolumeArray = @()
$VMNICArray = @()
$PODSummaryArray = @()
################################################
# Creating Vm Status Array
################################################
Function Create-VMStatusArray {
$VMStatusArray = @()
# Status 0
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "0"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Initializing"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is being initialized. This includes when a VPG is created and during initial sync."
$VMStatusArray += $VMStatusArrayLine
# Status 1
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "1"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "MeetingSLA"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is meeting the SLA specification."
$VMStatusArray += $VMStatusArrayLine
# Status 2
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "2"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "NotMeetingSLA"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is not meeting the SLA for both the journal history and RPO SLA settings."
$VMStatusArray += $VMStatusArrayLine
# Status 3
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "3"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "HistoryNotMeetingSLA"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is not meeting the SLA specification for the journal history."
$VMStatusArray += $VMStatusArrayLine
# Status 4
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "4"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "RpoNotMeetingSLA"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is not meeting the SLA specification for the RPO SLA setting."
$VMStatusArray += $VMStatusArrayLine
# Status 5
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "5"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "FailingOver"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is in a Failover operation."
$VMStatusArray += $VMStatusArrayLine
# Status 6
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "6"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Moving"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is in a Move operation."
$VMStatusArray += $VMStatusArrayLine
# Status 7
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "7"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Deleting"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG is being deleted."
$VMStatusArray += $VMStatusArrayLine
# Status 8
$VMStatusArrayLine = new-object PSObject
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "8"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Recovered"
$VMStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "The VPG has been recovered."
$VMStatusArray += $VMStatusArrayLine
# Outputting array to function
$VMStatusArray
}
# Running function created
$VMStatusArray = Create-VMStatusArray
################################################
# Creating Event Status Array
################################################
Function Create-EventStatusArray {
$EventStatusArray = @()
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "14"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "STR0001"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Datastore not accessible"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "15"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "STR0002"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Datastore is full"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "16"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "STR0004"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Datastore low in space"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "32"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0003"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG has low journal history"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "33"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0004"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG has low journal history"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "34"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0005"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG in error state"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "35"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0006"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG missing configuration details"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "36"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0007"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG replication paused"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "37"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0008"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG rollback failed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "38"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0009"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG target RPO exceeded"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "39"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0010"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG target RPO exceeded"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "40"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0011"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG test overdue"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "41"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0012"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG test overdue"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "42"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0014"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG waiting for commit or rollback"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "43"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0015"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Resources not enough to support VPG "
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "44"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0016"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Resources pool not found"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "45"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0017"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG protection paused"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "46"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0018"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VMs in VPG not configured with a storage profile"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "47"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0019"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile disabled"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "48"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0020"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile not found"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "49"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0021"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile not found"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "50"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0022"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile disabled"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "51"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0023"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile not found"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "52"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0024"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile does not include active datastores"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "53"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0025"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "vApp network mapping not defined"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "54"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0026"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery storage profile changed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "55"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0027"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG includes VMs that are no longer protected"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "56"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0028"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Corrupted Org vDC network mapping"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "57"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0035"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG protected resources not in ZORG"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "58"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0036"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VPG recovery resources not in ZORG"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "59"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0037"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal history is compromised"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "60"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0038"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal history is compromised"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "61"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0039"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "RDM has an odd number of blocks"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "62"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0040"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Virtual machine hardware mismatch with recovery site"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "63"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0041"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Virtual machine running Windows 2003"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "64"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0042"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery network not found"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "65"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VPG0043"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Cross-replication"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "66"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0001"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Host without VRA"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "67"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0002"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA without IP"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "68"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0003"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Host IP changes"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "69"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0004"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA lost IP"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "70"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0005"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRAs not connected"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "71"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0006"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Datastore for journal disk is full"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "72"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0007"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "I/O error to journal"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "73"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0008"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery disk and VMs missing"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "74"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0009"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery disk missing"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "75"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0010"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery disks turned off"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "76"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0011"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery disk inaccessible"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "77"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0012"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Cannot write to recovery disk"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "78"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0013"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "I/O error to recovery disk"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "79"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0014"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Cloned disks turned off"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "80"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0015"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Cloned disk inaccessible"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "81"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0016"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Datastore for clone disk is full"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "82"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0017"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "I/O error to clone"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "83"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0018"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Protected disk and VM missing"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "84"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0019"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Protected disk missing"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "85"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0020"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VM powered off"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "86"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0021"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VM disk inaccessible"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "87"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0022"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VM disk incompatible"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "88"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0023"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA cannot be registered"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "89"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0024"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA removed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "90"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0025"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "I/O synchronization"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "91"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0026"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Recovery disk removed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "92"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0027"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal disk removed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "93"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0028"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA powered off"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "94"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0029"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA memory low"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "95"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0030"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal size mismatch"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "96"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0032"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA out-of-date"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "97"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0035"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "VRA reconciliation"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "98"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0037"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Local MAC Address Conflict"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "99"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0038"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "MAC Address Conflict"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "100"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0039"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal reached configured limit"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "101"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0040"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Journal space low"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "102"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0049"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Host rollback failed"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "103"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "VRA0050"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Wrong host password"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "108"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0001"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "No connection to hypervisor manager"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "109"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0002"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "No connection to VRA"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "110"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0003"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "No connection to site"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "111"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0004"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Peer site out-of-date"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "112"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0005"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Zerto Virtual Manager space low"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "113"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0006"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Upgrade available"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "114"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0007"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Cannot upgrade"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "115"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0008"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Version mismatch"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "116"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0009"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Internal error"
$EventStatusArray += $EventStatusArrayLine
# Status line
$EventStatusArrayLine = new-object PSObject
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "117"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Identifier" -Value "ZVM0010"
$EventStatusArrayLine | Add-Member -MemberType NoteProperty -Name "Description" -Value "Synchronization between Zerto Virtual Managers"
$EventStatusArray += $EventStatusArrayLine
# Outputting
$EventStatusArray
}
# Running function created
$EventStatusArray = Create-EventStatusArray
################################################
# Creating Priority Array
################################################
Function Create-VMPriorityArray {
$VMPriorityArray = @()
# Priority 1
$VMPriorityArrayLine = new-object PSObject
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "1"
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "High"
$VMPriorityArray += $VMPriorityArrayLine
# Priority 2
$VMPriorityArrayLine = new-object PSObject
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "2"
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Medium"
$VMPriorityArray += $VMPriorityArrayLine
# Priority 3
$VMPriorityArrayLine = new-object PSObject
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Number" -Value "3"
$VMPriorityArrayLine | Add-Member -MemberType NoteProperty -Name "Name" -Value "Low"
$VMPriorityArray += $VMPriorityArrayLine
# Outputting
$VMPriorityArray
}
$VMPriorityArray = Create-VMPriorityArray
################################################
# Building Reports per POD
################################################
foreach ($POD in $vCenterArray)
{
# Setting variables
$SourcePOD = $POD.SourcePOD
$SourcevCenter = $POD.SourcevCenter
$SourceZVM = $POD.SourceZVM
$TargetPOD = $POD.TargetPOD
$TargetvCenter = $POD.TargetvCenter
$TargetZVM = $POD.TargetZVM
################################################
# Connecting to source vCenter for source VM info
################################################
Try
{
write-host "Connecting to vCenter:$SourcevCenter"
connect-viserver -Server $SourcevCenter -User $Username -Password $Password
$SourcevCenterAuthentication = "PASS"
}
Catch {
$SourcevCenterAuthentication = "FAIL"
}
# Connecting to Target vCenter for target info
Try
{
connect-viserver -Server $TargetvCenter -User $Username -Password $Password
$TargetvCenterAuthentication = "PASS"
}
Catch {
$TargetvCenterAuthentication = "FAIL"
}
# Catching failed vCenter authentication, only running reports for POD if it passses
if (($TargetvCenterAuthentication -eq "PASS") -and ($SourcevCenterAuthentication -eq "PASS"))
{
################################################
# Building Source Zerto API string and invoking API
################################################
$SourceZVMBaseURL = "https://" + $SourceZVM + ":"+"9669"+"/v1/"
# Authenticating with Zerto APIs
$SourceZVMSessionURL = $SourceZVMBaseURL + "session/add"
$SourceZVMAuthInfo = ("{0}:{1}" -f $Username,$Password)
$SourceZVMAuthInfo = [System.Text.Encoding]::UTF8.GetBytes($SourceZVMAuthInfo)
$SourceZVMAuthInfo = [System.Convert]::ToBase64String($SourceZVMAuthInfo)
$SourceZVMHeaders = @{Authorization=("Basic {0}" -f $SourceZVMAuthInfo)}
$SourceZVMSessionBody = '{"AuthenticationMethod": "1"}'
$TypeJSON = "application/json"
$TypeXML = "application/xml"
Try
{
$SourceZVMSessionResponse = Invoke-WebRequest -Uri $SourceZVMSessionURL -Headers $SourceZVMHeaders -Method POST -Body $SourceZVMSessionBody -ContentType $TypeJSON
$SourceZVMAuthentication = "PASS"
}
Catch {
$SourceZVMAuthentication = "FAIL"
}
#Extracting x-zerto-session from the response, and adding it to the actual API
$SourceZVMSession = $SourceZVMSessionResponse.headers.get_item("x-zerto-session")
$SourceZVMSessionHeader_JSON = @{"x-zerto-session"=$SourceZVMSession; "Accept"=$TypeJSON}
$SourceZVMSessionHeader_XML = @{"x-zerto-session"=$SourceZVMSession; "Accept"=$TypeXML}
if ($SourceZVMAuthentication -eq "PASS")
{
# Get SiteIdentifier for later in the script
$SourceSiteInfoURL = $SourceZVMBaseURL+"localsite"
$SourceSiteInfoCMD = Invoke-RestMethod -Uri $SourceSiteInfoURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
$SourceLocalSiteIdentifier = $SourceSiteInfoCMD | Select SiteIdentifier -ExpandProperty SiteIdentifier
}
################################################
# Building Taret Zerto API string and invoking API
################################################
$TargetZVMBaseURL = "https://" + $TargetZVM + ":"+"9669"+"/v1/"
$TargetZVMBaseResourceReportURL = "https://" + $TargetZVM + ":"+"9669"
# Authenticating with Zerto APIs
$TargetZVMSessionURL = $TargetZVMBaseURL + "session/add"
$TargetZVMAuthInfo = ("{0}:{1}" -f $Username,$Password)
$TargetZVMAuthInfo = [System.Text.Encoding]::UTF8.GetBytes($TargetZVMAuthInfo)
$TargetZVMAuthInfo = [System.Convert]::ToBase64String($TargetZVMAuthInfo)
$TargetZVMHeaders = @{Authorization=("Basic {0}" -f $TargetZVMAuthInfo)}
$TargetZVMSessionBody = '{"AuthenticationMethod": "1"}'
$TypeJSON = "application/json"
$TypeXML = "application/xml"
Try
{
$TargetZVMSessionResponse = Invoke-WebRequest -Uri $TargetZVMSessionURL -Headers $TargetZVMHeaders -Method POST -Body $TargetZVMSessionBody -ContentType $TypeJSON
$TargetZVMAuthentication = "PASS"
}
Catch {
$TargetZVMAuthentication = "FAIL"
}
#Extracting x-zerto-session from the response, and adding it to the actual API
$TargetZVMSession = $TargetZVMSessionResponse.headers.get_item("x-zerto-session")
$TargetZVMSessionHeader = @{"x-zerto-session"=$TargetZVMSession; "Accept"=$TypeJSON}
if ($TargetZVMAuthentication -eq "PASS")
{
# Get SiteIdentifier for later in the script
$TargetSiteInfoURL = $TargetZVMBaseURL+"localsite"
$TargetSiteInfoCMD = Invoke-RestMethod -Uri $TargetSiteInfoURL -TimeoutSec 100 -Headers $TargetZVMSessionHeader -ContentType $TypeJSON
$TargetLocalSiteIdentifier = $TargetSiteInfoCMD | Select SiteIdentifier -ExpandProperty SiteIdentifier
}
################################################
# Getting last resource report sample, for use in email reports
################################################
if ($ResourceReportHourlySample -eq "TRUE")
{
$NowDateTime = get-date -Format "yyyy-MM-dd"
$ThenDateTime = (get-date).AddDays(-1).ToString("yyyy-MM-dd")
}
else
{
$NowDateTime = get-date -Format "yyyy-MM-dd"
$ThenDateTime = (get-date).AddDays(-1).ToString("yyyy-MM-dd")
}
# QueryResourceReport with entries from the last hour
$ResourceReprtString = "/ZvmService/ResourcesReport/getSamples?fromTimeString="
$ResourceReportURL = $TargetZVMBaseResourceReportURL + $ResourceReprtString + $ThenDateTime + "&toTimeString=" + $NowDateTime + "&startIndex=0&count=500"
$ResourceReport = Invoke-RestMethod -Uri $ResourceReportURL -TimeoutSec 100 -Headers $TargetZVMSessionHeader -ContentType $TypeJSON
################################################
# Creating ProtectedVPGArray
################################################
# Getting VPGs
$ProtectedVPGsURL = $SourceZVMBaseURL+"vpgs"
$ProtectedVPGsCMD = Invoke-RestMethod -Uri $ProtectedVPGsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
foreach ($VPG in $ProtectedVPGsCMD)
{
$VPGName = $VPG.VpgName
$VPGIdentifier = $VPG.VpgIdentifier
$VMCount = $VPG.VmsCount
$PriorityNumber = $VPG.Priority
$RPO = $VPG.ActualRPO
$StatusNumber = $VPG.Status
$SizeInGb = $VPG.UsedStorageInMB / 1024
$SizeInGb = [math]::Round($SizeInGb,2)
# Converting priority
$VPGPriority = $VMPriorityArray | Where-Object {$_.Number -eq $PriorityNumber} | select -ExpandProperty Name
# Converting VM status
$VPGStatus = $VMStatusArray | Where-Object {$_.Number -eq $StatusNumber} | select -ExpandProperty Name
$VPGStatusDescription = $VMStatusArray | Where-Object {$_.Number -eq $StatusNumber} | select -ExpandProperty Description
# Getting VPG Journal size
$VPGResourceReport = $ResourceReport | Where-Object {$_.VpgName -eq $VPGName}
# Calculating total Journal usage
$VPGJournalUsage = $VPGResourceReport.RecoveryJournalUsedStorageInGB
$VPGTotalJournalUsage = 0
foreach ($_ in $VPGJournalUsage)
{
$VPGTotalJournalUsage += $_
}
$VPGTotalJournalUsage = [math]::Round($VPGTotalJournalUsage,2)
# Getting Alerts for the VPG for past 24 hours
$Tomorrow = (get-date).AddDays(1)
$Yesterday = (get-date).AddDays(-1)
# Building URL
$VPGAlertsURL = $SourceZVMBaseURL+"alerts?"+"startDate=$Yesterday&endDate=$Tomorrow&vpgIdentifier={$VPGIdentifier}&isDismissed=false"
# Getting events
$VPGAlertsCMD = Invoke-RestMethod -Uri $VPGAlertsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
$VPGLastAlert = $VPGAlertsCMD | select * -First 1
# Getting description of last alert
$VPGLastAlertIdentifier = $VPGLastAlert.HelpIdentifier
$VPGLastAlertDescription = $EventStatusArray | Where-Object {$_.Identifier -eq $VPGLastAlertIdentifier} | select -expandproperty Description
# Calculating RPO violations in last 24 hours
$VPGRPOAlerts = $VPGAlertsCMD | Where-Object {$_.HelpIdentifier -eq "VPG0009" -or $_.HelpIdentifier -eq "VPG0009"} | Measure-Object | select -ExpandProperty Count
# Adding to array
$ProtectedVPGArrayLine = new-object PSObject
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value $SourcePOD
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "TargetPOD" -Value $TargetPOD
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "VMCount" -Value $VMCount
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "Priority" -Value $VPGPriority
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "RPO" -Value $RPO
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "RPOAlerts" -Value $VPGRPOAlerts
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "Status" -Value $VPGStatus
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "SizeInGb" -Value $SizeInGb
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "JournalSizeInGb" -Value $VPGTotalJournalUsage
$ProtectedVPGArrayLine | Add-Member -MemberType NoteProperty -Name "AlertDescription" -Value $VPGLastAlertDescription
$ProtectedVPGArray += $ProtectedVPGArrayLine
}
# Getting VMs
$ProtectedVMsURL = $SourceZVMBaseURL+"vms"
$ProtectedVMsCMD = Invoke-RestMethod -Uri $ProtectedVMsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Adding to array
$ProtectedVMs = $ProtectedVMsCMD | Sort-Object VpgName
foreach ($VM in $ProtectedVMs)
{
$VPGName = $VM.VpgName
$VMName = $VM.VmName
$StatusNumber = $VM.Status
$PriorityNumber = $VM.Priority
$RPO = $VM.ActualRPO
$SizeInGb = $VM.UsedStorageInMB / 1024
$SizeInGb = [math]::Round($SizeInGb,2)
$VMDisks = $VM.Volumes.Count
# Converting priority
$VMPriority = $VMPriorityArray | Where-Object {$_.Number -eq $PriorityNumber} | select -ExpandProperty Name
# Converting VM status
$VMStatus = $VMStatusArray | Where-Object {$_.Number -eq $StatusNumber} | select -ExpandProperty Name
$VMStatusDescription = $VMStatusArray | Where-Object {$_.Number -eq $StatusNumber} | select -ExpandProperty Description
# Gettong VM Journal size
$VMResourceReport = $ResourceReport | Where-Object {$_.VmName -eq $VMName} | select -First 1
$VMSourceCluster = $VMResourceReport.SourceCluster
$VMTargetCluster = $VMResourceReport.TargetCluster
# Calculating total Journal usage
$VMJournalUsage = $VMResourceReport.RecoveryJournalUsedStorageInGB
$VMTotalJournalUsage = 0
foreach ($_ in $VMJournalUsage)
{
$VMTotalJournalUsage += $_
}
$VMTotalJournalUsage = [math]::Round($VMTotalJournalUsage,2)
# Creating array line
$ProtectedVMArrayLine = new-object PSObject
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value "$SourcePOD"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "SourceCluster" -Value "$VMSourceCluster"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "TargetPOD" -Value "$TargetPOD"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "TargetCluster" -Value "$VMTargetCluster"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value "$VPGName"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "VMName" -Value "$VMName"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "Priority" -Value "$VMPriority"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "RPO" -Value "$RPO"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "Status" -Value "$VMStatus"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "Disks" -Value "$VMDisks"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "SizeInGb" -Value "$SizeInGb"
$ProtectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "JournalSizeInGb" -Value "$VMTotalJournalUsage"
$ProtectedVMArray += $ProtectedVMArrayLine
}
################################################
# Creating TargetVRAArray
################################################
$TargetZVMHostsURL = $TargetZVMBaseURL+"virtualizationsites/"+$TargetLocalSiteIdentifier+"/hosts"
$TargetZVMHostsCMD = Invoke-RestMethod -Uri $TargetZVMHostsURL -TimeoutSec 100 -Headers $TargetZVMSessionHeader -ContentType $TypeJSON
$TargetZVMVRAsURL = $TargetZVMBaseURL+"vras"
$TargetZVMVRAsCMD = Invoke-RestMethod -Uri $TargetZVMVRAsURL -TimeoutSec 100 -Headers $TargetZVMSessionHeader -ContentType $TypeJSON
$TargetZVMVRAs = $TargetZVMVRAsCMD | Select-Object VraName,HostIdentifier,VraGroup,RecoveryCounters -Unique
# For each VRA
foreach ($TargetVRA in $TargetZVMVRAs)
{
$VRAName = $TargetVRA.VraName
$VRACluster = get-vm $VRAName | Get-Cluster | select -expandproperty Name
$VRAHostIdentifier = $TargetVRA.HostIdentifier
$VRAVMs = $TargetVRA.RecoveryCounters.Vms
$VRAHostIdentifier = $TargetVRA.HostIdentifier
$VRAVolumes = $TargetVRA.RecoveryCounters.Volumes
$VRAVpgs = $TargetVRA.RecoveryCounters.Vpgs
$VRAGroup = $TargetVRA.VraGroup
# Getting hostname
$VRAHostname = $TargetZVMHostsCMD | Where-Object {$_.HostIdentifier -eq $VRAHostIdentifier} | select -ExpandProperty VirtualizationHostName
# Getting over commit data from resource report
$TargetVraData = $ResourceReport | Where-Object {$_.TargetVraName -eq $VRAName} | Select-Object NumberOfvCpu,CpuUsedInMhz,MemoryInMB,ActiveGuestMemoryInMB,BandwidthInBytes,RecoveryVolumesUsedStorageInGB,RecoveryJournalUsedStorageInGB
# Calculating total CPUs
$TargetVraNumberOfvCPU = $TargetVraData.NumberOfvCpu
$TotalTargetVraNumberOfvCPU = 0
foreach ($_ in $TargetVraNumberOfvCPU)
{
$TotalTargetVraNumberOfvCPU += $_
}
# Calculating total CPU mhz
$TargetVraCpuUsedInMhz = $TargetVraData.CpuUsedInMhz
$TotalTargetVraCpuUsedInMhz = 0
foreach ($_ in $TargetVraCpuUsedInMhz)
{
$TotalTargetVraCpuUsedInMhz += $_
}
$TotalTargetVraCpuUsedInGhz = $TotalTargetVraCpuUsedInMhz / 1000
$TotalTargetVraCpuUsedInGhz = [math]::Round($TotalTargetVraCpuUsedInGhz,2)
# Calculating total MemoryInMB
$TargetVraMemoryInMB = $TargetVraData.MemoryInMB
$TotalTargetVraMemoryInMB = 0
foreach ($_ in $TargetVraMemoryInMB)
{
$TotalTargetVraMemoryInMB += $_
}
$TotalTargetVraMemoryInGB = $TotalTargetVraMemoryInMB / 1024
$TotalTargetVraMemoryInGB = [math]::Round($TotalTargetVraMemoryInGB,2)
# Calculating total ActiveGuestMemoryInMB
$TargetVraActiveGuestMemoryInMB = $TargetVraData.ActiveGuestMemoryInMB
$TotalTargetVraActiveGuestMemoryInMB = 0
foreach ($_ in $TargetVraActiveGuestMemoryInMB)
{
$TotalTargetVraActiveGuestMemoryInMB += $_
}
$TotalTargetVraActiveGuestMemoryInGB = $TotalTargetVraActiveGuestMemoryInMB / 1024
$TotalTargetVraActiveGuestMemoryInGB = [math]::Round($TotalTargetVraActiveGuestMemoryInGB,2)
# Calculating total BandwidthInBytes
$TargetVraBandwidthInBytes = $TargetVraData.BandwidthInBytes
$TotalTargetVraBandwidthInBytes = 0
foreach ($_ in $TargetVraBandwidthInBytes)
{
$TotalTargetVraBandwidthInBytes += $_
}
# Calculating total RecoveryVolumesUsedStorageInGB & TB
$TargetVraRecoveryVolumesUsedStorageInGB = $TargetVraData.RecoveryVolumesUsedStorageInGB
$TotalTargetVraRecoveryVolumesUsedStorageInGB = 0
foreach ($_ in $TargetVraRecoveryVolumesUsedStorageInGB)
{
$TotalTargetVraRecoveryVolumesUsedStorageInGB += $_
}
$TotalTargetVraRecoveryVolumesUsedStorageInTB = $TotalTargetVraRecoveryVolumesUsedStorageInGB / 1024
$TotalTargetVraRecoveryVolumesUsedStorageInTB = [math]::Round($TotalTargetVraRecoveryVolumesUsedStorageInTB,2)
# Calculating total RecoveryJournalUsedStorageInGB
$TargetVraRecoveryJournalUsedStorageInGB = $TargetVraData.RecoveryJournalUsedStorageInGB
$TotalTargetVraRecoveryJournalUsedStorageInGB = 0
foreach ($_ in $TargetVraRecoveryJournalUsedStorageInGB)
{
$TotalTargetVraRecoveryJournalUsedStorageInGB += $_
}
$TotalTargetVraRecoveryJournalUsedStorageInTB = $TotalTargetVraRecoveryJournalUsedStorageInGB / 1024
$TotalTargetVraRecoveryJournalUsedStorageInTB = [math]::Round($TotalTargetVraRecoveryJournalUsedStorageInTB,2)
# Creating array
$TargetVRAArrayLine = new-object PSObject
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "TargetPOD" -Value $TargetPOD
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRACluster" -Value $VRACluster
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRAName" -Value $VRAName
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "ESXiHostname" -Value $VRAHostname
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRAVPGs" -Value $VRAVpgs
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRAVMs" -Value $VRAVMs
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRAVolumes" -Value $VRAVolumes
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRABandwidthInBytes" -Value $TotalTargetVraBandwidthInBytes
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRARecoveryVolumesInGB" -Value $TotalTargetVraRecoveryVolumesUsedStorageInGB
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VraRecoveryVolumesInTB" -Value $TotalTargetVraRecoveryVolumesUsedStorageInTB
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRARecoveryJournalsInGB" -Value $TotalTargetVraRecoveryJournalUsedStorageInGB
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VRARecoveryJournalsInTB" -Value $TotalTargetVraRecoveryJournalUsedStorageInTB
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VMNumberOfvCPU" -Value $TotalTargetVraNumberOfvCPU
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VMCpuUsedInGhz" -Value $TotalTargetVraCpuUsedInGhz
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VMMemoryInGB" -Value $TotalTargetVraMemoryInGB
$TargetVRAArrayLine | Add-Member -MemberType NoteProperty -Name "VMActiveMemoryInGB" -Value $TotalTargetVraActiveGuestMemoryInGB
$TargetVRAArray += $TargetVRAArrayLine
}
################################################
# Creating UnprotectedVMArray
################################################
# Using ZVR API to get VMs
$SourceZVMUnprotectedVMsURL = $SourceZVMBaseURL+"virtualizationsites/"+$SourceLocalSiteIdentifier+"/vms"
$SourceZVMUnprotectedVMsCMD = Invoke-RestMethod -Uri $SourceZVMUnprotectedVMsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# For each unprotected VM
foreach ($VM in $SourceZVMUnprotectedVMsCMD)
{
# Getting vCenter VM ID from ZVR ID
$VMName = $VM.VmName
$VMZVRID = $VM.VmIdentifier
$Separator = "."
$VMZVRIDSplit = $VMZVRID.split($Separator)
$VMID = $VMZVRIDSplit[1]
$VMID = "VirtualMachine-" + $VMID
# Using vCenter VM ID to get more info
# Getting cluster info
$VMCluster = get-vm -Id $VMID | Get-Cluster | select -expandproperty Name -First 1
$VMInfo = get-vm -Id $VMID | select Folder,NumCPU,MemoryGB,HardDisks,NetworkAdapters,UsedSpaceGB -First 1
$VMFolder = $VMInfo.Folder
$VMNumCPU = $VMInfo.NumCpu
$VMMemoryGB = $VMInfo.MemoryGB
$VMMemoryGB = [math]::Round($VMMemoryGB,2)
$VMHardDisks = $VMInfo.HardDisks.Count
$VMNICS = $VMInfo.NetworkAdapters.Count
$VMUsedSpaceGB = $VMInfo.UsedSpaceGB
$VMUsedSpaceGB = [math]::Round($VMUsedSpaceGB,2)
# Building array line
$UnprotectedVMArrayLine = new-object PSObject
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value "$SourcePOD"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "VMFolder" -Value "$VMFolder"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "VMName" -Value "$VMName"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "VMCluster" -Value "$VMCluster"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "NumCPU" -Value "$VMNumCPU"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "MemoryGB" -Value "$VMMemoryGB"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "NICS" -Value "$VMNICS"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "HardDisks" -Value "$VMHardDisks"
$UnprotectedVMArrayLine | Add-Member -MemberType NoteProperty -Name "UsedSpaceGB" -Value "$VMUsedSpaceGB"
$UnprotectedVMArray += $UnprotectedVMArrayLine
}
################################################
# Creating TargetDatastoreArray
################################################
$TargetDatastoresURL = $TargetZVMBaseURL+"virtualizationsites/"+$TargetLocalSiteIdentifier+"/datastores"
$TargetDatastoresCMD = Invoke-RestMethod -Uri $TargetDatastoresURL -TimeoutSec 100 -Headers $TargetZVMSessionHeader -ContentType $TypeJSON
# For each datastore
foreach ($DS in $TargetDatastoresCMD)
{
# Getting vCenter VM ID from ZVR ID
$DSName = $DS.DatastoreName
$DSZVRID = $DS.DatastoreIdentifier
$Separator = "."
$DSZVRIDSplit = $DSZVRID.split($Separator)
$DSID = $DSZVRIDSplit[1]
$DSID = "Datastore-" + $DSID
# Using vCenter to get more info
$DSCluster = Get-Datastore -Id $DSID | Get-DatastoreCluster | select -ExpandProperty Name -First 1
$DSInfo = Get-Datastore -Id $DSID | select * -First 1
$DSCapacityGB = $DSInfo.CapacityGB
$DSCapacityGB = [math]::Round($DSCapacityGB)
$DSFreeSpaceGB = $DSInfo.FreeSpaceGB
$DSFreeSpaceGB = [math]::Round($DSFreeSpaceGB)
$DSFreePercentage = ($DSFreeSpaceGB / $DSCapacityGB) * 100
$DSFreePercentage = [math]::Round($DSFreePercentage)
# Finding if datastore is used for replication
$ResourceReportTargetDatastores = $ResourceReport | select -ExpandProperty TargetDatastores
# Checking if DSName found in any target VM replica datastores
if ($ResourceReportTargetDatastores -match $DSName)
{
$DSUsedByZVR = "TRUE"
}
else
{
$DSUsedByZVR = "FALSE"
}
# Building array line
$TargetDatastoreArrayLine = new-object PSObject
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "PODName" -Value $TargetPOD
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "DatastoreCluster" -Value "$DSCluster"
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "DatastoreName" -Value "$DSName"
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "UsedByZVR" -Value "$DSUsedByZVR"
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "CapacityGB" -Value "$DSCapacityGB"
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "FreeSpaceGB" -Value "$DSFreeSpaceGB"
$TargetDatastoreArrayLine | Add-Member -MemberType NoteProperty -Name "FreePercent" -Value "$DSFreePercentage"
$TargetDatastoreArray += $TargetDatastoreArrayLine
}
################################################
# Creating VPGArray, VMArray, VMVolumeArray, VMNICArray
################################################
# URL to create VPG settings
$CreateVPGURL = $SourceZVMBaseURL+"vpgSettings"
# Build List of VPGs
$vpgListApiUrl = $SourceZVMBaseURL+"vpgs"
$vpgList = Invoke-RestMethod -Uri $vpgListApiUrl -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
# Build List of VMs
$vmListApiUrl = $SourceZVMBaseURL+"vms"
$vmList = Invoke-RestMethod -Uri $vmListApiUrl -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
# Select IDs from the API array
$zertoprotectiongrouparray = $vpgList.ArrayOfVpgApi.VpgApi | Select-Object OrganizationName,vpgname,vmscount,vpgidentifier
$vmListarray = $vmList.ArrayOfVmApi.VmApi | select-object *
################################################
# Starting for each VPG action of collecting ZVM VPG data
################################################
foreach ($VPGLine in $zertoprotectiongrouparray)
{
$VPGidentifier = $VPGLine.vpgidentifier
$VPGOrganization = $VPGLine.OrganizationName
$VPGVMCount = $VPGLine.VmsCount
$JSON =
"{
""VpgIdentifier"":""$VPGidentifier""
}"
################################################
# Posting the VPG JSON Request to the API
################################################
Try
{
$VPGSettingsIdentifier = Invoke-RestMethod -Method Post -Uri $CreateVPGURL -Body $JSON -ContentType $TypeJSON -Headers $SourceZVMSessionHeader_JSON
$ValidVPGSettingsIdentifier = $true
}
Catch {
$ValidVPGSettingsIdentifier = $false
}
################################################
# Getting VPG settings from API
################################################
# Skipping if unable to obtain valid VPG setting identifier
if ($ValidVPGSettingsIdentifier -eq $true)
{
$VPGSettingsURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier
$VPGSettings = Invoke-RestMethod -Uri $VPGSettingsURL -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting recovery site ID (needed anyway for network settings)
$VPGRecoverySiteIdentifier = $VPGSettings.Basic.RecoverySiteIdentifier
# Getting site info
$VISitesURL = $SourceZVMBaseURL+"virtualizationsites"
$VISitesCMD = Invoke-RestMethod -Uri $VISitesURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting network info
$VINetworksURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/networks"
$VINetworksCMD = Invoke-RestMethod -Uri $VINetworksURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting datastore info
$VIDatastoresURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/datastores"
$VIDatastoresCMD = Invoke-RestMethod -Uri $VIDatastoresURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting datastore cluster info
$VIDatastoreClustersURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/datastoreclusters"
$VIDatastoreClustersCMD = Invoke-RestMethod -Uri $VIDatastoreClustersURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting folder info
$VIFoldersURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/folders"
$VIFoldersCMD = Invoke-RestMethod -Uri $VIFoldersURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting cluster info
$VIClustersURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/hostclusters"
$VIClustersCMD = Invoke-RestMethod -Uri $VIClustersURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting host info
$VIHostsURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/hosts"
$VIHostsCMD = Invoke-RestMethod -Uri $VIHostsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting resource pool info
$VIResourcePoolsURL = $SourceZVMBaseURL+"virtualizationsites/$VPGRecoverySiteIdentifier/resourcepools"
$VIResourcePoolsCMD = Invoke-RestMethod -Uri $VIResourcePoolsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting all VPG Settings
$VPGJournalHistoryInHours = $VPGSettings.Basic.JournalHistoryInHours
$VPGName = $VPGSettings.Basic.Name
$VPGPriortiy = $VPGSettings.Basic.Priority
$VPGProtectedSiteIdentifier = $VPGSettings.Basic.ProtectedSiteIdentifier
$VPGRpoInSeconds = $VPGSettings.Basic.RpoInSeconds
$VPGServiceProfileIdentifier = $VPGSettings.Basic.ServiceProfileIdentifier
$VPGTestIntervalInMinutes = $VPGSettings.Basic.TestIntervalInMinutes
$VPGUseWanCompression = $VPGSettings.Basic.UseWanCompression
$VPGZorgIdentifier = $VPGSettings.Basic.ZorgIdentifier
# Getting Boot Group IDs
$VPGBootGroups = $VPGSettings.BootGroups.BootGroups
$VPGBootGroupCount = $VPGSettings.BootGroups.BootGroups.Count
$VPGBootGroupNames = $VPGSettings.BootGroups.BootGroups.Name
$VPGBootGroupDelays = $VPGSettings.BootGroups.BootGroups.BootDelayInSeconds
$VPGBootGroupIdentifiers = $VPGSettings.BootGroups.BootGroups.BootGroupIdentifier
# Getting Journal info
$VPGJournalDatastoreClusterIdentifier = $VPGSettings.Journal.DatastoreClusterIdentifier
$VPGJournalDatastoreIdentifier = $VPGSettings.Journal.DatastoreIdentifier
$VPGJournalHardLimitInMB = $VPGSettings.Journal.Limitation.HardLimitInMB
$VPGJournalHardLimitInPercent = $VPGSettings.Journal.Limitation.HardLimitInPercent
$VPGJournalWarningThresholdInMB = $VPGSettings.Journal.Limitation.WarningThresholdInMB
$VPGJournalWarningThresholdInPercent = $VPGSettings.Journal.Limitation.WarningThresholdInPercent
# Getting Network IDs
$VPGFailoverNetworkID = $VPGSettings.Networks.Failover.Hypervisor.DefaultNetworkIdentifier
$VPGFailoverTestNetworkID = $VPGSettings.Networks.FailoverTest.Hypervisor.DefaultNetworkIdentifier
# Getting recovery info
$VPGDefaultDatastoreIdentifier = $VPGSettings.Recovery.DefaultDatastoreIdentifier
$VPGDefaultFolderIdentifier = $VPGSettings.Recovery.DefaultFolderIdentifier
$VPGDefaultHostClusterIdentifier = $VPGSettings.Recovery.DefaultHostClusterIdentifier
$VPGDefaultHostIdentifier = $VPGSettings.Recovery.DefaultHostIdentifier
$VPGResourcePoolIdentifier = $VPGSettings.Recovery.ResourcePoolIdentifier
# Getting scripting info
$VPGScriptingPreRecovery = $VPGSettings.Scripting.PreRecovery
$VPGScriptingPostRecovery = $VPGSettings.Scripting.PostRecovery
# Getting VM IDs in VPG
$VPGVMIdentifiers = $VPGSettings.VMs.VmIdentifier
################################################
# Translating Zerto IDs from VPG settings to friendly vSphere names
################################################
# Getting site names
$VPGProtectedSiteName = $VISitesCMD | Where-Object {$_.SiteIdentifier -eq $VPGProtectedSiteIdentifier} | select -ExpandProperty VirtualizationSiteName
$VPGRecoverySiteName = $VISitesCMD | Where-Object {$_.SiteIdentifier -eq $VPGRecoverySiteIdentifier} | select -ExpandProperty VirtualizationSiteName
# Getting network names
$VPGFailoverNetworkName = $VINetworksCMD | Where-Object {$_.NetworkIdentifier -eq $VPGFailoverNetworkID} | Select -ExpandProperty VirtualizationNetworkName
$VPGFailoverTestNetworkName = $VINetworksCMD | Where-Object {$_.NetworkIdentifier -eq $VPGFailoverTestNetworkID} | Select -ExpandProperty VirtualizationNetworkName
# Getting datastore cluster name
$VPGJournalDatastoreClusterName = $VIDatastoreClustersCMD | Where-Object {$_.DatastoreClusterIdentifier -eq $VPGJournalDatastoreClusterIdentifier} | select -ExpandProperty DatastoreClusterName
# Getting datastore names
$VPGDefaultDatastoreName = $VIDatastoresCMD | Where-Object {$_.DatastoreIdentifier -eq $VPGDefaultDatastoreIdentifier} | select -ExpandProperty DatastoreName
$VPGJournalDatastoreName = $VIDatastoresCMD | Where-Object {$_.DatastoreIdentifier -eq $VPGJournalDatastoreIdentifier} | select -ExpandProperty DatastoreName
# Getting folder name
$VPGDefaultFolderName = $VIFoldersCMD | Where-Object {$_.FolderIdentifier -eq $VPGDefaultFolderIdentifier} | select -ExpandProperty FolderName
# Getting cluster name
$VPGDefaultHostClusterName = $VIClustersCMD | Where-Object {$_.ClusterIdentifier -eq $VPGDefaultHostClusterIdentifier} | select -ExpandProperty VirtualizationClusterName
# Getting host name
$VPGDefaultHostName = $VIHostsCMD | Where-Object {$_.HostIdentifier -eq $VPGDefaultHostIdentifier} | select -ExpandProperty VirtualizationHostName
# Getting resource pool name
$VPGResourcePoolName = $VIResourcePoolsCMD | Where-Object {$_.ResourcePoolIdentifier -eq $VPGResourcePoolIdentifier} | select -ExpandProperty ResourcepoolName
################################################
# Adding all VPG setting info to $VPGArray
################################################
$VPGArrayLine = new-object PSObject
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value $SourcePOD
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGidentifier" -Value $VPGidentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGOrganization" -Value $VPGOrganization
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGVMCount" -Value $VPGVMCount
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGPriortiy" -Value $VPGPriortiy
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGProtectedSiteName" -Value $VPGProtectedSiteName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGProtectedSiteIdentifier" -Value $VPGProtectedSiteIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGRecoverySiteName" -Value $VPGRecoverySiteName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGRecoverySiteIdentifier" -Value $VPGRecoverySiteIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGRpoInSeconds" -Value $VPGRpoInSeconds
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGServiceProfileIdentifier" -Value $VPGServiceProfileIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGTestIntervalInMinutes" -Value $VPGTestIntervalInMinutes
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGUseWanCompression" -Value $VPGUseWanCompression
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGZorgIdentifier" -Value $VPGZorgIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGBootGroupCount" -Value $VPGBootGroupCount
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGBootGroupNames" -Value $VPGBootGroupNames
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGBootGroupDelays" -Value $VPGBootGroupDelays
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGBootGroupIdentifiers" -Value $VPGBootGroupIdentifiers
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalHistoryInHours" -Value $VPGJournalHistoryInHours
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalDatastoreClusterName" -Value $VPGJournalDatastoreClusterName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalDatastoreClusterIdentifier" -Value $VPGJournalDatastoreClusterIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalDatastoreName" -Value $VPGJournalDatastoreName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalDatastoreIdentifier" -Value $VPGJournalDatastoreIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalHardLimitInMB" -Value $VPGJournalHardLimitInMB
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalHardLimitInPercent" -Value $VPGJournalHardLimitInPercent
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalWarningThresholdInMB" -Value $VPGJournalWarningThresholdInMB
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGJournalWarningThresholdInPercent" -Value $VPGJournalWarningThresholdInPercent
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGFailoverNetworkName" -Value $VPGFailoverNetworkName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGFailoverNetworkID" -Value $VPGFailoverNetworkID
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGFailoverTestNetworkName" -Value $VPGFailoverTestNetworkName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGFailoverTestNetworkID" -Value $VPGFailoverTestNetworkID
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultDatastoreName" -Value $VPGDefaultDatastoreName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultDatastoreIdentifier" -Value $VPGDefaultDatastoreIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultFolderName" -Value $VPGDefaultFolderName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultFolderIdentifier" -Value $VPGDefaultFolderIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultHostClusterName" -Value $VPGDefaultHostClusterName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultHostClusterIdentifier" -Value $VPGDefaultHostClusterIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultHostName" -Value $VPGDefaultHostName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGDefaultHostIdentifier" -Value $VPGDefaultHostIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGResourcePoolName" -Value $VPGResourcePoolName
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGResourcePoolIdentifier" -Value $VPGResourcePoolIdentifier
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGScriptingPreRecovery" -Value $VPGScriptingPreRecovery
$VPGArrayLine | Add-Member -MemberType NoteProperty -Name "VPGScriptingPostRecovery" -Value $VPGScriptingPostRecovery
$VPGArray += $VPGArrayLine
################################################
# Starting for each VM ID action for collecting ZVM VM data
################################################
foreach ($_ in $VPGVMIdentifiers)
{
$VMIdentifier = $_
# Get VMs settings
$GetVMSettingsURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier+"/vms/"+$VMIdentifier
$GetVMSettings = Invoke-RestMethod -Method Get -Uri $GetVMSettingsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_JSON -ContentType $TypeJSON
# Getting the VM name and disk usage
$VMNameArray = $vmListarray | where-object {$_.VmIdentifier -eq $VMIdentifier} | Select-Object *
$VMName = $VMNameArray.VmName
$VMProvisionedStorageInMB = $VMNameArray.ProvisionedStorageInMB
$VMUsedStorageInMB = $VMNameArray.UsedStorageInMB
# Setting variables from the API
$VMVolumeCount = $GetVMSettings.Volumes.Count
$VMNICCount = $GetVMSettings.Nics.Count
$VMBootGroupIdentifier = $GetVMSettings.BootGroupIdentifier
$VMJournalDatastoreClusterIdentifier = $GetVMSettings.Journal.DatastoreClusterIdentifier
$VMJournalDatastoreIdentifier = $GetVMSettings.Journal.DatastoreIdentifier
$VMJournalHardLimitInMB = $GetVMSettings.Journal.Limitation.HardLimitInMB
$VMJournalHardLimitInPercent = $GetVMSettings.Journal.Limitation.HardLimitInPercent
$VMJournalWarningThresholdInMB = $GetVMSettings.Journal.Limitation.WarningThresholdInMB
$VMJournalWarningThresholdInPercent = $GetVMSettings.Journal.Limitation.WarningThresholdInPercent
$VMDatastoreClusterIdentifier = $GetVMSettings.Recovery.DatastoreClusterIdentifier
$VMDatastoreIdentifier = $GetVMSettings.Recovery.DatastoreIdentifier
$VMFolderIdentifier = $GetVMSettings.Recovery.FolderIdentifier
$VMHostClusterIdentifier = $GetVMSettings.Recovery.HostClusterIdentifier
$VMHostIdentifier = $GetVMSettings.Recovery.HostIdentifier
$VMResourcePoolIdentifier = $GetVMSettings.Recovery.ResourcePoolIdentifier
################################################
# Translating Zerto IDs from VM settings to friendly vSphere names
################################################
# Getting boot group
$VMBootGroupName = $VPGBootGroups | Where-Object {$_.BootGroupIdentifier -eq $VMBootGroupIdentifier} | select -ExpandProperty Name
$VMBootGroupDelay = $VPGBootGroups | Where-Object {$_.BootGroupIdentifier -eq $VMBootGroupIdentifier} | select -ExpandProperty BootDelayInSeconds
# Getting datastore cluster name
$VMJournalDatastoreClusterName = $VIDatastoreClustersCMD | Where-Object {$_.DatastoreClusterIdentifier -eq $VMJournalDatastoreClusterIdentifier} | select -ExpandProperty DatastoreClusterName
$VMDatastoreClusterName = $VIDatastoreClustersCMD | Where-Object {$_.DatastoreClusterIdentifier -eq $VMDatastoreClusterIdentifier} | select -ExpandProperty DatastoreClusterName
# Getting datastore name
$VMJournalDatastoreName = $VIDatastoresCMD | Where-Object {$_.DatastoreIdentifier -eq $VMJournalDatastoreIdentifier} | select -ExpandProperty DatastoreName
$VMDatastoreName = $VIDatastoresCMD | Where-Object {$_.DatastoreIdentifier -eq $VMDatastoreIdentifier} | select -ExpandProperty DatastoreName
# Getting folder name
$VMFolderName = $VIFoldersCMD | Where-Object {$_.FolderIdentifier -eq $VMFolderIdentifier} | select -ExpandProperty FolderName
# Getting cluster name
$VMHostClusterName = $VIClustersCMD | Where-Object {$_.ClusterIdentifier -eq $VMHostClusterIdentifier} | select -ExpandProperty VirtualizationClusterName
# Getting host name
$VMHostName = $VIHostsCMD | Where-Object {$_.HostIdentifier -eq $VMHostIdentifier} | select -ExpandProperty VirtualizationHostName
# Getting resource pool name
$VMResourcePoolName = $VIResourcePoolsCMD | Where-Object {$_.ResourcePoolIdentifier -eq $VMResourcePoolIdentifier} | select -ExpandProperty ResourcepoolName
################################################
# Adding all VM setting info to $VMArray
################################################
$VMArrayLine = new-object PSObject
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value $SourcePOD
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VPGidentifier" -Value $VPGidentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMIdentifier" -Value $VMIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICCount" -Value $VMNICCount
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeCount" -Value $VMVolumeCount
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMProvisionedStorageInMB" -Value $VMProvisionedStorageInMB
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMUsedStorageInMB" -Value $VMUsedStorageInMB
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMBootGroupName" -Value $VMBootGroupName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMBootGroupDelay" -Value $VMBootGroupDelay
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMBootGroupIdentifier" -Value $VMBootGroupIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalDatastoreClusterName" -Value $VMJournalDatastoreClusterName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalDatastoreClusterIdentifier" -Value $VMJournalDatastoreClusterIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalDatastoreName" -Value $VMJournalDatastoreName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalDatastoreIdentifier" -Value $VMJournalDatastoreIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalHardLimitInMB" -Value $VMJournalHardLimitInMB
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMJournalHardLimitInPercent" -Value $VMJournalHardLimitInPercent
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMDatastoreClusterName" -Value $VMDatastoreClusterName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMDatastoreClusterIdentifier" -Value $VMDatastoreClusterIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMDatastoreName" -Value $VMDatastoreName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMDatastoreIdentifier" -Value $VMDatastoreIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMFolderName" -Value $VMFolderName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMFolderIdentifier" -Value $VMFolderIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMHostClusterName" -Value $VMHostClusterName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMHostClusterIdentifier" -Value $VMHostClusterIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMHostName" -Value $VMHostName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMHostIdentifier" -Value $VMHostIdentifier
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMResourcePoolName" -Value $VMResourcePoolName
$VMArrayLine | Add-Member -MemberType NoteProperty -Name "VMResourcePoolIdentifier" -Value $VMResourcePoolIdentifier
$VMArray += $VMArrayLine
################################################
# Get VM Volume settings for the current VPG
################################################
$GetVMSettingVolumesURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier+"/vms/"+$VMIdentifier+"/volumes"
$GetVMSettingVolumes = Invoke-RestMethod -Method Get -Uri $GetVMSettingVolumesURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
$GetVMSettingVolumeIDs = $GetVMSettingVolumes.ArrayOfVpgSettingsVmVolumeApi.VpgSettingsVmVolumeApi | select-object VolumeIdentifier -ExpandProperty VolumeIdentifier
################################################
# Starting for each VM Volume ID action for collecting ZVM VM Volume data
################################################
foreach ($_ in $GetVMSettingVolumeIDs)
{
$VMVolumeID = $_
# Getting API data for volume
$GetVMSettingVolumeURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier+"/vms/"+$VMIdentifier+"/volumes/"+$VMVolumeID
$GetVMSettingVolume = Invoke-RestMethod -Method Get -Uri $GetVMSettingVolumeURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
# Setting values
$VMVolumeDatastoreClusterIdentifier = $GetVMSettingVolume.VpgSettingsVmVolumeApi.Datastore.DatastoreClusterIdentifier
$VMVolumeDatastoreIdentifier = $GetVMSettingVolume.VpgSettingsVmVolumeApi.Datastore.DatastoreIdentifier
$VMVolumeIsSWAP = $GetVMSettingVolume.VpgSettingsVmVolumeApi.IsSwap
$VMVolumeIsThin = $GetVMSettingVolume.VpgSettingsVmVolumeApi.Datastore.IsThin
# Getting datastore cluster name
$VMVolumeDatastoreClusterName = $VIDatastoreClustersCMD | Where-Object {$_.DatastoreClusterIdentifier -eq $VMVolumeDatastoreClusterIdentifier} | select -ExpandProperty DatastoreClusterName
# Getting datastore name
$VMVolumeDatastoreName = $VIDatastoresCMD | Where-Object {$_.DatastoreIdentifier -eq $VMVolumeDatastoreIdentifier} | select -ExpandProperty DatastoreName
################################################
# Adding all VM Volume setting info to $VMVolumeArray
################################################
$VMVolumeArrayLine = new-object PSObject
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value $SourcePOD
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VPGidentifier" -Value $VPGidentifier
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMName
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMIdentifier" -Value $VMIdentifier
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeID" -Value $VMVolumeID
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeIsSWAP" -Value $VMVolumeIsSWAP
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeIsThin" -Value $VMVolumeIsThin
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeDatastoreClusterName" -Value $VMVolumeDatastoreClusterName
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeDatastoreClusterIdentifier" -Value $VMVolumeDatastoreClusterIdentifier
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeDatastoreName" -Value $VMVolumeDatastoreName
$VMVolumeArrayLine | Add-Member -MemberType NoteProperty -Name "VMVolumeDatastoreIdentifier" -Value $VMVolumeDatastoreIdentifier
$VMVolumeArray += $VMVolumeArrayLine
}
################################################
# Get VM Nic settings for the current VPG
################################################
$GetVMSettingNICsURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier+"/vms/"+$VMIdentifier+"/nics"
$GetVMSettingNICs = Invoke-RestMethod -Method Get -Uri $GetVMSettingNICsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
$VMNICIDs = $GetVMSettingNICs.ArrayOfVpgSettingsVmNicApi.VpgSettingsVmNicApi | select-object NicIdentifier -ExpandProperty NicIdentifier
################################################
# Starting for each VM NIC ID action for collecting ZVM VM NIC data
################################################
foreach ($_ in $VMNICIDs)
{
$VMNICIdentifier = $_
$GetVMSettingNICURL = $SourceZVMBaseURL+"vpgSettings/"+$VPGSettingsIdentifier+"/vms/"+$VMIdentifier+"/nics/"+$VMNICIdentifier
$GetVMSettingNIC = Invoke-RestMethod -Method Get -Uri $GetVMSettingNICURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
# Building arrays
$VMSettingNICIDArray1 = $GetVMSettingNIC.VpgSettingsVmNicApi.Failover.Hypervisor
$VMSettingNICIDArray2 = $GetVMSettingNIC.VpgSettingsVmNicApi.Failover.Hypervisor.IpConfig
$VMSettingNICIDArray3 = $GetVMSettingNIC.VpgSettingsVmNicApi.FailoverTest.Hypervisor
$VMSettingNICIDArray4 = $GetVMSettingNIC.VpgSettingsVmNicApi.FailoverTest.Hypervisor.IpConfig
# Setting failover values
$VMNICFailoverDNSSuffix = $VMSettingNICIDArray1.DnsSuffix
$VMNICFailoverNetworkIdentifier = $VMSettingNICIDArray1.NetworkIdentifier
$VMNICFailoverShouldReplaceMacAddress = $VMSettingNICIDArray1.ShouldReplaceMacAddress
$VMNICFailoverGateway = $VMSettingNICIDArray2.Gateway
$VMNIsFailoverDHCP = $VMSettingNICIDArray2.IsDhcp
$VMNICFailoverPrimaryDns = $VMSettingNICIDArray2.PrimaryDns
$VMNICFailoverSecondaryDns = $VMSettingNICIDArray2.SecondaryDns
$VMNICFailoverStaticIp = $VMSettingNICIDArray2.StaticIp
$VMNICFailoverSubnetMask = $VMSettingNICIDArray2.SubnetMask
# Nulling blank content
if ($VMNICFailoverDNSSuffix.nil -eq $true){$VMNICFailoverDNSSuffix = $null}
if ($VMNICFailoverGateway.nil -eq $true){$VMNICFailoverGateway = $null}
if ($VMNICFailoverPrimaryDns.nil -eq $true){$VMNICFailoverPrimaryDns = $null}
if ($VMNICFailoverSecondaryDns.nil -eq $true){$VMNICFailoverSecondaryDns = $null}
if ($VMNICFailoverStaticIp.nil -eq $true){$VMNICFailoverStaticIp = $null}
if ($VMNICFailoverSubnetMask.nil -eq $true){$VMNICFailoverSubnetMask = $null}
# Setting failover test values
$VMNICFailoverTestDNSSuffix = $VMSettingNICIDArray3.DnsSuffix
$VMNICFailoverTestNetworkIdentifier = $VMSettingNICIDArray3.NetworkIdentifier
$VMNICFailoverTestShouldReplaceMacAddress = $VMSettingNICIDArray3.ShouldReplaceMacAddress
$VMNICFailoverTestGateway = $VMSettingNICIDArray4.Gateway
$VMNIsFailoverTestDHCP = $VMSettingNICIDArray4.IsDhcp
$VMNICFailoverTestPrimaryDns = $VMSettingNICIDArray4.PrimaryDns
$VMNICFailoverTestSecondaryDns = $VMSettingNICIDArray4.SecondaryDns
$VMNICFailoverTestStaticIp = $VMSettingNICIDArray4.StaticIp
$VMNICFailoverTestSubnetMask = $VMSettingNICIDArray4.SubnetMask
# Nulling blank content
if ($VMNICFailoverTestDNSSuffix.nil -eq $true){$VMNICFailoverTestDNSSuffix = $null}
if ($VMNICFailoverTestGateway.nil -eq $true){$VMNICFailoverTestGateway = $null}
if ($VMNICFailoverTestPrimaryDns.nil -eq $true){$VMNICFailoverTestPrimaryDns = $null}
if ($VMNICFailoverTestSecondaryDns.nil -eq $true){$VMNICFailoverTestSecondaryDns = $null}
if ($VMNICFailoverTestStaticIp.nil -eq $true){$VMNICFailoverTestStaticIp = $null}
if ($VMNICFailoverTestSubnetMask.nil -eq $true){$VMNICFailoverTestSubnetMask = $null}
# Mapping Network IDs to Names
$VMNICFailoverNetworkName = $VINetworksCMD | Where-Object {$_.NetworkIdentifier -eq $VMNICFailoverNetworkIdentifier} | Select VirtualizationNetworkName -ExpandProperty VirtualizationNetworkName
$VMNICFailoverTestNetworkName = $VINetworksCMD | Where-Object {$_.NetworkIdentifier -eq $VMNICFailoverTestNetworkIdentifier} | Select VirtualizationNetworkName -ExpandProperty VirtualizationNetworkName
################################################
# Adding all VM NIC setting info to $VMNICArray
################################################
$VMNICArrayLine = new-object PSObject
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "SourcePOD" -Value $SourcePOD
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VPGidentifier" -Value $VPGidentifier
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMName
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMIdentifier" -Value $VMIdentifier
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICIdentifier" -Value $VMNICIdentifier
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverNetworkName" -Value $VMNICFailoverNetworkName
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverNetworkIdentifier" -Value $VMNICFailoverNetworkIdentifier
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverDNSSuffix" -Value $VMNICFailoverDNSSuffix
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverShouldReplaceMacAddress" -Value $VMNICFailoverShouldReplaceMacAddress
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverGateway" -Value $VMNICFailoverGateway
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverDHCP" -Value $VMNIsFailoverDHCP
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverPrimaryDns" -Value $VMNICFailoverPrimaryDns
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverSecondaryDns" -Value $VMNICFailoverSecondaryDns
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverStaticIp" -Value $VMNICFailoverStaticIp
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverSubnetMask" -Value $VMNICFailoverSubnetMask
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestNetworkName" -Value $VMNICFailoverTestNetworkName
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestNetworkIdentifier" -Value $VMNICFailoverTestNetworkIdentifier
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestDNSSuffix" -Value $VMNICFailoverTestDNSSuffix
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestShouldReplaceMacAddress" -Value $VMNICFailoverTestShouldReplaceMacAddress
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestGateway" -Value $VMNICFailoverTestGateway
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestDHCP" -Value $VMNIsFailoverTestDHCP
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestPrimaryDns" -Value $VMNICFailoverTestPrimaryDns
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestSecondaryDns" -Value $VMNICFailoverTestSecondaryDns
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestStaticIp" -Value $VMNICFailoverTestStaticIp
$VMNICArrayLine | Add-Member -MemberType NoteProperty -Name "VMNICFailoverTestSubnetMask" -Value $VMNICFailoverTestSubnetMask
$VMNICArray += $VMNICArrayLine
# End of per VM NIC actions below
}
# End of per VM NIC actions above
#
# End of per VM actions below
}
# End of per VM actions above
################################################
# Deleting VPG edit settings ID (same as closing the edit screen on a VPG in the ZVM without making any changes)
################################################
Try
{
Invoke-RestMethod -Method Delete -Uri $VPGSettingsURL -TimeoutSec 100 -Headers $SourceZVMSessionHeader_XML -ContentType $TypeXML
}
Catch [system.exception]
{
}
#
# End of check for valid VPG settings ID below
}
# End of check for valid VPG settings ID above
#
# End of per VPG actions below
}
# End of per VPG actions above
#
################################################
# Building Report No.x - Zerto designed report, summary of PODs
################################################
# Building Source POD Summary data
$PODProtectedArray = $ProtectedVPGArray | Where-Object {$_.SourcePOD -eq $SourcePOD}
$PODTotalVPGs = $PODProtectedArray | Measure-Object | select -ExpandProperty Count
$PODTotalVPGsMeetingSLA = $PODProtectedArray | Where-Object {$_.Status -eq "MeetingSLA"} | Measure-Object | select -ExpandProperty Count
$PODTotalVPGsNotMeetingSLA = $PODProtectedArray | Where-Object {$_.Status -ne "MeetingSLA"} | Measure-Object | select -ExpandProperty Count
$PODTotalHighPriorityVPGs = $PODProtectedArray | Where-Object {$_.Priority -eq "High"} | Measure-Object | select -ExpandProperty Count
$PODTotalMediumPriorityVPGs = $PODProtectedArray | Where-Object {$_.Priority -eq "Medium"} | Measure-Object | select -ExpandProperty Count
$PODTotalLowPriorityVPGs = $PODProtectedArray | Where-Object {$_.Priority -eq "Low"} | Measure-Object | select -ExpandProperty Count
$PODAverageRPO = $PODProtectedArray | select RPO | Measure-Object | select -ExpandProperty Count
$PODTotalProtectedSizeGB = ($PODProtectedArray.SizeInGb | Measure-Object -Sum).Sum
$PODTotalProtectedSizeTB = $PODTotalProtectedSizeGB / 1024
$PODTotalProtectedSizeTB = [math]::Round($PODTotalProtectedSizeTB,2)
$PODTotalJournalSizeGB = ($PODProtectedArray.JournalSizeInGb | Measure-Object -Sum).Sum
$PODTotalJournalSizeTB = $PODTotalJournalSizeGB / 1024
$PODTotalJournalSizeTB = [math]::Round($PODTotalJournalSizeTB,2)
# Getting Protected VM totals
$PODProtectedVMArray = $ProtectedVMArray | Where-Object {$_.SourcePOD -eq $SourcePOD}
$PODProtectedVMs = $PODProtectedVMArray | Measure-Object | select -ExpandProperty Count
# Getting UnProtected VM totals
$PODUnProtectedVMArray = $UnprotectedVMArray | Where-Object {$_.SourcePOD -eq $SourcePOD}
$PODUnProtectedVMs = $PODUnProtectedVMArray | Measure-Object | select -ExpandProperty Count
# POD total VMs
$PODTotalVMs = $PODProtectedVMs + $PODUnProtectedVMs
# Adding array line
$PODSummaryArrayLine = new-object PSObject
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "PODName" -Value "$SourcePOD"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "VMs" -Value "$PODTotalVMs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "VMsUnProtected" -Value "$PODUnProtectedVMs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "VMsProtected" -Value "$PODProtectedVMs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "VPGs" -Value "$PODTotalVPGs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "MeetingSLA" -Value "$PODTotalVPGsMeetingSLA"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "NotMeetingSLA" -Value "$PODTotalVPGsNotMeetingSLA"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "AverageRPO" -Value "$PODAverageRPO"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "HighPriority" -Value "$PODTotalHighPriorityVPGs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "MediumPriority" -Value "$PODTotalMediumPriorityVPGs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "LowPriority" -Value "$PODTotalLowPriorityVPGs"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "ProtectedSizeTB" -Value "$PODTotalProtectedSizeTB"
$PODSummaryArrayLine | Add-Member -MemberType NoteProperty -Name "JournalSizeTB" -Value "$PODTotalJournalSizeTB"
$PODSummaryArray += $PODSummaryArrayLine
# Disconnecting from target vCenter, no longer needed
Disconnect-VIServer * -confirm:$false
# End of failed vCenter auth below
}
# End of failed vCenter auth above
else
{
# Failed vCenter auth, not running reports for POD
write-host "Failed to login to vCenter:$SourcevCenter
Skipping reports for POD:$SourcePOD"
}
# End of for each POD below
}
# End of for each POD above
#
################################################
# Function for building HTML table for ProtectedVPGArray
################################################
Function Create-ProtectedVPGArrayTable {
Param($Array,$TableCaption)
$ProtectedVPGArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">SourcePOD</th>
<th class="tg-foxd">TargetPOD</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMCount</th>
<th class="tg-foxd">Priority</th>
<th class="tg-foxd">RPO</th>
<th class="tg-foxd">RPOAlerts</th>
<th class="tg-foxd">Status</th>
<th class="tg-foxd">SizeInGB</th>
<th class="tg-foxd">JournalSizeInGB</th>
<th class="tg-foxd">AlertDescription</th>
</tr>
"@
# Building HTML table
$ProtectedVPGArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$SourcePOD = $_.SourcePOD
$TargetPOD = $_.TargetPOD
$VPGName = $_.VPGName
$VMCount = $_.VMCount
$Priority = $_.Priority
$RPO = $_.RPO
$RPOAlerts = $_.RPOAlerts
$Status = $_.Status
$SizeInGb = $_.SizeInGb
$JournalSizeInGb = $_.JournalSizeInGb
$AlertDescription = $_.AlertDescription
# Building HTML table row
$ProtectedVPGArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$SourcePOD</td>
<td class=""tg-yw4l"">$TargetPOD</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VMCount</td>
<td class=""tg-yw4l"">$Priority</td>
<td class=""tg-yw4l"">$RPO</td>
<td class=""tg-yw4l"">$RPOAlerts</td>
<td class=""tg-yw4l"">$Status</td>
<td class=""tg-yw4l"">$SizeInGb</td>
<td class=""tg-yw4l"">$JournalSizeInGb</td>
<td class=""tg-yw4l"">$AlertDescription</td>
</tr>
"
# Adding rows to table
$ProtectedVPGArrayHTMLTable += $ProtectedVPGArrayHTMLTableRow
}
# Compiling End of HTML email
$ProtectedVPGArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$ProtectedVPGArrayHTMLTable = $ProtectedVPGArrayHTMLTableStart + $ProtectedVPGArrayHTMLTable + $ProtectedVPGArrayHTMLTableEnd
$ProtectedVPGArrayHTMLTable
}
################################################
# Function for building HTML table for ProtectedVMArray
################################################
Function Create-ProtectedVMArrayTable {
Param($Array,$TableCaption)
$ProtectedVMArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">SourcePOD</th>
<th class="tg-foxd">SourceCluster</th>
<th class="tg-foxd">TargetPOD</th>
<th class="tg-foxd">TargetCluster</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMName</th>
<th class="tg-foxd">Priority</th>
<th class="tg-foxd">Status</th>
<th class="tg-foxd">RPO</th>
<th class="tg-foxd">Disks</th>
<th class="tg-foxd">SizeInGB</th>
<th class="tg-foxd">JournalSizeInGB</th>
</tr>
"@
# Building HTML table
$ProtectedVMArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$SourcePOD = $_.SourcePOD
$SourceCluster = $_.SourceCluster
$TargetPOD = $_.TargetPOD
$TargetCluster = $_.TargetCluster
$VPGName = $_.VPGName
$VMName = $_.VMName
$Priority = $_.Priority
$Status = $_.Status
$RPO = $_.RPO
$Disks = $_.Disks
$SizeInGb = $_.SizeInGb
$JournalSizeInGb = $_.JournalSizeInGb
# Building HTML table row
$ProtectedVMArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$SourcePOD</td>
<td class=""tg-yw4l"">$SourceCluster</td>
<td class=""tg-yw4l"">$TargetPOD</td>
<td class=""tg-yw4l"">$TargetCluster</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VMName</td>
<td class=""tg-yw4l"">$Priority</td>
<td class=""tg-yw4l"">$Status</td>
<td class=""tg-yw4l"">$RPO</td>
<td class=""tg-yw4l"">$Disks</td>
<td class=""tg-yw4l"">$SizeInGb</td>
<td class=""tg-yw4l"">$JournalSizeInGb</td>
</tr>
"
# Adding rows to table
$ProtectedVMArrayHTMLTable += $ProtectedVMArrayHTMLTableRow
}
# Compiling End of HTML email
$ProtectedVMArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$ProtectedVMArrayHTMLTable = $ProtectedVMArrayHTMLTableStart + $ProtectedVMArrayHTMLTable + $ProtectedVMArrayHTMLTableEnd
$ProtectedVMArrayHTMLTable
# End of ProtectedVMArrayTable function
}
################################################
# Function for building HTML table for TargetVRAArray
################################################
Function Create-TargetVRAArrayTable {
Param($Array,$TableCaption)
$TargetVRAArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">TargetPOD</th>
<th class="tg-foxd">VRACluster</th>
<th class="tg-foxd">RecoveryVRAName</th>
<th class="tg-foxd">ESXiHostname</th>
<th class="tg-foxd">VRAVPGs</th>
<th class="tg-foxd">VRAVMs</th>
<th class="tg-foxd">VRAVolumes</th>
<th class="tg-foxd">VRAVolumesTB</th>
<th class="tg-foxd">VRAJournalsTB</th>
<th class="tg-foxd">VMNumbervCPU</th>
<th class="tg-foxd">VMCpuUsedGhz</th>
<th class="tg-foxd">VMMemoryGB</th>
<th class="tg-foxd">VMActiveMemoryGB</th>
</tr>
"@
# Building HTML table
$TargetVRAArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$TargetPOD = $_.TargetPOD
$TargetCluster = $_.VRACluster
$VRAName = $_.VRAName
$ESXiHostname = $_.ESXiHostname
$VRAVPGs = $_.VRAVPGs
$VRAVMs = $_.VRAVMs
$VRAVolumes = $_.VRAVolumes
$VRARecoveryVolumesInTB = $_.VRARecoveryVolumesInTB
$VRARecoveryJournalsInTB = $_.VRARecoveryJournalsInTB
$VMNumberOfvCPU = $_.VMNumberOfvCPU
$VMCpuUsedInGhz = $_.VMCpuUsedInGhz
$VMMemoryInGB = $_.VMMemoryInGB
$VMActiveMemoryInGB = $_.VMActiveMemoryInGB
# Building HTML table row
$TargetVRAArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$TargetPOD</td>
<td class=""tg-yw4l"">$TargetCluster</td>
<td class=""tg-yw4l"">$VRAName</td>
<td class=""tg-yw4l"">$ESXiHostname</td>
<td class=""tg-yw4l"">$VRAVPGs</td>
<td class=""tg-yw4l"">$VRAVMs</td>
<td class=""tg-yw4l"">$VRAVolumes</td>
<td class=""tg-yw4l"">$VRARecoveryVolumesInTB</td>
<td class=""tg-yw4l"">$VRARecoveryJournalsInTB</td>
<td class=""tg-yw4l"">$VMNumberOfvCPU</td>
<td class=""tg-yw4l"">$VMCpuUsedInGhz</td>
<td class=""tg-yw4l"">$VMMemoryInGB</td>
<td class=""tg-yw4l"">$VMActiveMemoryInGB</td>
</tr>
"
# Adding rows to table
$TargetVRAArrayHTMLTable += $TargetVRAArrayHTMLTableRow
}
# Compiling End of HTML email
$TargetVRAArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$TargetVRAArrayHTMLTable = $TargetVRAArrayHTMLTableStart + $TargetVRAArrayHTMLTable + $TargetVRAArrayHTMLTableEnd
$TargetVRAArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for UnprotectedVMArrayTable
################################################
Function Create-UnprotectedVMArrayTable {
Param($Array,$TableCaption)
$UnprotectedVMArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">SourcePOD</th>
<th class="tg-foxd">VMFolder</th>
<th class="tg-foxd">VMName</th>
<th class="tg-foxd">VMCluster</th>
<th class="tg-foxd">NumCPU</th>
<th class="tg-foxd">MemoryGB</th>
<th class="tg-foxd">NICS</th>
<th class="tg-foxd">HardDisks</th>
<th class="tg-foxd">UsedSpaceGB</th>
</tr>
"@
# Building HTML table
$UnprotectedVMArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$SourcePOD = $_.SourcePOD
$VMFolder = $_.VMFolder
$VMName = $_.VMName
$VMCluster = $_.VMCluster
$NumCPU = $_.NumCPU
$MemoryGB = $_.MemoryGB
$NICS = $_.NICS
$HardDisks = $_.HardDisks
$UsedSpaceGB = $_.UsedSpaceGB
# Building HTML table row
$UnprotectedVMArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$SourcePOD</td>
<td class=""tg-yw4l"">$VMFolder</td>
<td class=""tg-yw4l"">$VMName</td>
<td class=""tg-yw4l"">$VMCluster</td>
<td class=""tg-yw4l"">$NumCPU</td>
<td class=""tg-yw4l"">$MemoryGB</td>
<td class=""tg-yw4l"">$NICS</td>
<td class=""tg-yw4l"">$HardDisks</td>
<td class=""tg-yw4l"">$UsedSpaceGB</td>
</tr>
"
# Adding rows to table
$UnprotectedVMArrayHTMLTable += $UnprotectedVMArrayHTMLTableRow
}
# Compiling End of HTML email
$UnprotectedVMArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$UnprotectedVMArrayHTMLTable = $UnprotectedVMArrayHTMLTableStart + $UnprotectedVMArrayHTMLTable + $UnprotectedVMArrayHTMLTableEnd
$UnprotectedVMArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for TargetDatastoreArray
################################################
Function Create-TargetDatastoreArrayTable {
Param($Array,$TableCaption)
$TargetDatastoreArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">DatastoreCluster</th>
<th class="tg-foxd">DatastoreName</th>
<th class="tg-foxd">UsedByZVR</th>
<th class="tg-foxd">CapacityGB</th>
<th class="tg-foxd">FreeSpaceGB</th>
<th class="tg-foxd">FreePercent</th>
</tr>
"@
# Building HTML table
$TargetDatastoreArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.PODName
$DatastoreCluster = $_.DatastoreCluster
$DatastoreName = $_.DatastoreName
$UsedByZVR = $_.UsedByZVR
$CapacityGB = $_.CapacityGB
$FreeSpaceGB = $_.FreeSpaceGB
$FreePercent = $_.FreePercent
# Building HTML table row
$TargetDatastoreArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$DatastoreCluster</td>
<td class=""tg-yw4l"">$DatastoreName</td>
<td class=""tg-yw4l"">$UsedByZVR</td>
<td class=""tg-yw4l"">$CapacityGB</td>
<td class=""tg-yw4l"">$FreeSpaceGB</td>
<td class=""tg-yw4l"">$FreePercent</td>
</tr>
"
# Adding rows to table
$TargetDatastoreArrayHTMLTable += $TargetDatastoreArrayHTMLTableRow
}
# Compiling End of HTML email
$TargetDatastoreArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$TargetDatastoreArrayHTMLTable = $TargetDatastoreArrayHTMLTableStart + $TargetDatastoreArrayHTMLTable + $TargetDatastoreArrayHTMLTableEnd
$TargetDatastoreArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for VPGArray
################################################
Function Create-VPGArrayTable {
Param($Array,$TableCaption)
$VPGArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMCount</th>
<th class="tg-foxd">Priortiy</th>
<th class="tg-foxd">ProtectedSiteName</th>
<th class="tg-foxd">RecoverySiteName</th>
<th class="tg-foxd">RpoInSeconds</th>
<th class="tg-foxd">TestIntervalInMinutes</th>
<th class="tg-foxd">UseWanCompression</th>
<th class="tg-foxd">BootGroupCount</th>
<th class="tg-foxd">BootGroupNames</th>
<th class="tg-foxd">BootGroupDelays</th>
<th class="tg-foxd">JournalHistoryInHours</th>
<th class="tg-foxd">JournalDatastoreClusterName</th>
<th class="tg-foxd">JournalDatastoreName</th>
<th class="tg-foxd">JournalHardLimitInMB</th>
<th class="tg-foxd">JournalHardLimitInPercent</th>
<th class="tg-foxd">JournalWarningThresholdInMB</th>
<th class="tg-foxd">JournalWarningThresholdInPercent</th>
<th class="tg-foxd">FailoverNetworkName</th>
<th class="tg-foxd">FailoverTestNetworkName</th>
<th class="tg-foxd">DefaultDatastoreName</th>
<th class="tg-foxd">DefaultFolderName</th>
<th class="tg-foxd">DefaultHostClusterName</th>
<th class="tg-foxd">DefaultHostName</th>
</tr>
"@
# Building HTML table
$VPGArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.SourcePOD
$VPGName = $_.VPGName
$VPGidentifier = $_.VPGidentifier
$VPGOrganization = $_.VPGOrganization
$VPGVMCount = $_.VPGVMCount
$VPGPriortiy = $_.VPGPriortiy
$VPGProtectedSiteName = $_.VPGProtectedSiteName
$VPGProtectedSiteIdentifier = $_.VPGProtectedSiteIdentifier
$VPGRecoverySiteName = $_.VPGRecoverySiteName
$VPGRecoverySiteIdentifier = $_.VPGRecoverySiteIdentifier
$VPGRpoInSeconds = $_.VPGRpoInSeconds
$VPGServiceProfileIdentifier = $_.VPGServiceProfileIdentifier
$VPGTestIntervalInMinutes = $_.VPGTestIntervalInMinutes
$VPGUseWanCompression = $_.VPGUseWanCompression
$VPGZorgIdentifier = $_.VPGZorgIdentifier
$VPGBootGroupCount = $_.VPGBootGroupCount
$VPGBootGroupNames = $_.VPGBootGroupNames
$VPGBootGroupDelays = $_.VPGBootGroupDelays
$VPGBootGroupIdentifiers = $_.VPGBootGroupIdentifiers
$VPGJournalHistoryInHours = $_.VPGJournalHistoryInHours
$VPGJournalDatastoreClusterName = $_.VPGJournalDatastoreClusterName
$VPGJournalDatastoreClusterIdentifier = $_.VPGJournalDatastoreClusterIdentifier
$VPGJournalDatastoreName = $_.VPGJournalDatastoreName
$VPGJournalDatastoreIdentifier = $_.VPGJournalDatastoreIdentifier
$VPGJournalHardLimitInMB = $_.VPGJournalHardLimitInMB
$VPGJournalHardLimitInPercent = $_.VPGJournalHardLimitInPercent
$VPGJournalWarningThresholdInMB = $_.VPGJournalWarningThresholdInMB
$VPGJournalWarningThresholdInPercent = $_.VPGJournalWarningThresholdInPercent
$VPGFailoverNetworkName = $_.VPGFailoverNetworkName
$VPGFailoverNetworkID = $_.VPGFailoverNetworkID
$VPGFailoverTestNetworkName = $_.VPGFailoverTestNetworkName
$VPGFailoverTestNetworkID = $_.VPGFailoverTestNetworkID
$VPGDefaultDatastoreName = $_.VPGDefaultDatastoreName
$VPGDefaultDatastoreIdentifier = $_.VPGDefaultDatastoreIdentifier
$VPGDefaultFolderName = $_.VPGDefaultFolderName
$VPGDefaultFolderIdentifier = $_.VPGDefaultFolderIdentifier
$VPGDefaultHostClusterName = $_.VPGDefaultHostClusterName
$VPGDefaultHostClusterIdentifier = $_.VPGDefaultHostClusterIdentifier
$VPGDefaultHostName = $_.VPGDefaultHostName
$VPGDefaultHostIdentifier = $_.VPGDefaultHostIdentifier
$VPGResourcePoolName = $_.VPGResourcePoolName
$VPGResourcePoolIdentifier = $_.VPGResourcePoolIdentifier
$VPGScriptingPreRecovery = $_.VPGScriptingPreRecovery
$VPGScriptingPostRecovery = $_.VPGScriptingPostRecovery
# Building HTML table row
$VPGArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VPGVMCount</td>
<td class=""tg-yw4l"">$VPGPriortiy</td>
<td class=""tg-yw4l"">$VPGProtectedSiteName</td>
<td class=""tg-yw4l"">$VPGRecoverySiteName</td>
<td class=""tg-yw4l"">$VPGRpoInSeconds</td>
<td class=""tg-yw4l"">$VPGTestIntervalInMinutes</td>
<td class=""tg-yw4l"">$VPGUseWanCompression</td>
<td class=""tg-yw4l"">$VPGBootGroupCount</td>
<td class=""tg-yw4l"">$VPGBootGroupNames</td>
<td class=""tg-yw4l"">$VPGBootGroupDelays</td>
<td class=""tg-yw4l"">$VPGJournalHistoryInHours</td>
<td class=""tg-yw4l"">$VPGJournalDatastoreClusterName</td>
<td class=""tg-yw4l"">$VPGJournalDatastoreName</td>
<td class=""tg-yw4l"">$VPGJournalHardLimitInMB</td>
<td class=""tg-yw4l"">$VPGJournalHardLimitInPercent</td>
<td class=""tg-yw4l"">$VPGJournalWarningThresholdInMB</td>
<td class=""tg-yw4l"">$VPGJournalWarningThresholdInPercent</td>
<td class=""tg-yw4l"">$VPGFailoverNetworkName</td>
<td class=""tg-yw4l"">$VPGFailoverTestNetworkName</td>
<td class=""tg-yw4l"">$VPGDefaultDatastoreName</td>
<td class=""tg-yw4l"">$VPGDefaultFolderName</td>
<td class=""tg-yw4l"">$VPGDefaultHostClusterName</td>
<td class=""tg-yw4l"">$VPGDefaultHostName</td>
</tr>
"
# Adding rows to table
$VPGArrayHTMLTable += $VPGArrayHTMLTableRow
}
# Compiling End of HTML email
$VPGArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$VPGArrayHTMLTable = $VPGArrayHTMLTableStart + $VPGArrayHTMLTable + $VPGArrayHTMLTableEnd
$VPGArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for VMArray
################################################
Function Create-VMArrayTable {
Param($Array,$TableCaption)
$VMArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMName</th>
<th class="tg-foxd">NICCount</th>
<th class="tg-foxd">VolumeCount</th>
<th class="tg-foxd">ProvisionedStorageInMB</th>
<th class="tg-foxd">UsedStorageInMB</th>
<th class="tg-foxd">BootGroupName</th>
<th class="tg-foxd">BootGroupDelay</th>
<th class="tg-foxd">JournalDatastoreClusterName</th>
<th class="tg-foxd">JournalDatastoreName</th>
<th class="tg-foxd">JournalHardLimitInMB</th>
<th class="tg-foxd">JournalHardLimitInPercent</th>
<th class="tg-foxd">DatastoreClusterName</th>
<th class="tg-foxd">DatastoreName</th>
<th class="tg-foxd">FolderName</th>
<th class="tg-foxd">HostClusterName</th>
<th class="tg-foxd">HostName</th>
</tr>
"@
# Building HTML table
$VMArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.SourcePOD
$VPGName = $_.VPGName
$VPGidentifier = $_.VPGidentifier
$VMName = $_.VMName
$VMIdentifier = $_.VMIdentifier
$VMNICCount = $_.VMNICCount
$VMVolumeCount = $_.VMVolumeCount
$VMProvisionedStorageInMB = $_.VMProvisionedStorageInMB
$VMUsedStorageInMB = $_.VMUsedStorageInMB
$VMBootGroupName = $_.VMBootGroupName
$VMBootGroupDelay = $_.VMBootGroupDelay
$VMBootGroupIdentifier = $_.VMBootGroupIdentifier
$VMJournalDatastoreClusterName = $_.VMJournalDatastoreClusterName
$VMJournalDatastoreClusterIdentifier = $_.VMJournalDatastoreClusterIdentifier
$VMJournalDatastoreName = $_.VMJournalDatastoreName
$VMJournalDatastoreIdentifier = $_.VMJournalDatastoreIdentifier
$VMJournalHardLimitInMB = $_.VMJournalHardLimitInMB
$VMJournalHardLimitInPercent = $_.VMJournalHardLimitInPercent
$VMDatastoreClusterName = $_.VMDatastoreClusterName
$VMDatastoreClusterIdentifier = $_.VMDatastoreClusterIdentifier
$VMDatastoreName = $_.VMDatastoreName
$VMDatastoreIdentifier = $_.VMDatastoreIdentifier
$VMFolderName = $_.VMFolderName
$VMFolderIdentifier = $_.VMFolderIdentifier
$VMHostClusterName = $_.VMHostClusterName
$VMHostClusterIdentifier = $_.VMHostClusterIdentifier
$VMHostName = $_.VMHostName
$VMHostIdentifier = $_.VMHostIdentifier
$VMResourcePoolName = $_.VMResourcePoolName
$VMResourcePoolIdentifier = $_.VMResourcePoolIdentifier
# Building HTML table row
$VMArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VMName</td>
<td class=""tg-yw4l"">$VMNICCount</td>
<td class=""tg-yw4l"">$VMVolumeCount</td>
<td class=""tg-yw4l"">$VMProvisionedStorageInMB</td>
<td class=""tg-yw4l"">$VMUsedStorageInMB</td>
<td class=""tg-yw4l"">$VMBootGroupName</td>
<td class=""tg-yw4l"">$VMBootGroupDelay</td>
<td class=""tg-yw4l"">$VMJournalDatastoreClusterName</td>
<td class=""tg-yw4l"">$VMJournalDatastoreName</td>
<td class=""tg-yw4l"">$VMJournalHardLimitInMB</td>
<td class=""tg-yw4l"">$VMJournalHardLimitInPercent</td>
<td class=""tg-yw4l"">$VMDatastoreClusterName</td>
<td class=""tg-yw4l"">$VMDatastoreName</td>
<td class=""tg-yw4l"">$VMFolderName</td>
<td class=""tg-yw4l"">$VMHostClusterName</td>
<td class=""tg-yw4l"">$VMHostName</td>
</tr>
"
# Adding rows to table
$VMArrayHTMLTable += $VMArrayHTMLTableRow
}
# Compiling End of HTML email
$VMArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$VMArrayHTMLTable = $VMArrayHTMLTableStart + $VMArrayHTMLTable + $VMArrayHTMLTableEnd
$VMArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for VMVolumeArray
################################################
Function Create-VMVolumeArrayTable {
Param($Array,$TableCaption)
$VMVolumeArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMName</th>
<th class="tg-foxd">VolumeID</th>
<th class="tg-foxd">VolumeIsSWAP</th>
<th class="tg-foxd">VolumeIsThin</th>
<th class="tg-foxd">VolumeDatastoreClusterName</th>
<th class="tg-foxd">VolumeDatastoreName</th>
</tr>
"@
# Building HTML table
$VMVolumeArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.SourcePOD
$VPGName = $_.VPGName
$VPGidentifier = $_.VPGidentifier
$VMName = $_.VMName
$VMIdentifier = $_.VMIdentifier
$VMVolumeID = $_.VMVolumeID
$VMVolumeIsSWAP = $_.VMVolumeIsSWAP
$VMVolumeIsThin = $_.VMVolumeIsThin
$VMVolumeDatastoreClusterName = $_.VMVolumeDatastoreClusterName
$VMVolumeDatastoreClusterIdentifier = $_.VMVolumeDatastoreClusterIdentifier
$VMVolumeDatastoreName = $_.VMVolumeDatastoreName
$VMVolumeDatastoreIdentifier = $_.VMVolumeDatastoreIdentifier
# Building HTML table row
$VMVolumeArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VMName</td>
<td class=""tg-yw4l"">$VMVolumeID</td>
<td class=""tg-yw4l"">$VMVolumeIsSWAP</td>
<td class=""tg-yw4l"">$VMVolumeIsThin</td>
<td class=""tg-yw4l"">$VMVolumeDatastoreClusterName</td>
<td class=""tg-yw4l"">$VMVolumeDatastoreName</td>
</tr>
"
# Adding rows to table
$VMVolumeArrayHTMLTable += $VMVolumeArrayHTMLTableRow
}
# Compiling End of HTML email
$VMVolumeArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$VMVolumeArrayHTMLTable = $VMVolumeArrayHTMLTableStart + $VMVolumeArrayHTMLTable + $VMVolumeArrayHTMLTableEnd
$VMVolumeArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for VMNICArray
################################################
Function Create-VMNICArrayTable {
Param($Array,$TableCaption)
$VMNICArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">VPGName</th>
<th class="tg-foxd">VMName</th>
<th class="tg-foxd">VMNICIdentifier</th>
<th class="tg-foxd">FailoverNetworkName</th>
<th class="tg-foxd">FailoverDNSSuffix</th>
<th class="tg-foxd">FailoverShouldReplaceMacAddress</th>
<th class="tg-foxd">FailoverGateway</th>
<th class="tg-foxd">FailoverDHCP</th>
<th class="tg-foxd">FailoverPrimaryDns</th>
<th class="tg-foxd">FailoverSecondaryDns</th>
<th class="tg-foxd">FailoverStaticIp</th>
<th class="tg-foxd">FailoverSubnetMask</th>
<th class="tg-foxd">FailoverTestNetworkName</th>
<th class="tg-foxd">FailoverTestDNSSuffix</th>
<th class="tg-foxd">FailoverTestShouldReplaceMacAddress</th>
<th class="tg-foxd">FailoverTestGateway</th>
<th class="tg-foxd">FailoverTestDHCP</th>
<th class="tg-foxd">FailoverTestPrimaryDns</th>
<th class="tg-foxd">FailoverTestSecondaryDns</th>
<th class="tg-foxd">FailoverTestStaticIp</th>
<th class="tg-foxd">FailoverTestSubnetMask</th>
</tr>
"@
# Building HTML table
$VMNICArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.SourcePOD
$VPGName = $_.VPGName
$VPGidentifier = $_.VPGidentifier
$VMName = $_.VMName
$VMNICIdentifier = $_.VMIdentifier
$VMNICIdentifier = $_.VMNICIdentifier
$VMNICFailoverNetworkName = $_.VMNICFailoverNetworkName
$VMNICFailoverNetworkIdentifier = $_.VMNICFailoverNetworkIdentifier
$VMNICFailoverDNSSuffix = $_.VMNICFailoverDNSSuffix
$VMNICFailoverShouldReplaceMacAddress = $_.VMNICFailoverShouldReplaceMacAddress
$VMNICFailoverGateway = $_.VMNICFailoverGateway
$VMNICFailoverDHCP = $_.VMNICFailoverDHCP
$VMNICFailoverPrimaryDns = $_.VMNICFailoverPrimaryDns
$VMNICFailoverSecondaryDns = $_.VMNICFailoverSecondaryDns
$VMNICFailoverStaticIp = $_.VMNICFailoverStaticIp
$VMNICFailoverSubnetMask = $_.VMNICFailoverSubnetMask
$VMNICFailoverTestNetworkName = $_.VMNICFailoverTestNetworkName
$VMNICFailoverTestNetworkIdentifier = $_.VMNICFailoverTestNetworkIdentifier
$VMNICFailoverTestDNSSuffix = $_.VMNICFailoverTestDNSSuffix
$VMNICFailoverTestShouldReplaceMacAddress = $_.VMNICFailoverTestShouldReplaceMacAddress
$VMNICFailoverTestGateway = $_.VMNICFailoverTestGateway
$VMNICFailoverTestDHCP = $_.VMNICFailoverTestDHCP
$VMNICFailoverTestPrimaryDns = $_.VMNICFailoverTestPrimaryDns
$VMNICFailoverTestSecondaryDns = $_.VMNICFailoverTestSecondaryDns
$VMNICFailoverTestStaticIp = $_.VMNICFailoverTestStaticIp
$VMNICFailoverTestSubnetMask = $_.VMNICFailoverTestSubnetMask
# Building HTML table row
$VMNICArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$VPGName</td>
<td class=""tg-yw4l"">$VMName</td>
<td class=""tg-yw4l"">$VMNICIdentifier</td>
<td class=""tg-yw4l"">$VMNICFailoverNetworkName</td>
<td class=""tg-yw4l"">$VMNICFailoverDNSSuffix</td>
<td class=""tg-yw4l"">$VMNICFailoverShouldReplaceMacAddress</td>
<td class=""tg-yw4l"">$VMNICFailoverGateway</td>
<td class=""tg-yw4l"">$VMNICFailoverDHCP</td>
<td class=""tg-yw4l"">$VMNICFailoverPrimaryDns</td>
<td class=""tg-yw4l"">$VMNICFailoverSecondaryDns</td>
<td class=""tg-yw4l"">$VMNICFailoverStaticIp</td>
<td class=""tg-yw4l"">$VMNICFailoverSubnetMask</td>
<td class=""tg-yw4l"">$VMNICFailoverTestNetworkName</td>
<td class=""tg-yw4l"">$VMNICFailoverTestDNSSuffix</td>
<td class=""tg-yw4l"">$VMNICFailoverTestShouldReplaceMacAddress</td>
<td class=""tg-yw4l"">$VMNICFailoverTestGateway</td>
<td class=""tg-yw4l"">$VMNICFailoverTestDHCP</td>
<td class=""tg-yw4l"">$VMNICFailoverTestPrimaryDns</td>
<td class=""tg-yw4l"">$VMNICFailoverTestSecondaryDns</td>
<td class=""tg-yw4l"">$VMNICFailoverTestStaticIp</td>
<td class=""tg-yw4l"">$VMNICFailoverTestSubnetMask</td>
</tr>
"
# Adding rows to table
$VMNICArrayHTMLTable += $VMNICArrayHTMLTableRow
}
# Compiling End of HTML email
$VMNICArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$VMNICArrayHTMLTable = $VMNICArrayHTMLTableStart + $VMNICArrayHTMLTable + $VMNICArrayHTMLTableEnd
$VMNICArrayHTMLTable
# End of TargetVRAArrayTable function
}
################################################
# Function for building HTML table for PODSummaryArray
################################################
Function Create-PODSummaryArrayTable {
Param($Array,$TableCaption)
$PODSummaryArrayHTMLTableStart = @"
<table class="tg">
<caption><span class="caption">$TableCaption</span></caption>
<tr>
<th class="tg-foxd">PODName</th>
<th class="tg-foxd">VMs</th>
<th class="tg-foxd">Protected</th>
<th class="tg-foxd">UnProtected</th>
<th class="tg-foxd">VPGs</th>
<th class="tg-foxd">MeetingSLA</th>
<th class="tg-foxd">NotMeetingSLA</th>
<th class="tg-foxd">AverageRPO</th>
<th class="tg-foxd">HighPriority</th>
<th class="tg-foxd">MediumPriority</th>
<th class="tg-foxd">LowPriority</th>
<th class="tg-foxd">ProtectedSizeTB</th>
<th class="tg-foxd">JournalSizeTB</th>
</tr>
"@
# Building HTML table
$PODSummaryArrayHTMLTable = $null
foreach ($_ in $Array)
{
# Setting values
$PODName = $_.PODName
$VMs = $_.VMs
$VMsUnProtected = $_.VMsUnProtected
$VMsProtected = $_.VMsProtected
$VPGs = $_.VPGs
$MeetingSLA = $_.MeetingSLA
$NotMeetingSLA = $_.NotMeetingSLA
$AverageRPO = $_.AverageRPO
$HighPriority = $_.HighPriority
$MediumPriority = $_.MediumPriority
$LowPriority = $_.LowPriority
$ProtectedSizeTB = $_.ProtectedSizeTB
$JournalSizeTB = $_.JournalSizeTB
# Building HTML table row
$PODSummaryArrayHTMLTableRow = "
<tr>
<td class=""tg-yw4l"">$PODName</td>
<td class=""tg-yw4l"">$VMs</td>
<td class=""tg-yw4l"">$VMsProtected</td>
<td class=""tg-yw4l"">$VMsUnProtected</td>
<td class=""tg-yw4l"">$VPGs</td>
<td class=""tg-yw4l"">$MeetingSLA</td>
<td class=""tg-yw4l"">$NotMeetingSLA</td>
<td class=""tg-yw4l"">$AverageRPO</td>
<td class=""tg-yw4l"">$HighPriority</td>
<td class=""tg-yw4l"">$MediumPriority</td>
<td class=""tg-yw4l"">$LowPriority</td>
<td class=""tg-yw4l"">$ProtectedSizeTB</td>
<td class=""tg-yw4l"">$JournalSizeTB</td>
</tr>
"
# Adding rows to table
$PODSummaryArrayHTMLTable += $PODSummaryArrayHTMLTableRow
}
# Compiling End of HTML email
$PODSummaryArrayHTMLTableEnd = @"
</table>
<br>
"@
# Compiling Final HTML
$PODSummaryArrayHTMLTable = $PODSummaryArrayHTMLTableStart + $PODSummaryArrayHTMLTable + $PODSummaryArrayHTMLTableEnd
$PODSummaryArrayHTMLTable
# End of TargetVRAArrayTable function
}
########################################################################################################################
# Customize reports below
########################################################################################################################
#########################################################################
# Building & Sending Report - POD Summary Report
#########################################################################
# Setting Email subject
$Subject = "Zerto POD Summary Report"
# Creating Tables for Email Body
# Table1
$PODSummaryArraySorted = $PODSummaryArray | Sort-Object PODName
$PODSummaryArrayHTML = Create-PODSummaryArrayTable -Array $PODSummaryArraySorted -TableCaption "POD Summary"
# Table2
$VPGAlerts = $ProtectedVPGArray | Where-Object {$_.Status -ne "MeetingSLA" -or $_.RPOAlerts -ge "1"} | Sort-Object SourcePOD,VPGName
if ($VPGAlertArraySorted -ne $null)
{
$VPGAlertArrayHTML = Create-ProtectedVPGArrayTable -Array $VPGAlerts -TableCaption "All VPG Violations by POD and VPGName"
}
else
{
$VPGAlertArrayHTML = $null
}
# Table2
$TargetDatastoreAlerts = $TargetDatastoreArray | where-object {$_.UsedByZVR -eq "TRUE" -and $_.FreePercent -le "35"} | Sort-Object PODName,FreeSpaceGB
# Only creating table if entries exist
if ($TargetDatastoreAlerts -ne $null)
{
$TargetDatastoreAlertHTML = Create-TargetDatastoreArrayTable -Array $TargetDatastoreAlerts -TableCaption "ZVR Datastores with less than 35% FreeSpace"
}
else
{
$TargetDatastoreAlertHTML = $null
}
# Table3
$ProtectedVPGArraySorted = $ProtectedVPGArray | Sort-Object SourcePOD,VPGName
$ProtectedVPGArrayHTML = Create-ProtectedVPGArrayTable -Array $ProtectedVPGArraySorted -TableCaption "All VPGs by POD and VPGName"
# Table4
$ProtectedVMArraySorted = $ProtectedVMArray | Sort-Object SourcePOD,SourceCluster,VPGName,VMName
$ProtectedVMArrayHTML = Create-ProtectedVMArrayTable -Array $ProtectedVMArraySorted -TableCaption "Protected VMs by POD, Cluster, VPGName and VMName"
# Table5
$UnprotectedVMArraySorted = $UnprotectedVMArray | Sort-Object SourcePOD,VMFolder,VMName
$UnprotectedVMArrayHTML = Create-UnprotectedVMArrayTable -Array $UnprotectedVMArraySorted -TableCaption "UnProtected VMs by POD, Folder and VMName"
# Table6
$TargetVRAArraySorted = $TargetVRAArray | Sort-Object TargetPOD,VRAName
$TargetVRAArrayHTML = Create-TargetVRAArrayTable -Array $TargetVRAArraySorted -TableCaption "VRAs by TargetPOD and VRAName"
# Table7
$TargetDatastoreArraySorted = $TargetDatastoreArray | where-object {$_.UsedByZVR -eq "TRUE"} | Sort-Object PODName,FreeSpaceGB
$TargetDatastoreArrayHTML = Create-TargetDatastoreArrayTable -Array $TargetDatastoreArraySorted -TableCaption "All ZVR Datastores by POD and least FreeSpace"
# Building Email Body
$Body = $ReportHTMLTableStyle + $PODSummaryArrayHTML + $VPGAlertArrayHTML + $TargetDatastoreAlertHTML + $ProtectedVPGArrayHTML + $ProtectedVMArrayHTML + $UnprotectedVMArrayHTML + $TargetVRAArrayHTML + $TargetDatastoreArrayHTML
# Saving CSVs of sorted arrays to disk, required to then email
$EmailAttachment1 = Save-CSV -Array $PODSummaryArraySorted -CSVFileName "PODSummaryArray" -CSVDirectory $CSVDirectory
# $EmailAttachment2 = Save-CSV -Array $VPGArray -CSVFileName "VPGArray2" -CSVDirectory $CSVDirectory
# Combining attachments if multiple are required
# $MultipleAttachments = @("$EmailAttachment1","$EmailAttachment2")
# Sending the email
Email-ZVRReport -EmailTo $EmailList1 -Subject $Subject -Body $Body -SMTPProfile $SMTPProfile1 -Attachment $EmailAttachment1
#########################################################################
# Building & Sending Report - VPG and VM Settings Report
#########################################################################
# Setting Email subject
$Subject = "Zerto VPG and VM Settings Report"
# Creating Tables for Email Body
# VPG settings table
$VPGArraySorted1 = $VPGArray | Sort-Object PODName,VPGName
$VPGArrayHTMLTable1 = Create-VPGArrayTable -Array $VPGArraySorted1 -TableCaption "VPG Settings by PODName and VPGName"
# VM settings table
$VMArraySorted1 = $VMArray | Sort-Object PODName,VPGName,VMName
$VMArrayHTMLTable1 = Create-VMArrayTable -Array $VMArraySorted1 -TableCaption "VM Settings by PODName, VPGName and VMName"
# Volume settings table
$VMVolumeArraySorted1 = $VMVolumeArray | Sort-Object PODName,VPGName,VMName,VMVolumeID
$VMVolumeArrayHTMLTable1 = Create-VMVolumeArrayTable -Array $VMVolumeArraySorted1 -TableCaption "Volume Settings by PODName, VPGName, VMName and VMVolumeID"
# NIC settings table
$VMNICArraySorted1 = $VMNICArray | Sort-Object PODName,VPGName,VMName,VMNICIdentifier
$VMNICArrayHTMLTable1 = Create-VMNICArrayTable -Array $VMNICArraySorted1 -TableCaption "NIC Settings by PODName, VPGName, VMName and VMNICIdentifier"
# Building Email Body
$Body = $ReportHTMLTableStyle + $VPGArrayHTMLTable1 + $VMArrayHTMLTable1 + $VMVolumeArrayHTMLTable1 + $VMNICArrayHTMLTable1
# Saving CSVs of sorted arrays to disk, required to then email
$EmailAttachment1 = Save-CSV -Array $VPGArraySorted1 -CSVFileName "ZVRVPGSettings" -CSVDirectory $CSVDirectory
$EmailAttachment2 = Save-CSV -Array $VMArraySorted1 -CSVFileName "ZVRVMSettings" -CSVDirectory $CSVDirectory
$EmailAttachment3 = Save-CSV -Array $VMVolumeArraySorted1 -CSVFileName "ZVRVolumeSettings" -CSVDirectory $CSVDirectory
$EmailAttachment4 = Save-CSV -Array $VMNICArraySorted1 -CSVFileName "ZVRNICSettings" -CSVDirectory $CSVDirectory
# Combining attachments if multiple are required
$MultipleAttachments = @("$EmailAttachment1","$EmailAttachment2","$EmailAttachment3","$EmailAttachment4")
# Sending the email
Email-ZVRReport -EmailTo $EmailList1 -Subject $Subject -Body $Body -SMTPProfile $SMTPProfile1 -Attachment $MultipleAttachments
