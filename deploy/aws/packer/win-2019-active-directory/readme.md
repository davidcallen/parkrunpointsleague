## Packer Instructions

#### To run the ansible playbook against a WIP packer image
modify file ansible/group_vars/static to contain the IP address of the WIP packer image.
Note if running packer from local machine use the public IP address, or if running packer from cloud VM then can use the private IP address.

`cd ansible
ansible-playbook playbook.yml -i group_vars/static --private-key=../ec2_amazon-ebs.pem
`
 