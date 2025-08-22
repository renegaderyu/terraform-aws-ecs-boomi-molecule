[SERVICE]
    Flush        15
    Grace        30
    Log_Level    ${log_level}
    parsers_file parsers_multiline.conf
    storage.max_chunks_up 256

[INPUT]
    Name              tail
    Tag               ${prefix}-http-logs
    Path              /var/log/**/logs/*.shared_http_server*.log
    Path_Key          efs_filename
    Inotify_Watcher   false
    DB                /var/log/flb_http_positions.db
    DB.journal_mode   TRUNCATE
    DB.locking        false
    DB.sync           Normal
    Skip_Long_Lines   On
    Skip_Empty_Lines  On
    Refresh_Interval  60
    Rotate_Wait       60
    Read_from_Head    true
    Ignore_Older      1d
    storage.type      memory
    storage.pause_on_chunks_overlimit false
    Buffer_Chunk_Size ${buffer_chunk_size}
    Buffer_Max_Size   ${buffer_max_size}
    Mem_Buf_Limit     ${http_buffer_limit}MB
    Parser            apache

[INPUT]
    Name              tail
    Tag               ${prefix}-runtime-logs
    Path              /var/log/**/logs/*.log
    Exclude_Path      /var/log/**/logs/*.shared_http_server*.log
    Path_Key          efs_filename
    Inotify_Watcher   false
    DB                /var/log/flb_positions.db
    DB.journal_mode   TRUNCATE
    DB.locking        false
    DB.sync           Normal
    Skip_Long_Lines   On
    Refresh_Interval  60
    Rotate_Wait       60
    Read_from_Head    true
    Skip_Empty_Lines  On
    Ignore_Older      1d
    storage.type      memory
    storage.pause_on_chunks_overlimit false
    Buffer_Chunk_Size ${buffer_chunk_size}
    Buffer_Max_Size   ${buffer_max_size}
    Mem_Buf_Limit     ${runtime_buffer_limit}MB
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