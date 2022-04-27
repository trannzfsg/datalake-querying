# s3 bucket
aws s3 mb s3://{bucket}
aws s3api put-bucket-encryption --bucket {bucket} --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
aws s3api put-object --bucket {bucket} --key {db-path}/

# iam role/polciy for dms
aws iam create-policy --policy-name {dms-role-name} --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "listgetputobj",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:PutObjectTagging",
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
aws iam create-role --role-name {dms-role-name} --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "dms.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'
aws iam attach-role-policy --role-name {dms-role-name} --policy-arn arn:aws:iam::{own-aws-account-id}:policy/{dms-role-name}

# dms source/target endpoints
aws dms create-endpoint --endpoint-identifier '{dms-target-id}' --engine-name s3 --endpoint-type target --service-access-role-arn arn:aws:iam::{own-aws-account-id}:role/{dms-role-name} --s3-settings '{
  "ServiceAccessRoleArn": "arn:aws:iam::{own-aws-account-id}:role/{dms-role-name}",
  "BucketFolder": "{db-path}",
  "BucketName": "{bucket}",
  "EncryptionMode": "SSE_S3",
  "DataFormat": "parquet",
  "ParquetVersion": "parquet-2-0"
}'
aws dms create-endpoint --endpoint-identifier {dms-source-endpoint} --engine-name=sqlserver --endpoint-type source --server-name '{source-rds-endpoint}' --port {port} --ssl-mode require --username {username} --password {password} --database-name {dbname}

# dms replication instance and required security group
aws ec2 create-security-group --group-name {sg-for-dms} --vpc-id {vpc-id}
aws ec2 authorize-security-group-ingress --group-id {sg-id} --protocol tcp --port {db-port} --cidr {cidr/range}
# (takes x seconds/minutes)
aws dms create-replication-instance --replication-instance-identifier {dms-instance-name} --replication-instance-class dms.{class.size} --allocated-storage {in-gb} --no-multi-az --replication-subnet-group-identifier {subnet-group-id} --no-publicly-accessible --vpc-security-group-ids "{sg-id}"

# dms replication task
aws dms create-replication-task --replication-task-identifier {dms-task-name} --replication-instance-arn {dms-instance-arn} --source-endpoint-arn {dms-source-endpoint-arn} --target-endpoint-arn {dms-target-endpoint-arn} --migration-type full-load --replication-task-settings '{
  "TargetMetadata": {
    "TargetSchema": "",
    "SupportLobs": false,
    "FullLobMode": false,
    "LobChunkSize": 0,
    "LimitedSizeLobMode": false,
    "LobMaxSize": 0,
    "InlineLobMaxSize": 0,
    "LoadMaxFileSize": 0,
    "ParallelLoadThreads": 0,
    "ParallelLoadBufferSize": 0,
    "BatchApplyEnabled": false,
    "TaskRecoveryTableEnabled": false,
    "ParallelLoadQueuesPerThread": 0,
    "ParallelApplyThreads": 0,
    "ParallelApplyBufferSize": 0,
    "ParallelApplyQueuesPerThread": 0
  },
  "FullLoadSettings": {
    "TargetTablePrepMode": "DROP_AND_CREATE",
    "CreatePkAfterFullLoad": false,
    "StopTaskCachedChangesApplied": false,
    "StopTaskCachedChangesNotApplied": false,
    "MaxFullLoadSubTasks": 8,
    "TransactionConsistencyTimeout": 600,
    "CommitRate": 10000
  },
  "Logging": {
    "EnableLogging": true,
    "LogComponents": [
      {
        "Id": "TRANSFORMATION",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "SOURCE_UNLOAD",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "IO",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "TARGET_LOAD",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "PERFORMANCE",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "SOURCE_CAPTURE",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "SORTER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "REST_SERVER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "VALIDATOR_EXT",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "TARGET_APPLY",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "TASK_MANAGER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "TABLES_MANAGER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "METADATA_MANAGER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "FILE_FACTORY",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "COMMON",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "ADDONS",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "DATA_STRUCTURE",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "COMMUNICATION",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      },
      {
        "Id": "FILE_TRANSFER",
        "Severity": "LOGGER_SEVERITY_DEFAULT"
      }
    ]
  },
  "ControlTablesSettings": {
    "historyTimeslotInMinutes": 5,
    "ControlSchema": "",
    "HistoryTimeslotInMinutes": 5,
    "HistoryTableEnabled": false,
    "SuspendedTablesTableEnabled": false,
    "StatusTableEnabled": false,
    "FullLoadExceptionTableEnabled": false
  },
  "StreamBufferSettings": {
    "StreamBufferCount": 3,
    "StreamBufferSizeInMB": 8,
    "CtrlStreamBufferSizeInMB": 5
  },
  "ChangeProcessingDdlHandlingPolicy": {
    "HandleSourceTableDropped": true,
    "HandleSourceTableTruncated": true,
    "HandleSourceTableAltered": true
  },
  "ErrorBehavior": {
    "DataErrorPolicy": "LOG_ERROR",
    "EventErrorPolicy": null,
    "DataTruncationErrorPolicy": "LOG_ERROR",
    "DataErrorEscalationPolicy": "SUSPEND_TABLE",
    "DataErrorEscalationCount": 0,
    "TableErrorPolicy": "SUSPEND_TABLE",
    "TableErrorEscalationPolicy": "STOP_TASK",
    "TableErrorEscalationCount": 0,
    "RecoverableErrorCount": -1,
    "RecoverableErrorInterval": 5,
    "RecoverableErrorThrottling": true,
    "RecoverableErrorThrottlingMax": 1800,
    "RecoverableErrorStopRetryAfterThrottlingMax": true,
    "ApplyErrorDeletePolicy": "IGNORE_RECORD",
    "ApplyErrorInsertPolicy": "LOG_ERROR",
    "ApplyErrorUpdatePolicy": "LOG_ERROR",
    "ApplyErrorEscalationPolicy": "LOG_ERROR",
    "ApplyErrorEscalationCount": 0,
    "ApplyErrorFailOnTruncationDdl": false,
    "FullLoadIgnoreConflicts": true,
    "FailOnTransactionConsistencyBreached": false,
    "FailOnNoTablesCaptured": true
  },
  "ChangeProcessingTuning": {
    "BatchApplyPreserveTransaction": true,
    "BatchApplyTimeoutMin": 1,
    "BatchApplyTimeoutMax": 30,
    "BatchApplyMemoryLimit": 500,
    "BatchSplitSize": 0,
    "MinTransactionSize": 1000,
    "CommitTimeout": 1,
    "MemoryLimitTotal": 1024,
    "MemoryKeepTime": 60,
    "StatementCacheSize": 50
  },
  "PostProcessingRules": null,
  "CharacterSetSettings": null,
  "LoopbackPreventionSettings": null,
  "BeforeImageSettings": null,
  "FailTaskWhenCleanTaskResourceFailed": false,
  "TTSettings": null
}' --table-mappings '{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "1",
      "object-locator": {
        "schema-name": "dbo",
        "table-name": "%"
      },
      "rule-action": "include",
      "filters": []
    }
  ]
}'

# dms test source/target endpoints (takes x seconds/minutes)
aws dms test-connection --replication-instance-arn {dms-instance-arn} --endpoint-arn {dms-target-arn}
aws dms test-connection --replication-instance-arn {dms-instance-arn} --endpoint-arn {dms-source-arn}
# dms start replication task (takes x seconds/minutes), to rerun use "--start-replication-task-type reload-target"
aws dms start-replication-task --replication-task-arn {dms-task-arn} --start-replication-task-type start-replication
