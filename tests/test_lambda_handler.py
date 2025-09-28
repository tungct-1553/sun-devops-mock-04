import unittest
from unittest.mock import Mock, patch, MagicMock
import json
import sys
import os

# Add the parent directory to the path so we can import the handler
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from handler import lambda_handler, generate_weekly_report, process_query_results


class TestDataAnalyzer(unittest.TestCase):

    def setUp(self):
        """Set up test fixtures before each test method."""
        self.mock_context = Mock()
        self.mock_context.function_name = "test-function"

        # Mock environment variables
        self.env_patcher = patch.dict(
            os.environ,
            {
                "ATHENA_DATABASE_NAME": "test_database",
                "ATHENA_WORKGROUP_NAME": "test_workgroup",
                "S3_BUCKET_NAME": "test-bucket",
                "S3_RESULTS_BUCKET_NAME": "test-results-bucket",
                "NOTIFICATION_EMAILS": "test@example.com,admin@example.com",
            },
        )
        self.env_patcher.start()

    def tearDown(self):
        """Clean up after each test method."""
        self.env_patcher.stop()

    @patch("handler.ses_client")
    @patch("handler.generate_weekly_report")
    def test_lambda_handler_success(self, mock_generate_report, mock_ses):
        """Test successful lambda execution"""
        # Mock the report data
        mock_report_data = {
            "summary": {
                "total_revenue": 1000.50,
                "total_transactions": 10,
                "total_stores": 2,
            },
            "details": [],
        }
        mock_generate_report.return_value = mock_report_data

        # Mock the event
        event = {"source": "eventbridge", "report_type": "weekly"}

        # Call the handler
        response = lambda_handler(event, self.mock_context)

        # Assertions
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(
            body["message"], "Weekly report generated and sent successfully"
        )
        self.assertIn("report_summary", body)

        mock_generate_report.assert_called_once()

    @patch("handler.send_error_notification")
    @patch("handler.generate_weekly_report")
    def test_lambda_handler_error(self, mock_generate_report, mock_send_error):
        """Test lambda execution with error"""
        # Mock an exception
        mock_generate_report.side_effect = Exception("Test error")

        event = {"source": "eventbridge"}

        # Call the handler
        response = lambda_handler(event, self.mock_context)

        # Assertions
        self.assertEqual(response["statusCode"], 500)
        body = json.loads(response["body"])
        self.assertEqual(body["message"], "Error generating weekly report")
        self.assertEqual(body["error"], "Test error")

        mock_send_error.assert_called_once_with("Test error")

    def test_process_query_results_with_data(self):
        """Test processing query results with data"""
        # Mock Athena results
        mock_results = {
            "ResultSet": {
                "Rows": [
                    {  # Header row
                        "Data": [
                            {"VarCharValue": "store_location"},
                            {"VarCharValue": "total_transactions"},
                            {"VarCharValue": "total_revenue"},
                        ]
                    },
                    {  # Data row
                        "Data": [
                            {"VarCharValue": "New York"},
                            {"VarCharValue": "10"},
                            {"VarCharValue": "1000.50"},
                            {"VarCharValue": "100.05"},
                            {"VarCharValue": "25"},
                            {"VarCharValue": "credit_card"},
                            {"VarCharValue": "8"},
                        ]
                    },
                ]
            }
        }

        # Process results
        result = process_query_results(mock_results)

        # Assertions
        self.assertIn("summary", result)
        self.assertIn("details", result)
        self.assertEqual(result["summary"]["total_revenue"], 1000.50)
        self.assertEqual(result["summary"]["total_transactions"], 10)
        self.assertEqual(result["summary"]["total_stores"], 1)
        self.assertEqual(len(result["details"]), 1)

    def test_process_query_results_no_data(self):
        """Test processing query results with no data"""
        # Mock empty results
        mock_results = {
            "ResultSet": {
                "Rows": [
                    {  # Only header row
                        "Data": [
                            {"VarCharValue": "store_location"},
                            {"VarCharValue": "total_transactions"},
                        ]
                    }
                ]
            }
        }

        # Process results
        result = process_query_results(mock_results)

        # Assertions
        self.assertEqual(result["summary"]["total_revenue"], 0)
        self.assertEqual(result["summary"]["total_transactions"], 0)
        self.assertEqual(result["summary"]["total_stores"], 0)
        self.assertEqual(len(result["details"]), 0)
        self.assertIn("No data available", result["message"])

    @patch("handler.get_query_results")
    @patch("handler.execute_athena_query")
    def test_generate_weekly_report(self, mock_execute, mock_get_results):
        """Test generate weekly report function"""
        # Mock return values
        mock_execute.return_value = "test-execution-id"
        mock_get_results.return_value = {
            "ResultSet": {
                "Rows": [
                    {"Data": [{"VarCharValue": "header"}]},  # Header
                    {
                        "Data": [  # Data row
                            {"VarCharValue": "Store1"},
                            {"VarCharValue": "5"},
                            {"VarCharValue": "500.00"},
                            {"VarCharValue": "100.00"},
                            {"VarCharValue": "10"},
                            {"VarCharValue": "cash"},
                            {"VarCharValue": "4"},
                        ]
                    },
                ]
            }
        }

        # Call function
        result = generate_weekly_report()

        # Assertions
        self.assertIn("summary", result)
        self.assertIn("details", result)
        mock_execute.assert_called_once()
        mock_get_results.assert_called_once_with("test-execution-id")


if __name__ == "__main__":
    unittest.main()
