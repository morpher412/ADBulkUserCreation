$Users=Import-csv "C:\Scripts\UserImport\BulkUserImport.csv"
$VerbosePreference = "Continue"

ForEach($User in $Users)
{
$sam = $User.username
$FileserverUser= "\\fileserver\users"
$homeDirectory="$FileserverUser\$SAM"

#Create HomeFolder
    if (!(Test-Path "$homeDirectory"))

        {
            $NewFolder = New-Item -Path $FileserverUser -Name $sam -ItemType "Directory"
            $Rights = [System.Security.AccessControl.FileSystemRights]"FullControl,Modify,ReadAndExecute,ListDirectory,Read,Write"
            $InheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
            $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
            $objType =[System.Security.AccessControl.AccessControlType]::Allow
            $dnsroot = (Get-ADDomain).dnsroot
            $objUser = New-Object System.Security.Principal.NTAccount "$dnsroot\$sam"
            $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
                    ($objUser, $Rights, $InheritanceFlag, $PropagationFlag, $objType)
            $ACL = Get-Acl -Path $NewFolder
            $ACL.AddAccessRule($objACE)
            Set-ACL -Path $NewFolder.FullName -AclObject $ACL
        }
}