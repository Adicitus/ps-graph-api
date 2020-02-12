function Unlock-SecureString {
    param(
        [SecureString]$SecString
    )
    $Marshal = [Runtime.InteropServices.Marshal]
    $bstr = $Marshal::SecureStringToBSTR($SecString)
    $r = $Marshal::ptrToStringAuto($bstr)
    $Marshal::ZeroFreeBSTR($bstr)
    return $r
}