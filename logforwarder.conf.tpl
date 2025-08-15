[SERVICE]
    Flush        5
    Grace        15
    Log_Level    info
    parsers_file parsers_multiline.conf

[INPUT]
    Name              tail
    Tag               ${prefix}-http-logs
    Path              /var/log/**/logs/*.shared_http_server*.log
    Path_Key          efs_filename
    DB                /var/log/flb_http_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  20
    Rotate_Wait       10
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      1h
    Mem_Buf_Limit     16M
    Parser            apache

[INPUT]
    Name              tail
    Tag               ${prefix}-runtime-logs
    Path              /var/log/**/logs/*.log
    Exclude_Path      /var/log/**/logs/*.shared_http_server*.log
    Path_Key          efs_filename
    DB                /var/log/flb_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  20
    Rotate_Wait       30
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      1h
    Mem_Buf_Limit     16M
    multiline.parser  multiline_boomi-runtime-logs

[FILTER]
    Name modify
    Match ${prefix}-http-logs
    Add boomi_log_type shared_http_server

[FILTER]
    Name modify
    Match ${prefix}-runtime-logs
    Add boomi_log_type runtime

[FILTER]
    Name parser
    Match ${prefix}-runtime-logs
    Key_Name log
    Parser parse-runtime-logs
    Reserve_Data On
    Preserve_Key On

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
    s3_key_format    ${destination_folder}/boomi/log_forwarder/%Y/%m/%d/%H.%M.%S.$UUID.gz
