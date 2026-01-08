HISTSIZE=100000
HISTFILESIZE=200000
HIST_STAMPS="dd.mm.yyyy"


# User configuration
 

# ---------------------------------------------------------------


####
#### OPENSSL
####
# --- VERIFICA SUBJECT
# openssl x509 -noout -dates -subject -issuer cert-des-v4.crt
# --- VERIFICA DATA
#openssl x509 -noout -dates -subject -issuer -in cert-des-v4.crt
# --- VALIDA CA COM CERT
#openssl verify -CAfile ca-des111.crt tls-des111.crt

##

alias jq.path="jq -r '[paths | map(.|tostring) | join("/")]'"


#######################
#### ALIASES OCP ######
#######################

ca.ldap(){
 oc get cm  ldap-ca -n openshift-config -o jsonpath='{.data.ca\.crt}' |  openssl crl2pkcs7 -nocrl -certfile /dev/stdin | openssl pkcs7 -print_certs -noout -text

}

cluster.network(){
  oc get network.config.openshift.io cluster -o yaml | yq '.spec.clusterNetwork, .status.clusterNetwork'
}

keepalived.api.ownership(){

  for i in $(oc get po -n openshift-vsphere-infra --no-headers=true | grep -v "coredns\|haproxy" | awk {'print $1'}); do echo $i; oc -n openshift-vsphere-infra logs pod/${i} -c keepalived | tail -n 15 | grep "Sending gratuitous ARP" ; done
}


keepalived.master0.conf(){
  oc get pods -n openshift-vsphere-infra --no-headers | grep '^keepalived.*-master-0' | awk '{print $1}' | head -n 1 | xargs -I {} oc exec -it {} -n openshift-vsphere-infra -c keepalived -- cat /etc/keepalived/keepalived.conf
}


keepalived.master1.conf(){
  oc get pods -n openshift-vsphere-infra --no-headers | grep '^keepalived.*-master-1' | awk '{print $1}' | head -n 1 | xargs -I {} oc exec -it {} -n openshift-vsphere-infra -c keepalived -- cat /etc/keepalived/keepalived.conf
}

keepalived.master2.conf(){
  oc get pods -n openshift-vsphere-infra --no-headers | grep '^keepalived.*-master-2' | awk '{print $1}' | head -n 1 | xargs -I {} oc exec -it {} -n openshift-vsphere-infra -c keepalived -- cat /etc/keepalived/keepalived.conf
}


pods.gc.config(){
  oc get --raw /api/v1/nodes/$1/proxy/configz | jq

}
#aliases PODs

pullsecret.dockerconfigjson(){
  oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}'
}

vsphere.driver.pods(){
  oc get pods -n openshift-cluster-csi-drivers -o wide
}

vsphere.driver.project(){
  oc project openshift-cluster-csi-drivers
}

pods(){
  oc get pods
}

pow(){
  oc get pods -o wide
}

poyaml(){
  oc get pods $1 -o yaml
}

dpod(){
  oc describe pods $1
}

dpodf(){
  oc delete pod $i --grace-period=0 --force
}

pods.error(){
  oc get po -A | grep -E 'Error'
}

pods.status.error.resume(){
  echo "Quantidade de pods e tipo de status:"
  oc get pods -A --no-headers | grep -v Running | awk '{print $4}' | sort | uniq -c
}

pods.error.count(){
  oc get po -A | grep -E 'Error' | wc -l
}

pods.node.list(){
  oc get pods -A --field-selector spec.nodeName=$1 -o wide
}

pods.delete.error(){
echo "Delete pods status: ImagePullBackOff|CreateContainerError|CreateContainerConfigError|InvalidImageName|ContainerStatusUnknown"
podserrors=$(oc get pods -A | grep -E 'ImagePullBackOff|CreateContainerError|CreateContainerConfigError|InvalidImageName|ContainerStatusUnknown' | egrep -v '(Running|Completed|NAME|openshift)' | wc -l)
echo "Total $podserrors"
oc get pods -A | grep -E 'ImagePullBackOff|CreateContainerError|CreateContainerConfigError|InvalidImageName|ContainerStatusUnknown' | egrep -v '(Running|Completed|NAME|openshift)' | awk '{print $1, $2}' | while read namespace pod; do
  oc delete pod $pod -n $namespace
done

}

ingress.default-externo.secret.cert.issue(){
oc -n openshift-ingress get secret default-cert-externo-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates -subject -issuer
}

ingress.default.secret.cert.issue(){
  oc -n openshift-ingress get secret apps-default-cert-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates -subject -issuer

}

#Aliases Bastion

vip(){
  oc get cm cluster-config-v1 -n kube-system -o yaml | grep VIP

}
vip_help(){
  echo "oc get cm cluster-config-v1 -n kube-system -o yaml | grep VIP"
}

