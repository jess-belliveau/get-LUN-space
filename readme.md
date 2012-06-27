# Get-LUN-Space

## Description
Accept user defined list of paths and analyse disk space metrics
- Name
- Percent Used
- Free space in GB
- Total size in GB

## Mandatory parameters
User must pass a file that contains a list of share paths to check - eg;
\\servername\path$

## Optional parameters
User can define '-email true' to have the script email the final report to the defined email variables
