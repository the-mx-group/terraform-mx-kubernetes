####
# This package configures autoscaling for EKS clusters
####

# Setup role and policy to allow autoscaling
resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  for_each = toset(var.granted_roles)
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = each.key
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${var.cluster_name}"
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
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
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
    resources      = ["storageclasses", "csinodes"]
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
        container {
          image = "k8s.gcr.io/autoscaling/cluster-autoscaler:v${var.autoscaling_version}"
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