ingress.domain(){
  oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}' | sed 's/oauth-openshift//g'
}

domain(){
  oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}' | sed 's/oauth-openshift//g'
}

ingress(){
  oc get ingresscontroller -n openshift-ingress-operator
}

ingress.secret.cert.validate(){
  oc -n openshift-ingress get secret apps-default-cert-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates -subject -issuer
}

#aliases GATEKEEPER

gatekeeper.help(){
  echo -e "oc get validatingwebhookconfiguration | grep gatekeeper\n oc get mutatingwebhookconfiguration | grep gatekeeper"
}

gatekeeper.validatingwebhookconfiguration(){
  oc get validatingwebhookconfiguration | grep gatekeeper
}

gatekeeper.mutatingwebhookconfiguration(){
  oc get mutatingwebhookconfiguration | grep gatekeeper
}



#aliases NODES

nodes.state.mcp(){
  oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.machineconfiguration\.openshift\.io/state}{"\n"}{end}'
}
node.logs(){
  oc get nodes -l node-role.kubernetes.io/master --no-headers | awk '{print $1}' | head -n 1 | xargs -I {} oc adm node-logs --path=kube-apiserver {}
}

pnodes.help(){
  echo "oc get pod --field-selector=spec.nodeName="$1" -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[*].kind}{"\n"}{end}' | egrep -v '(DaemonSet|Node)'"
}

pnodes(){
    oc get pod --field-selector=spec.nodeName="$1" -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.ownerReferences[*].kind}{"\n"}{end}' | egrep -v '(DaemonSet|Node)'
}

nodes.infra(){
  oc get nodes -l node-role.kubernetes.io/infra=
}

now(){
  oc get nodes -o wide
}

nodes.labels(){
  oc get nodes --show-labels
}

nodes(){
  oc get nodes
}

nodes.diskpressure(){
  oc get nodes -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="DiskPressure" and .status=="True")) | .metadata.name'
}

nodes.cpu (){
  oc get nodes -o=custom-columns=NAME:.metadata.name,CPU:.status.capacity.cpu --selector='node-role.kubernetes.io/worker,!node-role.kubernetes.io/infra'
}

nodes.cpu.total(){
  echo -e "\nCluster: $(oc cluster-info | grep k8s | awk '{print $7}' | awk -F. '{print $2}')\n"
  oc get nodes --selector='node-role.kubernetes.io/worker,!node-role.kubernetes.io/infra' --output=custom-columns=VM:".metadata.name",CPU:".status.capacity.cpu" | grep -v NAME | tee -a report-cpus.txt | awk '{ soma += $2 } END { print "\nCPU Total: " soma }'
}

nodes.pods.list(){
  oc get pods -A --field-selector spec.nodeName='$1' -o wide
}


# aliasses volumes Backup


velero(){
  oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero
}

volume.trident.label10d.listpv(){

  for i in `oc get pvc -A -l backup.volume.k8s.XPTO/politica=nas-client-10d | awk '{print $4}'`; do oc get pv $i -o jsonpath='{.spec.csi.volumeAttributes.internalName}{"\n"}'; done

}

volume.trident.svm.list(){
  oc get tridentbackends.trident.netapp.io -n psc-trident-operator -o json| jq -r '.items[] | {SVM: .config.ontap_config.svm , BACKENDUID: .backendUUID}'
}

volume.handle.govc(){
  oc get nodes | grep odf | awk '{print $1}' | while read VM ; do echo $VM && echo && govc device.info -vm="$VM" -json | jq '.devices[] | select(.type == "VirtualDisk") | {FileName: .backing.fileName, Label: .deviceInfo.label, volumeHandle: .vDiskId.id}' ; done
 
}


#Aliases Events

events.total.projects(){
  oc get events --all-namespaces --no-headers | awk '{print $1}' | sort | uniq -c | sort -nr
}

events(){
  oc get events --sort-by='lastTimestamp'
}

#aliases curl

curl.help(){
  echo -e "curl -k --resolve IP DOMINIO"
}

curl.resolv(){

  curl -k --resolve '$1' '$2'
}






#aliases APIcount Removed Releases

api.requests.counts.json(){
  echo -e "API Count Removed Release: \n"; oc get apirequestcounts -o jsonpath='{range .items[?(@.status.removedInRelease!="")]}{.status.removedInRelease}{"\t"}{.status.requestCount}{"\t"}{.metadata.name}{"\n"}{end}'
}


api.openshift.upgrade(){
  oc -n openshift-cluster-version get pods -l k8s-app=cluster-version-operator -o jsonpath="{.items[0].metadata.name}"; curl -k -v https://api.openshift.com/
}



#aliases VSPHERE

