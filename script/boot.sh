S_ID=99
OS_HOST=nova
[ ! -z $1 ] && OS_ID=$1
[ ! -z $2 ] && OS_HOST="nova:$2"

OS_NAME=Test0${OS_ID}

OS_IMAGE='395aae22-ac29-48f7-8c2d-f409fe63f91d'
OS_NET='24a88064-f249-4770-a57d-10ee1a4894bc'

nova --debug boot --flavor m1.small --image $OS_IMAGE \
--nic net-id=$OS_NET \
--availability-zone $OS_HOST --key-name sysop \
$OS_NAME

