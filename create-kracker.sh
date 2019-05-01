#!/bin/sh

AMI="ami-0c80039f389c69c1f"
KEY="Kali Key"
SECURITYGROUP="EC2 - Only SSH Inbound"
#SECURITYGROUP="sg-046ebfedbd6b759ca"
INSTANCETYPE="g3.16xlarge"
NAMETAG="Kracker"
BUILDSCRIPT="~/code/Misc/awscracker-build.sh"
SSHKEY="~/.ssh/KaliKey.pem"
SSHUSER="ubuntu"
TMPFILE=`mktemp -t awsinfo`

echo "Creating $NAMETAG Instance."
aws ec2 run-instances --image-id $AMI \
    --key-name "$KEY" \
    --security-groups "$SECURITYGROUP" \
    --instance-type $INSTANCETYPE \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value='$NAMETAG'}]" > $TMPFILE
    

INSTANCEID=`cat $TMPFILE | jq -r .Instances[0].InstanceId`

if [ -z $INSTANCEID ]; then
    echo ERROR: check $TMPFILE
    exit 255
fi

rm $TMPFILE

STATUS=`aws ec2 describe-instances --instance-ids $INSTANCEID | jq -r .Reservations[0].Instances[0].State.Name`

echo "Instance $INSTANCEID create and in $STATUS status"

while [ "$STATUS" != "running" ]; do
    echo "Waiting for system to boot..."
    sleep 30
    STATUS=`aws ec2 describe-instances --instance-ids $INSTANCEID | jq -r .Reservations[0].Instances[0].State.Name`
    echo "Status: $STATUS"
done

AWSVM_IP=`aws ec2 describe-instances --instance-ids $INSTANCEID | jq .Reservations[0].Instances[0].PublicIpAddress |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"`

echo "Back off"
sleep 15

echo "Copying Build script"
scp -i $SSHKEY $BUILDSCRIPT $SSHUSER@$AWSVM_IP:

echo "SSH to the IP $AWSVM_IP"
