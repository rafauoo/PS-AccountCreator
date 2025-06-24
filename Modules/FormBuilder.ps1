$global:fieldInputs = @{}

function ReplacePlaceholders {
    param ($template, $inputFirstName, $inputSurname)

    $map = @{
        "cFirstname" = $inputFirstName
        "Surnamec"   = $inputSurname
        "cfsurnamec" = ($inputFirstName.Substring(0, 1) + $inputSurname)
    }

    foreach ($field in $template.Template.Fields.Field) {
        if ($field.Template) {
            $value = $field.Template
            foreach ($token in $map.Keys) {
                $value = $value -replace $token, $map[$token]
            }
            $field.Value = $value
        }
    }
}

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
    Write-Host "Aktualizacja pól zależnych..."

    # Zbuduj słownik tylko z aktualnych pól lokalnych
    foreach ($field in $Template.Template.Fields.Field) {
        Write-Host "Pole: $($field.Name), Typ: $($field.Type), Wartość: $($field.Value)"
        if ($field.LocalVar -eq "true") {
            if ($global:fieldInputs.ContainsKey($field.Name)) {
                $localVars[$field.Name] = $global:fieldInputs[$field.Name].Text
            }
        }
    }

    # Oblicz wartości pól zależnych
    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.Template -and ($field.Editable -ne $null -and $field.Editable.ToLower() -ne "true")) {
            $evaluated = Evaluate-TemplateString -template $field.Template -localVars $localVars
            Write-Host "Aktualizacja pola: $($field.Name), Wartość: $evaluated"

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

            Write-Host "Pole: $($field.Name), Nowa wartość: $evaluated"
        }
    }

}




function Build-Form {
    param (
        [System.Windows.Forms.Panel]$Panel,
        [xml]$Template
    )

    $Panel.Controls.Clear()
    $global:fieldInputs.Clear()
    $y = 10

    foreach ($field in $Template.Template.Fields.Field) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $field.Label
        $label.Location = New-Object System.Drawing.Point(10, $y)
        $label.Width = 130
        $Panel.Controls.Add($label)

        $input = $null
        $isEditable = ($field.Editable -eq "true")

        if ($field.Type -eq "Checkbox") {
            $input = New-Object System.Windows.Forms.CheckBox
            $input.Location = New-Object System.Drawing.Point(150, $y)
            $input.Checked = ($field.Value -eq "true")
            $input.Enabled = $isEditable
        }
        else {
            $input = New-Object System.Windows.Forms.TextBox
            $input.Location = New-Object System.Drawing.Point(150, $y)
            $input.Width = 250
            $input.Text = $field.Value
            $input.ReadOnly = -not $isEditable
        }

        $input.Name = $field.Name
        $Panel.Controls.Add($input)
        $global:fieldInputs[$field.Name] = $input
        $y += 30
    }

    # Podpinanie dynamicznych zdarzeń dla wszystkich pól typu LocalVar
    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.LocalVar -eq "true" -and $global:fieldInputs.ContainsKey($field.Name)) {
            $global:fieldInputs[$field.Name].Add_TextChanged({
                    param($sender, $e)
                    Update-DependentFields $global:currentTemplate
                })
        }
    }

    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Utwórz konto"
    $submitButton.Location = New-Object System.Drawing.Point(150, ($y + 20))
    $submitButton.Add_Click({
            Handle-CreateAccount $Template
        })
    $Panel.Controls.Add($submitButton)
}


