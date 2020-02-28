function Remove-GraphAPICalendarEvent {
    param(
        [Parameter(Mandatory=$true, HelpMessage="Authorization object returned by Get-GraphAPIAuth")]
        [hashtable]$AuthObject,
        [Parameter(Mandatory=$true, HelpMessage="User ID (GUID) or Principal Name.")]
        [String]$User,
        [Parameter(Mandatory=$false, HelpMessage="Calendar ID of the calendar containing the event. Uses the user's default calendar if not specified.")]
        [guid]$CalendarID,
        [Parameter(Mandatory=$true, HelpMessage="ID of the Event to remove.")]
        [string]$EventID,
        [Parameter(Mandatory=$false, HelpMessage="Optional extra headers")]
        [hashtable]$ExtraHeaders = @{}
    )

    
    $encodedUser = [System.Web.HttpUtility]::UrlEncode($User)
    if ($CalendarID) {
        $uri = "https://graph.microsoft.com/v1.0/users/{0}/calendar/{1}/events/{2}" -f $encodedUser, $CalendarID, $EventID
    } else {
        $uri = "https://graph.microsoft.com/v1.0/users/{0}/events/{1}" -f $encodedUser, $EventID
    }

    $headers = $AuthObject.Headers.clone()

    if ($ExtraHeaders) {
        foreach ($header in $ExtraHeaders.Keys) {
            if ($headers.ContainsKey($header)) {
                $headers.$header = $headers.$header, $ExtraHeaders.$header -join ","
            } else {
                $headers.$Header = $ExtraHeaders.$header
            }
        }
    }

    Invoke-WebRequest -Method Delete -Uri $uri -Headers $headers

}