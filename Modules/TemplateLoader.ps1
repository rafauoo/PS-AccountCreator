function Load-TemplateXml {
    param (
        [string]$FilePath
    )
    return [xml](Get-Content $FilePath)
}