vsphere.secret(){
  oc get secret vsphere-creds -n kube-system -o json | jq -r '.data[]'
}

vcenter.datacenter(){
  oc get cm cluster-config-v1 -n kube-system -o yaml | grep "datacenter" | awk '{print $2}'
}

vcenter(){
  oc get cm cluster-config-v1 -n kube-system -o yaml | grep "vCenter" | awk '{print $2}'
}

#aliases OLM OPERATOR CATALOG

olm.project(){
  oc project openshift-operator-lifecycle-manager
}
olm.pods(){
  oc get pods -n openshift-operator-lifecycle-manager
}

olm.operator(){
  oc delete pods -n openshift-operator-lifecycle-manager -l app=olm-operator
}

olm.catalog(){
  oc get pods -n openshift-operator-lifecycle-manager -l app=catalog-operator
}

olm.catalog.delete(){
  oc delete pod -n openshift-operator-lifecycle-manager -l app=catalog-operator

}
olm.operator.delete(){
  oc delete pods -n openshift-operator-lifecycle-manager -l app=olm-operator
}



#aliases ETCD


etcd.overload.network2h(){
  echo ""
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd --since=2h | grep "Raft message since sending buffer is full"| wc -l ;done
}

etcd.overload.network24h(){
  echo ""
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd --since=24h | grep "Raft message since sending buffer is full"| wc -l ;done
}

etcd.overload.network72h(){
  echo ""
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd --since=72h | grep "Raft message since sending buffer is full"| wc -l ;done
}
etcd.overload.network(){
  echo ""
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd | grep "Raft message since sending buffer is full"| wc -l ;done
}

etcd.overload(){
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd| grep "server is likely overloaded"| wc -l; done
}

etcd.heartbeat(){
  echo -e "slow response times and may cause unexpected leadership changes which directly affects RHOCP control plane (https://access.redhat.com/articles/6967785)\n"
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd| grep 'failed to send out heartbeat on time'| wc -l; done
}

etcd.tooktolong(){
  echo -e "If the average request duration exceeds 100 milliseconds (https://access.redhat.com/articles/6967785)\n"
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd --since=24h | grep 'took too long'| wc -l; done
}

etcd.clock(){
  echo -e "When clocks are out of sync with each other they are causing I/O timeouts and the liveness probe is failing which makes the etcd pod to restart frequently.(https://access.redhat.com/articles/6967785)\n"
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd| grep 'clock difference'| wc -l; done
}

etcd.database.space(){
  echo -e "If etcd runs low on storage space, it raises a space quota alarm to protect the cluster from further writes.(https://access.redhat.com/articles/6967785)\n"
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd| grep 'database space exceeded'| wc -l; done
}

etcd.leadership.failures(){
  oc get pods -n openshift-etcd -l app=etcd --no-headers|while read POD line; do echo -e "$POD \n"; oc logs $POD -c etcd -n openshift-etcd| grep 'leader changed'| wc -l; done
}


etcd.count.objects(){
  echo -e "list how many objects there are by object type. (https://access.redhat.com/solutions/5864891)\n"
  oc get pods -n openshift-etcd -l app=etcd --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc rsh -n openshift-etcd {} bash -c "etcdctl get / --prefix --keys-only | sed '/^$/d' | cut -d/ -f3 | sort | uniq -c | sort -rn"
}

etcd.status.endpoint(){
  oc get pods -n openshift-etcd -l app=etcd --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc rsh -n openshift-etcd {} bash -c "etcdctl endpoint status --cluster -w table"
}


etcd.health(){
  oc get pods -n openshift-etcd -l app=etcd --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc rsh -n openshift-etcd {} bash -c "etcdctl endpoint.health"
}

etcd.wal.broken(){
  for i in $(oc get no --selector=node-role.kubernetes.io/master= -o NAME); do oc debug $i -- ls -lh /host/var/lib/etcd/member/wal/; done
}


#Aliases machines/machinesets

machines(){
  oc get machines.machine.openshift.io -n openshift-machine-api
}

machineset(){
  oc get machineset.machine.openshift.io -n openshift-machine-api
}

drain(){
  oc adm drain --ignore-daemonsets --delete-emptydir-data
}

mcp(){
  oc get machineconfigpool -n openshift-machine-api
}

mcp.currentConfig(){
  oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.machineconfiguration\.openshift\.io/currentConfig}{"\t"}{.metadata.annotations.machineconfiguration\.openshift\.io/state}{"\n"}{end}'
}

mcp.desiredConfig(){
  oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.machineconfiguration\.openshift\.io/desiredConfig}{"\t"}{.metadata.annotations.machineconfiguration\.openshift\.io/state}{"\n"}{end}'
}

