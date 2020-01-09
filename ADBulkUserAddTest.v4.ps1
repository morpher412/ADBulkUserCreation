Import-module activedirectory
$Users=Import-csv "C:\UserImport\BulkUserImport.TEST.csv"
$a=1;
$b=1;
$failedUsers = @()
$successUsers = @()
$VerbosePreference = "Continue"
$LogFolder = "C:\UserImport\log"


ForEach($User in $Users)
{
   $FullName = $User.FirstName + " " + $User.LastName
        for ($i = 1; $i -le $user.FirstName.Length; $i++) {
                $SAM = $user.FirstName.Substring(0,$i) + $user.LastName #example John snow will be Jsnow
                if (-not (get-aduser -Filter " samaccountname -eq '$SAM' ")) {
                    "$SAM is available!"
                    $SAM = $sam.ToLower()
                    break
                } else {
                    if ($i -eq $user.firstname.Length) {
                        "Username cannot be auto-generated"
                        exit
                    }
                }
            }
            write-host "$SAM"

   $dnsroot = '@' + (Get-ADDomain).dnsroot
   $SAM=$sam.tolower()


$Password = (convertto-securestring $User.Password -AsPlainText -Force)
$UPN = $SAM + "$dnsroot" # change "$dnsroot to custom domain if you want, by default it will take from DNS ROOT"
$OU="OU=Unsorted,OU=All Users,DC=gwcu,DC=gwcu,DC=org"
$FileserverUser= "\\fileserver\users"
$homeDirectory="$FileserverUser\$SAM"
$LogonScript = "default.bat"
$phone = "801-337-8300"


try {
    if (!(get-aduser -Filter {samaccountname -eq "$SAM"}))
    {
    $Parameters = @{
    'SamAccountName'             = $Sam
    'UserPrincipalName'          = $UPN
    'Name'                       = $Fullname
    'GivenName'                  = $User.FirstName
    'Surname'                    = $User.Lastname
    'AccountPassword'            = $Password
    'ChangePasswordAtLogon'      = $true
    'Enabled'                    = $true
    'Path'                       = $OU
    'Description'                = $User.jobtitle
    'Office'                     = $User.Office
    'homeDirectory'              = $homeDirectory
    'homeDrive'                  = "U:"
    'scriptpath'                 = $LogonScript
    'DisplayName'                = $FullName
    'officephone'                = $phone
    #Attributes listed above that are imported from .csv need to have a $User. in front of the attribute. 
    }

New-ADUser @Parameters
     Write-Verbose "[PASS] Created $FullName under $ou"
     $successUsers += $FullName + "," +$SAM
    }
   
}
catch {
    Write-Warning "[ERROR]Can't create user [$($FullName)] : $_"
    $failedUsers += $FullName + "," +$SAM + "," +$_
}

#Add New User to Group
Add-AdGroupMember -Identity Everybody $SAM

#Add New User Home Folder (Had to create separate scripts since running code within produced errors.)
$PSScriptRoot
& "$PSScriptRoot\AddHomeFolder.ps1"
}
if ( !(test-path $LogFolder)) 
    {
    Write-Verbose "Folder [$($LogFolder)] does not exist, creating"
    new-item $LogFolder -type directory -Force 
    }

Write-verbose "Writing logs"
$failedUsers |ForEach-Object {"$($b).) $($_)"; $b++} | out-file -FilePath  $LogFolder\FailedUsers.log -Force -Verbose
$successUsers | ForEach-Object {"$($a).) $($_)"; $a++} |out-file -FilePath  $LogFolder\successUsers.log -Force -Verbose

$su=(Get-Content "$LogFolder\successUsers.log").count
$fu=(Get-Content "$LogFolder\FailedUsers.log").count


Write-Host "$fu Users Creation Failed and " -NoNewline -ForegroundColor red
Write-Host "$su Users Successfully Created "  -NoNewline -ForegroundColor green