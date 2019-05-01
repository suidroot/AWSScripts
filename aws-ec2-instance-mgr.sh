#!/bin/bash
# 
# Script to start and check status of a VM in AWS EC2
#
NAMETAG=$1
COMMAND=$2
SSHUSER=$3
SSHKEY="~/.ssh/KaliKey.pem"

## Test if needed utliities are installed
if [[ ! -e /usr/local/bin/jq ]]; then
    echo "ERROR jq not installed (json parser)"
    exit 255
fi

if [[ ! -e /usr/local/bin/aws ]]; then
    echo "ERROR aws not installed (awscli)"
    exit 255
fi

## Functions
list_instances() {
    aws ec2 describe-instances --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text | sort
}

start_instance() {
    echo "Starting $NAMETAG Instance"
    aws ec2 start-instances --instance-ids $INSTANCE_ID > /dev/null
}

connect_instance() {
  
    STATUS=`aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq -r .Reservations[0].Instances[0].State.Name`

    if [ "$STATUS" != "running" ]; then
        echo "$STATUS"
        echo "System is not Running"
        exit 255
    fi

    if [ -z $SSHUSER ]; then
        echo
        echo "Specify username"
        exit 255
    fi
    
    AWSVM_IP=`aws ec2 describe-instances --instance-ids $INSTANCE_ID | jq .Reservations[0].Instances[0].PublicIpAddress |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"`
    ssh -i $SSHKEY $SSHUSER@$AWSVM_IP
    exit 1
}

instance_info() {
    TMPFILE=`mktemp -t awsinfo`
    aws ec2 describe-instances --instance-ids $INSTANCE_ID > $TMPFILE

    echo -n "Instance Information: "

    cat $TMPFILE | jq .Reservations[0].Instances[0].State.Name
    echo -n "Public IPs: " 
    cat $TMPFILE | jq .Reservations[0].Instances[0].PublicIpAddress

    #echo $TMPFILE
    # Remove Temp File
    rm $TMPFILE
}

display_commands() {
    echo
    echo "Commands"
    echo "-------"
    echo "connect - connect via SSH to Host"
    echo "start - Start VM host"
    echo "status - Host status"
}

error() {
    echo
    echo "Current AWS Instances"
    echo "---------------------"
    list_instances
    display_commands
    exit 255
}

### Main ###
#
if [ "$#" -lt 1 ]; then
    echo "Must specify VM and action $#"
    error
fi

if echo $(list_instances) | grep -w $NAMETAG > /dev/null; then 

    INSTANCE_ID=`aws ec2 describe-instances --filter Name=tag:Name,Values=$NAMETAG | jq -r .Reservations[0].Instances[0].InstanceId`

    case $COMMAND in
        start)
            start_instance
            ;;
        connect)
            connect_instance
            ;;
        status)
            instance_info
            ;;
        *)
            instance_info
            echo ""
            display_commands
            ;;
    esac

else 
    echo "Invalid Instance Name"
    echo
    error 
fi
