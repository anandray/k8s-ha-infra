# Jenkins IAM Role
resource "aws_iam_role" "jenkins" {
  name = "${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Jenkins IAM Policy
resource "aws_iam_policy" "jenkins" {
  name = "${var.environment}-jenkins-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Jenkins IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "jenkins" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins.arn
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private[0].id
  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  tags = {
    Name = "${var.environment}-jenkins"
  }
}

# Jenkins IAM Instance Profile
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins.name
} 