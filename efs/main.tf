resource "helm_release" "efs-storage-class" {
  name       = "efs-storage-class"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"
  version    = "2.4.3"
  namespace  = "kube-system"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region_code}.amazonaws.com/eks/aws-efs-csi-driver"
  }

  set {
    name  = "controller.podAnnotations.cluster-autoscaler\\.kubernetes\\.io/safe-to-evict"
    value = "\"true\""
  }
}

# PDB for efs csi controller, for kube 1.25+
resource "kubernetes_pod_disruption_budget_v1" "efs-csi-controller" {
  count = tonumber(var.kubernetes_version) >= 1.25 ? 1 : 0
  metadata {
    name      = "efs-csi-controller-pdb"
    namespace = "kube-system"
  }
  spec {
    max_unavailable = 1
    selector {
      match_labels = {
        "app" = "efs-csi-controller"
      }
    }
  }
}

# PDB for efs csi controller, for kube 1.24 and prior
resource "kubernetes_pod_disruption_budget" "efs-csi-controller-pdb" {
  count = tonumber(var.kubernetes_version) < 1.25 ? 1 : 0
  metadata {
    name      = "efs-csi-controller-pdb"
    namespace = "kube-system"
  }
  spec {
    max_unavailable = 1
    selector {
      match_labels = {
        "app" = "efs-csi-controller"
      }
    }
  }
}

resource "aws_iam_policy" "efs-policy" {
  name        = "AmazonEKS_EFS_CSI_Driver_Policy-${var.cluster_name}"
  path        = "/"
  description = "Allows access to EFS resources from Kubernetes"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"elasticfilesystem:DescribeAccessPoints",
				"elasticfilesystem:DescribeFileSystems"
			],
			"Resource": "*"
		},
		{
			"Effect": "Allow",
			"Action": [
				"elasticfilesystem:CreateAccessPoint"
			],
			"Resource": "*",
			"Condition": {
				"StringLike": {
					"aws:RequestTag/efs.csi.aws.com/cluster": "true"
				}
			}
		},
		{
			"Effect": "Allow",
			"Action": "elasticfilesystem:DeleteAccessPoint",
			"Resource": "*",
			"Condition": {
				"StringEquals": {
					"aws:ResourceTag/efs.csi.aws.com/cluster": "true"
				}
			}
		}
	]
}
EOF
}

resource "aws_iam_role" "efs-csi-driver-role" {
  name = "AmazonEKS_EFS_CSI_DriverRole-${var.cluster_name}"
  assume_role_policy = templatefile("${path.module}/policy/oidc_assume_role_policy.json", {
    OIDC_ARN  = var.oidc_arn,
    OIDC_URL  = replace(var.oidc_url, "https://", ""),
    NAMESPACE = "kube-system",
    SA_NAME   = "efs-csi-controller-sa"
  })
}

resource "aws_iam_role_policy_attachment" "efs-csi-driver-role" {
  role       = aws_iam_role.efs-csi-driver-role.name
  policy_arn = aws_iam_policy.efs-policy.arn
  depends_on = [aws_iam_role.efs-csi-driver-role]
}

resource "kubernetes_service_account" "efs-csi-controller-sa" {
  metadata {
    name = "efs-csi-controller-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs-csi-driver-role.arn
    }
  }
}
