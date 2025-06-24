function Handle-CreateAccount {
    param (
        [xml]$Template
    )

    $fields = $global:fieldInputs
    $accountName = $fields["AccountName"].Text
    $azureSynced = $false
    if ($fields.ContainsKey("AzureSynced")) {
        $azureSynced = $fields["AzureSynced"].Checked
    }

    Write-Host "== Tworzenie konta =="
    Write-Host "Konto: $accountName"
    Write-Host "OU: $($Template.Template.BaseOU)"
    Write-Host "Azure Synced: $azureSynced"

    foreach ($group in $Template.Template.Groups.Group) {
        Write-Host "Dodaj do grupy: $group"
    }

    # Można tu dodać: New-ADUser, Add-ADGroupMember, itp.
    [System.Windows.Forms.MessageBox]::Show("Konto zostało utworzone: $accountName", "Sukces", "OK", "Information")
}
