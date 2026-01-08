#!/bin/bash

CLUSTER_VERSION_POD=$(oc get pod -n openshift-cluster-version -l k8s-app=cluster-version-operator -o jsonpath='{.items[0].metadata.name}')
INSIGHTS_POD=$(oc get pod -n openshift-insights -l app=insights-operator -o jsonpath='{.items[0].metadata.name}')
TELEMETER_POD=$(oc get pod -n openshift-monitoring -l app.kubernetes.io/component=telemetry-metrics-collector -o jsonpath='{.items[0].metadata.name}')

oc exec -n openshift-cluster-version $CLUSTER_VERSION_POD -- \
sh -c 'for url in https://api.openshift.com; do
  code=$(curl --connect-timeout 5 --max-time 5 -ks -o /dev/null -w "%{http_code}" "$url") || code="ERROR"
  if [ "$code" != "200" ]; then
    echo "FAILED: $url - Status: $code"
  fi
done'

oc exec -n openshift-insights $INSIGHTS_POD -- \
sh -c 'for url in https://infogw.api.openshift.com/healthz https://console.redhat.com https://cert-api.access.redhat.com https://api.access.redhat.com; do
  code=$(curl --connect-timeout 5 --max-time 5 -ks -o /dev/null -w "%{http_code}" "$url") || code="ERROR"
  if [ "$code" != "200" ]; then
    echo "FAILED: $url - Status: $code"
  fi
done'

oc exec -n openshift-monitoring $TELEMETER_POD -c telemeter-client -- \
sh -c 'for url in https://infogw.api.openshift.com/healthz; do
  code=$(curl --connect-timeout 5 --max-time 5 -ks -o /dev/null -w "%{http_code}" "$url") || code="ERROR"
  if [ "$code" != "200" ]; then
    echo "FAILED: $url - Status: $code"
  fi
done'
 
