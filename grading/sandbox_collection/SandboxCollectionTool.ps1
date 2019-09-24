# Copyright 2019 Amazon.com, Inc. or its affiliates. 
# All Rights Reserved. SPDX-License-Identifier: MIT-0

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Purpose:
# This script is intended to be used with the Access Key, Secret Key, and Session token from the AWS Academy labs. The script pulls 
# in information about resources deployed in the sandbox environment in a human, readable format. Each resource collection is 
# handled by an independent function and can be disabled by commenting the outpt line at the end of the script. 

#Import the AWS PowerShell Module to enable powershell to utilize AWS specific commands
Import-Module AWSPowerShell

# Welcome Script
Write-Host "Sandbox Collection Tool - v2" -ForegroundColor Green
#Collect Keys/Credentials from User, Store as secure string, must use Plaintext for Global:Session variables
$secure_accesskey = Read-Host -Prompt 'Enter AWS Access Key' -AsSecureString
$secure_accesskey
$secure_secretkey = Read-Host -Prompt 'Enter AWS Secret Key' -AsSecureString
$secure_secretkey
$secure_sessionToken = Read-Host -Prompt 'Enter Session Key' -AsSecureString
$secure_sessionToken
$BSTR_accesskey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_accesskey)
$BSTR_secretkey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_secretkey)
$BSTR_sessionkey = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_sessionToken)
$Global:AccessKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR_accesskey)
$Global:SecretKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR_secretkey)
$Global:SessionToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR_sessionkey)

#Prompt user for Region to run collection functions against
$Global:Region = Read-Host -Prompt 'Enter Region to run the script against (Default = us-east-1):'
    if ($Global:Region) {Write-Host "The region you enterd is [$Global:Region]" -ForegroundColor Green} else {$Global:Region = 'us-east-1'}
$Global:Region

Write-Host "Your Region is set to: [$Region]" -ForegroundColor Green

#Configure AWS credentials for AWS PowerShell module
Set-AWSCredentials -AccessKey $Global:AccessKey -SecretKey $Global:SecretKey -SessionToken $Global:SessionToken -StoreAs "RunCollection"
Set-AWSCredentials -ProfileName "RunCollection"
Set-DefaultAWSRegion $Global:Region

Write-Host "AWS Powershell access has been granted" -ForegroundColor Yellow

#Run the collection script functions to gather information
#Function to set naming schema for output file. Modify to fit needs of export.
function filenaming {
    $FileName = "Collection"+(Get-Date).tostring("dd-MM-yyyy")
    $FolderPath = "C:\Temp"
    $Global:Path = $FolderPath+"\"+$FileName+".txt"
}
#Function to collect all EC2 instances in defined region
function list-ec2{
    $EC2s = (Get-EC2Instance).Instances
    Write-Output "##### EC2 Instance List #####"
    foreach ($EC2 in $EC2s)
        {
            New-Object -TypeName PSObject -Property @{
                'EC2 Name' = ($EC2.Tags | Where-Object {$_.Key -eq 'Name'}).Value
                'Instance ID' = $EC2.InstanceId
                'Platfrom' = $EC2.Platform
                'Instance Type' = $EC2.InstanceType
                'Launch Time' = $EC2.LaunchTime
                'Network Interface' = $EC2.NetworkInterfaces
                'Public DNS Name' = $EC2.PublicDnsName
                'Public IP Address' = $EC2.PublicIpAddress
                'Attached Security Groups' = $EC2.SecurityGroups
                'Subnet IDs' = $EC2.SubnetId
                'VPC' = $EC2.VpcId
            }
        }
    }
