function Show-SummaryForm {
    param (
        [xml]$Template
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Podsumowanie konta"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterScreen"

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = 'Fill'
    $grid.ReadOnly = $true
    $grid.AutoSizeColumnsMode = 'Fill'
    $grid.ColumnCount = 3
    $grid.Columns[0].Name = "Label"
    $grid.Columns[1].Name = "AD Attribute"
    $grid.Columns[2].Name = "Value"

    foreach ($field in $Template.Template.Fields.Field) {
        if ($field.ADAttribute) {
            $value = if ($field.Value) { $field.Value } else { "" }
            $grid.Rows.Add($field.Label, $field.ADAttribute, $value)
        }
    }

    $form.Controls.Add($grid)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Zamknij"
    $closeButton.Dock = 'Bottom'
    $closeButton.Height = 30
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)

    $form.ShowDialog() | Out-Null
}
