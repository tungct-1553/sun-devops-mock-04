import json
import boto3
import os
import time
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
athena_client = boto3.client("athena")
s3_client = boto3.client("s3")
ses_client = boto3.client("ses")

# Environment variables
ATHENA_DATABASE = os.environ.get("ATHENA_DATABASE_NAME")
ATHENA_WORKGROUP = os.environ.get("ATHENA_WORKGROUP_NAME")
S3_BUCKET = os.environ.get("S3_BUCKET_NAME")
S3_RESULTS_BUCKET = os.environ.get("S3_RESULTS_BUCKET_NAME")
NOTIFICATION_EMAILS = os.environ.get("NOTIFICATION_EMAILS", "").split(",")


def lambda_handler(event, context):
    """
    Main Lambda handler function
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Generate weekly report
        report_data = generate_weekly_report()

        # Format and send email report
        send_email_report(report_data)

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "message": "Weekly report generated and sent successfully",
                    "report_summary": report_data.get("summary", {}),
                }
            ),
        }

    except Exception as e:
        logger.error(f"Error generating report: {str(e)}")

        # Send error notification
        send_error_notification(str(e))

        return {
            "statusCode": 500,
            "body": json.dumps(
                {"message": "Error generating weekly report", "error": str(e)}
            ),
        }


def generate_weekly_report() -> Dict[str, Any]:
    """
    Generate weekly sales report using Athena
    """
    logger.info("Starting weekly report generation")

    # Weekly report query
    query = """
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
    """

    # Execute Athena query
    query_execution_id = execute_athena_query(query)

    # Wait for query completion and get results
    results = get_query_results(query_execution_id)

    # Process results
    report_data = process_query_results(results)

    logger.info("Weekly report generation completed")
    return report_data


def execute_athena_query(query: str) -> str:
    """
    Execute Athena query and return execution ID
    """
    logger.info("Executing Athena query")

    response = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={"Database": ATHENA_DATABASE},
        WorkGroup=ATHENA_WORKGROUP,
        ResultConfiguration={
            "OutputLocation": f"s3://{S3_RESULTS_BUCKET}/athena-results/"
        },
    )

    query_execution_id = response["QueryExecutionId"]
    logger.info(f"Query execution started: {query_execution_id}")

    return query_execution_id


def get_query_results(query_execution_id: str) -> Dict[str, Any]:
    """
    Wait for query completion and return results
    """
    logger.info(f"Waiting for query completion: {query_execution_id}")

    max_wait_time = 300  # 5 minutes
    wait_interval = 10  # 10 seconds
    elapsed_time = 0

    while elapsed_time < max_wait_time:
        response = athena_client.get_query_execution(
            QueryExecutionId=query_execution_id
        )

        status = response["QueryExecution"]["Status"]["State"]

        if status == "SUCCEEDED":
            logger.info("Query completed successfully")
            break
        elif status in ["FAILED", "CANCELLED"]:
            error_msg = response["QueryExecution"]["Status"].get(
                "StateChangeReason", "Unknown error"
            )
            raise Exception(f"Query failed: {error_msg}")

        time.sleep(wait_interval)
        elapsed_time += wait_interval

    if elapsed_time >= max_wait_time:
        raise Exception("Query execution timeout")

    # Get query results
    results = athena_client.get_query_results(QueryExecutionId=query_execution_id)

    return results


def process_query_results(results: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process Athena query results into report format
    """
    logger.info("Processing query results")

    rows = results.get("ResultSet", {}).get("Rows", [])

    if len(rows) <= 1:  # Only header row or no data
        return {
            "summary": {
                "total_revenue": 0,
                "total_transactions": 0,
                "total_stores": 0,
                "report_date": datetime.now().strftime("%Y-%m-%d"),
            },
            "details": [],
            "message": "No data available for the past week",
        }

    # Skip header row
    data_rows = rows[1:]

    # Process data
    report_details = []
    total_revenue = 0
    total_transactions = 0
    stores = set()

    for row in data_rows:
        data = row.get("Data", [])
        if len(data) >= 7:
            store_location = data[0].get("VarCharValue", "")
            transactions = int(data[1].get("VarCharValue", "0"))
            revenue = float(data[2].get("VarCharValue", "0.0"))
            avg_value = float(data[3].get("VarCharValue", "0.0"))
            items_sold = int(data[4].get("VarCharValue", "0"))
            payment_method = data[5].get("VarCharValue", "")
            unique_customers = int(data[6].get("VarCharValue", "0"))

            report_details.append(
                {
                    "store_location": store_location,
                    "total_transactions": transactions,
                    "total_revenue": revenue,
                    "avg_transaction_value": avg_value,
                    "total_items_sold": items_sold,
                    "payment_method": payment_method,
                    "unique_customers": unique_customers,
                }
            )

            total_revenue += revenue
            total_transactions += transactions
            stores.add(store_location)

    return {
        "summary": {
            "total_revenue": total_revenue,
            "total_transactions": total_transactions,
            "total_stores": len(stores),
            "report_date": datetime.now().strftime("%Y-%m-%d"),
            "report_period": f"{(datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')} to {datetime.now().strftime('%Y-%m-%d')}",
        },
        "details": report_details,
    }


