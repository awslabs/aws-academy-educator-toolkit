#!/bin/bash

# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.

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

# Wrapper around awless to list common resources in an AWS account.
# See https://github.com/wallix/awless/wiki/Installation.
#
# Uses AWS CLI for CloudTrail as this is not supported by awless at this time.


REGION=ap-southeast-2
VPC=
VPC_FILTER=
OUTPUT=table
INSTALL_LINUX=false
INSTALL_MACOSX=false
prog=`basename $0`

_usage()
{
    echo "Usage: $prog [-hjlmt] [-r region] [-v vpc]"
    echo ""
    echo "-h         Usage"
    echo "-j         Output in json"
    echo "-l         Install awless on Linux"
    echo "-m         Install awless on MacOSX"
    echo "-r region  Specify AWS region"
    echo "-t         Output in text"
    echo "-v vpc     Limit resources to this vpc"
    exit 1
}

while getopts "hjlmr:tv:" arg; do
  case ${arg} in
    h)
        _usage
        ;;
    j)
        OUTPUT=json
        ;;
    l)
        INSTALL_LINUX=true
        ;;
    m)
        INSTALL_MACOSX=true
        ;;
    r)
        REGION=${OPTARG}
        ;;
    t)
        OUTPUT=text
        ;;
    v)
      VPC=${OPTARG}
      VPC_FILTER="Name=vpc-id,Values=${OPTARG}"
      ;;
  esac
done
shift $((OPTIND-1))

_gen_less_filter()
{
    if [ "X$VPC" != "X" ]; then
        echo "--filter ${1}=${VPC}"
    fi
}

if $INSTALL_LINUX; then
    curl https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash
fi

if $INSTALL_MACOSX; then
    brew tap wallix/awless; brew install awless
fi

which awless 2>&1 >/dev/null
if [ $? -ne 0 ]; then
    cat << EOF
$prog: awless not found in path

Use -l or -m options to install on Linux or MacOSX.

See https://github.com/wallix/awless/wiki/Installation for more information.
EOF
    exit 1
fi

which aws 2>&1 >/dev/null
if [ $? -ne 0 ]; then
    cat << EOF
$prog: aws not found in path

See https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html for installation instructions.
EOF
    exit 1
fi

echo ""
echo "Time and Date: "`date`
echo ""
echo "User and Account: "

if $LESS; then 
    awless whoami
else
    aws sts get-caller-identity --output $OUTPUT
fi

if [ $? -ne 0 ]; then
    echo "Check your AWS credentials with 'aws configure'"
    exit 1
fi

echo ""
echo "Region: $REGION"
echo ""

AWLESS="awless --aws-region $REGION"
AWS="aws --region $REGION --output $OUTPUT"

echo ""
if [ "X$VPC" != "X" ]; then
    echo "=== VPC: $VPC ==="
else
    echo "=== VPCs ==="
fi
echo ""

$AWLESS list vpcs \
`_gen_less_filter id`

echo ""
echo "=== SUBNETS ==="
echo ""

$AWLESS list subnets \
`_gen_less_filter vpc` \
--sort CIDR

echo ""
echo "=== Internet Gateways ==="
echo ""

$AWLESS list internetgateways \
`_gen_less_filter vpcs`

echo ""
echo "=== NAT Gateway ==="
echo ""

$AWLESS list natgateways \
`_gen_less_filter vpc`

echo ""
echo "=== Route Tables ==="
echo ""

$AWLESS list routetables \
`_gen_less_filter vpc`

echo ""
echo "=== Security Groups ==="
echo ""

$AWLESS list securitygroups \
`_gen_less_filter vpc`

echo ""
echo "=== Elastic IPs ==="
echo ""

$AWLESS list elasticips

echo ""
echo "=== Load Balancers ==="
echo ""

$AWLESS list loadbalancers \
`_gen_less_filter vpc`

echo ""
echo "=== Listeners ==="
echo ""

$AWLESS list listeners

echo ""
echo "=== Target Groups ==="
echo ""

$AWLESS list targetgroups \
`_gen_less_filter vpc`

echo ""
echo "=== Launch Configurations ==="
echo ""

$AWLESS list launchconfigurations

echo ""
echo "=== Auto Scaling Groups ==="
echo ""

$AWLESS list scalinggroups

echo ""
echo "=== Database Subnet Groups ==="
echo ""

$AWLESS list dbsubnetgroups \
`_gen_less_filter vpc`

echo ""
echo "=== Databases ==="
echo ""

$AWLESS list databases

echo ""
echo "=== Route53 Zones ==="
echo ""

$AWLESS list zones

echo ""
echo "=== Route53 Records ==="
echo ""

$AWLESS list records

echo ""
echo "=== CloudTrail ==="
echo ""

$AWS cloudtrail describe-trails \
--query 'trailList[*].{Name:Name,Bucket:S3BucketName}'
 
echo ""
echo "=== S3 Buckets ==="
echo ""

$AWLESS list buckets \
--sort CREATED
 
