#Import Active Directory Module
Import-module activedirectory

#Autopopulate Domain
$dnsDomain =gc env:USERDNSDOMAIN
$split = $dnsDomain.split(".")
if ($split[2] -ne $null) {
	$domain = "DC=$($split[0]),DC=$($split[1]),DC=$($split[2])"
} else {
	$domain = "DC=$($split[0]),DC=$($split[1])"
}

#Declare any Variables
$dirpath = $pwd.path
$orgUnit = "CN=Users"
$dummyPassword = ConvertTo-SecureString -AsPlainText "P@ss1W0Rd!" -Force
$counter = 0

#import CSV File
$ImportFile = Import-csv "$dirpath\ADUsers.csv"
$TotalImports = $importFile.Count

#Create Users
$ImportFile | foreach {
	$counter++
	$progress = [int]($counter / $totalImports * 100)
	Write-Progress -Activity "Provisioning User Accounts" -status "Provisioning account $counter of $TotalImports" -perc $progress
	if ($_.Manager -eq "") {
		New-ADUser -SamAccountName $_.SamAccountName -Name $_.Name -Surname $_.Sn -GivenName $_.GivenName -Path "$orgUnit,$domain" -AccountPassword $dummyPassword -Enabled $true -title $_.title -officePhone $_.officePhone -department $_.department -emailaddress $_.mail
	} else {
    New-ADUser -SamAccountName $_.SamAccountName -Name $_.Name -Surname $_.Sn -GivenName $_.GivenName -Path "$orgUnit,$domain" -AccountPassword $dummyPassword -Enabled $true -title $_.title -officePhone $_.officePhone -department $_.department -manager "$($_.Manager),$orgUnit,$domain" -emailaddress $_.mail
	}
	If (gci "$dirpath\userimages\$($_.name).jpg") {
		$photo = [System.IO.File]::ReadAllBytes("$dirpath\userImages\$($_.name).jpg")
		Set-ADUSER $_.samAccountName -Replace @{thumbnailPhoto=$photo}
	}
}
