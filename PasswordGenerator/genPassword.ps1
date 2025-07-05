function New-HumanFriendlyPassword {
    param (
        [int]$Length = 24,
        [string]$WordListPath = "$PSScriptRoot\words.json",
        [double]$ReplacementChance = 0.2
    )

    if (-not (Test-Path $WordListPath)) {
        throw "Password file not found: $WordListPath"
    }

    $words = Get-Content -Raw -Path $WordListPath | ConvertFrom-Json
    $random = [System.Random]::new()
    $password = ""

    while ($password.Length -lt ($Length - 6)) {
        $pickedWord = $words[$random.Next(0, $words.Count)]
        if (($pickedWord.Length + $password.Length) -lt ($Length - 1)) {
            $pickedWord = $pickedWord.Substring(0, 1).ToUpper() + $pickedWord.Substring(1)
            $password += $pickedWord
        }
    }

    $replacements = @{
        'e' = '3'
        'o' = '0'
        's' = '$'
    }

    $passwordChars = $password.ToCharArray()
    for ($i = 0; $i -lt $passwordChars.Length; $i++) {
        $char = $passwordChars[$i].ToString()
        if ($replacements.ContainsKey($char)) {
            if ($random.NextDouble() -lt $ReplacementChance) {
                $passwordChars[$i] = $replacements[$char] | Get-Random
            }
        }
    }

    $password = -join $passwordChars

    $digits = '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'
    $specialChars = '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '='

    if ($password -notmatch '\d') {
        $password += ($digits | Get-Random)
    }

    if ($password -notmatch '[!@#$%^&*()\-\+=]') {
        $password += ($specialChars | Get-Random)
    }

    while ($password.Length -lt $Length) {
        $password += ($digits + $specialChars | Get-Random)
    }

    return $password
}
