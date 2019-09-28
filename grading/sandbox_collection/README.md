## sandbox_collection

This script is intended to be used with the Access Key, Secret Key, and Session token from the AWS Academy labs. The script pulls in information about resources deployed in the sandbox environment in a human, readable format. Each resource collection is handled by an independent function and can be disabled by commenting the outpt line at the end of the script.

## How To
Launch Powershell.exe, set ExecutionPolicy to Unrestricted for the scope of the process (PowerShell Window)
1. Open Powershell
2. Run the following command: Set-ExecutionPolicy Unrestricted -Scope Process -Force
3. Navigate to the location where the PowerShell script is saved (Ex. C:\Temp)
4. Execute the PowerShell script: .\SandboxCollectionTool.ps1

### Example

```ps
C:\Temp\SandboxCollectionTool.ps1

Sandbox Collection Tool - v2
Enter AWS Access Key: ********************
System.Security.SecureString
Enter AWS Secret Key: ****************************************
System.Security.SecureString
Enter Session Key: ************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************
System.Security.SecureString
Enter Region to run the script against (Default = us-east-1):: us-east-1
The region you enterd is [us-east-1]
us-east-1
Your Region is set to: [us-east-1]
AWS Powershell access has been granted
File path has been set to [C:\Temp\Collection24-09-2019.txt]
##### Script completed, Please review [C:\Temp\Collection24-09-2019.txt] for collected details.
##### Removing stored AWS credentials for RunCollection
```

### Example: Contents of generated file

