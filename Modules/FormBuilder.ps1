$global:fieldInputs = @{}

function Evaluate-TemplateString {
    param (
        [string]$template,
        [hashtable]$localVars
    )

    $pattern = '\{([^\{\}]+)\}'
    return [System.Text.RegularExpressions.Regex]::Replace($template, $pattern, {
            param($match)
            $key = $match.Groups[1].Value

            if ($key -match '^(\w+)\[(\d+)\]$') {
                $localMatches = $Matches
                $varName = $localMatches[1]
                $index = [int]$localMatches[2]
                if ($localVars.ContainsKey($varName) -and $localVars[$varName].Length -gt $index) {
                    return $localVars[$varName][$index]
                }
            }
            elseif ($localVars.ContainsKey($key)) {
                return $localVars[$key]
            }
            return ""
        })
}




function Update-DependentFields {
    param ([xml]$Template)

    $localVars = @{}
    #Write-Host "Aktualizacja pól zależnych..."

    # Zbuduj słownik tylko z aktualnych pól lokalnych
    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.LocalVar -eq "true" -and $global:fieldInputs.ContainsKey($field.Name)) {
            $ctrl = $global:fieldInputs[$field.Name]
            if ($ctrl -is [System.Windows.Forms.ComboBox]) {
                $selectedLabel = $ctrl.SelectedItem
                $map = $ctrl.Tag
                if ($map -and $map.ContainsKey($selectedLabel)) {
                    $selectedValue = $map[$selectedLabel]
    
                    if ($selectedValue -is [hashtable]) {
                        foreach ($k in $selectedValue.Keys) {
                            $localVars[$k] = $selectedValue[$k]
                        }
                        $localVars[$field.Name] = $selectedLabel
                    }
                    else {
                        $localVars[$field.Name] = $selectedValue
                    }
                }
                else {
                    $localVars[$field.Name] = $selectedLabel
                }
            }
            elseif ($ctrl -is [System.Windows.Forms.CheckBox]) {
                $localVars[$field.Name] = $ctrl.Checked
            }
            else {
                $localVars[$field.Name] = $ctrl.Text
            }
        }
    }

    # Oblicz wartości pól zależnych
    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.Template -and ($field.Editable -ne $null -and $field.Editable.ToLower() -ne "true")) {
            $evaluated = Evaluate-TemplateString -template $field.Template -localVars $localVars
            #Write-Host "Aktualizacja pola: $($field.Name), Wartość: $evaluated"

            if ($field.Value) {
                $field.Value = $evaluated
            }
            else {
                $newValueNode = $Template.CreateElement("Value")
                $newValueNode.InnerText = $evaluated
                $field.AppendChild($newValueNode) | Out-Null
            }

            if ($global:fieldInputs.ContainsKey($field.Name)) {
                $global:fieldInputs[$field.Name].Text = $evaluated
            }

            #Write-Host "Pole: $($field.Name), Nowa wartość: $evaluated"
        }
    }

}

function Add-GroupInfoDisplay {
    param (
        [System.Windows.Forms.Panel]$Panel,
        [xml]$Template,
        [int]$StartY
    )


    $groupBoxContainer = New-Object System.Windows.Forms.GroupBox
    $groupBoxContainer.Text = "Automatically Assigned Groups"
    $groupBoxContainer.Location = New-Object System.Drawing.Point(10, $StartY)
    $groupBoxContainer.Width = 410
    $groupBoxContainer.Height = 90

    $groupBox = New-Object System.Windows.Forms.TextBox
    $groupBox.Multiline = $true
    $groupBox.ReadOnly = $true
    $groupBox.ScrollBars = 'Vertical'
    $groupBox.Width = 390
    $groupBox.Height = 60
    $groupBox.Location = New-Object System.Drawing.Point(10, 20)
    $groupBox.BackColor = [System.Drawing.SystemColors]::Control
    $groupBox.BorderStyle = 'FixedSingle'

    $groupText = ""
    foreach ($group in $Template.Template.Groups.Group) {
        $groupText += "$group`r`n"
    }
    $groupBox.Text = $groupText.Trim()

    $groupBoxContainer.Controls.Add($groupBox)
    $Panel.Controls.Add($groupBoxContainer)

    return ($StartY + $groupBox.Height + 20)
}


