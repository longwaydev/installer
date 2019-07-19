## Installation Steps of Longdb

### Step 1. Config network on all nodes
1. edit install.properties, make sure that hostips are all new ips (all are not assigned) 
2. run install script
	```
        $ ./1_install_network.sh
	```
		
### Step 2. Install cdh 5.14.0 on master
1. $ ./2_install_cdh.sh
2. Open http://localhost:7180 and set up cluster following web wizard(user/password: admin/admin)
3. product meta database

	|    product      |   database  | user     | password  |
	|  -------------- | ----------- | -------- | ---------- |
	| hive            | metastore   | root     | 123456    |
	| report manager  | rman        | root     | 123456    |
	| hue             | hue         | root     | 123456    |
	| oozie           | oozie       | root     | 123456    |
    
### Step3. Install spark2
1. run script:  
	```
	$ ./install_spark2.sh
	```
2. Open http://localhost:7180 and login (admin/admin)
3. Click Actions > add service --> select spark2 --> click continue
    
### Step4. Install longdb(splice)
1. Run script:     
	```
	$ ./install_longdb.sh
	```



