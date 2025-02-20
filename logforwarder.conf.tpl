[SERVICE]
    Flush        5
    Grace        15
    Log_Level    info
    parsers_file parsers_multiline.conf

[INPUT]
    Name              tail
    Tag               ${prefix}-process-logs
    Path              /var/log/**/execution/history/**/**/**/**/process_log.xml
    Path_Key          efs_filename
    DB                /var/log/flb_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  10
    Rotate_Wait       30
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      1d
    multiline.parser  multiline_boomi-process-logs

[INPUT]
    Name              tail
    Tag               ${prefix}-runtime-logs
    Path              /var/log/**/logs/*.log
    Path_Key          efs_filename
    DB                /var/log/flb_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  10
    Rotate_Wait       30
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      14d
    multiline.parser  multiline_boomi-runtime-logs

[FILTER]
    Name modify
    Match ${prefix}-process-logs
    Add boomi_log_type process

[FILTER]
    Name modify
    Match ${prefix}-runtime-logs
    Add boomi_log_type runtime

[FILTER]
    Name parser
    Match ${prefix}-runtime-logs
    Key_Name message
    Parser parse-runtime-logs
    Reserve_Data On
    Preserve_Key On

# Leave disabled for now as ECS metadata is not available in the container
#[FILTER]
#    # These values are added by the ECS agent but will all be from the logforwarding service
#    Name ecs
#    Match *
#    ADD ecs_task_arn $TaskARN
#    ADD ecs_cluster_name $ClusterName
#    ADD ecs_service $TaskDefinitionFamily
#    ADD task_def_version $TaskDefinitionVersion
#    ADD task_id $TaskID

[OUTPUT]
    Name             s3
    Match            *
    region           ${aws_region}
    bucket           ${bucket_name}
    total_file_size  ${total_file_size}
    upload_timeout   ${upload_timeout}
    retry_limit      ${retry_limit}
    use_put_object   On
    compression      gzip
    s3_key_format    ${destination_folder}/boomi/%Y/%m/%d/%H.%M.%S.$UUID.gz