#Function to collect associated EC2 Security Groups
function list-ec2SecurityGroups{
    $ec2Instances_all = (Get-EC2Instance).Instances 
    $rdsInstances_all = Get-RDSDBInstance 
    $securityGroups_all = Get-EC2SecurityGroup
    $elbs_all_v1 = Get-ELBLoadBalancer
    $elbs_all_v2 = Get-ELB2LoadBalancer
    #Setup objects and loops
    $ec2 = @()
    $outputdetails = @{}
    $SGList = New-Object 'System.Collections.Generic.List[System.String]'
    $ec2SGDetails = @()
        foreach ($sg in $securityGroups_all){
            $securityGroupDetailsInbound = $sg.IpPermissions
            $securityGroupDetailsOutbound = $sg.IpPermissionsEgress
                foreach ($value in $securityGroupDetailsInbound){
                    foreach ($entry in $value.Ipv4Ranges){
                        $SecDetails = @{
                            'VPC ID' = $sg.VpcId
                            'SG ID' = $sg.GroupId
                            'SG Name' = $sg.GroupName
                            'SG Description' = $sg.Description
                            'From Port' = ($value.FromPort | out-string).Trim()
                            'To Port' = ($value.ToPort | out-string).Trim()
                            'IP Range' = ($entry.CidrIP | out-string).Trim()
                            'IP Range Descption' = ($entry.Description | out-string).Trim()
                            'Protocol' = ($value.IpProtocol | Out-String).Trim()
                            'Traffic Flow' = "Ingress"
                            }
                        $ec2SGDetails += New-Object PSObject -Property $SecDetails
                        }
                        foreach ($entry in $value.UserIdGroupPairs){
                            $SecDetails = @{
                                'VPC ID' = $sg.VpcID
                                'SG ID' = $sg.GroupId
                                'SG Name' = $sg.GroupName
                                'SG Description' = $sg.Description
                                'From Port' = ($value.FromPort | out-string).Trim()
                                'To Port' = ($value.ToPort | out-string).Trim()
                                'IP Range' = ($entry.GroupId | out-string).Trim()
                                'IP Range Description' = ($entry.Description | out-string).Trim()
                                'Protocol' = ($value.IpProtocol | Out-String).Trim()
                                'Traffic Flow' = "Ingress"
                                }
                            $ec2SGDetails += New-Object PSObject -Property $SecDetails
                        }
                }
            foreach ($value in $securityGroupDetailsOutbound){
                foreach ($entry in $value.Ipv4Ranges){
                    $SecDetails = @{
                        'VPC ID' = $sg.VpcID
                        'SG ID' = $sg.GroupId
                        'SG Name' = $sg.GroupName
                        'SG Description' = $sg.Description
                        'From Port' = ($value.FromPort | out-string).Trim()
                        'To Port' = ($value.ToPort | out-string).Trim()
                        'IP Range' = ($entry.CidrIP | out-string).Trim()
                        'IP Range Description' = ($entry.Description | out-string).Trim()
                        'Protocol' = ($value.IpProtocol | Out-String).Trim()
                        'Traffic Flow' = "Egress"
                        }
                    $ec2SGDetails += New-Object PSObject -Property $SecDetails
                    }
                foreach ($entry in $value.UserIdGroupPairs){
                    $SecDetails = @{
                        'VPC ID' = $sg.VpcID
                        'SG ID' = $sg.GroupId
                        'SG Name' = $sg.GroupName
                        'SG Description' = $sg.Description
                        'From Port' = ($value.FromPort | out-string).Trim()
                        'To Port' = ($value.ToPort | out-string).Trim()
                        'IP Range' = ($entry.GroupId | out-string).Trim()
                        'IP Range Description' = ($entry.Description | out-string).Trim()
                        'Protocol' = ($value.IpProtocol | Out-String).Trim()
                        'Traffic Flow' = "Egress"
                        }
                    $ec2SGDetails += New-Object PSObject -Property $SecDetails
                    }
                }
            $EC2Match = $ec2Instances_all | Where {$_.securitygroups.GroupId | foreach { if ($_ -eq $sg.GroupId) { $_ }}}
            $RDSMatch = $rdsInstances_all | Where {$_.VpcSecurityGroups.VpcSecurityGroupId | foreach { if ($_ -eq $sg.GroupId) { $_ }}}
            $ELB_v1Match = $elbs_all_v1 | Where {$_.SecurityGroups | foreach { if ($_ -eq $sg.GroupId) { $_ }}}
            $ELB_v2Match = $elbs_all_v2 | Where {$_.SecurityGroups | foreach { if ($_ -eq $sg.GroupId) { $_ }}}
                
            if ($EC2Match -OR $RDSMatch -OR $ELB_v1Match -OR $ELB_v2Match) { $SGList.Add($sg.GroupId) }
                
            if ($EC2Match){
                foreach ($instance in $EC2Match){
                    $outputdetails = @{
                        'EC2 ID' = $instance.InstanceId
                        'EC2 Name' = ($instance.Tag | Where-Object { $_.key -ceq "Name" } | select -ExpandProperty Value);
                        'EC2 State' = $instance.State | select -ExpandProperty Name
                        'Type' = "EC2 Instance"
                        'SG ID' = $sg.GroupId
                        'SG Name' = $sg.GroupName
                        'SG Description' = ($sg.Description | out-string).Trim()
                        'SG Active?' = "True"
                        }
                    $ec2 += New-Object PSObject -Property $outputdetails 
                    }
                }
            else{
                $sgtemp = $sg.GroupId
                if (!($SGList.Contains($sgtemp))){
                    $ActiveStatus = "False"
                    $ec2SGDetails | where {$_.SecurityGroupRuleIPRange | foreach { if ($_ -eq $sgtemp) { $ActiveStatus = "True" }}}
                    $outputdetails = @{
                        'EC2 ID' = ""
                        'EC2 Name' = ""
                        'EC2 State' = ""
                        'Type' = ""
                        'SG ID' = $sg.GroupId
                        'SG Name' = $sg.GroupName
                        'SG Description' = $sg.Description
                        'SG Active?' = $ActiveStatus
                        }
                    $ec2 += New-Object PSObject -Property $outputdetails 
                        }
                }
                if ($RDSMatch){
                    foreach ($instance in $RDSMatch){
                        $outputdetails = @{
                            'RDS ID' = $instance.DbiResourceId
                            'RDS Name' = $instance.DBInstanceIdentifier
                            'RDS State' = $instance.DBInstanceStatus
                            'Type' = "RDS Instace"
                            'SG ID' = $sg.GroupId
                            'SG Name' = $sg.GroupName
                            'SG Description' = ($sg.Description | out-string).Trim()
                            'SG Active?' = "True"
                            }
                        $ec2 += New-Object PSObject -Property $outputdetails 
                            }
                    }
                if ($ELB_v1Match){
                    foreach ($instance in $ELB_v1Match){
                        $outputdetails = @{
                            'ELB ID' = ""
                            'ELB Name' = $instance.LoadBalancerName
                            'ELB State' = ""
                            'Type' = "ELB"
                            'SG ID' = $sg.GroupId
                            'SG Name' = $sg.GroupName
                            'SG Description' = ($sg.Description | out-string).Trim()
                            'SG Active?' = "True"
                            }
                        $ec2 += New-Object PSObject -Property $outputdetails 
                        }
                }
                if ($ELB_v2Match){
                    foreach ($instance in $ELB_v2Match){
                        $outputdetails = @{
                            'ELB V2 ID' = ""
                            'ELB V2 Name' = $instance.LoadBalancerName
                            'ELB V2 State' = $instance.State.Code
                            'Type' = ($instance.Type.Value | out-string).Trim() + " ELB V2"
                            'SG ID' = $sg.GroupId
                            'SG Name' = $sg.GroupName
                            'SG Description' = ($sg.Description | out-string).Trim()
                            'SG Active?' = "True"
                            }
                        $ec2 += New-Object PSObject -Property $outputdetails 
                        }
                }
            }
        $addtext = Write-Output "##### EC2 Security Group List #####" 
        $addtext | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append         
        $ec2 | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
        $ec2SGDetails | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
    }