def send_email_report(report_data: Dict[str, Any]):
    """
    Send email report via SES
    """
    logger.info("Sending email report")

    # Generate email content
    subject = f"Weekly Sales Report - {report_data['summary']['report_date']}"

    html_body = generate_html_report(report_data)
    text_body = generate_text_report(report_data)

    # Send to all notification emails
    for email in NOTIFICATION_EMAILS:
        if email.strip():
            try:
                ses_client.send_email(
                    Source=email.strip(),  # Using same email as source (must be verified)
                    Destination={"ToAddresses": [email.strip()]},
                    Message={
                        "Subject": {"Data": subject},
                        "Body": {
                            "Html": {"Data": html_body},
                            "Text": {"Data": text_body},
                        },
                    },
                )
                logger.info(f"Email sent to {email}")
            except Exception as e:
                logger.error(f"Failed to send email to {email}: {str(e)}")


def generate_html_report(report_data: Dict[str, Any]) -> str:
    """
    Generate HTML email report
    """
    summary = report_data["summary"]
    details = report_data["details"]

    html = f"""
    <html>
    <head>
        <style>
            body {{ font-family: Arial, sans-serif; }}
            .header {{ background-color: #f0f0f0; padding: 20px; text-align: center; }}
            .summary {{ margin: 20px 0; padding: 15px; background-color: #e8f4fd; }}
            .details {{ margin: 20px 0; }}
            table {{ border-collapse: collapse; width: 100%; }}
            th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
            .metric {{ font-weight: bold; color: #2c5282; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Weekly Sales Report</h1>
            <p>Report Date: {summary['report_date']}</p>
            <p>Period: {summary.get('report_period', 'Last 7 days')}</p>
        </div>
        
        <div class="summary">
            <h2>Summary</h2>
            <p><span class="metric">Total Revenue:</span> ${summary['total_revenue']:,.2f}</p>
            <p><span class="metric">Total Transactions:</span> {summary['total_transactions']:,}</p>
            <p><span class="metric">Total Stores:</span> {summary['total_stores']}</p>
        </div>
        
        <div class="details">
            <h2>Detailed Breakdown</h2>
    """

    if details:
        html += """
            <table>
                <tr>
                    <th>Store Location</th>
                    <th>Payment Method</th>
                    <th>Transactions</th>
                    <th>Revenue</th>
                    <th>Avg Transaction</th>
                    <th>Items Sold</th>
                    <th>Unique Customers</th>
                </tr>
        """

        for detail in details:
            html += f"""
                <tr>
                    <td>{detail['store_location']}</td>
                    <td>{detail['payment_method']}</td>
                    <td>{detail['total_transactions']:,}</td>
                    <td>${detail['total_revenue']:,.2f}</td>
                    <td>${detail['avg_transaction_value']:,.2f}</td>
                    <td>{detail['total_items_sold']:,}</td>
                    <td>{detail['unique_customers']:,}</td>
                </tr>
            """

        html += "</table>"
    else:
        html += "<p>No data available for this period.</p>"

    html += """
        </div>
        
        <div style="margin-top: 30px; font-size: 12px; color: #666;">
            <p>This report was automatically generated by the Data Analytics System.</p>
        </div>
    </body>
    </html>
    """

    return html


def generate_text_report(report_data: Dict[str, Any]) -> str:
    """
    Generate text email report
    """
    summary = report_data["summary"]
    details = report_data["details"]

    text = f"""
WEEKLY SALES REPORT
Report Date: {summary['report_date']}
Period: {summary.get('report_period', 'Last 7 days')}

SUMMARY
=======
Total Revenue: ${summary['total_revenue']:,.2f}
Total Transactions: {summary['total_transactions']:,}
Total Stores: {summary['total_stores']}

DETAILED BREAKDOWN
==================
"""

    if details:
        for detail in details:
            text += f"""
Store: {detail['store_location']} | Payment: {detail['payment_method']}
  Transactions: {detail['total_transactions']:,}
  Revenue: ${detail['total_revenue']:,.2f}
  Avg Transaction: ${detail['avg_transaction_value']:,.2f}
  Items Sold: {detail['total_items_sold']:,}
  Unique Customers: {detail['unique_customers']:,}
"""
    else:
        text += "No data available for this period."

    text += """

---
This report was automatically generated by the Data Analytics System.
"""

    return text


def send_error_notification(error_message: str):
    """
    Send error notification via SES
    """
    logger.info("Sending error notification")

    subject = f"Weekly Report Generation Failed - {datetime.now().strftime('%Y-%m-%d')}"

    body = f"""
An error occurred while generating the weekly sales report:

Error: {error_message}
Timestamp: {datetime.now().isoformat()}

Please check the CloudWatch logs for more details.

Lambda Function: Data Analytics Reporter
"""

    for email in NOTIFICATION_EMAILS:
        if email.strip():
            try:
                ses_client.send_email(
                    Source=email.strip(),
                    Destination={"ToAddresses": [email.strip()]},
                    Message={
                        "Subject": {"Data": subject},
                        "Body": {"Text": {"Data": body}},
                    },
                )
            except Exception as e:
                logger.error(f"Failed to send error notification to {email}: {str(e)}")
