data "aws_eks_cluster" "kubernetes" {
  name = module.kubernetes.cluster_name
  depends_on = [ module.kubernetes ]
}

data "aws_eks_cluster_auth" "kubernetes" {
  name = module.kubernetes.cluster_name
  depends_on = [ module.kubernetes ]
}

provider "kubernetes" {
  host                   = module.kubernetes.cluster_endpoint
  cluster_ca_certificate = base64decode(module.kubernetes.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.kubernetes.token
}

provider "helm" {
  kubernetes {
    host                   = module.kubernetes.cluster_endpoint
    cluster_ca_certificate = base64decode(module.kubernetes.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.kubernetes.token
  }
}

