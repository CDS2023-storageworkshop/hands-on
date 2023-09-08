#!/bin/bash
shopt -s expand_aliases
alias rke1='export KUBECONFIG=/home/user/kubeconfigs/rke1/kube_config_cluster.yml'
alias rke2='export KUBECONFIG=/home/user/kubeconfigs/rke2/kube_config_cluster.yml'

echo "#######################################################################################################"
echo "Add Region & Zone labels to Kubernetes nodes"
echo "#######################################################################################################"

kubectl label node worker1.rke1.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node worker2.rke1.demo.netapp.com "topology.kubernetes.io/region=west" --overwrite
kubectl label node worker3.rke1.demo.netapp.com "topology.kubernetes.io/region=east" --overwrite

kubectl label node worker1.rke1.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node worker2.rke1.demo.netapp.com "topology.kubernetes.io/zone=west1" --overwrite
kubectl label node worker3.rke1.demo.netapp.com "topology.kubernetes.io/zone=east1" --overwrite


echo "#######################################################################################################"
echo "Make tridentctl working"
echo "#######################################################################################################"

cd
mkdir 22.10.0 && cd 22.10.0
wget https://github.com/NetApp/trident/releases/download/v22.10.0/trident-installer-22.10.0.tar.gz
tar -xf trident-installer-22.10.0.tar.gz
sudo rm -f /usr/bin/tridentctl
sudo cp trident-installer/tridentctl /usr/bin/

echo
tridentctl -n trident version

echo "#######################################################################################################"
echo "UPDATING RKE1 ISCSI CONFIG"
echo "#######################################################################################################"
echo
i=0
hosts=( "cp1.rke1" "cp2.rke1" "worker1.rke1" "worker2.rke1" "worker3.rke1")
for host in "${hosts[@]}"
do
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i 's/^\(node.session.scan\).*/\1 = manual/' /etc/iscsi/iscsid.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i '2 a \    find_multipaths no' /etc/multipath.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i /iqn/s/.$/$i/ /etc/iscsi/initiatorname.iscsi"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart iscsid"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart multipathd"
  i=$((i+1))
done

rke1
kubectl get -n trident po -l app=node.csi.trident.netapp.io -o name | xargs kubectl delete -n trident


echo "#######################################################################################################"
echo "UPDATING RKE2 ISCSI CONFIG"
echo "#######################################################################################################"
echo
hosts=( "cp1.rke2" "cp2.rke2" "worker1.rke2" "worker2.rke2" "worker3.rke2")
for host in "${hosts[@]}"
do
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i 's/^\(node.session.scan\).*/\1 = manual/' /etc/iscsi/iscsid.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i '2 a \    find_multipaths no' /etc/multipath.conf"
  ssh -o "StrictHostKeyChecking no" root@$host -t "sed -i /iqn/s/.$/$i/ /etc/iscsi/initiatorname.iscsi"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart iscsid"
  ssh -o "StrictHostKeyChecking no" root@$host -t "systemctl restart multipathd"
  i=$((i+1))
done

rke2
kubectl get -n trident po -l app=node.csi.trident.netapp.io -o name | xargs kubectl delete -n trident


echo "#######################################################################################################"
echo "CONFIGURE iSCSI on CLUSTER1 (SVM 'SVM1')"
echo "#######################################################################################################"
echo

# Create the first iSCSI LIF on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.245", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster1-01" }
    }
  },
  "name": "iSCSIlif1",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/network/ip/interfaces"


# Create the second iSCSI LIF on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.246", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster1-02" }
    }
  },
  "name": "iSCSIlif2",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/network/ip/interfaces"

# Enable iSCSI on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "enabled": true,
  "svm": { "name": "svm1" }
}' "https://cluster1.demo.netapp.com/api/protocols/san/iscsi/services"


echo "#######################################################################################################"
echo "CONFIGURE iSCSI on CLUSTER3 (SVM 'SVM2')"
echo "#######################################################################################################"
echo

# Create one iSCSI LIF on SVM1
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "ip": { "address": "192.168.0.247", "netmask": "24" },
  "location": {
    "home_port": {
      "name": "e0d",
      "node": { "name": "cluster3-01" }
    }
  },
  "name": "iSCSIlif1",
  "scope": "svm",
  "service_policy": { "name": "default-data-iscsi" },
  "svm": { "name": "svm2" }
}' "https://cluster3.demo.netapp.com/api/network/ip/interfaces"

# Enable iSCSI on SVM2
curl -X POST -ku admin:Netapp1! -H "accept: application/json" -H "Content-Type: application/json" -d '{
  "enabled": true,
  "svm": { "name": "svm2" }
}' "https://cluster3.demo.netapp.com/api/protocols/san/iscsi/services"


echo "#######################################################################################################"
echo "ADD NEW TRIDENT BACKENDS & SC ON RKE1"
echo "#######################################################################################################"
echo

cd /home/user/hands-on/prework/

rke1
tridentctl -n trident create backend -f rke1_trident_svm1_san_backend.json
tridentctl -n trident create backend -f rke1_trident_svm1_san_eco_backend.json

echo "#######################################################################################################"
echo "ADD NEW TRIDENT BACKENDS & SC ON RKE2"
echo "#######################################################################################################"
echo

rke2
tridentctl -n trident create backend -f rke2_trident_svm2_san_backend.json
tridentctl -n trident create backend -f rke2_trident_svm2_san_eco_backend.json
kubectl create -f rke2_sc_san.yaml
kubectl create -f rke2_sc_saneco.yaml

rke1