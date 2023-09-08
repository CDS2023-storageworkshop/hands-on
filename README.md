# :trident: ContainerDays 2023 - Everything you always wanted to know about storage

# Introduction
You will work in the NetApp Lab on Demand environment, but we`ve prepared some more resources for you than the typical lab guide offers. A special thanks to our dear trusted colleague Yves Weisser (https://github.com/YvosOnTheHub) who created a lot of the code we are using in this lab. Before you can start, there are some preparations to do.

You will connect to a Linux jumphost from which you can access the training environment.
It will provide you two K8s clusters, two ONTAP Clusters,Tridend with preconfigured backend and a preconfigured nas storageclass.
## Prework

1. Access the lab environment:  
https://lod-bootcamp.netapp.com  
<span style="color:red">Please ignore the Lab Guide that is provided there and use this one</span>

2. Request the lab *Cloud-native Applications with Astra Control Center v1.3* and connect to the jumphost 

3. Open a terminal    

4. We've prepared some exercises for you that are hosted in a github repo. To have them available on your training environment, please create a directory, enter it and clone the repo with the following commands:  
```console
cd /home/user
git clone https://github.com/CDS2023-storageworkshop/hands-on
```

You should now have several directories available. The lab is structured with different scenarios. Everything you need is placed in a folder with the same name. 

5. As this lab is used for different things and has a lot of stuff in it that might be confusing, please run this little cleanup script which removes all things you don't need in this workshop, updates the environment to a recent version and creates some necessary stuff.   
Please run the following commands:  
**You will be asked to enter the password for user during the script. It is "Netapp1!"**

```console
cd /home/user/hands-on/prework
bash prework.sh
```


We split the lab into multiple parts:

[Part 1 - Storage in Kubernetes  - Overview](Part1.md)

[Part 2 - Storage in Kubernetes - Deep-dive](Part2.md)

[Part 3 - Snapshots & Clones, Consumption Control](Part3.md)

[Bonus - Backup & Restore with Astra Control](Bonus.md)


