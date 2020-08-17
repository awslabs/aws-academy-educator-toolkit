## cli_dump

Simple BASH wrapper for aws cli to generate a human readable dump of common resources in an AWS account.

The tool could be run by students in their labs and the output submitted to the educator to evaluate their work.

This tool works with both AWS CLI v1 and v2, with v2 you can use the `-y` option to generate YAML. By default the tool outputs tables.

### Example

```bash
$ ./cli_dump.sh -h
Usage: cli_dump.sh [-cdhjnt] [-r region] [-v vpc]
 
-c         Add color to output
-d         Debug output
-h         Usage
-j         Output in json
-n         Dummy run, do nothing
-r region  Specify AWS region
-t         Output in text
-v vpc     Limit resources to this vpc
-V         List VPCs and terminate
-y         Output in YAML(*)
 
(*) Requires AWS CLI v2

$ ./cli_dump.sh -d -r us-east-1 -v vpc-0179f1c66181a4120
 
User:
aws sts get-caller-identity --output table --query {Account:Account, User:Arn}
-----------------------------------------------------------------------------------------------
|                                      GetCallerIdentity                                      |
+--------------+------------------------------------------------------------------------------+
|    Account   |                                    User                                      |
+--------------+------------------------------------------------------------------------------+
|  123456789012|  arn:aws:sts::123456789012:assumed-role/user                         |
+--------------+------------------------------------------------------------------------------+
 
AWS Region:
aws ec2 describe-availability-zones --output table --query {Region:AvailabilityZones[0].{Region:GroupName}}
---------------------------
|DescribeAvailabilityZones|
+-------------------------+
||        Region         ||
|+---------+-------------+|
||  Region |  us-east-1  ||
|+---------+-------------+|
 
VPCs:
aws ec2 describe-vpcs --filter Name=vpc-id,Values=vpc-0179f1c66181a4120 --output table --query Vpcs[*].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault,Name:Tags[?Key == `Name`] | [0].Value}
----------------------------------------------------------------
|                         DescribeVpcs                         |
+-------------+----------+-------------------------+-----------+
|    CIDR     | Default  |           ID            |   Name    |
+-------------+----------+-------------------------+-----------+
|  10.0.0.0/16|  False   |  vpc-0179f1c66181a4120  |  Lab VPC  |
+-------------+----------+-------------------------+-----------+
 
Subnets:
aws ec2 describe-subnets --filter Name=vpc-id,Values=vpc-0179f1c66181a4120 --output table --query Subnets[*].{AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIP:MapPublicIpOnLaunch,Name:Tags[?Key == `Name`] | [0].Value}
------------------------------------------------------------------
|                         DescribeSubnets                        |
+------------+--------------+--------------+---------------------+
|     AZ     |    CIDR      | MapPublicIP  |        Name         |
+------------+--------------+--------------+---------------------+
|  us-east-1a|  10.0.1.0/24 |  False       |  Private Subnet 1   |
|  us-east-1b|  10.0.3.0/24 |  False       |  Private Subnet 2   |
|  us-east-1b|  10.0.2.0/24 |  True        |  Public Subnet 2    |
|  us-east-1a|  10.0.0.0/24 |  True        |  Public Subnet 1    |
+------------+--------------+--------------+---------------------+
.
.
.
```

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
