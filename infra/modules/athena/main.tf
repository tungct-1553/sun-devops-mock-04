# Athena Database
resource "aws_athena_database" "main" {
  name   = "${replace(var.project_name, "-", "_")}_${var.environment}"
  bucket = var.s3_results_bucket_name

  encryption_configuration {
    encryption_option = "SSE_S3"
  }

  force_destroy = true
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name = "${var.project_name}-${var.environment}-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.s3_results_bucket_name}/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    bytes_scanned_cutoff_per_query = 1000000000 # 1GB limit
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-workgroup"
  }
}

# Athena Data Catalog Table cho sample data
resource "aws_athena_named_query" "create_table" {
  name        = "${var.project_name}-${var.environment}-create-sales-table"
  workgroup   = aws_athena_workgroup.main.name
  database    = aws_athena_database.main.name
  description = "Create sales data table"

  query = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS sales_data (
  transaction_id string,
  customer_id string,
  product_name string,
  quantity int,
  unit_price double,
  total_amount double,
  transaction_date string,
  store_location string,
  payment_method string
)
STORED AS JSON
LOCATION 's3://${var.s3_bucket_name}/sample-logs/'
TBLPROPERTIES ('has_encrypted_data'='false');
EOF
}

# Named query để tạo weekly report
resource "aws_athena_named_query" "weekly_report" {
  name        = "${var.project_name}-${var.environment}-weekly-report"
  workgroup   = aws_athena_workgroup.main.name
  database    = aws_athena_database.main.name
  description = "Generate weekly sales report"

  query = <<EOF
SELECT 
  store_location,
  COUNT(*) as total_transactions,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_transaction_value,
  SUM(quantity) as total_items_sold,
  payment_method,
  COUNT(DISTINCT customer_id) as unique_customers
FROM sales_data 
WHERE transaction_date >= date_format(date_add('day', -7, current_date), '%Y-%m-%d')
GROUP BY store_location, payment_method
ORDER BY total_revenue DESC;
EOF
}
