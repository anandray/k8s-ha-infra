# RDS MySQL
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

resource "aws_db_instance" "mysql" {
  identifier           = "${var.environment}-mysql"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  storage_type        = "gp2"
  db_name             = "main"
  username            = var.db_username
  password            = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az              = true

  tags = {
    Name = "${var.environment}-mysql"
  }
}

# Aurora MySQL
resource "aws_rds_cluster" "aurora" {
  cluster_identifier  = "${var.environment}-aurora"
  engine             = "aurora-mysql"
  engine_version     = "5.7.mysql_aurora.2.11.2"
  database_name      = "main"
  master_username    = var.db_username
  master_password    = var.db_password
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name = "${var.environment}-aurora"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = 2
  identifier         = "${var.environment}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
}

# DynamoDB
resource "aws_dynamodb_table" "main" {
  name           = "${var.environment}-dynamodb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.environment}-dynamodb"
  }
}

# ElastiCache Redis
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "redis" {
  name        = "${var.environment}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-redis-sg"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-redis"
  engine              = "redis"
  node_type           = "cache.t3.medium"
  num_cache_nodes     = 1
  parameter_group_name = "default.redis6.x"
  port                = 6379
  security_group_ids  = [aws_security_group.redis.id]
  subnet_group_name   = aws_elasticache_subnet_group.main.name

  tags = {
    Name = "${var.environment}-redis"
  }
} 