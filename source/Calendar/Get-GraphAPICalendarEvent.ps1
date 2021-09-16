function Get-GraphAPICalendarEvent {
    param(
        [Parameter(Mandatory=$true, HelpMessage="Authorization object returned by Get-GraphAPIAuth")]
        [hashtable]$AuthObject,
        [Parameter(Mandatory=$true, HelpMessage="User ID (GUID) or Principal Name.")]
        [String]$User,
        [Parameter(Mandatory=$false, HelpMessage="Calendar ID for the calendar to get the event from. Uses the user's default calendar if not specified.")]
        [guid]$CalendarID,
        [Parameter(Mandatory=$false, HelpMessage="Number of events to skip")]
        [int]$Skip=0,
        [Parameter(Mandatory=$false, HelpMessage="ID of the Event to retrieve.")]
        [string]$EventID,
        [Parameter(Mandatory=$false, HelpMessage="The preferred timezone for returned dateTimes.")]
        [System.TimeZoneInfo]$PreferredTimeZone = [System.TimeZoneInfo]::Utc,
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
    } else {
        $c = @( $uri )

        if ($Skip -gt 0) {
            $c += '$skip={0}' -f $Skip
        }

        #Further OData parameters go here.

        if ($c.count -gt 1) {
            $c[0] += "?"
            $uri = $c -join "&"
        }
    }

    Write-Host $uri

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

    $r = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers -UseBasicParsing

    $h = @{
        StatusCode = $r.StatusCode
        Content = $r.Content | ConvertFrom-Json 
    }

    if ($EventID) {
        $h.Event = $h.Content
    } else {
        $h.Events = $h.Content.Value
    }

    $h

}