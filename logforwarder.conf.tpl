[SERVICE]
    Flush        5
    Grace        15
    Log_Level    info
    parsers_file parsers_multiline.conf

[INPUT]
    Name              tail
    Tag               ${prefix}-process-logs
    Path              /var/log/**/execution/history/**/**/process.xml
    DB                /var/log/flb_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  10
    Rotate_Wait       30
    Read_from_Head    true
    Ignore_Older      14d
    Skip_Empty_Lines  On
    multiline.parser  multiline_boomi-process-logs

[INPUT]
    Name              tail
    Tag               ${prefix}-runtime-logs
    Path              /var/log/**/logs/*.log
    DB                /var/log/flb_positions.db
    DB.locking        true
    Skip_Long_Lines   On
    Refresh_Interval  10
    Rotate_Wait       30
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      14d

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
