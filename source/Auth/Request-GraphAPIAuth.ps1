function Request-GraphAPIAuth {
	[CmdLetBinding()]
	param(
		[String]$ClientId,
		[SecureString]$ClientSecret,
		[String]$TenantId,
		[String[]]$Scopes = @("https://graph.microsoft.com/.default")
	)
	
	$uri = "https://login.microsoftonline.com/{0}/oauth2/v2.0/token" -f $TenantId
	
	$body = @{
		client_id = $ClientId
		client_secret = Unlock-SecureString $ClientSecret
		scope = $Scopes -join ", "
		grant_type = "client_credentials"
	}
	
	$r = Invoke-RestMethod -Method Post -Uri $uri -Body $body

	return @{
		TenantId = $TenantId
		ClientId = $ClientId
		ClientSecret = $ClientSecret
		Scopes = $Scopes
		TokenType  = $r.token_type
		AccessToken = $r.access_token
		Expiration = [datetime]::now.AddSeconds($r.expires_in)
		Headers = @{
			Authorization = "{0} {1}" -f $r.token_type, $r.access_token
		}
	}
}