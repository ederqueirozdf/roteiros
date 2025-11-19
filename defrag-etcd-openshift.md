# Procedimento Operacional — Defrag ETCD no OpenShift

Este documento descreve o passo a passo para identificar o líder do ETCD e executar o *defrag* de forma segura, seguindo a mesma lógica utilizada no script automatizado fornecido.

---

## Pré-requisitos

- Acesso ao cluster via `oc` com permissões administrativas.
- Todos os pods do ETCD devem estar em estado `Running`.
- Namespace dos pods ETCD:

	  openshift-etcd

 ## 1. Identificar todos os pods do ETCD

 Liste os pods:

	   oc get pods -n openshift-etcd -l app=etcd

Exemplo de saída:

	  etcd-master-0
	  etcd-master-1
	  etcd-master-2

## 2. Verificar o status do cluster ETCD

Execute em qualquer pod:

	  oc exec -n openshift-etcd <etcd-pod> -c etcd -- \
	  etcdctl endpoint status -w table --cluster

Exemplo de saída:

	  ENDPOINT               DB SIZE   IS LEADER
	  https://10.0.0.11:2379   8.6 MB     false
	  https://10.0.0.12:2379   8.4 MB     true
	  https://10.0.0.13:2379   8.5 MB     false

## 3. Identificar qual pod é o líder

Liste IPs e pods:

	  oc get pod -n openshift-etcd -o wide

> Compare o IP do endpoint líder com o IP dos pods.

Exemplo: 
10.0.0.12 → etcd-master-1. Na tabela acima, o ip 10.0.12 é o líder. Portando, este será o último a ser feito o defrag.

## 4. Defrag

	  oc rsh -n openshift-etcd etcd-master-0

Execute:

	  etcdctl endpoint status -w table
	  unset ETCDCTL_ENDPOINTS
	  rev=$(etcdctl --endpoints 127.0.0.1:2379 endpoint status --write-out="json" | egrep -o '"revision":[0-9]*' | egrep -o '[0-9]*')
	  etcdctl --endpoints 127.0.0.1:2379 compact ${rev}
	  etcdctl --command-timeout=1m --endpoints 127.0.0.1:2379 defrag
	  etcdctl alarm list
	  etcdctl --endpoints 127.0.0.1:2379 alarm disarm
	  exit

  Execute o passo acima nos demais pods do etc etcd-master-2 e por ultimo, neste exemplo, o etcd-master-1 (por ser o líder).

## 4. Validacao

  oc exec -n openshift-etcd <etcd-pod> -c etcd -- etcdctl endpoint status -w table --cluster

Verifique:
	•	Redução do DB SIZE
	•	Alarms desarmados
	•	Todos os endpoints acessíveis

📝 Observações Importantes
	•	Não execute defrag simultâneo nos nós.
	•	O líder deve sempre ser o último a receber defrag.
	•	Pequenos picos de latência do API Server podem ocorrer durante o processo.


# Script para DEFRAG
	
	    #!/usr/bin/env bash
	    
	    NAMESPACE="openshift-etcd"
	    
	    echo "[INFO] Iniciando defrag etcd..."
	    
	    # Lista todos os pods etcd
	    ETCD_PODS=($(oc get pods -n "$NAMESPACE" -l app=etcd -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort))
	    
	    # Executa etcdctl em qualquer membro para obter a tabela
	    STATUS=$(oc exec -n "$NAMESPACE" "${ETCD_PODS[0]}" -c etcd -- \
	      etcdctl endpoint status -w table --cluster 2>/dev/null)
	    
	    # Identifica o endpoint onde IS LEADER == true
	    LEADER_ENDPOINT=$(echo "$STATUS" | awk '/true/ {print $2; exit}')
	    
	    if [[ -z "$LEADER_ENDPOINT" ]]; then
	      echo "[ERROR] Não foi possível identificar o líder no output do etcdctl."
	      exit 1
	    fi
	    
	    echo "[INFO] Endpoint do líder: $LEADER_ENDPOINT"
	    
	    # Identifica o pod correspondente ao endpoint líder
	    LEADER_POD=$(for pod in "${ETCD_PODS[@]}"; do
	      POD_IP=$(oc get pod -n "$NAMESPACE" "$pod" -o jsonpath='{.status.podIP}')
	      if echo "$LEADER_ENDPOINT" | grep -q "$POD_IP"; then
	        echo "$pod"
	        break
	      fi
	    done)
	    
	    if [[ -z "$LEADER_POD" ]]; then
	      echo "[ERROR] Não foi possível mapear o líder para um pod."
	      exit 1
	    fi
	    
	    echo "[INFO] Líder identificado: $LEADER_POD"
	    
	    # Monta ordem: todos os pods exceto o líder, depois o líder
	    ORDER=($(printf "%s\n" "${ETCD_PODS[@]}" | grep -v "$LEADER_POD"))
	    ORDER+=("$LEADER_POD")
	    
	    # Executa defrag em cada pod, líder por último
	    for POD in "${ORDER[@]}"; do
	      echo "--------------------------------------------"
	      echo "[INFO] Executando defrag em $POD"
	      oc rsh -n "$NAMESPACE" "$POD" /bin/bash -c "
	        etcdctl endpoint status -w table --cluster
	        unset ETCDCTL_ENDPOINTS
	        etcdctl --command-timeout=30s --endpoints=https://localhost:2379 defrag
	        etcdctl alarm list
	        etcdctl alarm disarm
	        sleep 100
	      "
	    done 
	    
