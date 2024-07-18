{
  "files": {
    "${flb_config_destination}": {
      "source": {
        "S3": {
          "BucketName": "${bucket_name}",
          "Key": "${flb_config_key}"
        }
      }
    },
    "${flb_parser_destination}": {
      "source": {
        "S3": {
          "BucketName": "${bucket_name}",
          "Key": "${flb_parser_key}"
        }
      }
    }
  }
}
