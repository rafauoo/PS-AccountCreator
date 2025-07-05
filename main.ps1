Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Wczytaj moduły
. "$PSScriptRoot\Modules\TemplateLoader.ps1"
. "$PSScriptRoot\Modules\FormBuilder.ps1"
. "$PSScriptRoot\Modules\AccountCreator.ps1"
. "$PSScriptRoot\Modules\Menu.ps1"
. "$PSScriptRoot\Modules\SummaryForm.ps1"
. "$PSScriptRoot\PasswordGenerator\genPassword.ps1"

# Uruchom GUI
Show-GUI