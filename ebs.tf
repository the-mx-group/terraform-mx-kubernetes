data "aws_iam_policy_document" "csi-controller-assume-policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.kubernetes.cluster_oidc_issuer_url, "https://", "")}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.kubernetes.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs-csi-controller-role" {
  count = var.ebs_addon_enabled ? 1 : 0
  name = "${local.cluster_name}-AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = data.aws_iam_policy_document.csi-controller-assume-policy.json
}

resource "aws_iam_role_policy_attachments_exclusive" "ebs-csi-controller-role" {
  count     = var.ebs_addon_enabled ? 1 : 0
  role_name = one(aws_iam_role.ebs-csi-controller-role).name
  policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
}

resource "aws_iam_role_policies_exclusive" "ebs-csi-controller-role" {
  count        = var.ebs_addon_enabled ? 1 : 0
  role_name    = one(aws_iam_role.ebs-csi-controller-role).name
  policy_names = []
}
