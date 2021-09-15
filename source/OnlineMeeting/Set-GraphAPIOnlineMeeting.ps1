function Set-GraphAPIOnlineMeeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Authorization object returned by Get-GraphAPIAuth.")]
        [hashtable]$AuthObject,
        [Parameter(Mandatory=$true, HelpMessage="User ID or Principal Name.")]
        [String]$User,
        [Parameter(Mandatory=$true, HelpMessage="ID of the meeting to update.")]
        [String]$MeetingId,
        [Parameter(Mandatory=$true, ParameterSetName="Hashtable", HelpMessage="OnineMeeting object (See https://docs.microsoft.com/en-us/graph/api/resources/onlinemeeting?view=graph-rest-1.0).")]
        [hashtable]$Body,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Subject for the Meeting.")]
        [string]$Subject,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Meeting start time.")]
        [datetime]$Start,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Meeting end time.")]
        [datetime]$End,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Specifies who can be a presenter in a meeting.")]
        [validateSet('everyone', 'organization', 'roleIsPresenter', 'organizer', 'unknownFutureValue')]
        [string]$AllowedPresenters='organizer',
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Indicates whether attendees can turn on their camera.")]
        [boolean]$AllowAttendeeToEnableCamera=$true,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Indicates whether attendees can turn on their microphone.")]
        [boolean]$AllowAttendeeToEnableMic=$true,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Specifies the mode of meeting chat.")]
        [validateSet('enabled', 'disabled', 'limited', 'unknownFutureValue')]
        [string]$AllowMeetingChat='enabled',
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Indicates whether Teams reactions are enabled for the meeting.")]
        [boolean]$AllowTeamworkReactions=$true,
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Specifies the type of participants that are automatically admitted into a meeting, bypassing the lobby.")]
        [validateSet('organizer', 'organization', 'organizationAndFederated', 'everyone', 'unknownFutureValue')]
        [string]$AllowLobbyBypass='everyone',
        [Parameter(Mandatory=$false, ParameterSetName="Params", HelpMessage="Specifies whether or not to always let dial-in callers bypass the lobby.")]
        [boolean]$AlwaysAdmitDialIn=$false,

        [Parameter(Mandatory=$false, HelpMessage="Optional extra headers.")]
        [hashtable]$ExtraHeaders = @{}
    )

    $encodedUser = [System.Web.HttpUtility]::UrlEncode($User)
    $uri = "https://graph.microsoft.com/v1.0/users/{0}/onlineMeetings/{1}" -f $encodedUser, $MeetingId

    Write-Host $uri

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

        "Hashtable" { $Body | ConvertTo-Json -Depth 10 }

        "Params" {
            $requestBody = @{}
            foreach ($param in $PSCmdlet.MyInvocation.BoundParameters.Keys) {
                switch ($param) {
                    "Subject" { $requestBody.subject = $Subject }
                    "Start" {
                            $requestBody.startDateTime = $Start.ToString("yyyy-MM-ddTHH\:mm\:ss.fffffffzzz");
                    }
                    "End" {
                        $requestBody.endDateTime = $End.ToString("yyyy-MM-ddTHH\:mm\:ss.fffffffzzz");
                    }
                    "AllowedPresenters" {
                        $requestBody.allowedPresenters = switch($AllowedPresenters) {
                            'roleIsPresenter' { 'roleIsPresenter' }
                            'unknownFutureValue' { 'unknownFutureValue' }
                            default {
                                $AllowedPresenters.toLower()
                            }
                        }
                    }
                    "AllowAttendeeToEnableCamera" {
                        $requestBody.allowAttendeeToEnableCamera = $AllowAttendeeToEnableCamera
                    }
                    "AllowAttendeeToEnableMic" {
                        $requestBody.allowAttendeeToEnableMic = $AllowAttendeeToEnableMic
                    }
                    "AllowMeetingChat" {
                        $requestBody.allowMeetingChat = switch($AllowedMeetingChat) {
                            'unknownFutureValue' { 'unknownFutureValue' }
                            default {
                                $AllowedMeetingChat.toLower()
                            }
                        }
                    }
                    "AllowTeamworkReactions" {
                        $requestBody.allowTeamworkReactions = $AllowTeamworkReactions
                    }
                    { $_ -in "AlwaysAdminDialIn", "AllowLobbyBypass" } {
                        if (!$requestBody.lobbyBypassSettings) {
                            $requestBody.lobbyBypassSettings = @{
                                scope = switch ($AllowLobbyBypass) {
                                    'unknownFutureValue' { 'unknownFutureValue' }
                                    'organizationAndFederated' { 'organizationAndFederated' }
                                    default {
                                        $AllowLobbyBypass.ToLower()
                                    }
                                }
                                isDialInBypassEnabled = $AlwaysAdmitDialIn
                            }
                        }
                    }
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