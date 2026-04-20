# ---------------------------------------------------------
# RDS MySQL Instance (Primary)
# ---------------------------------------------------------
resource "aws_db_instance" "mysql" {
  # RDS インスタンス名（AWS 上での識別子）
  identifier = "my-mysql"

  # DB エンジン設定
  engine         = "mysql"
  engine_version = "8.0"

  # インスタンススペック
  instance_class = "db.t3.micro"

  # ストレージ容量（GB）
  allocated_storage = 20

  # 認証情報（variables.tf で変数化）
  username = var.db_username
  password = var.db_password

  # ネットワーク設定（RDS Subnet Group と SG）
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # セキュリティ設定
  publicly_accessible = false # パブリックアクセス禁止
  multi_az            = true  # マルチ AZ（冗長化）

  # 自動バックアップ保持期間（日）
  backup_retention_period = 7

  # 削除保護（本番では true）
  deletion_protection = false

  # 削除時のスナップショットをスキップ
  skip_final_snapshot = true

  # タグ
  tags = {
    Name = "mysql-instance"
  }
}

# ---------------------------------------------------------
# RDS MySQL Read Replica（読み取り専用レプリカ）
# ---------------------------------------------------------
resource "aws_db_instance" "mysql_replica" {
  # レプリカの識別子
  identifier = "my-mysql-replica"

  # 複製元（Primary の identifier を参照）
  replicate_source_db = aws_db_instance.mysql.identifier

  # インスタンススペック（Primary と同じで OK）
  instance_class = "db.t3.micro"

  # パブリックアクセス禁止
  publicly_accessible = false

  # 削除時のスナップショットをスキップ
  skip_final_snapshot = true

  # タグ
  tags = {
    Name = "mysql-replica"
  }
}