```ps
##### VPC List #####

CIDR Block    VPC Owner    VPC Name      VPC State Default VPC VPC ID               
----------    ---------    --------      --------- ----------- ------               
10.0.0.0/16   554119769727 RunCollection available       False vpc-06acc09b0dac30cd4
172.31.0.0/16 554119769727               available        True vpc-05a015107becca777

##### EC2 Instance List #####

Subnet IDs               Launch Time          VPC                   Network Interface            Instance Type EC2 Name           Public DNS Name                           Platfrom Instance ID         Public IP Address Attached Security Groups
----------               -----------          ---                   -----------------            ------------- --------           ---------------                           -------- -----------         ----------------- ------------------------
subnet-0952d3d779a289cf9 9/23/2019 3:43:52 PM vpc-06acc09b0dac30cd4 {ip-10-0-1-47.ec2.internal}  t2.micro      RunCollection-Test ec2-34-205-39-116.compute-1.amazonaws.com          i-0580b0ebb93326e72 34.205.39.116     {RunCollection Test}    
subnet-0952d3d779a289cf9 9/23/2019 3:43:52 PM vpc-06acc09b0dac30cd4 {ip-10-0-1-214.ec2.internal} t2.micro      RunCollection-Test ec2-3-219-217-31.compute-1.amazonaws.com           i-0061659474db76b2b 3.219.217.31      {RunCollection Test}    
subnet-0952d3d779a289cf9 9/23/2019 3:43:52 PM vpc-06acc09b0dac30cd4 {ip-10-0-1-104.ec2.internal} t2.micro      RunCollection-Test ec2-3-218-152-251.compute-1.amazonaws.com          i-06dd397a40ccb8991 3.218.152.251     {RunCollection Test}    

##### EC2 Security Group List #####

SG Active? EC2 ID              SG Name            Type         SG ID                SG Description             EC2 State EC2 Name          
---------- ------              -------            ----         -----                --------------             --------- --------          
False                          default                         sg-044d71cbf90f790b8 default VPC security group                             
False                          default                         sg-06de20b530e4ef957 default VPC security group                             
True       i-0580b0ebb93326e72 RunCollection Test EC2 Instance sg-0f06bbaeed4815a61 Run Collection Test SG     running   RunCollection-Test
True       i-0061659474db76b2b RunCollection Test EC2 Instance sg-0f06bbaeed4815a61 Run Collection Test SG     running   RunCollection-Test
True       i-06dd397a40ccb8991 RunCollection Test EC2 Instance sg-0f06bbaeed4815a61 Run Collection Test SG     running   RunCollection-Test

From Port IP Range             SG Description             Traffic Flow VPC ID                SG Name            SG ID                IP Range Description To Port Protocol
--------- --------             --------------             ------------ ------                -------            -----                -------------------- ------- --------
0         sg-044d71cbf90f790b8 default VPC security group Ingress      vpc-06acc09b0dac30cd4 default            sg-044d71cbf90f790b8                      0       -1      
0         0.0.0.0/0            default VPC security group Egress       vpc-06acc09b0dac30cd4 default            sg-044d71cbf90f790b8                      0       -1      
0         sg-06de20b530e4ef957 default VPC security group Ingress      vpc-05a015107becca777 default            sg-06de20b530e4ef957                      0       -1      
0         0.0.0.0/0            default VPC security group Egress       vpc-05a015107becca777 default            sg-06de20b530e4ef957                      0       -1      
22        0.0.0.0/0            Run Collection Test SG     Ingress      vpc-06acc09b0dac30cd4 RunCollection Test sg-0f06bbaeed4815a61                      22      tcp     
0         0.0.0.0/0            Run Collection Test SG     Egress       vpc-06acc09b0dac30cd4 RunCollection Test sg-0f06bbaeed4815a61                      0       -1      

##### EC2 Subnet List #####

EC2 Name           EC2 ID              EC2 Subnet               Subnet Name    Availability Zone State     CIDR        Available Addresses Is default?
--------           ------              ----------               -----------    ----------------- -----     ----        ------------------- -----------
RunCollection-Test i-0580b0ebb93326e72 subnet-0952d3d779a289cf9 Private subnet us-east-1b        available 10.0.1.0/24                 248       False
RunCollection-Test i-0061659474db76b2b subnet-0952d3d779a289cf9 Private subnet us-east-1b        available 10.0.1.0/24                 248       False
RunCollection-Test i-06dd397a40ccb8991 subnet-0952d3d779a289cf9 Private subnet us-east-1b        available 10.0.1.0/24                 248       False

##### EC2 NACL List #####

Network ACL ID        VPC ID                ACL CIDR BLOCK Is Egress? Action Rule Number
--------------        ------                -------------- ---------- ------ -----------
acl-01429a39bf7a89dbc vpc-06acc09b0dac30cd4 0.0.0.0/0           False deny         32767
acl-0414e2cfa7bfa53d1 vpc-05a015107becca777 0.0.0.0/0           False deny         32767

##### Internet Gateway List #####

IGW Name IGW ID                VPC Attachment         
-------- ------                --------------         
         igw-077472b24561cf9c3 {}                     
         igw-0a0332cc5a8545fd5 {vpc-06acc09b0dac30cd4}
         igw-0b13c548f4e6088b5 {vpc-05a015107becca777}

##### NAT Gateway with Elastic IP List #####

NAT GW ID             NAT GW Name NAT GW State NAT GW SubnetId          NAT GW Public IP Address NAT GW Private IP Address
---------             ----------- ------------ ---------------          ------------------------ -------------------------
nat-0daad37cd38370a65             available    subnet-0aa857e59e7a99b78 3.230.92.220             10.0.0.141               

##### EBS Volume Information #####

EC2 Instance ID     EC2 Name           EBS Volume ID         EBS Volume Name    EBS Volume State EBS Volume Size EBS Volume Type IOPS Is Encrypted Creation Time       
---------------     --------           -------------         ---------------    ---------------- --------------- --------------- ---- ------------ -------------       
i-06dd397a40ccb8991 RunCollection-Test vol-06d6e7af84d8d6e75 RunCollection-Test in-use                         8 gp2              100        False 9/23/2019 3:43:52 PM
i-0061659474db76b2b RunCollection-Test vol-0fb89a84cfa9b1144 RunCollection-Test in-use                         8 gp2              100        False 9/23/2019 3:43:53 PM
i-0580b0ebb93326e72 RunCollection-Test vol-0e80c45ad03c8b3c3 RunCollection-Test in-use                         8 gp2              100        False 9/23/2019 3:43:52 PM
```

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
