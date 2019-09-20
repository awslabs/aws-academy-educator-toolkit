## awless_dump

Simple BASH wrapper for awless and aws cli tools to generate a human readable dump of common resources in an AWS account.

The tool could be run by students in their labs and the output submitted to the educator to evaluate their work.

### Example

```bash
$  ./awless_dump.sh -r ap-southeast-1

Time and Date: Fri 20 Sep 2019 10:57:06 AEST

User and Account:
Username: XXX, ID: XXX, Account: XXX


Attached policies (i.e. managed):
        - AWSCodeCommitFullAccess
        - IAMUserChangePassword

Inlined policies: none

Region: ap-southeast-1


=== VPCs ===

|     ID ▲     | NAME | DEFAULT |   STATE   |     CIDR      |
|--------------|------|---------|-----------|---------------|
| vpc-ba391cdd |      | true    | available | 172.31.0.0/16 |

=== SUBNETS ===

|       ID        | NAME |     CIDR ▲     |      ZONE       | DEFAULT |     VPC      | PUBLIC |   STATE   |
|-----------------|------|----------------|-----------------|---------|--------------|--------|-----------|
| subnet-2a1dd873 |      | 172.31.0.0/20  | ap-southeast-1c | true    | vpc-ba391cdd | true   | available |
| subnet-86939de1 |      | 172.31.16.0/20 | ap-southeast-1a | true    | vpc-ba391cdd | true   | available |
| subnet-681c2221 |      | 172.31.32.0/20 | ap-southeast-1b | true    | vpc-ba391cdd | true   | available |

=== Internet Gateways ===

|     ID ▲     | NAME |      VPCS      |
|--------------|------|----------------|
| igw-3c6c2958 |      | [vpc-ba391cdd] |

=== NAT Gateway ===

No results found.

=== Route Tables ===

|     ID ▲     | NAME |     VPC      | DEFAULT |             ROUTES             |    ASSOCIATIONS    |
|--------------|------|--------------|---------|--------------------------------|--------------------|
| rtb-2e62cb48 |      | vpc-ba391cdd | true    | 172.31.0.0/16->gw:local        | rtbassoc-2f74ac56: |
|              |      |              |         | 0.0.0.0/0->gw:igw-3c6c2958     |                    |

=== Security Groups ===

|    ID ▲     |     VPC      |       INBOUND       |     OUTBOUND      |  NAME   |        DESCRIPTION         |
|-------------|--------------|---------------------|-------------------|---------|----------------------------|
| sg-c6ac20be | vpc-ba391cdd | [sg-c6ac20be](any)  | [0.0.0.0/0](any)  | default | default VPC security group |

=== Elastic IPs ===

No results found.
```

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
