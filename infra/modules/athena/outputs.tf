output "database_name" {
  description = "Name of the Athena database"
  value       = aws_athena_database.main.name
}

output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "create_table_query_id" {
  description = "ID of the create table named query"
  value       = aws_athena_named_query.create_table.id
}

output "weekly_report_query_id" {
  description = "ID of the weekly report named query"
  value       = aws_athena_named_query.weekly_report.id
}
