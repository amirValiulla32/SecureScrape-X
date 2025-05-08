# =========================================
# 🔐 Stage 3: Secrets Manager + IAM Role for EC2
# =========================================

# 1. Create a secret in Secrets Manager (for RDS creds)
resource "aws_secretsmanager_secret" "rds_creds" {
  name        = "rds-creds-${random_id.secret_suffix.hex}"
  description = "MySQL DB credentials for SecureScape X"
}

# 2. Secret value (username + password JSON)
resource "aws_secretsmanager_secret_version" "rds_creds_version" {
  secret_id     = aws_secretsmanager_secret.rds_creds.id
  secret_string = jsonencode({
    username = "admin"
    password = "temporarypass123"
  })
}
resource "random_id" "secret_suffix" {
  byte_length = 4
}

# 3. IAM policy to allow reading this secret
resource "aws_iam_policy" "read_rds_secret" {
  name        = "ReadRDSSecretPolicy"
  description = "Allows EC2 to read RDS credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.rds_creds.arn
      }
    ]
  })
}

# 4. IAM Role for EC2
resource "aws_iam_role" "ec2_ssm_secrets" {
  name = "EC2SecretsAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 5. Attach both Secrets Manager + SSM permissions
resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.ec2_ssm_secrets.name
  policy_arn = aws_iam_policy.read_rds_secret.arn
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_secrets.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 6. IAM instance profile to attach to EC2s
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-secrets"
  role = aws_iam_role.ec2_ssm_secrets.name
}

