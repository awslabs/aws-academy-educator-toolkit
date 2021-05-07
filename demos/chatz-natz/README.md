## chatz-natz

Cloudformation template that launches a simple NAT instance for use in long running labs.

NAT Gateways are an important component in most VPC networks providing private hosts with a route to the internet without the need for a public IP address. This template can be used by students to provide NAT functionality in their networks whicle solving two problems:
* In labs that do not permit NAT Gateways (AWS Educate Classrooms).
* In long running labs NAT Gateways are expensive and cannot be stopped, costing ~USD$33 per month (us-east-1). They can therefore consume a large proportion of the available credits in AWS Academy Capstone Project and Learner Lab environments. The NAT instance if left running 24x7 will cost about ~USD$8.50 (if configured as a t2.micro) and can be easily stopped and restarted to further reduce costs.

### Installation

After the student has created their VPC, subnets and route tables, they can
* Run this cloudformation template in that region specifying their network paramters (defined below)
  * Educate classroom: [chatz-natz-educate.yaml](./chatz-natz-educate.yaml)
  * Other environments that support SSM parameter store: [chatz-natz.yaml](./chatz-natz.yaml)
* Copy the elastic network interface (ENI) for the NAT instance is listed in the template output.
* Update the private route table route to the internet to use the ENI listed in the template.

### Parameters

The cloudformation template requires

* The VPC ID
* The public subnet for the NAT instance
* The CIDR range of private subnets or the CIDR range of the VPC
  * Default is the whole VPC with 10.0.0.0/16
* The EC2 instance type for the NAT instance
  * Default is t2.micro
* Which linux interface to configure for IP masquerading
  * Default is eth0
* Which Amazon Linux 2 AMI to use
  * If using the educate template you will need to get this AMI ID from the EC2 console by starting to launch an instance
  * The other template will automatically fetch the AMI ID from the SSM parameter store so this parameter can be left unchanged

### Stopping and Starting the NAT instance

To further reduce costs the student can stop the NAT instance at anytime. When they return to the lab the NAT intance can be started again without the need to update the route table.

If the student accidentally terminates the NAT instance they should delete the cloudformation stack and deploy it again.

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
