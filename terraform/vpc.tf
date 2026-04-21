# VPC (Virtual Private Cloud)
# - AWS 上に独立したネットワーク空間を作成する基盤リソース
# - 全てのサブネット（Public / Private）はこの VPC 内に配置される
# - 構成図の 10.0.0.0/16 のネットワーク範囲に対応
resource "aws_vpc" "main" {
  # VPC 全体のアドレス範囲
  # - /16 を切ることで、Public / Private サブネットを複数作成可能
 
  cidr_block = "10.0.0.0/16"

  # DNS サポートを有効化
  # - VPC 内で名前解決（EC2 の internal DNS）が利用可能になる
  # -------------------------------------------------------
  enable_dns_support = true
  
  # DNS ホスト名を有効化
  # - Public IP を持つ EC2 にパブリック DNS 名が割り当てられる
  # - ALB や Bastion など外部公開リソースで必須
  # -------------------------------------------------------
  enable_dns_hostnames = true

  # -------------------------------------------------------
  # タグ（統一タグ + リソース固有タグ）
  # - default_tags は terraform.tfvars で定義
  # - merge により共通タグと Name タグを統合
  # -------------------------------------------------------
  tags = merge(
    var.default_tags,
    { Name = "main-vpc" }
  )
}
