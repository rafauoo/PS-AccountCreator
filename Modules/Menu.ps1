Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Tworzenie konta AD"
    $form.Size = New-Object System.Drawing.Size(500, 500)

    $templateFolder = "$PSScriptRoot\..\Templates"
    $templateDropdown = New-Object System.Windows.Forms.ComboBox
    $templateDropdown.Location = New-Object System.Drawing.Point(10, 10)
    $templateDropdown.Size = New-Object System.Drawing.Size(460, 20)
    $templateDropdown.DropDownStyle = 'DropDownList'
    $form.Controls.Add($templateDropdown)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(10, 50)
    $panel.Size = New-Object System.Drawing.Size(460, 380)
    $form.Controls.Add($panel)

    $templateFiles = Get-ChildItem -Path $templateFolder -Filter *.xml
    $templateFiles | ForEach-Object {
        $templateDropdown.Items.Add($_.Name)
    }

    $templateDropdown.Add_SelectedIndexChanged({
            $selectedFile = Join-Path $templateFolder $templateDropdown.SelectedItem
            $templateXml = Load-TemplateXml $selectedFile
            $global:currentTemplate = $templateXml
            Build-Form -Panel $panel -Template $templateXml
        })

    $form.Topmost = $true
    $form.Add_Shown({ $form.Activate() })
    [void]$form.ShowDialog()
}
