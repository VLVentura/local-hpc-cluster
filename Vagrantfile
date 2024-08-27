# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.synced_folder ".", "/vagrant", disabled: false

  config.vm.provision "shell", inline: <<-SHELL
    cat << EOF > /etc/apt/sources.list
deb http://br.archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://br.archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://br.archive.ubuntu.com/ubuntu/ jammy universe
deb http://br.archive.ubuntu.com/ubuntu/ jammy-updates universe
deb http://br.archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://br.archive.ubuntu.com/ubuntu/ jammy-updates multiverse
deb http://br.archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted
deb http://security.ubuntu.com/ubuntu jammy-security universe
deb http://security.ubuntu.com/ubuntu jammy-security multiverse
EOF

    cat << EOF >> /etc/hosts
    192.168.56.10 master master
    192.168.56.11 node1 node1
    192.168.56.12 node2 node2
EOF

    apt update
    DEBIAN_FRONTEND=noninteractive apt install ntpdate -y --no-install-recommends

    # Setup users for slurm
    adduser --system --group --uid 151 slurm && usermod -aG syslog slurm
    mkdir -p /etc/slurm /var/spool/slurm/slurmctld /var/spool/slurm/slurmd /var/log/slurm /var/spool/slurmctld
    chown slurm:slurm /etc/slurm /var/spool/slurm/slurmctld /var/spool/slurm/slurmd /var/log/slurm /var/spool/slurmctld
    chown -R slurm:slurm /etc/slurm

    # Setup user for munge
    adduser --system --group --uid 152 munge && usermod -aG syslog munge
    mkdir -p /etc/munge
    chown -R munge:munge /etc/munge
    chmod 700 -R /etc/munge
  SHELL

  config.vm.define :master do |master|
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "192.168.56.10"

    master.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive

      # Setup NFS
      apt install nfs-kernel-server -y --no-install-recommends
      mkdir /mnt/share_dir
      chown nobody:nogroup /mnt/share_dir # No-one is owner
      chmod 777 /mnt/share_dir # Everyone can modify files
      echo "/mnt/share_dir *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
      exportfs -ra # Making the file share available
      systemctl restart nfs-kernel-server # Restarting the NFS kernel

      # Setup slurm
      apt install slurm-wlm -y --no-install-recommends

      mkdir /mnt/share_dir/conf
      cat << EOF > /mnt/share_dir/conf/slurm.conf
ClusterName=hpc-team
SlurmctldHost=master
ProctrackType=proctrack/linuxproc
ReturnToService=1
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/var/run/slurmd.pid
SlurmdPort=6818
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
SlurmdUser=root
StateSaveLocation=/var/spool/slurmctld
TaskPlugin=task/affinity
#
# TIMERS
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
VSizeFactor=0
Waittime=0
#
# SCHEDULING
SchedulerTimeSlice=30
SchedulerType=sched/backfill
SelectType=select/cons_tres
#
# LOGGING AND ACCOUNTING
JobCompType=jobcomp/filetxt
JobAcctGatherFrequency=30
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurmd.log
#
# COMPUTE NODES
NodeName=node[1-2] CPUs=2 State=IDLE
PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP
EOF
      cp /mnt/share_dir/conf/*.conf /etc/slurm/
      cp /etc/munge/munge.key /mnt/share_dir/conf
      chmod 700 -R /etc/munge
      systemctl enable munge && systemctl start munge && systemctl restart munge
      systemctl enable slurmctld && systemctl start slurmctld
    SHELL
  end

  (1..2).each do |i|
    config.vm.define "node#{i}" do |subconfig|
      subconfig.vm.hostname = "node#{i}"
      subconfig.vm.network :private_network, ip: "192.168.56.#{10 + i}"

      subconfig.vm.provision "shell", inline: <<-SHELL
        export DEBIAN_FRONTEND=noninteractive 

        # Setup NFS
        apt install nfs-common -y --no-install-recommends
        mkdir /mnt/share_dir
        echo "master:/mnt/share_dir /mnt/share_dir nfs defaults 0 0" >> /etc/fstab
        mount -av

        # Setup slurm
        apt install slurmd slurm-client -y --no-install-recommends
        cp /mnt/share_dir/conf/*.conf /etc/slurm/
        cp /mnt/share_dir/conf/munge.key /etc/munge/
        chmod 700 -R /etc/munge
        systemctl enable munge && systemctl start munge && systemctl restart munge
        systemctl enable slurmd && systemctl start slurmd
      SHELL
    end
  end
end
