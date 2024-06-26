# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# Integration tests for Azure Quick Start Templates
#

# Notes:
# This integration test downloads the Azure quick start templates and
# attempts to export resource data from each template using azuredeploy.json
# and azuredeploy.parameters.json files.

[CmdletBinding()]
param (

)


BeforeDiscovery {
    # Setup error handling
    $ErrorActionPreference = 'Stop';
    Set-StrictMode -Version latest;

    if ($Env:SYSTEM_DEBUG -eq 'true') {
        $VerbosePreference = 'Continue';
    }

    # Setup tests paths
    $rootPath = $PWD;
    Import-Module (Join-Path -Path $rootPath -ChildPath out/modules/PSRule.Rules.Azure) -Force;
    $clonePath = Join-Path -Path $rootPath -ChildPath out/tests/quickstart/;
    $exportPath = Join-Path -Path $clonePath -ChildPath azure-quickstart-templates-master/;
    $cloneDownload = Join-Path -Path $rootPath -ChildPath quickstart.zip;

    # Download and unpack files
    if (!(Test-Path -Path $cloneDownload)) {
        $Null = Invoke-WebRequest -Uri 'https://github.com/Azure/azure-quickstart-templates/archive/master.zip' -OutFile $cloneDownload -UseBasicParsing;
    }
    if (!(Test-Path -Path $clonePath)) {
        $Null = New-Item -Path $clonePath -ItemType Directory -Force;
        $Null = Expand-Archive -Path $cloneDownload -DestinationPath $clonePath;
    }

    function Get-Sample {
        [CmdletBinding()]
        [OutputType([PSObject])]
        param (
            [Parameter(Mandatory = $True)]
            [String]$Path
        )
        process {
            Get-ChildItem -Path $Path/azure-quickstart-templates-master -Directory | ForEach-Object -Process {
                $directory = $_;
                $templateFile = Join-Path -Path $directory.FullName -ChildPath 'azuredeploy.json';
                $parametersFile = Join-Path -Path $directory.FullName -ChildPath 'azuredeploy.parameters.json';
                if (Test-Path -Path $templateFile -PathType Leaf) {
                    [PSCustomObject]@{
                        Name = $directory.Name;
                        TemplateFile = $templateFile;
                        ParametersFile = $parametersFile;
                    }
                }
            }
        }
    }
}

Describe 'Azure Quickstart Templates' -Tag integration {
    Context 'Export template data' {
        BeforeDiscovery {
            # Skips templates because they are not complete
            $skipTemplates = @(
                "100-blank-template"
                # "101-hdinsight-custom-ambari-db"
                # "101-sql-vm-aglistener-setup"
                # "101-sql-vm-ag-setup"
                # "101-vm-windows-copy-datadisks"
                # "201-api-management-logs-oms-integration"
                # "201-data-factory-ftp-hive-blob"
                # "201-list-storage-keys-windows-vm"
                # "201-vm-msi"
                # "201-vm-win-iis-app-ssl"
                # "201-vmss-win-iis-app-ssl"
                # "301-custom-images-at-scale"
                # "301-drupal8-vmss-glusterfs-mysql"
                # "301-jenkins-aptly-spinnaker-vmss"
                # "301-vm-sql-full-autobackup-autopatching-keyvault"
                # "blockchain"
                # "chef-ha-cluster"
                # "couchbase"
                # "hdinsight-genomics-adam"
                # "hdinsight-linux-run-script-action"
                # "intel-lustre-client-server"
                # "sql-server-2014-alwayson-existing-vnet-and-ad"
                # "kemp-loadmaster-multinic"
                # "memcached-multi-vm-ubuntu"
                # "oms-azure-storage-analytics-solution"
                # "openedx-devstack-ubuntu"
                # "opensis-cluster-ubuntu"
                # "rhel-3tier-iaas"
                # "slurm-on-sles12-hpc"
                # "traffic-manager-demo-setup"
                # "vsts-fullbuild-redhat-vm"
                # "vsts-fullbuild-ubuntu-vm"
                # "vsts-minbuildjava-ubuntu-vm"
            )
        }
        It '<_.Name>' -ForEach (Get-Sample -Path $clonePath | Where-Object { $_.Name -notin $skipTemplates }) {
            $result = Export-AzRuleTemplateData -TemplateFile $_.TemplateFile -ParameterFile $_.ParametersFile -OutputPath $exportPath;
            $result | Should -Not -BeNullOrEmpty;
        }
    }

    Context 'Validate template' {
        It 'All templates resources' {
            try {
                Push-Location -Path $exportPath;
                $Null = Invoke-PSRule -Module PSRule.Rules.Azure -InputPath . -Format File -WarningAction SilentlyContinue;
            }
            finally {
                Pop-Location;
            }
        }
    }
}
