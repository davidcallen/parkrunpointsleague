#!/usr/bin/python3
# Delete unused AMIs - this will process across all our specified Org accounts within the specified region
#
# We rarely want to delete all unused AMIs but more likely to keep at least 1 (the latest) AMI for each of our image "types".
# We use a Tag called 'Basename' and 'Encrypted' to infer and group by this "type". Tag names defined in var '_image_type_grouping_tags'.
# This can be overriden with --keep-latest-ami-per-type
#
import getopt
import sys
import logging
import boto3
import datetime

_regions = ["eu-west-1", 'us-east-1']
_image_owning_account = {
	'account_id': '228947135432',
	'account_name': 'core',
	'customer_name': 'prpl',
	'assume_role_name': 'prpl-core-admin',
	'regions': ["eu-west-1", 'us-east-1']
}
_image_using_accounts = [
	{
		'account_id': '597767386394',
		'account_name': 'backbone',
		'customer_name': 'prpl',
		'assume_role_name': '',
		'regions': ["eu-west-1", 'us-east-1']
	},
	{
		'account_id': '228947135432',
		'account_name': 'core',
		'customer_name': 'prpl',
		'assume_role_name': 'prpl-core-admin',
		'regions': ["eu-west-1", 'us-east-1']
	},
	{
		'account_id': '472687107726',
		'account_name': 'prod',
		'customer_name': 'prpl',
		'assume_role_name': 'prpl-prod-admin',
		'regions': ["eu-west-1", 'us-east-1']
	}
	# {
	# 	'account_id': '760245709408',
	# 	'account_name': 'dev',
	# 	'customer_name': 'prpl',
	# 	'assume_role_name': 'prpl-core-admin',
	# 	'regions': ["eu-west-1", 'us-east-1']
	# }
]
# The Tags on the AMI Images to infer and group AMI by "type".
# Used if option '--keep-latest-ami-per-type' is True
_image_type_grouping_tags = ['Basename', 'Encrypted']


# ---------------------------------------------------------------------------------------
def usage():
	print('+----------------------------------------------------------------------------+')
	print('| delete-unused-amis - Delete Unused AMIs and their snapshots')
	print('+----------------------------------------------------------------------------+')
	print('')
	print('')
	print('Usage: --help ^| [--log-level] [--max-deletes] [--dry-run]')
	print('')
	print('    -h, --help                      : Displays this help page.')
	print('    -l, --log-level                 : Logging Level [DEBUG, INFO, WARNING, ERROR, CRITICAL].')
	print('    -m, --max-deletes               : Maximum number of deletions to perform (default is 10000)')
	print('    -d, --dry-run                   : No deleting of AMIS. Just display the report. (default is False)')
	print('    -k, --keep-latest-ami-per-type  : Keep the latest AMI per "type", regardless if unused.  (default is True)')
	print('                                      (uses Tags "Basename" and "Encrypted" to group on this "type")')


# ---------------------------------------------------------------------------------------
def get_aws_ec2_client(account, region_name):
	if account['assume_role_name'] != '':
		sts_client = boto3.client('sts')
		assumed_role_object = sts_client.assume_role(
			RoleArn=f"arn:aws:iam::{account['account_id']}:role/{account['assume_role_name']}",
			RoleSessionName=f"{account['assume_role_name']}")
		credentials = assumed_role_object['Credentials']

		ec2_client = boto3.client('ec2',
								  region_name=region_name,
								  aws_access_key_id=credentials['AccessKeyId'],
								  aws_secret_access_key=credentials['SecretAccessKey'],
								  aws_session_token=credentials['SessionToken'])
	else:
		ec2_client = boto3.client('ec2', region_name=region_name)
	return ec2_client


# ---------------------------------------------------------------------------------------
def get_images(account):
	images = {}
	for region in _regions:
		logging.info("Checking for images in account %s and region %s ...", account['account_name'], region)
		ec2_client = get_aws_ec2_client(account, region)
		describe_images = ec2_client.describe_images(Owners=['self'])
		for describe_image in describe_images['Images']:
			images_usages = []
			# Get image snapshot ids
			snapshot_ids = []
			block_device_mappings = describe_image.get('BlockDeviceMappings')
			if block_device_mappings is not None:
				for block_device_mapping in block_device_mappings:
					snapshot_ids.append(block_device_mapping['Ebs']['SnapshotId'])
			image = {'image_id': describe_image['ImageId'], 'image_name': describe_image['Name'],
					 'account_id': account['account_id'], 'account_name': account['account_name'],
					 'region_name': region, 'snapshot_ids': snapshot_ids, 'image_tags': describe_image['Tags'],
					 'image_creation_date': datetime.datetime.strptime(describe_image['CreationDate'],
																	   "%Y-%m-%dT%H:%M:%S.%fZ"),
					 'image_usages': images_usages}
			images[image['image_id']] = image
			logging.info("Found image '%s' ('%s')", image['image_id'], image['image_name'])
		return images


