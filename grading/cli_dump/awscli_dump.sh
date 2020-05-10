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


COLOR=false
DEBUG=false
REGION=ap-southeast-2
RUN=true
VPC=
VPC_FILTER=
OUTPUT="--output table"
INSTALL_LINUX=false
INSTALL_MACOSX=false
prog=`basename $0`

_usage()
{
    echo "Usage: $prog [-cdhjnt] [-r region] [-v vpc]"
    echo ""
    echo "-c         Add color to output"
    echo "-d         Debug output"
    echo "-h         Usage"
    echo "-j         Output in json"
    echo "-n         Dummy run, do nothing"
    echo "-r region  Specify AWS region"
    echo "-t         Output in text"
    echo "-v vpc     Limit resources to this vpc"
    echo "-y         Output in YAML(*)"
    echo ""
    echo "(*) Requires AWS CLI v2"
    exit 1
}

while getopts "cdhjnr:tv:y" arg; do
  case ${arg} in
    c)
        COLOR=true
        ;;
    d)
        DEBUG=true
        ;;
    h)
        _usage
        ;;
    j)
        OUTPUT="--output json"
        ;;
    n)
        RUN=false
        ;;
    r)
        REGION=${OPTARG}
        ;;
    t)
        OUTPUT="--output text"
        ;;
    v)
        VPC=${OPTARG}
        VPC_FILTER="--filter Name=vpc-id,Values=${OPTARG}"
        ;;
    y)
        OUTPUT="--output yaml"
        ;;
    *)
        exit 1
  esac
done
shift $((OPTIND-1))

# Define colur using the terminal color settings
if $COLOR; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    AQUA=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    NONE=$(tput sgr0)
else
    RED=
    GREEN=
    YELLOW=
    BLUE=
    PURPLE=
    AQUA=
    WHITE=
    NONE=
fi

HEADER=${PURPLE}
KEY=${AQUA}
VERBOSE=${YELLOW}

# If VPC specified check it exists
if [ ! -z "$VPC" ]; then
    CHECK_VPC=$(aws ec2 describe-vpcs $VPC_FILTER --query 'Vpcs[*].{ID:VpcId}' --output text)
    if [ -z "$CHECK_VPC" ]; then
        echo "Error: VPC ($VPC) does not exist"
        exit 1
    fi
fi

function run() {
    $DEBUG && echo "${VERBOSE}"$@"${NONE}"
    $RUN && "$@"
}

function always() {
    $DEBUG && echo "${VERBOSE}"$@"${NONE}"
    "$@"
}

# Whoami
echo ""
echo "${HEADER}User:${NONE}"
run aws sts get-caller-identity \
    $OUTPUT \
    --query '{Account:Account, User:Arn}'

# Region
echo ""
echo "${HEADER}AWS Region:${NONE}"
run aws ec2 describe-availability-zones \
    --output text \
    --query 'AvailabilityZones[0].{Region:GroupName}'

# VPCs
echo ""
echo "${HEADER}VPCs:${NONE}"
run aws ec2 describe-vpcs \
    $VPC_FILTER \
    $OUTPUT \
    --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,Default:IsDefault,Name:Tags[?Key == `Name`] | [0].Value}'

# Subnets
SUBNET_QUERY="Subnets[*].{AZ:AvailabilityZone,CIDR:CidrBlock,MapPublicIP:MapPublicIpOnLaunch"
if [ -z "$VPC" ]; then
    SUBNET_QUERY="${SUBNET_QUERY},VPC:VpcId"
fi
SUBNET_QUERY="${SUBNET_QUERY},Name:Tags[?Key == "'`Name`'"] | [0].Value}"

echo ""
echo "${HEADER}Subnets:${NONE}"
run aws ec2 describe-subnets \
    $VPC_FILTER \
    $OUTPUT \
    --query "$SUBNET_QUERY"

# Route Tables
echo ""
echo "${HEADER}Main Route Table:${NONE}"
if [ -z "$VPC" ]; then
    ROUTE_FILTER="--filter Name=association.main,Values=true"
    ROUTE_QUERY="RouteTables[*].{RouteTable:RouteTableId,VPC:VpcId}"
    ROUTE_OUTPUT="$OUTPUT"
else
    ROUTE_FILTER="${VPC_FILTER} Name=association.main,Values=true"
    ROUTE_QUERY="RouteTables[*].RouteTableId"
    ROUTE_OUTPUT="--output text"
fi

run aws ec2 describe-route-tables \
    $ROUTE_FILTER \
    $ROUTE_OUTPUT \
    --query "$ROUTE_QUERY"

echo ""
echo "${HEADER}Other Route Tables:${NONE}"
if [ -z "$VPC" ]; then
    ROUTE_FILTER="--filter Name=association.main,Values=false"
    ROUTE_QUERY="RouteTables[*].{RouteTable:RouteTableId,VPC:VpcId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
else
    ROUTE_FILTER="${VPC_FILTER} Name=association.main,Values=false"
    ROUTE_QUERY="RouteTables[*].{RouteTable:RouteTableId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
fi

run aws ec2 describe-route-tables \
    $ROUTE_FILTER \
    $OUTPUT \
    --query "$ROUTE_QUERY"

echo ""
echo "${HEADER}Routes:${NONE}"
ROUTE_TABLES=$(aws ec2 describe-route-tables $VPC_FILTER --query 'RouteTables[*].RouteTableId' --output text)
for t in $ROUTE_TABLES; do
    echo ""
    echo "${HEADER}Route Table $t:${NONE}"
    run aws ec2 describe-route-tables \
        $OUTPUT \
        --route-table-ids $t \
        --query 'RouteTables[].{Associations:Associations[].{Subnet:SubnetId},Routes:Routes[?State== `active`].{Destination:DestinationCidrBlock,GateWay:GatewayId},Name:Tags[?Key == `Name`] | [0].Value}'
done

# NACLS
echo ""
echo "${HEADER}NACLs:${NONE}"
run aws ec2 describe-network-acls \
    $VPC_FILTER \
    $OUTPUT \
    --query 'NetworkAcls[*].{Subnets:Associations[*].SubnetId,ID:NetworkAclId,Ingress:Entries[?Egress == `false`],Egress:Entries[?Egress == `true`],Name:Tags[?Key == `Name`] | [0].Value}' --output table 
