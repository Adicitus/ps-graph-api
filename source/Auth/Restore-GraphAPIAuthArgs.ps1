function Restore-GraphAPIAuthArgs {
    param(
		[String]$Path
	)

    $argsRaw = Get-Content $Path

    $argsSec = ConvertTo-SecureString $argsRaw
    $argsSec | ForEach-Object MakeReadOnly

    $argsClearObj = Unlock-SecureString $argsSec | ConvertFrom-Json

    $argsClear = @{}
    $argsClearObj.psobject.properties | ForEach-Object { $argsClear[$_.Name] = $_.Value }
    $argsClear.ClientSecret = $argsClear.ClientSecret | ConvertTo-SecureString
    $argsClear.ClientSecret | ForEach-Object MakeReadOnly

    return $argsClear

}
