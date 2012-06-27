<#
.SYNOPSIS
Grabs the free space and total space for the user defined shares

.PARAMETER
-email Instructs the script to email the final report
-targets The file to be used which lists LUN path

.DESCRIPTION
Generates and displays (or emails) an overview report that contains the free space and total space for each LUN on specified device.

.EXAMPLES
.\get-LUN-space.ps1 -targets lun-paths.txt
Uses default method and displays results to console
.\get-LUN-space.ps1 -targets lun-paths.txt -email true
Specifies the report to be emailed
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory=$true)]
	[string]$targets,
	[string]$email
)


# and then... I got in!
# dabbling in function for initialize variables
function master_control_program($command){
	if($command -eq "rez"){
		$net = @()
		$drive = @()
		$drive_total = 0
		$drive_free = 0
		$drive_total_N0 = 0
		$drive_free_N2 = 0
		$drive_percent = 0
		$drive_used = 0
	}
}

# Import the list of LUNs to read
$filers = Get-Content .\$targets

# Rez an array to store all the info
$LunInfo = @()

# Scan through all the LUNs imported above
foreach ($lun in $filers){
	# rez variables
	master_control_program("rez")

	# Build ComObject to Network 
	$net = new-object -ComObject WScript.Network
	# Map network drive to path based on entry in input text
	$net.MapNetworkDrive("y:", $lun, $false)
	
	# Scan through our WMI object list for object matching Y
	$drive = get-WmiObject Win32_MappedLogicalDisk | where-Object { $_.name -eq "Y:" }
	# Lets get the drive total in GB's
	$drive_total = ($drive.Size / 1GB)
	# Set the same to decimal places
	$drive_total_N0 = "{0:N0}" -f $drive_total
	# Lets get the drive free data
	$drive_free = ($drive.FreeSpace / 1GB )
	# Set the same to decimal places
	$drive_free_N2 = "{0:N2}" -f $drive_free
	# Compute the used space
	$drive_used = $drive_total - $drive_free

	# Lets get the percent free
	$drive_percent = (($drive_used / $drive_total) * 100)
	# Set the same to decimal places
	$drive_percent = "{0:N2}" -f $drive_percent
	
	# Here we build our structure to store variables
	# Define the object
	$objLunInfo = New-Object System.Object
	# Each line adds a new member to the object
	# We develop a single object with multiple members that contains our values
	$objLunInfo | Add-Member -MemberType NoteProperty -Name Name -Value $lun
	$objLunInfo | Add-Member -MemberType NoteProperty -Name PercentUsed -Value $drive_percent
	$objLunInfo | Add-Member -MemberType NoteProperty -Name FreeInGB -Value $drive_free_N2
	$objLunInfo | Add-Member -MemberType NoteProperty -Name SizeInGB -Value $drive_total_N0
	# Then dump the objects into our array
	# We finish with an array of objects
	$LunInfo += $objLunInfo
	
	# Disconnect the existing network drive
	$net.RemoveNetworkDrive("y:")
}

# Lets build our report and sort on PercentUsed variable
$report = $LunInfo | sort -Descending -Property "PercentUsed" | FT -AutoSize | out-String
# Output to the console
$report

if ($email){
	# When using email - ask users for variables
	# users you would like to send to
	$recipients = read-Host	"Enter reciepeint email address (comma separated)"
	# Subject of the email when sent
	$subject = read-Host "Enter email subject"
	# The server that the email should indicate from
	$from = read-Host "Enter originating server email address"
	# The SMTP server to use when sending email
	$smtpserver = read-Host "Provide SMTP server"

	send-mailmessage -to $recipients -Subject $subject -from $from -smtpserver $smtpserver -body $report
}