function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$OpsMgrServer,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$VMMServerCredential,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SCVMMAdminCredential
	)

    $returnvalue = Invoke-Command -ComputerName . -Credential $SCVMMAdminCredential {
        try
        {
            $VMMServer = Get-SCVMMServer -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue
            if($VMMServer)
            {
                $SCOpsMgrConnection = Get-SCOpsMgrConnection -VMMServer $VMMServer -ErrorAction SilentlyContinue
                if($SCOpsMgrConnection)
                {
                    $Ensure = "Present"
                    if(!($SCOpsMgrConnection.OpsMgrUserName))
                    {
                        $UseVMMServerServiceAccount = $true
                    }
                    else
                    {
                        $UseVMMServerServiceAccount = $false
                    }
                }
                else
                {
                    $Ensure = "Absent"
                }
            }
        }
        catch   
        {
            $Ensure = "Absent"
        }
        @{
		    Ensure = $Ensure
		    OpsMgrServer = $SCOpsMgrConnection.OpsMgrServerName
		    EnablePRO = $SCOpsMgrConnection.PROEnabled
		    EnableMaintenanceModeIntegration = $SCOpsMgrConnection.MaintenanceModeEnabled
		    OpsMgrServerCredential = $SCOpsMgrConnection.OpsMgrUserName
		    UseVMMServerServiceAccount = $UseVMMServerServiceAccount
	    }
    }

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$OpsMgrServer,

		[System.Boolean]
		$EnablePRO,

		[System.Boolean]
		$EnableMaintenanceModeIntegration,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$VMMServerCredential,

		[System.String]
		$OpsMgrServerCredential,

		[System.Boolean]
		$UseVMMServerServiceAccount,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SCVMMAdminCredential
	)

    Invoke-Command -ComputerName . -Credential $SCVMMAdminCredential {
		$Ensure = $args[0]
		$OpsMgrServer = $args[1]
		$EnablePRO = $args[2]
		$EnableMaintenanceModeIntegration = $args[3]
		$VMMServerCredential = $args[4]
		$OpsMgrServerCredential = $args[5]
		$UseVMMServerServiceAccount = $args[6]
        try
        {
            $VMMServer = Get-SCVMMServer -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue
            if($VMMServer)
            {
                switch($Ensure)
                {
                    "Present"
                    {
                        switch($UseVMMServerServiceAccount)
                        {
                            $true
                            {
                                New-SCOpsMgrConnection -OpsMgrServer $OpsMgrServer -EnablePRO $EnablePro -EnableMaintenanceModeIntegration $EnableMaintenanceModeIntegration -VMMServerCredential $VMMServerCredential -UseVMMServerServiceAccount
                            }
                            $false
                            {
                                $OpsMgrServerRunAs = Get-SCRunAsAccount -Name $OpsMgrServerCredential -VMMServer $VMMServer
                                if($OpsMgrServerRunAs)
                                {
                                    New-SCOpsMgrConnection -OpsMgrServer $OpsMgrServer -EnablePRO $EnablePro -EnableMaintenanceModeIntegration $EnableMaintenanceModeIntegration -VMMServerCredential $VMMServerCredential -OpsMgrServerCredential $OpsMgrServerRunAs
                                }
                            }
                        }
                    }
                    "Absent"
                    {
                        Remove-SCOpsMgrConnection -VMMServer $VMMServer
                    }
                }
            }
        }
        catch
        {
        }
    } -ArgumentList @($Ensure,$OpsMgrServer,$EnablePRO,$EnableMaintenanceModeIntegration,$VMMServerCredential,$OpsMgrServerCredential,$UseVMMServerServiceAccount)
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[parameter(Mandatory = $true)]
		[System.String]
		$OpsMgrServer,

		[System.Boolean]
		$EnablePRO,

		[System.Boolean]
		$EnableMaintenanceModeIntegration,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$VMMServerCredential,

		[System.String]
		$OpsMgrServerCredential,

		[System.Boolean]
		$UseVMMServerServiceAccount,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$SCVMMAdminCredential
	)

    $result = ((Get-TargetResource -Ensure $Ensure -OpsMgrServer $OpsMgrServer -VMMServerCredential $VMMServerCredential -SCVMMAdminCredential $SCVMMAdminCredential).Ensure -eq $Ensure)
	
	$result
}


Export-ModuleMember -Function *-TargetResource