function Save-GraphAPIAuthArgs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position = 1)]
        [String]$Path,
        [Parameter(Mandatory=$true, ParameterSetName="Hashtable", Position = 2)]
        [hashtable]$AuthArgs,
        [Parameter(Mandatory=$true, ParameterSetName="Params", Position = 2)]
		[String]$ClientId,
        [Parameter(Mandatory=$true, ParameterSetName="Params", Position = 3)]
		[SecureString]$ClientSecret,
        [Parameter(Mandatory=$true, ParameterSetName="Params", Position = 4)]
		[String]$TenantId
	)

    if ($PSCmdlet.ParameterSetName -eq "Params") {
        $authArgs = @{
            ClientId = $ClientId
            ClientSecret = ConvertFrom-SecureString $ClientSecret
            TenantId = $TenantId
        }
    } else {
        $authArgs = @{
            ClientId = $AuthArgs.ClientId
            ClientSecret = ConvertFrom-SecureString $AuthArgs.ClientSecret
            TenantId = $AuthArgs.TenantId
        }
    }

    $jsonArgs = $authArgs | ConvertTo-Json

    $jsonArgs | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString > $Path

}