#Function to collect associated EC2 Subnets
function list-ec2Subnets{
    $subnetlist = Get-EC2Subnet
    $ec2list = (Get-EC2Instance).Instances
    $output =@()
        foreach ($entry in $ec2list){
            $CurrentSubnet = $subnetlist | Where-Object {$_.SubnetId -eq $entry.SubnetId}
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'EC2 Name' = ($entry.tags | Where-Object -Property key -EQ 'Name').Value
                'EC2 ID' = $entry.InstanceId
                'EC2 Subnet' = $entry.SubnetId
                'Subnet Name' = $CurrentSubnet.Tag | Where-Object {($_.key -eq "Name")} | select -ExpandProperty Value
                'Availability Zone' = ($subnetlist | Where-Object -Property subnetid -EQ $entry.SubnetId).AvailabilityZone
                'State' = $CurrentSubnet.State
                'CIDR' = $CurrentSubnet.CidrBlock
                'Available Addresses' = $CurrentSubnet.AvailableIpAddressCount
                'Is default?' = $CurrentSubnet.DefaultForAz
                })
            $output += $out
        }
    Write-Output "##### EC2 Subnet List #####" 
    $output
}
#Function to collect associated EC2 Network ACLS
function list-ec2networkacls{
 #   $ec2NACL = Get-EC2NetworkAcl
 #   $ec2NACLEntries = (Get-EC2NetworkAcl).Entries
 #   $ec2Instnaces = (Get-EC2Instance).Instances
    $acls = @()
        foreach ($acl in Get-EC2NetworkAcl){
             foreach ($entry in $acl.Entries){
                $acloutput = New-Object -TypeName PSObject -Property ([ordered]@{ 
                    'Network ACL ID' = $acl.NetworkAclId
                    'VPC ID' = $acl.VpcId
                    'ACL CIDR BLOCK' = $entry.CidrBlock
                    'Is Egress?' = $entry.Egress
                    'Action' = $entry.RuleAction
                    'Rule Number' = $entry.RuleNumber
                })
            }
        $acls += $acloutput
        }
    Write-Output "##### EC2 NACL List #####" 
    $acls
}
#Function to collect associated EC2 VPC details
function list-vpc{
    $VPCS = Get-EC2Vpc
    Write-Output "##### VPC List #####"
        foreach ($VPC in $VPCS){
            New-Object PSObject -Property @{
            'VPC ID' = $VPC.VpcId
            'VPC Name' = ($VPC.Tags | Where-Object {$_.Key -eq 'Name'}).Value          
            'VPC State' = $VPC.VpcState
            'VPC Owner' = $VPC.OwnerId
            'CIDR Block' = $VPC.CidrBlock
            'Default VPC' = $VPC.IsDefault
        }
    }
}
#Function to collect associated InternetGateway details
function list-ec2internetgateway {
    $IGW = Get-EC2InternetGateway
    $igws =@()
        foreach ($i in $IGW){
            $igwoutput = New-Object -TypeName PSObject -Property ([ordered]@{
                'IGW Name' = ($i.Tag | Where-Object {$_.key -ceq "Name" } | select -ExpandProperty Value)
                'IGW ID' = $i.InternetGatewayId
                'VPC Attachment' = $i.Attachments
                })
        $igws += $igwoutput
    }
    Write-Output "##### Internet Gateway List #####" 
    $igws
}
#Function to collect associated NAT Gateway details
function list-ec2NGW{
    $ngws = @()
    $ElasticIPAddresses = Get-EC2Address
        foreach ($ngw in Get-EC2NatGateway){
            foreach ($a in $ngw.NatGatewayAddresses){
                $currentNGWAddress = $ElasticIPAddresses | Where-Object {$_.AllocationId -eq $a.AllocationId}
                $ngwoutput = New-Object -TypeName PSObject -Property ([ordered]@{
                    'NAT GW ID' = $ngw.NatGatewayId
                    'NAT GW Name' = ($ngw.Tags | Where-Object {$_.key -ceq "Name"} | select -ExpandProperty Value)
                    'NAT GW State' = $ngw.State
                    'NAT GW SubnetId' = $ngw.SubnetId
                    'NAT GW Public IP Address' = ($currentNGWAddress.PublicIp)
                    'NAT GW Private IP Address' = ($currentNGWAddress.PrivateIpAddress)
                })
        }
    $ngws += $ngwoutput
    }
    Write-Output "##### NAT Gateway with Elastic IP List #####" 
    $ngws
}
#Function to collect associated EC2 EBS Volume details
function list-ebsVolumes{
    $Volumes = Get-EC2Volume
    $output = @()
        foreach ($Volume in $Volumes){
            $ec2 = (Get-EC2Instance).Instances | Where-Object {$_.InstanceId -eq $Volume.Attachments.InstanceId}
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'EC2 Instance ID' = $ec2.InstanceId
                'EC2 Name' = ($ec2.tags | where-object -Property key -EQ 'Name').Value
                'EBS Volume ID' = $Volume.VolumeId
                'EBS Volume Name' = ($Volume.tags | where-object -Property key -EQ 'Name').Value
                'EBS Volume State' = $Volume.State
                'EBS Volume Size' = $Volume.Size
                'EBS Volume Type' = $Volume.VolumeType
                'IOPS' = $Volume.Iops
                'Is Encrypted' = $Volume.Encrypted
                'Creation Time' = $Volume.CreateTime
            })
        $output += $out
    }
    Write-Output "##### EBS Volume Information #####"
    $output 
}
#Function to collect associated Elastic Loadbalancer details
function list-elbclassic{
    $elbclassic = Get-ELBLoadBalancer
    $output = @()
        foreach ($elb in $elbclassic){
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'ELB Name' = $elb.LoadBalancerName
                'ELB DNS' = $elb.DNSName
                'ELB Scheme' = $elb.Scheme
                'ELB AZs' = ($elb.AvailabilityZones | out-string).Trim()
                'EC2 Instances' = $elb.Instances
                'Security Group' = $elb.SecurityGroups
                'Source Securigy Group' = $elb.SourceSecurityGroup.GroupName
                'Created Time' = $elb.CreatedTime
                'ELB Listener Port' = $elb.ListenerDescriptions.Listener.LoadBalancerPort
                'ELB Listener Protocol' = $elb.ListenerDescriptions.Listener.Protocol
                'EC2 Listener Port' = $elb.ListenerDescriptions.Listener.InstancePort
                'EC2 Listener Protocol' = $elb.ListenerDescriptions.Listener.InstanceProtocol
                'ELB SSL Certificate ID' = $elb.ListenerDescriptions.Listener.SSLCertificateId
            })
        $output += $out
    }
    Write-Output "##### ELB Classic Information #####"
    $output
}
#Function to collect associated Elastic Load Balancer V2 details (ALB or NLB)
function list-elb2{
    $elb2 = Get-ELB2Loadbalancer
    $output =@()
        foreach ($v2 in $elb2){
            $output += '##### ELB V2 Information #####'
            $lbarn = $v2.LoadBalancerArn
            $listener = (Get-ELB2Listener -LoadBalancerArn $lbarn)
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'ELB Name' = $v2.LoadbalancerName
                'Public DNS' = $v2.DNSName
                'IP Address Type' = $v2.IpAddressType
                'Availability Zones' = ($v2.AvailabilityZones | select -ExpandProperty ZoneName | out-string).Trim()
                'Subnets' = ($v2.AvailabilityZones | select -ExpandProperty SubnetId | out-string).Trim()
                'Security Groups' = $v2.SecurityGroups
                'Scheme'= $v2.Scheme
                'Type' = $v2.Type
                'VPC' = $v2.VpcId
                'Listener Port' = $listener.Port
                'Listener Protocol' = $listener.Protocol
                'Listener Default Actions' = $listener.DefaultActions.Type
                'Target Group' = $listener.DefaultActions.TargetGroupArn
            })
        $output += $out
        }
    $output
}
#Function to collect associated Elastic Loadbalancer V2 (ALB/NLB) Target Group details
function list-elb2targetgroup {
    $elb2 = Get-ELB2LoadBalancer
    $output =@()
        foreach ($v2 in $elb2) {
            $targetGroup = (Get-ELB2TargetGroup -LoadBalancerArn $v2.LoadBalancerArn)
               foreach ($tg in $targetGroup){
                    $output += "##### ELB Target Group Details #####"
                    $out = New-Object -TypeName PSObject -Property ([ordered]@{
                        'Target Group Name' = $tg.TargetGroupName
                        'Target Group Arn' = $tg.TargetGroupArn
                        'Target Group VPC' = $tg.VpcId
                        'Target Group Type' = $tg.TargetType
                        'Health Check Enabled' = $tg.HealthCheckEnabled
                        'Health Check Interval' = $tg.HealthCheckIntervalSeconds
                        'Health Check Path' = $tg.HealthCheckPath
                        'Health Check Threshold' = $tg.HealthyThresholdCount
                        'Health Check Protocol' = $tg.HealthCheckProtocol
                        'Health Check Port' = $tg.Port
                        'Health Check Matcher HTTP Code' = $tg.Matcher.HttpCode
                    })
                $output += $out
            }
        }
    $output
}
#Function to collect associated Autoscaling Group details (ASG)
function list-AutoScalingGroup {
    $AutoscalilngGroup = Get-ASAutoScalingGroup
    $output = @()
        foreach ($g in $AutoscalilngGroup){
            $output += "##### AutoScaling Information #####"
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'ASG Name' = $g.AutoScalingGroupName
                'ASG ARN' = $g.AutoScalingGroupARN
                'Launch Configuration' = $g.LaunchConfigurationName
                'ASG Availability Zones' = ($g.AvailabilityZones | out-string).Trim()
                'ASG Termination Policy' = $g.TerminationPolicies
                'ASG Subnets' = ($g.VPCZoneIdentifier | out-string).Trim()
                'Cool Down' = $g.DefaultCooldown
                'Grace Period' = $g.HealthCheckGracePeriod
                'Desired Capacity' = $g.DesiredCapacity
                'Min Size' = $g.MinSize
                'Max Size' = $g.MaxSize
                'Status' = $g.Status
                'Associated Instances' = $g.Instances        
                'Health Check Type' = $g.HealthCheckType
                'Associated ELBs' = $g.LoadBalancerNAmes
                'Associated Target Groups' = $g.TargetGroupARNs
                'Created Time' = $g.CreatedTime
            })
        $output += $out
    }
    $output
}
#Function to list associated S3 and S3 Bucket details
function list-s3details {
    $s3buckets = (Get-S3Bucket)
    $output = @()
        foreach ($b in $s3buckets){
            $output += "##### S3 Storage Details #####"
#            $s3acl = (Get-S3ACL -BucketName $b.BucketName)
#            $s3encryption = (Get-S3BucketEncryption -BucketName $b.BucketName)
            $s3version = (Get-S3BucketVersioning -BucketName $b.BucketName)
            $s3website = (Get-S3BucketWebsite -BucketName $b.BucketName)
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'S3 Bucket' = $b.BucketName
                'S3 Bucket Location' = (Get-S3BucketLocation -BucketName $b.BucketName)
                'S3 Bucket Policy' = (Get-S3BucketPolicy -BucketName $b.BucketName | out-string).Trim()
                'Versioning Status' = $s3version.Status
                'S3 Website active?' = If (($s3website).IndexDocumentSuffix) {'True'} else {'False'}
            })
        $output += $out
    }
    $output
}
#Function to collect associated RDS details
function list-RDSdetails {
    $rds = (Get-RDSDBInstance)
    $output = @()
        foreach ($db in $rds ){
            $output += "##### RDS DB Instance Information #####"
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'RDS DB Identifier' = $db.DBInstanceIdentifier
                'DB Name' = $db.DBName
                'DB Engine' = $db.Engine
                'Engine Version' = $db.EngineVersion
                'DB Instance Class' = $db.DBInstanceClass
                'Status' = $db.DBInstanceStatus
                'RDS Create Time' = $db.InstanceCreateTime
                'Accessible by Public' = $db.PubliclyAccessible
                'Storage Type' = $db.StorageType
                'Allocated Storage (GB)' = $db.AllocatedStorage
                'Allocated IOPS' = $db.IOPS
                'Max Storage' = $db.MaxAllocatedStorage
                'Storage Encrypted' = $db.StorageEncrypted
                'Multi AZ Enabled' = $db.MultiAZ
                'RDS VPC Id' = $db.DBSubnetGroup.VpcId
                'VPC Security Group Membership' = ($db.VpcSecurityGroups | out-string).Trim()
                'DB Subnet Group Name' = $db.DBSubnetGroup.DBSubnetGroupName
                'DB Subnets' = ($db.DBSubnetGroup.Subnets.SubnetIdentifier | out-string).Trim()
                'DB Subnet AZs' = ($db.DBSubnetGroup.Subnets.SubnetAvailabilityZone | out-string).Trim()
                'RDS Endpoint' = ($db.Endpoint | out-string).Trim()
                'Master Username' = $db.MasterUsername
            })
        $output += $out
        }
    $output
}
#Function to collect associated Aurora Cluster details
function list-AuroraDetails {
    $rdscluster = (Get-RDSDBCluster)
        $output = @()
            foreach ($db in $rdscluster ){
            $output += "##### RDS DB Cluster Information #####"
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'RDS Cluster Identifier' = $db.DBClusterIdentifier
                'Database Name' = if (!$db.DatabaseName) {'No DB Name Entered'} else {$db.DatabaseName}
                'Cluster Engine' = $db.Engine
                'Cluster Engine Mode' = $db.EngineMode
                'Engine Version' = $db.EngineVersion
                'Status' = $db.Status
                'Cluster Create Time' = $db.ClusterCreateTime
                'Storage Encrypted' = $db.StorageEncrypted
                'Multi AZ Enabled' = $db.MultiAZ
                'Cluster Subnet Group' = $db.DBSubnetGroup
                'VPC Security Group Membership' = ($db.VpcSecurityGroups | out-string).Trim()
                'Cluster Endpoint' = ($db.Endpoint | out-string).Trim()
                'Clulster Port' = $db.Port
                'Cluster Reader Endpoint' = $db.ReaderEndpoint
                'Read Replicas' = $db.ReadReplicaIdentifiers
                'Master Username' = $db.MasterUsername
                'HTTP Endpoint Enabled' = $db.HttpEndpointEnabled
                'IAM Authentication Enabled' = $db.IAMDatabaseAuthenticationEnabled
            })
        $output += $out
    }
    $output
}
#Function to collect associated CloudFront distrobution details
function list-cloudfrontdetails {
    $cfront = (Get-CFDistributionList)
    $output = @()
        foreach ($d in $cfront ){
            $output += "##### CloudFront Distribution Information #####"
            $out = New-Object -TypeName PSObject -Property ([ordered]@{
                'Distribution Id' = $d.Id
                'Domain Name' = $d.DomainName
                'Status' = $d.Status
                'Aliases' = ($d.Aliases.Items | out-string).Trim()
                'Enabled' = $d.Enabled
                'HTTP Version' =$d.HttpVersion
                'Origins' = $d.Origins.Items.Id
                'Origin Domain Name' = ($d.Origins.Items.DomainName | out-string).Trim()
                'Origin Path' = if (!$d.Origins.Items.OriginPath) {'Default'} else {$d.Origins.Items.OriginPath}
                'Price Class' = $d.PriceClass
                'Cache TTL' = $d.DefaultCacheBehavior.DefaultTTL
                'Cache Max TTL' = $d.DefaultCacheBehavior.MaxTTL
                'Cache Min TTL' = $d.DefaultCacheBehavior.MinTTL
                'Lambda Function Association' = ($d.DefaultCacheBehavior.LambdaFunctionAssociations.Items | out-string).Trim()
                'View Policy' = $d.DefaultCacheBehavior.ViewerProtocolPolicy
                'Last Modified' =$d.LastModifiedTime
                'Comments' = if (!$d.Comment) {'No Comments added'} else {$d.Comment}
            })
        $output += $out
        }
    $output
}
#Run each collection function in order and append to text file.
#This file type can be changed to CSV at a later time if needed or desired. *Note* Must also change list-ec2SecurityGroups output in function if changing to csv
filenaming
Write-Host "File path has been set to [$Global:Path]"
list-vpc | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
list-ec2 | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
list-ec2SecurityGroups #This is formatted in the function due to the multiple variable call and array storage
list-ec2Subnets | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
list-ec2networkacls | Format-Table -Property * -AutoSize | Out-String -Width 4096 | Out-file -FilePath "$Global:Path" -Append
list-ec2internetgateway | Format-Table -Property * -AutoSize | Out-string -Width 4096 | Out-File -FilePath "$Global:Path" -Append
list-ec2NGW | Format-Table -Property * -AutoSize | Out-string -Width 4096 | Out-File -FilePath "$Global:Path" -Append
list-ebsVolumes | Format-Table -Property * -AutoSize | Out-string -Width 4096 | Out-File -FilePath "$Global:Path" -Append
list-elbclassic | Format-List | Out-string -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-elb2 | Format-List -GroupBy 'ELB Name' | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-elb2targetgroup | Format-List -GroupBy 'Target Group Name' | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-AutoScalingGroup | Format-List -GroupBy 'ASG Name' | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-s3details | Format-List -GroupBy 'S3 Bucket' | out-string -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-cloudfrontdetails | Format-List -GroupBy "Distribution Id" | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-RDSdetails | Format-List -GroupBy "RDS DB Identifier" | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append
list-AuroraDetails | Format-List -GroupBy "RDS Cluster Identifier" | Out-String -Width 8192 | Out-File -FilePath "$Global:Path" -Append

Write-Host "##### Script completed, Please review [$Global:Path] for collected details." -ForegroundColor Green
Write-Host "##### Removing stored AWS credentials for RunCollection" -ForegroundColor Yellow
Remove-AWSCredentialProfile -ProfileName "RunCollection" -Force
