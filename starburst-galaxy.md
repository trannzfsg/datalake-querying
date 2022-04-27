# use AWS DMS to migrate data from RDS (source of truth) to S3 (data lake)
[aws-dms](aws-dms.md)

# create starburst reference to data lake (s3)
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
