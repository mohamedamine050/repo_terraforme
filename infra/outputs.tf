output "random_suffix" {
  value = random_string.suffix.result
}

output "scripts_bucket_name" {
  value = aws_s3_bucket.scripts.id
}

output "scripts_bucket_arn" {
  value = aws_s3_bucket.scripts.arn
}

output "scripts_bucket_domain_name" {
  value = aws_s3_bucket.scripts.bucket_domain_name
}

output "output_bucket_name" {
  value = aws_s3_bucket.output.id
}

output "output_bucket_arn" {
  value = aws_s3_bucket.output.arn
}

output "output_bucket_domain_name" {
  value = aws_s3_bucket.output.bucket_domain_name
}

output "glue_test_script_s3_key" {
  value = aws_s3_object.glue_test_script.key
}

output "glue_test_script_s3_bucket" {
  value = aws_s3_object.glue_test_script.bucket
}

output "glue_job_name" {
  value = aws_glue_job.etl.id
}

output "glue_job_arn" {
  value = aws_glue_job.etl.arn
}

output "glue_second_job_name" {
  value = aws_glue_job.etl_second.id
}

output "glue_second_job_arn" {
  value = aws_glue_job.etl_second.arn
}

output "glue_second_script_s3_key" {
  value = aws_s3_object.glue_second_script.key
}

output "glue_second_script_s3_bucket" {
  value = aws_s3_object.glue_second_script.bucket
}

output "glue_job_role_name" {
  value = aws_iam_role.glue_job.name
}

output "glue_job_role_arn" {
  value = aws_iam_role.glue_job.arn
}

output "rds_instance_id" {
  value = aws_db_instance.rds.id
}

output "rds_instance_arn" {
  value = aws_db_instance.rds.arn
}

output "rds_instance_address" {
  value = aws_db_instance.rds.address
}

output "rds_instance_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_instance_port" {
  value = aws_db_instance.rds.port
}

output "rds_instance_db_name" {
  value = aws_db_instance.rds.db_name
}

output "rds_instance_engine" {
  value = aws_db_instance.rds.engine
}

output "rds_instance_engine_version_actual" {
  value = aws_db_instance.rds.engine_version_actual
}

output "rds_instance_instance_class" {
  value = aws_db_instance.rds.instance_class
}

output "rds_instance_username" {
  value = aws_db_instance.rds.username
}

output "rds_instance_status" {
  value = aws_db_instance.rds.status
}

output "rds_instance_resource_id" {
  value = aws_db_instance.rds.resource_id
}