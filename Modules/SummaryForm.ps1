function Show-SummaryForm {
    param (
        [xml]$Template
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Account creation summary"
    $form.Size = New-Object System.Drawing.Size(650, 600)
    $form.StartPosition = "CenterScreen"

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(10, 40)
    $grid.Size = New-Object System.Drawing.Size(610, 280)
    $grid.ReadOnly = $true
    $grid.AutoSizeColumnsMode = 'Fill'
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.RowHeadersVisible = $false

    $grid.ColumnCount = 3
    $grid.Columns[0].Name = "Label"
    $grid.Columns[1].Name = "AD Attribute"
    $grid.Columns[2].Name = "Value"

    $toolTip = New-Object System.Windows.Forms.ToolTip

    foreach ($field in $Template.Template.Fields.Field) {
        $value = ""
        $source = "Empty"

        if ($field.Value) {
            $value = $field.Value
            $source = "From Template"
        }
        elseif ($global:fieldInputs.ContainsKey($field.Name)) {
            $ctrl = $global:fieldInputs[$field.Name]

            if ($ctrl -is [System.Windows.Forms.CheckBox]) {
                $value = $ctrl.Checked
            }
            elseif ($ctrl -is [System.Windows.Forms.ComboBox]) {
                $selectedLabel = $ctrl.SelectedItem
                $map = $ctrl.Tag

                if ($map -and $map.ContainsKey($selectedLabel)) {
                    $value = $map[$selectedLabel]
                }
                else {
                    $value = $selectedLabel
                }
            }
            else {
                $value = $ctrl.Text
            }

            $source = "From User Input"
        }

        # Jeśli wartość to mapa AD atrybutów — pokaż każdą parę
        if ($value -is [hashtable]) {
            foreach ($adAttr in $value.Keys) {
                $val = $value[$adAttr]
                $rowIndex = $grid.Rows.Add($field.Label, $adAttr, $val)

                if (-not $val) {
                    $grid.Rows[$rowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::MistyRose
                    $grid.Rows[$rowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkRed
                }

                $toolTip.SetToolTip($grid, "Source: $source")
            }
        }
        elseif ($field.ADAttribute) {
            # Standardowe pola z jednym ADAttribute
            $rowIndex = $grid.Rows.Add($field.Label, $field.ADAttribute, $value)

            if (-not $value) {
                $grid.Rows[$rowIndex].DefaultCellStyle.BackColor = [System.Drawing.Color]::MistyRose
                $grid.Rows[$rowIndex].DefaultCellStyle.ForeColor = [System.Drawing.Color]::DarkRed
                $source = "Empty"
            }

            $toolTip.SetToolTip($grid, "Source: $source")
        }
    }

    $rowIndex = $grid.Rows.Add("BaseOU", "BaseOU", $Template.Template.BaseOU)
    $form.Controls.Add($grid)

    # GroupBox z grupami
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Text = "Assigned Groups"
    $groupBox.Location = New-Object System.Drawing.Point(10, 330)
    $groupBox.Size = New-Object System.Drawing.Size(610, 150)

    $groupBoxText = New-Object System.Windows.Forms.TextBox
    $groupBoxText.Multiline = $true
    $groupBoxText.ReadOnly = $true
    $groupBoxText.ScrollBars = 'Vertical'
    $groupBoxText.Location = New-Object System.Drawing.Point(10, 20)
    $groupBoxText.Size = New-Object System.Drawing.Size(590, 120)
    $groupBoxText.BackColor = [System.Drawing.SystemColors]::Control
    $groupBoxText.BorderStyle = 'FixedSingle'

    $groupsText = ""
    foreach ($group in $Template.Template.Groups.Group) {
        $groupsText += "$group`r`n"
    }
    $groupBoxText.Text = $groupsText.Trim()

    $groupBox.Controls.Add($groupBoxText)
    $form.Controls.Add($groupBox)

    # Panel z przyciskami
    $buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 480)
    $buttonPanel.Size = New-Object System.Drawing.Size(650, 40)
    $buttonPanel.FlowDirection = 'RightToLeft'
    $buttonPanel.Padding = '10,5,10,5'

    $confirmButton = New-Object System.Windows.Forms.Button
    $confirmButton.Text = "Create"
    $confirmButton.Width = 100
    $confirmButton.BackColor = [System.Drawing.Color]::LightGreen
    $confirmButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $confirmButton.Add_Click({
            $accountData = @{}
            foreach ($row in $grid.Rows) {
                $adAttr = $row.Cells[1].Value
                $val = $row.Cells[2].Value
                if ($adAttr) {
                    $accountData[$adAttr] = $val
                }
            }

            $groups = @()
            foreach ($group in $Template.Template.Groups.Group) {
                $groups += $group
            }
            # write account data:
            Write-Host "Account Data:"
            foreach ($key in $accountData.Keys) {
                Write-Host "$($key): $($accountData[$key])"
            }
            $form.Close()
            Handle-CreateAccount -AccountData $accountData -Groups $groups
            Reset-FormFields
        })

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Width = 100
    $cancelButton.Add_Click({ $form.Close() })
    $cancelButton.BackColor = [System.Drawing.Color]::LightSalmon

    $buttonPanel.Controls.Add($confirmButton)
    $buttonPanel.Controls.Add($cancelButton)
    $form.Controls.Add($buttonPanel)

    $form.ShowDialog($global:mainForm) | Out-Null
}
