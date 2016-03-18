CAS-CI Rsync-Files Tasks 
======
Below are all rsync commands for migration from build2.corp.hp.com(source server) to casci-core.glb1.hpecorp.net(destination server)  

1. Login to server: build2.corp.hp.com with our account and execute “pbrun  su - casfw”  after access.                          
2. Run all the below rsync commands(we should create one password-less ssh connection between above two servers for casfw user)

    nohup rsync -rav /casfw/var/data/hudson/  casci-core.glb1.hpecorp.net:/casfw/var/data/hudson/ &
    nohup rsync -rav /casfw/var/data/nexus/ casfw@casci-core.glb1.hpecorp.net:/casfw/var/data/nexus/ &
    nohup rsync -rav /casfw/var/data/svn/ casfw@casci-core.glb1.hpecorp.net:/casfw/var/data/svn/ &
