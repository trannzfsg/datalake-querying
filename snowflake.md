## Snowflake

### Use AWS DMS to migrate data from RDS (source of truth) to S3 (data lake)
[aws-dms.sh](aws-dms.sh)

### AWS IAM to allow S3 access (bash)
```
# iam role/polciy for snowflake
aws iam create-policy --policy-name {snowflake-role-name} --policy-document '{
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
# requires snowflake "storage integration" to be created first - otherwise use placeholder for AWS account and ExternalId fields, and update later when snowflake is created
aws iam create-role --role-name {snowflake-role-name} --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "AWS": "{snowflake-aws-account-id}"
            },
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "{snowflake-external-id}"
                }
            }
        }
    ]
}'
# to update assumed role only
# aws iam update-assume-role-policy --role-name {snowflake-role-name} --policy-document 'xxxx'
aws iam attach-role-policy --role-name {snowflake-role-name} --policy-arn arn:aws:iam::{own-aws-account-id}:policy/{snowflake-role-name}
```

### Snowflake database and role setup (SQL)
```
create database {database};
use database {database};
create schema {schema};
use schema {schema};

create or replace file format sf_parquet_format
  type = 'parquet';

create storage integration {storage-integration-name}
    type = external_stage
    storage_provider = s3
    storage_aws_role_arn = '{snowflake-role-arn}'
    enabled = true
    storage_allowed_locations = ( 's3://{bucketname}' );
--to find out snowflake aws account id and external id: DESC INTEGRATION {storage-integration-name};
--update aws IAM role to use above

create stage {stage-name}
    url = 's3://{bucketname}'
    storage_integration = {storage-integration-name};

CREATE ROLE IDENTIFIER('"{integration-role-name}"') COMMENT = '';
GRANT ROLE IDENTIFIER('"{integration-role-name}"') TO ROLE IDENTIFIER('"SYSADMIN"');
GRANT USAGE ON DATABASE IDENTIFIER('"{database}"') TO ROLE IDENTIFIER('"{integration-role-name}"');
GRANT USAGE ON SCHEMA IDENTIFIER('"{database}"."{schema}"') TO ROLE IDENTIFIER('"{integration-role-name}"');
GRANT SELECT ON FUTURE TABLES IN SCHEMA IDENTIFIER('"{database}"."{schema}"') TO ROLE IDENTIFIER('"{integration-role-name}"');
GRANT SELECT ON FUTURE EXTERNAL TABLES IN SCHEMA IDENTIFIER('"{database}"."{schema}"') TO ROLE IDENTIFIER('"{integration-role-name}"');
```

### Snowflake create external tables (SQL)
```
use database {database};
use schema {schema};
create external table {tablename}
    (
        {column1} {type1} as (value:{parquet-column1}::{parquet-type1}),
        {column2} {type2} as (value:{parquet-column2}::{parquet-type2}),
        ...
    )
    with location = @{stage-name}/{database}/{schema}/{table}/
    refresh_on_create = true
    auto_refresh = true
    file_format = (type = parquet);
```

### Snowflake create internal tables (SQL) - copy data to Snowflake
```
use database {database};
use schema {schema};
create or replace table {tablename}(
    {column1} {type1},
    {column2} {type2},
    ...
);
copy into {tablename} (
    {column1},
    {column2},
    ...
    )
from (select
    $1:{parquet-column1}::{parquet-type1},
    $1:{parquet-column2}::{parquet-type2},
    ...
from @{stage-name}/{database}/{schema}/{table}/
(file_format => sf_parquet_format));
```