# ---------------------------------------------------------------------------------------
def calc_latest_images_by_type(image_type_grouping_tags, images):
	# Create a dictionary of the grouping by image "type" and hold the latest AMI ID and CreationDate
	# Use the grouping Tag values for the dictionary keys.
	logging.info("Getting list of Latest images grouped by 'type'...")
	latest_images_by_type = {}
	grouping_key_delimiter = '_#_'
	for image_id, image in images.items():
		grouping_key = ''
		image_tags = image['image_tags']
		for image_type_grouping_tag in image_type_grouping_tags:
			found_type_grouping_tag = False
			for tag in image_tags:
				if tag['Key'] == image_type_grouping_tag:  # Is this a grouping tag
					grouping_key = grouping_key + tag['Value'] + grouping_key_delimiter
					found_type_grouping_tag = True
			if not found_type_grouping_tag:
				logging.warning("Found image '%s' ('%s') that is missing our Grouping Tag '%s'", image['image_id'],
								image['image_name'], image_type_grouping_tag)
		if grouping_key == '':
			logging.warning("Found image '%s' ('%s') that has an empty Grouping key", image['image_id'],
							image['image_name'])
		else:
			latest_image_by_type = latest_images_by_type.get(grouping_key)
			if latest_image_by_type is None:
				latest_image_by_type = {
					'image_id': image['image_id'],
					'image_name': image['image_name'],
					'image_creation_date': image['image_creation_date']
				}
				latest_images_by_type[grouping_key] = latest_image_by_type
			else:
				if latest_image_by_type['image_creation_date'] < image['image_creation_date']:
					latest_image_by_type['image_id'] = image['image_id']
					latest_image_by_type['image_name'] = image['image_name']
					latest_image_by_type['image_creation_date'] = image['image_creation_date']
	return latest_images_by_type


# ---------------------------------------------------------------------------------------
# Search thru list of Tags (elements are dictionaries with 'Key' and 'Value' attributes).
def get_tag_value(tags, tag_key):
	for tag in tags:
		if tag['Key'] == tag_key:
			return tag['Value']
	return None


# ---------------------------------------------------------------------------------------
def get_image_usages(account, images):
	logging.info("Checking if images are used...")
	for region in _regions:
		for account in _image_using_accounts:
			ec2_client = get_aws_ec2_client(account, region)
			ec2_describe_instances = ec2_client.describe_instances(Filters=[
				{
					'Name': 'instance-state-name',
					'Values': ['pending', 'running', 'shutting-down', 'stopping', 'stopped']
				}
			])
		for ec2_describe_instance_reservation in ec2_describe_instances['Reservations']:
			for ec2_describe_instance_instance in ec2_describe_instance_reservation['Instances']:
				instance_name = ''
				instance_name_tag = get_tag_value(ec2_describe_instance_instance['Tags'], 'Name')
				if instance_name_tag is not None:
					instance_name = instance_name_tag
				instance = {
					'instance_id': ec2_describe_instance_instance['InstanceId'],
					'instance_name': instance_name,
					'image_id': ec2_describe_instance_instance['ImageId']
				}
				image = images.get(instance['image_id'])
				if image is None:
					logging.warning(
						"EC2 instance [%s (%s)] has image_id of %s. But image not found in our registered images.",
						instance['instance_name'], instance['instance_id'], instance['image_id'])
				logging.info("EC2 instance [%s (%s)] using image [%s %s]",
							 instance['instance_name'], instance['instance_id'],
							 image['image_name'], image['image_id'])
				image_usage = {
					'instance_name': instance['instance_name'],
					'instance_id': instance['instance_id'],
					'account_name': account['account_name'],
					'region_name': region
				}
				image['image_usages'].append(image_usage)
	return images


# ---------------------------------------------------------------------------------------
def get_report_column_widths(images):
	col_widths = [22, 14, 23, 16, 12, 7, 10, 12]
	for image_id, image in images.items():
		col_widths[0] = max(col_widths[0], len(image['image_name']))
		col_widths[1] = max(col_widths[1], len(image['image_id']))
		col_widths[4] = max(col_widths[4], len(image['account_name']))
		col_widths[5] = max(col_widths[5], len(image['region_name']))
		for image_usage in image['image_usages']:
			col_widths[2] = max(col_widths[2], len(image_usage['instance_name']))
			col_widths[3] = max(col_widths[3], len(image_usage['instance_id']))
			col_widths[4] = max(col_widths[4], len(image_usage['account_name']))
			col_widths[5] = max(col_widths[5], len(image_usage['region_name']))
	return col_widths


