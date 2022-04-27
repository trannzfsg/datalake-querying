## Starburst Galaxy
Starburst cloud offering

### Use AWS DMS to migrate data from RDS (source of truth) to S3 (data lake)
[aws-dms.sh](aws-dms.sh)

### AWS IAM to allow S3 access
```
# iam role/polciy for starburst
aws iam create-policy --policy-name {starburst-role-name} --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "listgetobj",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::{bucket}/*",
                "arn:aws:s3:::{bucket}"
            ]
        },
        {
            "Sid": "listbuckets",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
}'
# requires starburst "storage integration" to be created first - otherwise use placeholder for AWS account and ExternalId fields, and update later when starburst is created
aws iam create-role --role-name {starburst-role-name} --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "AWS": "{starburst-aws-account-id}"
            },
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "{starburst-external-id}"
                }
            }
        }
    ]
}'
# to update assumed role only
# aws iam update-assume-role-policy --role-name {starburst-role-name} --policy-document 'xxxx'
aws iam attach-role-policy --role-name {starburst-role-name} --policy-arn arn:aws:iam::{own-aws-account-id}:policy/{starburst-role-name}
```

### Create starburst reference to data lake (s3)
```
create schema {db}.{schema} with (location = 's3://{bucket}/{path/starburst-db-file}');

create table {db}.{schema}.{table} 
(
	{column1} {type},
	{column2} {type}
)
with (
    external_location = 's3://{bucket}/{path/sourcefile}.{csv|parquet|etc}', 
    format='parquet'
);
```
