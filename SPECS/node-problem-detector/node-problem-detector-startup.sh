#!/bin/sh

# This script exists to be able to fetch the kube-apiserver address at runtime.
# Note: kubeconfig can live in different places depending on whether the node is a master node or a worker node
if [ -f "/home/azureuser/.kube/config" ]
then
    KUBECONFIG_FILE="/home/azureuser/.kube/config"
elif [ -f "/var/lib/kubelet/kubeconfig" ]
then
    KUBECONFIG_FILE="/var/lib/kubelet/kubeconfig"
fi
KUBE_APISERVER_ADDR=$(grep server ${KUBECONFIG_FILE} | awk -F"server: " '{print $2}')
NODE_NAME=$(hostname | tr '[:upper:]' '[:lower:]')
SYSTEM_LOG_MONITOR_FILES=$(find /etc/node-problem-detector.d/system-log-monitor/ -path '*json' | paste -s -d ',' -)
CUSTOM_PLUGIN_MONITOR_FILES=$(find /etc/node-problem-detector.d/custom-plugin-monitor/ -path '*json' | paste -s -d ',' -)
SYSTEM_STATS_MONITOR_FILES=$(find /etc/node-problem-detector.d/system-stats-monitor/ -path '*json' | paste -s -d ',' -)

# You can review the preconfigured systemd defaults here at:
#   https://github.com/kubernetes/node-problem-detector/blob/master/config/systemd/node-problem-detector-metric-only.service
#
#   Here is a list of the configurable runtime flags for node-problem-detector 
# 
# root@ubuntu-bionic:~# /usr/local/bin/node-problem-detector -h
# Usage of /usr/local/bin/node-problem-detector:
#      --address string                           The address to bind the node problem detector server. (default "127.0.0.1")
#      --alsologtostderr                          log to standard error as well as files
#      --apiserver-override string                Custom URI used to connect to Kubernetes ApiServer. This is ignored if --enable-k8s-exporter is false.
#      --apiserver-wait-interval duration         The interval between the checks on the readiness of kube-apiserver. This is ignored if --enable-k8s-exporter is false. (default 5s)
#      --apiserver-wait-timeout duration          The timeout on waiting for kube-apiserver to be ready. This is ignored if --enable-k8s-exporter is false. (default 5m0s)
#      --config.custom-plugin-monitor strings     Comma separated configurations for custom-plugin-monitor monitor. Set to config file paths.
#      --config.system-log-monitor strings        Comma separated configurations for system-log-monitor monitor. Set to config file paths.
#      --config.system-stats-monitor strings      Comma separated configurations for system-stats-monitor monitor. Set to config file paths.
#      --enable-k8s-exporter                      Enables reporting to Kubernetes API server. (default true)
#      --exporter.stackdriver string              Configuration for Stackdriver exporter. Set to config file path.
#      --hostname-override string                 Custom node name used to override hostname
#      --k8s-exporter-heartbeat-period duration   The period at which k8s-exporter does forcibly sync with apiserver. (default 5m0s)
#      --log_backtrace_at traceLocation           when logging hits line file:N, emit a stack trace (default :0)
#      --log_dir string                           If non-empty, write log files in this directory
#      --logtostderr                              log to standard error instead of files
#      --port int                                 The port to bind the node problem detector server. Use 0 to disable. (default 20256)
#      --prometheus-address string                The address to bind the Prometheus scrape endpoint. (default "127.0.0.1")
#      --prometheus-port int                      The port to bind the Prometheus scrape endpoint. Prometheus exporter is enabled by default at port 20257. Use 0 to disable. (default 20257)
#      --stderrthreshold severity                 logs at or above this threshold go to stderr (default 2)
#  -v, --v Level                                  log level for V logs
#      --version                                  Print version information and quit
#      --vmodule moduleSpec                       comma-separated list of pattern=N settings for file-filtered logging
#  pflag: help requested
# In order to enable reporting to kubernetes, set KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT  
#   or use the --apiserver-override flag
/usr/local/bin/node-problem-detector \
    --config.system-log-monitor=${SYSTEM_LOG_MONITOR_FILES} \
    --config.custom-plugin-monitor=${CUSTOM_PLUGIN_MONITOR_FILES} \
    --config.system-stats-monitor=${SYSTEM_STATS_MONITOR_FILES} \
    --prometheus-address 0.0.0.0 \
    --apiserver-override "${KUBE_APISERVER_ADDR}?inClusterConfig=false&auth=${KUBECONFIG_FILE}" \
    --hostname-override "${NODE_NAME}" \
    --logtostderr
