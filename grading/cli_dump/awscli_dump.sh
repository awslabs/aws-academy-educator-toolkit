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

COLOR=false
DEBUG=false
REGION=ap-southeast-2
RUN=true
VPC=
VPC_FILTER=
IGW_FILTER=
OUTPUT="--output table"
PAGER=
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

while getopts "cdhjnpr:tv:y" arg; do
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
    p)
        PAGER=less
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
        IGW_FILTER="--filter Name=attachment.vpc-id,Values=${OPTARG}"
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

export AWS_PAGER=$PAGER


function run() {
    $DEBUG && echo "${VERBOSE}"$@"${NONE}"
    $RUN && "$@"
}

function always() {
    $DEBUG && echo "${VERBOSE}"$@"${NONE}"
    "$@"
}

# Whoami and check credentials
echo ""
echo "${HEADER}User:${NONE}"
run aws sts get-caller-identity \
    $OUTPUT \
    --query '{Account:Account, User:Arn}'
if [[ ! $? ]]; then
    echo "$0: Credentials may not be valid ($?)"
    exit 1
fi

# If VPC specified check it exists
if [[ ! -z "$VPC" ]]; then
    CHECK_VPC=$(aws ec2 describe-vpcs $VPC_FILTER --query 'Vpcs[*].{ID:VpcId}' --output text)
    if [ -z "$CHECK_VPC" ]; then
        echo "Error: VPC ($VPC) does not exist"
        exit 1
    fi
fi

# Region
echo ""
echo "${HEADER}AWS Region:${NONE}"
run aws ec2 describe-availability-zones \
    $OUTPUT \
    --query '{Region:AvailabilityZones[0].{Region:GroupName}}'

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
else
    ROUTE_FILTER="${VPC_FILTER} Name=association.main,Values=true"
    ROUTE_QUERY="{RouteTable:RouteTables[*].RouteTableId}"
fi

run aws ec2 describe-route-tables \
    $ROUTE_FILTER \
    $OUTPUT \
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

# Internet Gateways
echo ""
echo "${HEADER}Internet Gateways:${NONE}"

if [ -z "$VPC" ]; then
    IGW_QUERY="InternetGateways[*].{ID:InternetGatewayId,VPC:Attachments.VpcId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
else
    IGW_QUERY="InternetGateways[*].{ID:InternetGatewayId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
fi

run aws ec2 describe-internet-gateways \
    $IGW_FILTER \
    $OUTPUT \
    --query "$IGW_QUERY"

# NAT Gateways
echo ""
echo "${HEADER}NAT Gateways:${NONE}"

if [ -z "$VPC" ]; then
    NGW_QUERY="NatGateways[*].{ID:NatGatewayId,VPC:VpcId,Subnet:SubnetId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
else
    NGW_QUERY="NatGateways[*].{ID:NatGatewayId,Subnet:SubnetId,Name:Tags[?Key == "'`Name`'"] | [0].Value}"
fi

run aws ec2 describe-nat-gateways \
    $VPC_FILTER \
    $OUTPUT \
    --query "$NGW_QUERY"

# Security Groups
echo ""
echo "${HEADER}Security Groups:${NONE}"
run aws ec2 describe-security-groups \
    $VPC_FILTER \
    $OUTPUT \
    --query 'SecurityGroups[*].{Name:GroupName,ID:GroupId}'

SGRPS=$(aws ec2 describe-security-groups $VPC_FILTER --query 'SecurityGroups[*].GroupId' --output text)

if [ -z "$VPC" ]; then
    SGRP_QUERY="SecurityGroups[*].{VPC:VpcId,Name:GroupName,Description:Description,ID:GroupId,Ingress:IpPermissions[].{From:FromPort,To:ToPort,Protocol:IpProtocol,CIDR:IpRanges[].CidrIp,Group:UserIdGroupPairs[].GroupId},Egress:IpPermissionsEgress[].{From:FromPort,To:ToPort,Protocol:IpProtocol,CIDR:IpRanges[].CidrIp,Group:UserIdGroupPairs[].GroupId}}"
else
    SGRP_QUERY="SecurityGroups[*].{Name:GroupName,Description:Description,ID:GroupId,Ingress:IpPermissions[].{From:FromPort,To:ToPort,Protocol:IpProtocol,CIDR:IpRanges[].CidrIp,Group:UserIdGroupPairs[].GroupId},Egress:IpPermissionsEgress[].{From:FromPort,To:ToPort,Protocol:IpProtocol,CIDR:IpRanges[].CidrIp,Group:UserIdGroupPairs[].GroupId}}"
fi

for s in $SGRPS; do
    echo ""
    echo "${HEADER}Security Group $s:${NONE}"
    run aws ec2 describe-security-groups \
        $OUTPUT \
        --group-ids $s \
        --query "$SGRP_QUERY"
done

# Key Pairs
echo ""
echo "${HEADER}Key Pairs:${NONE}"

run aws ec2 describe-key-pairs \
    $OUTPUT \
    --query 'KeyPairs[*].{ID:KeyPairId,Name:KeyName}'

# Load Balancers
echo ""
echo "${HEADER}Classic Load Balancers:${NONE}"
echo "TODO"

echo ""
echo "${HEADER}Load Balancers:${NONE}"

if [[ -z "$VPC" ]]; then
    ELB_SUMMARY="LoadBalancers[*].{Name:LoadBalancerName,Type:Type,Arn:LoadBalancerArn}"
    ELB_QUERY="LoadBalancers[*].{VPC:VpcId,Scheme:Scheme,Type:Type,SecurityGroups:SecurityGroups,AZs:AvailabilityZones[*].{Zone:ZoneName,Subnet:SubnetId},Name:LoadBalancerName,DNS:DNSName}"
    ELB_LIST="LoadBalancers[*].LoadBalancerArn"
else
    ELB_SUMMARY="LoadBalancers[?VpcId == "'`'$VPC'`'"].{Name:LoadBalancerName,Type:Type,Arn:LoadBalancerArn}"
    ELB_QUERY="LoadBalancers[*].{Scheme:Scheme,Type:Type,SecurityGroups:SecurityGroups,AZs:AvailabilityZones[*].{Zone:ZoneName,Subnet:SubnetId},Name:LoadBalancerName,DNS:DNSName}"
    ELB_LIST="LoadBalancers[?VpcId == "'`'$VPC'`'"].LoadBalancerArn"
fi

always aws elbv2 describe-load-balancers \
    $OUTPUT \
    --query "$ELB_SUMMARY"

#run aws elbv2 describe-load-balancers \
#    $OUTPUT \
#    --query "$ELB_QUERY"

ELBS=$(aws elbv2 describe-load-balancers --output text --query "$ELB_LIST")

for lb in $ELBS; do
    echo ""
    echo "${HEADER}Load Balancers $lb:${NONE}"
    always aws elbv2 describe-load-balancers \
    --load-balancer-arn $lb \
    $OUTPUT \
    --query "$ELB_QUERY"
    echo ""
    always aws elbv2 describe-listeners \
        --load-balancer-arn $lb \
        $OUTPUT \
        --query 'Listeners[*].{Port:Port,Protocol:Protocol,Actions:DefaultActions[*].{Type:Type,TargetGroup:TargetGroupArn}}'
done