function Build-Form {
    param (
        [System.Windows.Forms.Panel]$Panel,
        [xml]$Template
    )

    $Panel.Controls.Clear()
    $global:fieldInputs.Clear()
    $y = 20

    $labelFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $inputFont = New-Object System.Drawing.Font("Segoe UI", 9)

    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.Visible -and $field.Visible.ToLower() -eq "false") {
            continue
        }
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $field.Label
        $label.Font = $labelFont
        $label.Location = New-Object System.Drawing.Point(20, $y)
        $label.Width = 180
        $label.AutoSize = $false
        $label.AutoEllipsis = $true
        $Panel.Controls.Add($label)

        $input = $null
        $isEditable = ($field.Editable -eq "true")

        if ($field.Type -eq "Checkbox") {
            $input = New-Object System.Windows.Forms.CheckBox
            $input.Location = New-Object System.Drawing.Point(210, $y)
            $input.Checked = ($field.Value -eq "true")
            $input.Enabled = $isEditable
        }
        elseif ($field.Type -eq "Select") {
            $input = New-Object System.Windows.Forms.ComboBox
            $input.Location = New-Object System.Drawing.Point(210, $y)
            $input.Width = 250
            $input.Font = $inputFont
            $input.DropDownStyle = 'DropDownList'
            $input.Enabled = $isEditable

            $optionMap = @{}
            foreach ($option in $field.Options.Option) {
                $label = $option.Label

                if ($option.Attributes) {
                    # Rzutuj atrybuty do hashtable
                    $attrMap = @{}
                    foreach ($attr in $option.Attributes.ChildNodes) {
                        $adAttr = $attr.Attributes["ADAttribute"].Value
                        $val = $attr.Attributes["Value"].Value
                        $attrMap[$adAttr] = $val
                    }

                    $optionMap[$label] = $attrMap
                }
                else {
                    # Backward compatibility (jeśli tylko <Value>)
                    $optionMap[$label] = $option.Value
                }

                $input.Items.Add($label) | Out-Null
            }


            $input.Tag = $optionMap

            # Ustawienie wartości domyślnej, jeśli istnieje
            if ($field.Value) {
                $selected = $optionMap.GetEnumerator() | Where-Object { $_.Value -eq $field.Value } | Select-Object -First 1
                if ($selected) {
                    $input.SelectedItem = $selected.Key
                }
            }
            elseif ($input.Items.Count -gt 0) {
                $input.SelectedIndex = 0
            }
        }
        else {
            $input = New-Object System.Windows.Forms.TextBox
            $input.Location = New-Object System.Drawing.Point(210, $y)
            $input.Width = 250
            $input.Font = $inputFont
            $input.Text = $field.Value
            $input.ReadOnly = -not $isEditable
        }


        $input.Name = $field.Name
        $Panel.Controls.Add($input)
        $global:fieldInputs[$field.Name] = $input
        $y += 30
    }

    $y = Add-GroupInfoDisplay -Panel $Panel -Template $Template -StartY $y

    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.LocalVar -eq "true" -and $global:fieldInputs.ContainsKey($field.Name)) {
            $ctrl = $global:fieldInputs[$field.Name]

            if ($ctrl -is [System.Windows.Forms.ComboBox]) {
                $ctrl.Add_SelectedIndexChanged({
                        param($sender, $e)
                        Update-DependentFields $global:currentTemplate
                    })
            }
            else {
                $ctrl.Add_TextChanged({
                        param($sender, $e)
                        Update-DependentFields $global:currentTemplate
                    })
            }
        }
    }


    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Create Account"
    $submitButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $submitButton.BackColor = [System.Drawing.Color]::LightGreen
    $submitButton.Location = New-Object System.Drawing.Point(150, ($y + 20))
    $submitButton.Size = New-Object System.Drawing.Size(160, 30)
    $submitButton.Add_Click({
            Update-DependentFields $global:currentTemplate
            Show-SummaryForm $global:currentTemplate
        })

    $Panel.Controls.Add($submitButton)
    $resetButton = New-Object System.Windows.Forms.Button
    $resetButton.Text = "Reset Form"
    $resetButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $resetButton.BackColor = [System.Drawing.Color]::LightGray
    $resetButton.Location = New-Object System.Drawing.Point(320, ($y + 20))
    $resetButton.Size = New-Object System.Drawing.Size(110, 30)
    $resetButton.Add_Click({
            Reset-FormFields
        })
    $Panel.Controls.Add($resetButton)

    # Przewiń widok do dolnych przycisków
    $Panel.ScrollControlIntoView($resetButton)
    # Ustaw wysokość lub przewiń do przycisku
    $Panel.ScrollControlIntoView($submitButton)

    Update-DependentFields $global:currentTemplate
}


function Reset-FormFields {
    Build-Form -Panel $panel -Template $global:currentTemplate
}
