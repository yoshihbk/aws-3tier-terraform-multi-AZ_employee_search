# AWS リージョン
variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "AWS リージョン"
}

# ---------------------------------------------------------
# VPC CIDR
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC 全体の CIDR ブロック"
}

# ---------------------------------------------------------
# Public / Private Subnets
variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
  description = "Public Subnet の CIDR 一覧"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
  description = "Private Subnet の CIDR 一覧"
}

# ---------------------------------------------------------
# Availability Zones
variable "azs" {
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
  description = "使用する AZ の一覧"
}

# ---------------------------------------------------------
# EC2 Instance Type
# ---------------------------------------------------------
variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 インスタンスタイプ"
}

# ---------------------------------------------------------
# 共通タグ（terraform.tfvars で値を設定）
# ---------------------------------------------------------
variable "default_tags" {
  type        = map(string)
  description = "全リソースに付与する共通タグ"
}

# ---------------------------------------------------------
# RDS 認証情報
variable "db_username" {
  type        = string
  description = "RDS のユーザー名"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS のパスワード（sensitive）"
}
