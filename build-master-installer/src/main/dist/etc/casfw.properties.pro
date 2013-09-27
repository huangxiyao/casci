tomcat_hudson_server_port=18705
tomcat_hudson_connector_http_port=18780
tomcat_hudson_connector_https_port=18743
tomcat_hudson_connector_ajp_port=18709

tomcat_sonar_server_port=18505
tomcat_sonar_connector_http_port=18580
tomcat_sonar_connector_https_port=18543
tomcat_sonar_connector_ajp_port=18509

http_proxy_host=web-proxy.corp.hp.com
http_proxy_port=8088

nexus_server_username=deployment
nexus_server_password=deploy123ment

site_username=app-cas-site-deploy
site_password=HPInvent@2010

hudson_global_maven_opts=-XX:MaxPermSize=512m -Xmx2048m -Duser.timezone=America/Los_Angeles -Dhttp.proxyHost=web-proxy.corp.hp.com -Dhttp.proxyPort=8088

sonar_server_url=build2.corp.hp.com

# make hudson scramble sonar_jdbc_password after executing config.sh script
# DONOT change the value
sonar_rescramble_jdbc_password=0

sonar_jdbc_url=jdbc:oracle:thin:@(DESCRIPTION=(SDU=32768)(enable=broken)(LOAD_BALANCE=yes)(ADDRESS=(PROTOCOL=TCP)(HOST=gcu41831.houston.hp.com)(PORT=1526))(ADDRESS=(PROTOCOL=TCP)(Host=gcu90692.houston.hp.com)(Port=1526))(CONNECT_DATA=(SERVICE_NAME=CASCIP)))
sonar_jdbc_username=SONAR
sonar_jdbc_password=sonar$i201204
sonar_jdbc_driverClassName=oracle.jdbc.driver.OracleDriver
sonar_jdbc_validationQuery=select 1 from dual
sonar_jdbc_dialect=oracle
sonar_derby_port=1527

casfw_var_home=/casfw/var/data/hudson/master

hudson_master_mode=NORMAL
hudson_slaves_list=

#E-mail notification configuration
smtp_server=smtp3.hp.com
e-mail_suffix=@hp.com
admin_e-mail_address=NOREPLY@hp.com
hudson_master_url=http://build2.corp.hp.com/hudson/