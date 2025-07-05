function Handle-CreateAccount {
    param (
        [hashtable]$AccountData,
        [string[]]$Groups
    )

    # Przygotuj parametry dla New-ADUser
    $generatedPassword = New-HumanFriendlyPassword -Length 24
    $newUserParams = @{
        AccountPassword = $generatedPassword  # Tu możesz podstawić właściwe hasło
    }

    # Dodaj inne atrybuty, jeśli są
    foreach ($key in $AccountData.Keys) {
        if ($key -notin $newUserParams.Keys) {
            $newUserParams[$key] = $AccountData[$key]
        }
    }

    # Wyświetl parametry konta
    Write-Host "----- New-ADUser parameters -----"
    $newUserParams.GetEnumerator() | ForEach-Object {
        Write-Host "$($_.Key): $($_.Value)"
    }

    # Wyświetl grupy
    Write-Host "`n----- Groups to be added to -----"
    foreach ($group in $Groups) {
        Write-Host $group
    }

    # $newUser = New-ADUser @newUserParams

    # foreach ($group in $groups) {
    #     Add-ADGroupMember -Identity $group -Members $newUser.SamAccountName -WhatIf
    # }
    
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