# ---------------------------------------------------------------------------------------
def report_image_usages(images, latest_images_by_type, keep_latest_ami_per_type):
	col_widths = get_report_column_widths(images)
	logging.info("                            Image Usage Report")
	logging.info("                            ==================")
	report_row_format = '%-{:d}s %-{:d}s %-{:d}s %-{:d}s %-{:d}s %-{:d}s %{:d}s %-{:d}s'.format(col_widths[0], col_widths[1],
																						 col_widths[2], col_widths[3],
																						 col_widths[4], col_widths[5],
																						 col_widths[6], col_widths[7])
	logging.info(report_row_format, 'Image Name', 'Image ID', 'EC2 Instance Name', 'EC2 Instance ID', 'Account Name',
				 'Region', 'Age (days)', 'Action')
	logging.info(report_row_format, '----------------------', '--------------', '-----------------------',
				 '----------------', '------------', '-------', '----------', '---------')
	for image_id, image in images.items():
		# Check if image should be retained since is the latest one for a "type"
		action = ''
		image_age = datetime.datetime.now() - image['image_creation_date']
		image_age_days = image_age.days
		image_usages = image['image_usages']
		if len(image_usages) == 0:
			if keep_latest_ami_per_type and check_if_image_is_latest_by_type(latest_images_by_type, image_id):
				action = 'KEEP_LATEST'
			logging.info(report_row_format, image['image_name'], image['image_id'], '', '', '', '', image_age_days, action)
		else:
			for image_usage in image_usages:
				action = 'IN_USE'
				logging.info(report_row_format, image['image_name'], image['image_id'],
							 image_usage['instance_name'], image_usage['instance_id'],
							 image_usage['account_name'], image_usage['region_name'],
							 image_age_days, action)


# ---------------------------------------------------------------------------------------
def check_if_image_is_latest_by_type(latest_images_by_type, image_id):
	for key, latest_image_by_type in latest_images_by_type.items():
		if image_id == latest_image_by_type['image_id']:
			return True
	return False


# ---------------------------------------------------------------------------------------
def delete_unused_images(image_owning_account, images, dry_run, max_num_deletes, latest_images_by_type,
						 keep_latest_ami_per_type):
	num_deletes = 0
	for image_id, image in images.items():
		if num_deletes >= max_num_deletes:
			break
		if len(image['image_usages']) == 0:
			# Check if image should be retained since is the latest one for a "type"
			if keep_latest_ami_per_type and check_if_image_is_latest_by_type(latest_images_by_type, image_id):
				logging.info(
					"Keeping unused image '%s' ('%s') from account '%s' ('%s') and region '%s'. Since is LATEST image for this 'type'.",
					image['image_name'], image['image_id'],
					image['account_name'], image['account_id'],
					image['region_name'])
			else:
				logging.info("Deleting unused image '%s' ('%s') from account '%s' ('%s') and region '%s'",
							 image['image_name'], image['image_id'],
							 image['account_name'], image['account_id'],
							 image['region_name'])
				ec2_client = get_aws_ec2_client(image_owning_account, image['region_name'])
				if dry_run:
					logging.warning("--dry-run was selected so skipping unused image deletion")
				else:
					deregister_image = ec2_client.deregister_image(ImageId=image['image_id'])
					num_deletes += 1
					for snapshot_id in image['snapshot_ids']:
						delete_snapshot = ec2_client.delete_snapshot(SnapshotId=snapshot_id)
						logging.debug(
							"  Deleted snapshot '%s' of unused image '%s' ('%s') from account '%s' ('%s') and region '%s'",
							snapshot_id, image['image_name'], image['image_id'],
							image['account_name'], image['account_id'],
							image['region_name'])
					logging.debug(
						"  Deleted unused image '%s' ('%s') and its snapshots from account '%s' ('%s') and region '%s'",
						image['image_name'], image['image_id'],
						image['account_name'], image['account_id'],
						image['region_name'])


# ---------------------------------------------------------------------------------------
def main():
	dry_run: bool = False
	max_num_deletes: int = 10000
	keep_latest_ami_per_type: bool = True
	log_level: str = "INFO"
	try:
		opts, args = getopt.getopt(sys.argv[1:], 'hdm:kl:',
								   ['help', 'dry-run', 'max-deletes=', 'keep-latest-ami-per-type=', 'log-level='])
	except getopt.GetoptError as err:
		print('ERROR: Invalid args. %s', str(err))
		usage()
		return 2
	for opt, arg in opts:
		if opt in ('-h', '--help'):
			usage()
			return 0
		elif opt in ('-d', '--dry-run'):
			dry_run = True
		elif opt in ('-m', '--max-deletes'):
			max_num_deletes = int(arg)
		elif opt in ('-k', '--keep-latest-ami-per-type'):
			keep_latest_ami_per_type = bool(arg)
		elif opt in ('-l', '--log-level'):
			log_level = arg
		else:
			print('ERROR: Invalid args. Use --help to see valid arguments (%s).', opt)
			return 1
	# Full log format :
	# logging.basicConfig(format='%(asctime)s %(levelname)s %(funcName)s(%(lineno)d) : %(message)s',
	#					datefmt='%Y-%m-%d %H:%M:%S', level=log_level)
	logging.basicConfig(format='%(levelname)s : %(funcName)s(%(lineno)d) : %(message)s', level=log_level)
	#
	images = get_images(_image_owning_account)
	latest_images_by_type = calc_latest_images_by_type(_image_type_grouping_tags, images)
	images = get_image_usages(_image_using_accounts, images)
	report_image_usages(images, latest_images_by_type, keep_latest_ami_per_type)
	delete_unused_images(_image_owning_account, images, dry_run, max_num_deletes, latest_images_by_type,
						 keep_latest_ami_per_type)
	logging.info("Finished.")


# ---------------------------------------------------------------------------------------
if __name__ == '__main__':
	sys.exit(main())
