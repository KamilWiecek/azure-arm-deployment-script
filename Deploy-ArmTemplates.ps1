[CmdletBinding()]
param (
    [string]
    $Location = 'westeurope',

    [string]
    $DeploymentDefinitionsPath = "$(Get-Location)\ManagementGroupsHierarchy.DeploymentDefinition.json",

    [string]
    $TemplatesRootPath = "$(Get-Location)",

    [switch]
    $WhatIfDeployment
)

$context = Get-AzContext

if (-not $context) {
    Write-Error -Exception "Login to Azure first!"
}

if (-not (Test-Path -Path $DeploymentDefinitionsPath) ) {
    Write-Error -Exception "Provide deployment definitions path"
}

if (-not (Test-Path -Path $TemplatesRootPath) ) {
    Write-Error -Exception "Provide templates path"
}

$deploymentDefinitions = Get-Content -Path $DeploymentDefinitionsPath -Raw | ConvertFrom-Json -AsHashtable

$deploymentObjects =  $deploymentDefinitions | % { New-Object -TypeName PSObject -Property $_ } | Sort-Object -Property Order

foreach ($item in $deploymentObjects) {
    Write-Output -InputObject "Deploying: `n $($item | ConvertTo-Json -Depth 100)"

    if ($item.TenantId -and (-not $item.ManagementGroupId) -and ( -not $item.SubscriptionId ) ) {
        $deploymentParameters = @{
            Name         = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile = (Join-Path -Path (Get-Location) -ChildPath $item.TemplateFile )
            Verbose      = $true
            Location     = $location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
    
        Set-AzContext -TenantId $item.TenantId | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Write-Output -InputObject 'WhatIf only deployment is not supported at Tenant scope'
        } else {
            New-AzTenantDeployment @deploymentParameters -Confirm:$false -ErrorAction Stop
        }

    }
    elseif ($item.ManagementGroupId  ) {
        $deploymentParameters = @{
            ManagementGroupId = $item.ManagementGroupId
            Name              = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile      = (Join-Path -Path (Get-Location) -ChildPath $item.TemplateFile )
            Verbose           = $true
            Location          = $Location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
    
        Set-AzContext -TenantId $item.TenantId | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Write-Output -InputObject 'WhatIf only deployment is not supported at Management Group scope'
        } else {
            New-AzManagementGroupDeployment @deploymentParameters -Confirm:$false -ErrorAction Stop
        }
    }
    elseif ($item.SubscriptionId -and (-not $item.RgName) ) {
        $deploymentParameters = @{
            Name         = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            TemplateFile = (Join-Path -Path (Get-Location) -ChildPath ($item.Template) )
            Verbose      = $true
            Location     = $Location
        }
    
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
        
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
        
        Set-AzContext -TenantId $item.TenantId -SubscriptionId $item.SubscriptionId -ErrorAction Stop | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Get-AzSubscriptionDeploymentWhatIfResult @deploymentParameters -ErrorAction Stop
        } else {
            New-AzSubscriptionDeployment  @deploymentParameters -Confirm:$false  -ErrorAction Stop
        }

    }
    elseif ($item.RgName) {
        $deploymentParameters = @{
            Name              = ('deployment' + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm'))
            ResourceGroupName = $item.RgName
            TemplateFile      = (Join-Path -Path (Get-Location) -ChildPath ($item.Template) )
            Mode              = $item.Mode
        }
            
        $parametersFilePath = (Join-Path -Path (Get-Location) -ChildPath ($item.TemplateParameterFile) )
            
        if (Test-Path -Path $parametersFilePath) {
            $deploymentParameters['TemplateParameterFile'] = $parametersFilePath
        }
            
        Set-AzContext -TenantId $item.TenantId -SubscriptionId $item.SubscriptionId -ErrorAction Stop | Out-Null
        
        if ($WhatIfDeployment.IsPresent) {
            Get-AzResourceGroupDeploymentWhatIfResult  @deploymentParameters -ErrorAction Stop
        } else {
            New-AzResourceGroupDeployment  @deploymentParameters -ErrorAction Stop
        }
    }
}
