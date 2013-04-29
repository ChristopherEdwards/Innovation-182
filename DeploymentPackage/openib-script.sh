#!/bin/bash
#---------------------------------------------------------------------------
# Copyright 2011-2013 The Open Source Electronic Health Record Agent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#---------------------------------------------------------------------------
# VM Settings:
#    512MB Ram (1024MB RAM required for Graphical Installer)
#    10GB HDD

# Install Centos 6.3 Minimal
#    Take all Defaults
#    Dont forget to edit the network settings in the graphical installer

yum update -y
yum install vim man yum-priorities -y

# Install new 3rd party repos

rpm -Uvh http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh http://mirrors.dotsrc.org/jpackage/6.0/generic/free/RPMS/jpackage-utils-5.0.0-7.jpp6.noarch.rpm

# create jpackage repo file
cat > /etc/yum.repos.d/jpackage50.repo << EOF
# Be sure to enable the distro specific repository for your distro below:
# - jpackage-fc for Fedora Core
# - jpackage-rhel for Red Hat Enterprise Linux and derivatives

[jpackage-generic]
name=JPackage (free), generic
mirrorlist=http://www.jpackage.org/mirrorlist.php?dist=generic&type=free&release=6.0
failovermethod=priority
gpgcheck=1
gpgkey=http://www.jpackage.org/jpackage.asc
enabled=1

# Devel
[jpackage-devel]
name=JPackage 6 generic devel
mirrorlist=http://www.jpackage.org/mirrorlist.php?dist=generic&type=devel&release=6.0
failovermethod=priority
gpgcheck=1
gpgkey=http://www.jpackage.org/jpackage.asc
enabled=1

EOF

# Install more packages
yum install java-1.6.0-openjdk tomcat7 tomcat7-admin-webapps mysql mysql-server maven22 mlocate git -y

# Make MySQL and tomcat7 start on bootup
chkconfig tomcat7 on
chkconfig mysqld on

# start MySQL and tomcat7 now
service mysqld start
service tomcat7 start

# Secure the MySQL server
mysql_secure_installation

cat > /etc/tomcat7/tomcat-users.xml << EOF
<?xml version='1.0' encoding='utf-8'?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<tomcat-users>
<!--
  NOTE:  By default, no user is included in the "manager-gui" role required
  to operate the "/manager/html" web application.  If you wish to use this app,
  you must define such a user - the username and password are arbitrary.
-->
<!--
  NOTE:  The sample user and role entries below are wrapped in a comment
  and thus are ignored when reading this file. Do not forget to remove
  <!.. ..> that surrounds them.
-->
  <role rolename="manager-gui"/>
  <user username="tomcat" password="tomcat" roles="manager-gui"/>
-->
</tomcat-users>
EOF

# Clone OpenInfoButton repo
mkdir ~/Development
cd ~/Development
git clone git://github.com/VHAINNOVATIONS/Innovation-182.git openinfobutton
cd openinfobutton

# Clean & install each project
cd infobutton-db
mvn22 clean
mvn22 install
if [ ! -f "target/infobutton-db-0.0.1-SNAPSHOT.jar" ]
then
    echo "Infobutton-db build failed, Quitting"
    exit
fi

cd ../infobutton-kbschema
mvn22 clean
mvn22 install
if [ ! -f "target/infobutton-kbschema-0.0.1-SNAPSHOT.jar" ]
then
    echo "Infobutton-kbschema build failed, Quitting"
    exit
fi

cd ../infobutton-schema
mvn22 clean
mvn22 install
if [ ! -f "target/infobutton-schema-0.0.1-SNAPSHOT.jar" ]
then
    echo "Infobutton-schema build failed, Quitting"
    exit
fi

cd ../inference-rxnorm
mvn22 clean
mvn22 install
if [ ! -f "target/inference-rxnorm-0.0.1-SNAPSHOT.jar" ]
then
    echo "inference-rxnorm build failed, Quitting"
    exit
fi

cd ../UTSMetathesaurus
mvn22 clean
mvn22 install
if [ ! -f "target/UTSMetathesaurus-0.0.1-SNAPSHOT.jar" ]
then
    echo "UTSMetathesaurus build failed, Quitting"
    exit
fi

cd ../infobutton-externalresources
mvn22 clean
mvn22 install
if [ ! -f "target/infobutton-externalresources-0.0.1-SNAPSHOT.jar" ]
then
    echo "infobutton-externalresources build failed, Quitting"
    exit
fi

cd ../infobutton-service
mvn22 clean
echo You can customize the WebApp by editing src/main/webapp/*.html
#recommended search/replace
#search <option value="http://dev-service.oib.utah.edu:8080/infobutton-service/infoRequest?">Development</option>
# replace <option value="http://localhost:8080/infobutton-service/infoRequest?">Local Development</option>
sed -i 's#<option value="http://dev-service.oib.utah.edu:8080/infobutton-service/infoRequest?">Development</option>#<option value="http://localhost:8080/infobutton-service/infoRequest?">Local Development</option>#' src/main/webapp/InfobuttonQA.html

# change Db parameters
# ~/Development/openinfobutton/infobutton-service/src/main/webapp/WEB-INF/serviceParams.properties

# Main OpenInfoButton DB
sed -i 's/datasource1.user\=username/datasource1.user\=openib/' ~/Development/openinfobutton/infobutton-service/src/main/webapp/WEB-INF/serviceParams.properties

sed -i 's/datasource1.password\=password/datasource1.password\=openib/' ~/Development/openinfobutton/infobutton-service/src/main/webapp/WEB-INF/serviceParams.properties

# Profiles DB
sed -i 's/datasource2.user\=username/datasource2.user\=openib/' ~/Development/openinfobutton/infobutton-service/src/main/webapp/WEB-INF/serviceParams.properties

sed -i 's/datasource2.password\=password/datasource2.password\=openib/' ~/Development/openinfobutton/infobutton-service/src/main/webapp/WEB-INF/serviceParams.properties

mvn22 install
if [ ! -f "target/infobutton-service.war" ]
then
    echo "infobutton-service build failed, Quitting"
    exit
fi

# install db tables
cat > ~/Development/openinfobutton/DeploymentPackage/CreateDB.sql << EOF
GRANT ALL PRIVILEGES ON *.* TO 'openib'@'localhost' IDENTIFIED BY 'openib' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'openib'@'%' IDENTIFIED BY 'openib' WITH GRANT OPTION;
EOF
echo "Enter your MySQL Password at the next sequence of prompts"
echo "This will be a series of 7 Password: prompts. It may look like you typed an invalid password, but you probably didn't"
cd ~/Development/openinfobutton/DeploymentPackage
mysql -u root -p < CreateDB.sql
cd ~/Development/openinfobutton/DeploymentPackage/sqlWithInsert
mysql -u root -p < prodoib_concept.sql
mysql -u root -p < prodoib_subset.sql
mysql -u root -p < prodoib_subsetmember.sql
cd ~/Development/openinfobutton/DeploymentPackage/sqlDump
mysql -u root -p < prodoib_logs.sql
mysql -u root -p < profilesdbprod_resource_profiles.sql
cd ~/Development/openinfobutton/DeploymentPackage/sqlWithInsert
mysql -u root -p profilesdbprod < profilesdbprod_resource_profiles.sql

# Deploy war file
cp ~/Development/openinfobutton/infobutton-service/target/infobutton-service.war /var/lib/tomcat7/webapps/