mcp.status(){
  oc get mcp -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Updating" or .type=="Degraded") and .status=="True")) | [.metadata.name, "MachineCount=" + (.status.machineCount|tostring), "Ready=" + (.status.readyMachineCount|tostring), "Updated=" + (.status.updatedMachineCount|tostring)] | @tsv' | column -t

}

mcp.roles(){
  oc get mcp -o json | jq -r '.items[] | "\(.metadata.name) | \(.spec.nodeSelector.matchLabels)"' | column -s'|' -t
}

mcp.nodes(){
  oc get nodes -o json | jq -r '.items[] | "\(.metadata.name) | \(.metadata.labels | to_entries[] | select(.key | test("node-role.kubernetes.io")) | .key)"' | column -s '|' -t
}

mc(){
  oc get machineconfig -n openshift-machine-api
}



machine.datastore(){
  oc -n openshift-machine-api get machine.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.providerSpec.value.workspace.datastore}{"\n"}{end}'
}

machine.networkname(){
  oc -n openshift-machine-api get machine.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.providerSpec.value.network.devices[*].networkName}{"\n"}{end}'
}

machineset.datastore(){
  oc -n openshift-machine-api get machineset.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.template.spec.providerSpec.value.workspace.datastore}{"\n"}{end}'
}

machineset.datastore.select(){
  oc get machineset.machine.openshift.io -n openshift-machine-api -o json | jq -r '.items[] | select(.spec.template.spec.providerSpec.value.workspace.datastore == OCEAN09LUN0282) | .metadata.name'
}

machineset.networkname(){
  oc -n openshift-machine-api get machineset.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.template.spec.providerSpec.value.network.devices[*].networkName}{"\n"}{end}'
}


machineset.memoria(){
  oc -n openshift-machine-api get machineset.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.template.spec.providerSpec.value.memoryMiB}{"\n"}{end}'
}

machineset.cpu(){
  oc -n openshift-machine-api get machineset.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.template.spec.providerSpec.value.numCPUs}{"\n"}{end}'
}

machineset.replicas(){
  oc -n openshift-machine-api get machineset.machine.openshift.io -o jsonpath='{range .items[*]}{.metadata.name}{" | "}{.spec.replicas}{"\n"}{end}'}


#Aliases Elastic

elastic.allow.delete(){
    oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_all/_settings -d '{"index.blocks.read_only_allow_delete": null}' -XPUT"

}


elastic.explain(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cluster/allocation/explain?pretty"
}

elastic.pods(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}'
}

elastic.aliases(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cat/aliases"
}

elastic.indices(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cat/indices?pretty=true"
}

elastic.indices.health.date(){
    oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cat/indices?h=health,status,index,id,pri,rep,docs.count,docs.deleted,store.size,creation.date.string"
}

elastic.indices.health(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cat/health?v"
}

elastic.nodes(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=_cat/nodes?v"
}

elastic.delete.indices(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -- bash -c "es_util --query=$1 -XDELETE"
}

elastic.indices.write(){
    oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -c elasticsearch -- bash -c "es_util --query=*/_alias" | jq '. | to_entries[] | select(.value.aliases[].is_write_index == true)'
}

elastic.indices.recovery(){
    oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -c elasticsearch -- bash -c "es_util --query=_cat/recovery?v"
}

elastic.indices.unassigned(){
  oc get pods --selector=component=elasticsearch -n openshift-logging --no-headers | head -n1 | awk '{print $1}' | xargs -I {} oc exec -n openshift-logging {} -c elasticsearch -- bash -c "es_util --query=_cat/shards?h=index,shard,prirep,state,unassigned.reason,node | grep UNASSIGNED"
}

####Aliases CSR

csr.approve(){
  oc get csr --ignore-not-found=true | egrep -v '(Approved|NAME)' | awk '{print$1}' | xargs oc adm certificate approve
}
csr.check(){
        echo -e "${PURPLE}******** CHECKING IF HAVE CSR FOR APPROVAL *********${NC}"
        if [ "`oc get csr --ignore-not-found=true | egrep -v '(Approved|NAME)' | wc -l`" -gt "1" ]; then
            echo -e "${PURPLE}Found csr to approve.. Aproving them...${NC}"
            oc get csr --ignore-not-found=true | egrep -v '(Approved|NAME)' | awk '{print$1}' | xargs oc adm certificate approve
        fi
}

secret.legacy(){
  echo "https://access.redhat.com/solutions/7088515"
  oc get secrets -A --show-labels --field-selector type=kubernetes.io/service-account-token --selector kubernetes.io/legacy-token-last-used
}

drain.force(){
  oc adm drain $1 --ignore-daemonsets --force --disable-eviction --delete-emptydir-data
}
complete -C '$HOME/aws-cli/v2/current/bin/aws_completer' aws
