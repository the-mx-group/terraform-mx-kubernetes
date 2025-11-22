resource "aws_iam_policy" "this" {
  description = "Policy for ${var.irsa_role_name_prefix}-external-dns addon"
  name        = "${var.irsa_role_name_prefix}-external-dns"
  policy = jsonencode(
    {
      Statement = [
        {
          Action   = "route53:ChangeResourceRecordSets"
          Effect   = "Allow"
          Resource = "arn:aws:route53:::hostedzone/*"
          Sid      = "ChangeResourceRecordSets"
        },
        {
          Action = [
            "route53:ListTagsForResource",
            "route53:ListResourceRecordSets",
            "route53:ListHostedZones",
          ]
          Effect   = "Allow"
          Resource = "*"
          Sid      = "ListResourceRecordSets"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "this" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${var.cluster_identity_oidc_issuer}:sub" = "system:serviceaccount:kube-system:external-dns"
            }
          }
          Effect = "Allow"
          Principal = {
            Federated = var.cluster_identity_oidc_issuer_arn
          }
          Sid = ""
        },
      ]
      Version = "2012-10-17"
    }
  )
  name                 = "${var.irsa_role_name_prefix}-external-dns"
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}



