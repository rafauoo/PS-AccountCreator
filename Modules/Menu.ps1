function Show-GUI {
    $global:mainForm = New-Object System.Windows.Forms.Form
    $form = $global:mainForm
    $form.Text = "PS-AccountCreator by Rafal Budnik"
    $form.Size = New-Object System.Drawing.Size(520, 620)
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $templateFolder = "$PSScriptRoot\..\Templates"

    $templateDropdown = New-Object System.Windows.Forms.ComboBox
    $templateDropdown.Location = New-Object System.Drawing.Point(30, 10)
    $templateDropdown.Size = New-Object System.Drawing.Size(440, 25)
    $templateDropdown.DropDownStyle = 'DropDownList'
    $form.Controls.Add($templateDropdown)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(10, 50)
    $panel.Size = New-Object System.Drawing.Size(480, 510)
    $panel.AutoScroll = $true
    $panel.BorderStyle = 'FixedSingle'
    $form.Controls.Add($panel)

    # Tu dodajemy hashtable do mapowania AccountType na ścieżkę pliku
    $accountTypeToFileMap = @{}

    # Wczytujemy pliki i dodajemy AccountType do ComboBoxa
    $templateFiles = Get-ChildItem -Path $templateFolder -Filter *.xml
    foreach ($file in $templateFiles) {
        try {
            [xml]$xmlContent = Get-Content $file.FullName
            $accountType = $xmlContent.Template.AccountType
            if ($accountType) {
                $templateDropdown.Items.Add($accountType)
                $accountTypeToFileMap[$accountType] = $file.FullName
            }
        }
        catch {
            Write-Warning "Cannot process: $($file.FullName)"
        }
    }

    $templateDropdown.Add_SelectedIndexChanged({
            $selectedAccountType = $templateDropdown.SelectedItem
            if ($accountTypeToFileMap.ContainsKey($selectedAccountType)) {
                $selectedFile = $accountTypeToFileMap[$selectedAccountType]
                $global:currentTemplate = Load-TemplateXml $selectedFile
                Build-Form -Panel $panel -Template $global:currentTemplate
            }
        })

    $form.Topmost = $true
    $form.Add_Shown({ $form.Activate() })

    [void]$form.ShowDialog()
}
