#!/bin/sh

    
RED='\033[0;31m'
NC='\033[0m' # No Color    
G='\033[1;32m'



printf "${RED}Skuurr$ Skkkrrt\n{NC}"

ip a
sudo read -p "Entrez l'ip de l'initiator : " ipInitiatior
sudo read -p "Entrez l'ip du serveur Target : " ipTarget

sudo lsblk
sudo read -p "Entrez les deux disques à fusionner séparer d'un espace: " disque1 disque2


sudo read -p "Entrez le nom de votre groupe virtuel LVM : " virtualGroupe
sudo read -p "Entrez le nom de votre volume logique   : " logicalVolume

sudo read -p "Entrez le nom d'Hote ou le nom de domaine (Targer)  : " targetName
sudo read -p "Entrez le nom d'Hote ou le nom de domaine (Initiator)  : " initiatorName
echo "$virtualGroupe"


sudo apt-get update
sudo apt-get install tgt lvm2 -y
#sudo sudo read -p "Select your interface" interface


#ip=$(sudo ifconfig | sudo grep -A 1 'eth0' | sudo tail -1 | sudo cut -d ':' -f 2 | sudo cut -d ' ' -f 1)

sudo vgcreate $virtualGroupe /dev/sd{$disque1,$disque1}
# vgs  (Only needed to confirm the creation of the volume group)

#sudo lvcreate -l 100%FREE $logicalVolume etna
sudo lvcreate -n $logicalVolume-L 19g $virtualGroupe
# lvs  (Simply used to confirm the creation of the logical volume)

sudo  cat <<EOF > /etc/tgt/conf.d/test.conf
<target $targetName:lun1>
     # Provided device as an iSCSI target
     backing-store /dev/mapper/$logicalVolume
     initiator-address $ipInitiatior
     incominguser etna-iscsi-user password
     outgoinguser debian-iscsi-target secretpass
</target>
EOF

sudo service tgt restart  
# (For sysv init systems)
sudo systemctl restart tgt  
# (For systemd init systems)
# (This will show all targets)


sudo tgtadm --mode target --op show  

#atach LV $logicalVolume to ISCSI
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 -b /dev/$virtualGroupe/$logicalVolume


sudo tgtadm --mode target --op show



sudo read -p "Entrez l'utilisateur de la VM initiator : " userInitiatior
sudo read -p "Entrez le password ssh de la VM initiator : " passwordInitiatior


sudo ssh $userInitiatior@$ipInitiatior -p '$passwordInitiatior'


#################
##########Connected in INITIATOR
#################


sudo apt-get update
sudo apt-get install open-iscsi -y
sudo apt-get install tgt lvm2 -y
sudo su

#ip=$(ifconfig | sudo grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)

sudo iscsiadm -m discovery -t st -p $ipTarget




#Synchronise you token 
sudo  cat <<EOF > /etc/iscsi/nodes/$initiatorName\:lun1/$ipTarget\,3260\,1/default
#Enable CHAP Authentication
node.session.auth.authmethod = CHAP                  

#Target to Initiator authentication
node.session.auth.username = etna-iscsi-user

#Target to Initiator authentication      
node.session.auth.password = password                

#Initiator to Target authentication
node.session.auth.username_in = debian-iscsi-target  

#Initiator to Target authentication
node.session.auth.password_in = secretpass           

node.startup = automatic

EOF



#(For sysv init systems)
sudo service open-iscsi restart  

sudo service tgt restart  
# (For sysv init systems)
sudo systemctl restart tgt  
#(For systemd init systems)
sudo systemctl restart open-iscsi 

sudo lsblk

sudo iscsiadm -m session

sudo  tgtadm --mode conn --op show --tid 1


sudo iscsiadm -m discovery -t st -p $ipTarget 
sudo iscsiadm -m node \
       --targetname $targetName:lun1 -p $ipTarget:3260 -l

sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 -b /dev/$virtualGroupe/$logicalVolume


printf "I ${G} 
          0000_____________0000________0000000000000000__000000000000000000++++++------------->>
        00000000_________00000000______000000000000000__0000000000000000000+
       000____000_______000____000_____000_______0000__00______0+
      000______000_____000______000_____________0000___00______0+
     0000______0000___0000______0000___________0000_____0_____0+
     0000______0000___0000______0000__________0000___________0+ 
     0000______0000___0000______0000_________000___0000000000+  
     0000______0000___0000______0000________0000+				
      000______000_____000______000________0000+				
       000____000_______000____000_______00000+					
        00000000_________00000000_______0000000+
          0000_____________0000________000000007


          ${G}			GOLDENEYE MERGE SAN CONNECTED\n"






