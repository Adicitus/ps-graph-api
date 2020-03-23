function Set-GraphAPICalendarEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Authorization object returned by Get-GraphAPIAuth")]
        [hashtable]$AuthObject,
        [Parameter(Mandatory=$true, HelpMessage="User ID (GUID) or Principal Name.")]
        [String]$User,
        [Parameter(Mandatory=$false, HelpMessage="Calendar ID of teh calendar containing the event. Uses the user's default calendar if not specified.")]
        [guid]$CalendarID,
        [Parameter(Mandatory=$true, HelpMessage="ID of the Event to modify.")]
        [string]$EventID,
        [Parameter(Mandatory=$false, ParameterSetName="Hashtable", HelpMessage="Event object (See https://docs.microsoft.com/en-us/graph/api/resources/event?view=graph-rest-1.0).")]
        [hashtable]$EventBody,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Subject for the Meeting.")]
        [string]$Subject,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Meeting start time.")]
        [datetime]$Start,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Meeting end time.")]
        [datetime]$End,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="List of Attendees (See https://docs.microsoft.com/en-us/graph/api/resources/attendeebase?view=graph-rest-1.0).")]
        [hashtable[]]$Attendees,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Time zone for the meeting Start and End times (See https://docs.microsoft.com/en-us/graph/api/resources/datetimetimezone?view=graph-rest-1.0). Defaults to local time.")]
        [System.TimeZoneInfo]$TimeZone = [System.TimeZoneInfo]::Local,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="The Meeting description. Can be left empty.")]
        [String]$Body,
        [ValidateSet("HTML", "Text")]
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Which type of description to use (HTML or Plain Text). HTML is default.")]
        [String]$BodyType="HTML",
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Short, plain text preview of the Body.")]
        [String]$BodyPreview,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Locations for the meeting (See https://docs.microsoft.com/en-us/graph/api/resources/location?view=graph-rest-1.0).")]
        [hashtable[]]$locations,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Categories for the Meeting.")]
        [String[]]$Categories,
        [Parameter(Mandatory=$false, HelpMessage="Enables reminder on the meeting.")]
        [boolean]$EnableReminder,
        [Parameter(Mandatory=$false, HelpMessage="Number of minutes before meeting start that attendees will be reminded.")]
        [int]$ReminderTime,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="List of Attendees (See https://docs.microsoft.com/en-us/graph/api/resources/attendeebase?view=graph-rest-1.0).")]
        [boolean]$IsAllDay=$false,
        [ValidateSet("low", "normal", "high")]
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Which type of description to use (HTML or Plain Text). HTML is default.")]
        [String]$Importance="normal",
        [ValidateSet("normal", "personal", "private", "confidential")]
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Which type of description to use (HTML or Plain Text). HTML is default.")]
        [String]$Sensitivity="normal",
        [ValidateSet("free", "tentative", "busy", "oof", "workingElsewhere", "unknown")]
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Which type of description to use (HTML or Plain Text). HTML is default.")]
        [String]$ShowAs="busy",
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Whether the or not the meeting should request a response from recipients.")]
        [bool]$ResponseRequested,
        [Parameter(Mandatory=$false, HelpMessage="Optional extra headers")]
        [hashtable]$ExtraHeaders = @{}
    )

    $encodedUser = [System.Web.HttpUtility]::UrlEncode($User)
    if ($CalendarID) {
        $uri = "https://graph.microsoft.com/v1.0/users/{0}/calendar/{1}/events/{2}" -f $encodedUser, $CalendarID, $EventID
    } else {
        $uri = "https://graph.microsoft.com/v1.0/users/{0}/calendar/events/{1}" -f $encodedUser, $EventID
    }

    $headers = @{ "Content-Type"="application/json; charset=utf-8" } + $AuthObject.Headers

    if ($ExtraHeaders) {
        foreach ($header in $ExtraHeaders.Keys) {
            if ($headers.ContainsKey($header)) {
                $headers.$header = $headers.$header, $ExtraHeaders.$header -join ","
            } else {
                $headers.$Header = $ExtraHeaders.$header
            }
        }
    }

    $jsonBody = switch ($PSCmdlet.ParameterSetName) {

        "Hashtable" { $EventBody | ConvertTo-Json -Depth 10 }

        "Params" {
            $requestBody = @{}
            foreach ($param in $PSCmdlet.MyInvocation.BoundParameters.Keys) {
                switch ($param) {
                    "Subject" { $requestBody.subject = $Subject }
                    "Start" {
                            $requestBody.start = @{
                                dateTime=("{0:yyyy-MM-dd}T{0:HH:mm:sss}" -f $Start)
                                timeZone=$TimeZone.Id
                            }
                    }
                    "End" {
                        $requestBody.end = @{
                            dateTime=("{0:yyyy-MM-dd}T{0:HH:mm:sss}" -f $End)
                            timeZone=$TimeZone.Id
                        } 
                    }
                    "Attendees" { $requestBody.attendees = $Attendees }
                    "Body" { $requestBody.body = @{ content = $Body; contentType = $BodyType } }
                    "BodyPreview" { $requestBody.bodyPreview = $BodyPreview }
                    "Locations" { $requestBody.locations = $Locations }
                    "Categories" { $requestBody.categories = $categories }
                    "EnableReminder" { $requestBody.isReminderOn = $EnableReminder }
                    "ReminderTime" { $requestBody.reminderMinutesBeforeStart = $Reminder }
                    "IsAllDay" { $requestBody.isAllDay = $IsAllDay }
                    "Importance" { $requestBody.importance = $Importance }
                    "Sensitivity" { $requestBody.sensitivity = $Sensitivity }
                    "ResponseRequested" { $requestBody.responseRequested = $ResponseRequested }
                }
            }

            $requestBody | ConvertTo-Json -Depth 10
        }

    }
    # The built in ConvertTo-Json Cmdlet does not properly escape non-ascii characters,
    # So we do that here:
    $jsonBody = ConvertTo-UnicodeEscapedString $jsonBody

    $jsonBody | Write-Host

    Invoke-WebRequest -Method Patch -Uri $uri -Headers $headers -Body $jsonBody -UseBasicParsing
}