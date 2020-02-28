function Get-GraphAPICalendarEvent {
    param(
        [Parameter(Mandatory=$true, HelpMessage="Authorization object returned by Get-GraphAPIAuth")]
        [hashtable]$AuthObject,
        [Parameter(Mandatory=$true, HelpMessage="User ID (GUID) or Principal Name.")]
        [String]$User,
        [Parameter(Mandatory=$false, HelpMessage="Calendar ID for the calendar to get the event from. Uses the user's default calendar if not specified.")]
        [guid]$CalendarID,
        [Parameter(Mandatory=$false, HelpMessage="ID of the Event to retrieve.")]
        [string]$EventID,
        [Parameter(Mandatory=$false, HelpMessage="The preferred timezone for returned dateTimes.")]
        [System.TimeZoneInfo]$PreferredTimeZone = [System.TimeZoneInfo]::Local,
        [Parameter(Mandatory=$false, HelpMessage="Optional extra headers")]
        [hashtable]$ExtraHeaders = @{}
    )

    
    $encodedUser = [System.Web.HttpUtility]::UrlEncode($User)
    $uri = if ($CalendarID) {
        "https://graph.microsoft.com/v1.0/users/{0}/calendar/{1}/events" -f $encodedUser, $CalendarID
    } else {
        "https://graph.microsoft.com/v1.0/users/{0}/calendar/events" -f $encodedUser
    }

    if ($EventID) {
        $uri = $uri + "/" + $EventID
    }

    $headers = $AuthObject.Headers.clone()

    if ($PreferredTimeZone) {
        $headers = $headers + @{ "Prefer"= 'outlook.timezone="{0}"' -f $PreferredTimeZone.Id }
    }

    if ($ExtraHeaders) {
        foreach ($header in $ExtraHeaders.Keys) {
            if ($headers.ContainsKey($header)) {
                $headers.$header = $headers.$header, $ExtraHeaders.$header -join ","
            } else {
                $headers.$Header = $ExtraHeaders.$header
            }
        }
    }

    Invoke-WebRequest-Method Get -Uri $uri -Headers $headers

}