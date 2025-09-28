variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sample_data_files" {
  description = "List of sample data files to upload"
  type        = list(string)
  default     = ["sales_data_2024_01.json", "sales_data_2024_02.json"]
}
