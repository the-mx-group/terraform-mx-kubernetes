####
# This package configures autoscaling for EKS clusters
####


resource "aws_iam_role" "this" {
  name = "${var.cluster_name}-cluster-autoscaler"
  description = "Cluster autoscaler role for cluster ${var.cluster_name}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": var.cluster_oidc_arn
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${var.cluster_oidc_endpoint}:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
})
}

# Setup role and policy to allow autoscaling
resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "${var.cluster_name}-eks-worker-autoscaling"
  description = "EKS worker node autoscaling policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}


####
# Install the autoscaler
####

# service account
resource "kubernetes_service_account" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app" = "cluster-autoscaler"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
  automount_service_account_token = true
}

#cluster role
resource "kubernetes_cluster_role" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app" = "cluster-autoscaler"
    }
  }

  rule {
    api_groups     = [""]
    resources      = ["events", "endpoints"]
    verbs          = ["create", "patch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["pods/eviction"]
    verbs          = ["create"]
  }

  rule {
    api_groups     = [""]
    resources      = ["pods/status"]
    verbs          = ["update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }

  rule {
    api_groups     = [""]
    resources      = ["nodes"]
    verbs          = ["watch", "list", "get", "update"]
  }

  rule {
    api_groups     = [""]
    resources      = [
      "namespaces",
      "pods",
      "services",
      "replicationcontrollers",
      "persistentvolumeclaims",
      "persistentvolumes",
    ]
    verbs          = ["watch", "list", "get"]
  }

  rule {
    api_groups     = ["extensions"]
    resources      = ["replicasets", "daemonsets"]
    verbs          = ["watch", "list", "get"]
  }

  rule {
    api_groups     = ["policy"]
    resources      = ["poddisruptionbudgets"]
    verbs          = ["watch", "list"]
  }

  rule {
    api_groups     = ["apps"]
    resources      = ["statefulsets", "replicasets", "daemonsets"]
    verbs          = ["watch", "list", "get"]
  }

  rule {
    api_groups     = ["storage.k8s.io"]
    resources      = ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities", "volumeattachments"]
    verbs          = ["watch", "list", "get"]
  }

  rule {
    api_groups     = ["batch", "extensions"]
    resources      = ["jobs"]
    verbs          = ["get", "list", "watch", "patch"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    verbs          = ["create"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resource_names = ["cluster-autoscaler"]
    resources      = ["leases"]
    verbs          = ["get", "update"]
  }
}

#scaler entity role
resource "kubernetes_role" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app" = "cluster-autoscaler"
    }
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    verbs          = ["create","list","watch"]
  }

  rule {
    api_groups     = [""]
    resource_names = ["cluster-autoscaler-status", "cluster-autoscaler-priority-expander"]
    resources      = ["configmaps"]
    verbs          = ["delete", "get", "update", "watch"]
  }
}

#bind the roles to the service account
resource "kubernetes_cluster_role_binding" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app" = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}

resource "kubernetes_role_binding" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app" = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cluster-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}

# and deploy the actual autoscaler deployment
resource "kubernetes_deployment" "autoscaler" {
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cluster-autoscaler"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port" = "8085"
        }
      }

      spec {
        service_account_name = "cluster-autoscaler"
        automount_service_account_token = true
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        container {
          image = "registry.k8s.io/autoscaling/cluster-autoscaler:v${var.autoscaling_version}"
          image_pull_policy = "Always"
          name  = "cluster-autoscaler"

          resources {
            limits = {
              cpu    = "100m"
              memory = "600Mi"
            }
            requests =  {
              cpu    = "100m"
              memory = "300Mi"
            }
          }

          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}",
          ]

          volume_mount {
            name = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-certificates.crt" #/etc/ssl/certs/ca-bundle.crt for Amazon Linux Worker Nodes
            read_only = true
          }
        }

        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }

      }
    }
  }
}

# PDB for autoscaler, for kube 1.25+
resource "kubernetes_pod_disruption_budget_v1" "autoscaler" {
  count = tonumber(var.kubernetes_version) >= 1.25 ? 1 : 0
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }
  spec {
    max_unavailable = "1"
    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }
  }
}

# PDB for autoscaler, for kube 1.24 and prior
resource "kubernetes_pod_disruption_budget" "autoscaler" {
  count = tonumber(var.kubernetes_version) < 1.25 ? 1 : 0
  metadata {
    name = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }
  spec {
    max_unavailable = "1"
    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }
  }
}
