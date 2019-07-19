# Splice installation notes

### 1. Download splice installation files including (parcel, parcel.sha1, manifest.json) 
* SPLICEMACHINE-${version}-${os}.parcel.sha1 is a text file which content is hash of *.parcel file. You can find the hash in manifest.json.
Edit Splice download file: splice_download.sh
	```
	$ vim splice_download.sh
	
	########### Edit part start #######################################
	# edit splice_dir and splice_link according to your situation
	splice_dir=splice_parcel
	splice_link=https://s3.amazonaws.com/splice-releases/2.7.0.1833/cluster/parcel/cdh5.14.0/SPLICEMACHINE-2.7.0.1833.cdh5.14.0.p0.138-el7.parcel
	########### Edit part end #########################################
	
	mkdir -p $splice_dir
	splice_name=`basename "${splice_link}"`
	link_base=${splice_link%SPLICE*}
	
	# download parcel and manifest.json
	wget -P ${splice_dir}/ ${link_base}${splice_name}
	wget -P ${splice_dir}/ ${link_base}manifest.json
	
	# Generate parcel.sha1
	row=$(cat ${splice_dir}/manifest.json | awk '{i=index($0, "'${splice_name}'");if (i>0) print NR}')
	((row-=2))
	hash=$(cat ${splice_dir}/manifest.json | awk 'NR=="'${row}'"{gsub(".*:[^a-z0-9]*|[^0-9a-z]+", "", $0); print $0}')
	echo "$hash" > ${splice_dir}/${splice_name}.sha1
	```
    
### 2. Configure installation properties in file "splice_0.config" including:
- CDH version
- Directory of splice parcel files
- Splice file name
	```
	$ vim splice_0.config
	
	################ Edit part start #############################
	#The properties below need be set.
	downloads=/splice_parcel
	
	# hosts=(hostname:192.168.195.120 hostname1:192.168.195.121 hostname2:192.168.195.122)
	hosts=(standalone:192.168.195.150 hostname1:192.168.195.121)
	cm_version=5.14.0
	
	# require 3 files: *.parcel, *.parcel.sha1, manifest.json
	splice_parcel_dir=${downloads}/splice
	splice_parcel_name=SPLICEMACHINE-2.7.0.1833.cdh5.14.0.p0.138-el7
	################ Edit part end #############################
	
	# Don't change line below
	export hosts=$hosts
	export splice_parcel_dir=$splice_parcel_dir
	export splice_parcel_name=$splice_parcel_name
	splice_version=${splice_parcel_name#SPLICEMACHINE-}
	splice_version=${splice_version%-*}
	export splice_version=${splice_version}
	export cm_version=$cm_version
	```
### prere check:

    
        
### 3. Install Splice parcel to Cloudera cluster including steps:
- Copy Splice parcel to cloudera repos
- Deploy Splice parcel
- Activate Splice parcel
- Restart cluster service
	```
	$ ./splice_2_install.sh
	```
   
### 4. Configure properties including:
- Cloudera manager service
- HDFS
- HBase
- Zookeeper
- Yarn
- log (optional)
- Hbase Authentication Mechanism (optional)
	```
	$ ./splice_3_set_properties.sh
	```
    
### 5. Redeploy cluster config
- Restart Cloudera Manager service
- Redeploy cluster client config
- Restart cluster services
	```
	$ ./splice_4_deploy_client.sh
	```
    
    
