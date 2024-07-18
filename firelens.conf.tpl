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
