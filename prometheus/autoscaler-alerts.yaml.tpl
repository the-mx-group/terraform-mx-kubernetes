# Alerts for node autoscaling health. Loaded (via templatefile) only when the cluster runs the
# cluster-autoscaler. Templated variables: ${cluster_name}.
#
# These exist because a runaway workload (e.g. thousands of Pending pods) can drive a cluster to its
# maximum node count, and a broken autoscaler (crash loop, missing IAM permission) fails silently:
# pods just sit Pending. None of the stock kube-prometheus-stack rules cover either case.
#
# Annotations are deliberately static text (no Prometheus {{ $labels }} templating) so they pass through
# Helm unchanged. Thresholds are intentionally conservative; tune `expr` / `for` per your environment.
additionalPrometheusRulesMap:
  node-autoscaling-alerts:
    groups:
      - name: node-autoscaling
        rules:
          - alert: ClusterAutoscalerDown
            # Not scraped successfully for 10m (covers crash loops, a missing deployment, or a broken scrape).
            expr: |
              (avg_over_time(up{job="cluster-autoscaler"}[10m]) < 0.5)
              or
              absent(up{job="cluster-autoscaler"})
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "[${cluster_name}] cluster-autoscaler is down or crash-looping"
              description: "The cluster-autoscaler on cluster ${cluster_name} has not been scrapeable for 10 minutes. Pending pods will not trigger new nodes. Check the cluster-autoscaler pod in kube-system (CrashLoopBackOff, OOMKilled, or AWS permission errors in its logs)."

          - alert: ClusterAutoscalerNearMaxNodes
            # Ready nodes at/above 85% of the autoscaler's configured maximum node count.
            expr: |
              sum(cluster_autoscaler_nodes_count{state="ready"})
              /
              max(cluster_autoscaler_max_nodes_count)
              > 0.85
            for: 30m
            labels:
              severity: warning
            annotations:
              summary: "[${cluster_name}] node count is near the autoscaler maximum"
              description: "Cluster ${cluster_name} has been at 85% or more of its maximum node count for 30 minutes. If this is unexpected, look for a runaway workload (for example CronJobs piling up Pending pods) before raising the maximum."

          - alert: ClusterAutoscalerErrors
            # The autoscaler is reporting failures (AWS API errors, permission problems, etc.).
            expr: sum by (type) (increase(cluster_autoscaler_errors_total[15m])) > 0
            for: 15m
            labels:
              severity: warning
            annotations:
              summary: "[${cluster_name}] cluster-autoscaler is reporting errors"
              description: "The cluster-autoscaler on cluster ${cluster_name} has been logging errors for 15 minutes. Check its logs in kube-system; a common cause is a missing IAM permission."

          - alert: ManyPodsUnschedulable
            # Independent of which autoscaler (or none) is in use: pods the scheduler can't place.
            expr: sum(kube_pod_status_unschedulable) > 20
            for: 30m
            labels:
              severity: warning
            annotations:
              summary: "[${cluster_name}] many pods have been unschedulable for 30 minutes"
              description: "More than 20 pods on cluster ${cluster_name} have been unschedulable for 30 minutes. The cluster is out of capacity or the autoscaler cannot add nodes."
