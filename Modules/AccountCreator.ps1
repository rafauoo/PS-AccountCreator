function Handle-CreateAccount {
    param (
        [hashtable]$AccountData,
        [string[]]$Groups
    )

    # Wygeneruj hasło
    $generatedPassword = New-HumanFriendlyPassword -Length 24

    # Wyciągnij OU i usuń z hashtable
    $ou = $AccountData['OU']
    if (-not $ou -or $ou -eq '') {
        # Fallback do BaseOU jeśli dostępne
        if ($AccountData.ContainsKey('BaseOU') -and $AccountData['BaseOU']) {
            $ou = $AccountData['BaseOU']
            $AccountData.Remove('BaseOU')
        }
        else {
            Show-ErrorBox -Message "Missing OU and no fallback BaseOU provided."
            return
        }
    }
    else {
        $AccountData.Remove('OU')
    }

    # Przygotuj podstawowe parametry
    $newUserParams = @{
        Path            = $ou
        AccountPassword = (ConvertTo-SecureString $generatedPassword -AsPlainText -Force)
        Enabled         = $true
    }

    # Lista podstawowych parametrów New-ADUser, które NIE idą do -OtherAttributes
    $standardParams = @(
        'Name', 'GivenName', 'Surname', 'DisplayName', 'UserPrincipalName', 'SamAccountName',
        'Path', 'AccountPassword', 'Enabled', 'PasswordNeverExpires', 'ChangePasswordAtLogon', 'CannotChangePassword'
        'Description', 'EmailAddress', 'EmployeeID'
    )

    # Rozdziel parametry: standardowe vs inne (np. extensionAttributes)
    foreach ($key in $AccountData.Keys) {
        if ($standardParams -contains $key) {
            $newUserParams[$key] = $AccountData[$key]
        }
        else {
            if (-not $newUserParams.ContainsKey('OtherAttributes')) {
                $newUserParams['OtherAttributes'] = @{}
            }
            $newUserParams['OtherAttributes'][$key] = $AccountData[$key]
        }
    }

    # Debug — wyświetl parametry
    Write-Host "----- New-ADUser parameters -----"
    $newUserParams.GetEnumerator() | ForEach-Object {
        if ($_.Key -eq 'OtherAttributes') {
            Write-Host "OtherAttributes:"
            $_.Value.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)"
            }
        }
        else {
            Write-Host "$($_.Key): $($_.Value)"
        }
    }

    Write-Host "`n----- Groups to be added to -----"
    foreach ($group in $Groups) {
        Write-Host $group
    }

    try {
        # Tworzenie konta
        New-ADUser @newUserParams -ErrorAction Stop
        $newUser = Get-ADUser -Identity $newUserParams['SamAccountName']
    }
    catch {
        Show-ErrorBox -Message "Failed to create user account.`n`n$($_.Exception.Message)"
        return
    }

    foreach ($group in $Groups) {
        try {
            Add-ADGroupMember -Identity $group -Members $newUser.SamAccountName -ErrorAction Stop
        }
        catch {
            Show-ErrorBox -Message "User created, but failed to add to group: $group.`n`n$($_.Exception.Message)"
        }
    }

    Show-PasswordBox -Password $generatedPassword
}


function Show-PasswordBox {
    param (
        [string]$Password
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Account created successfully"
    $form.Size = New-Object System.Drawing.Size(400, 150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Generated password (select and copy):"
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 35)
    $textBox.Size = New-Object System.Drawing.Size(360, 25)
    $textBox.ReadOnly = $true
    $textBox.Text = $Password
    $textBox.SelectAll()
    $textBox.Focus()
    $form.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(75, 25)
    $okButton.Location = New-Object System.Drawing.Point(295, 70)
    $okButton.Add_Click({ $form.Close() })
    $form.Controls.Add($okButton)

    $form.Topmost = $true
    $form.ShowDialog()
}

function Show-ErrorBox {
    param (
        [string]$Message
    )

    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($Message, "Error", 'OK', 'Error')
}

