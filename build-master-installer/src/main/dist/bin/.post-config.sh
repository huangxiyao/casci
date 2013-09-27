#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

echo "Setting up Maven"
if ${cygwin}; then
    echo "Please update your $HOME/.m2/settings.xml"
    echo "file so it contains all the settings present in"
    echo "${CASFW_HOME}/etc/maven/settings.xml"
elif [[ ! -e $HOME/.m2/settings.xml && ! -L $HOME/.m2/settings.xml ]]; then
    if [[ ! -d $HOME/.m2 ]]; then
        mkdir $HOME/.m2
    fi
    
    echo "Copying ${CASFW_HOME}/etc/maven/settings.xml to $HOME/.m2"
    cp ${CASFW_HOME}/etc/maven/settings.xml $HOME/.m2/.
else
    echo "WARNING:"
    echo " replace existed $HOME/.m2/settings.xml with new settings.xml."
    mv "$HOME/.m2/settings.xml" "$HOME/.m2/settings.xml.$(date '+%Y%m%d_%H%M%S')"
    cp ${CASFW_HOME}/etc/maven/settings.xml $HOME/.m2/.
fi

# "Migrate slave node and view definition from old version to new environment"
 master_home="$(ls -d ${CASFW_HOME} 2>/dev/null | tail -n1)"
 master_version="$(basename ${master_home} | sed 's/build-master-//')"
if [ -f "${CASFW_HOME}/old-version-config-${master_version}.xml" ]; then
    echo "Begin to migrate slaves and views configuration from old hudson config.xml to the current installed one"
    # execute migration by a custom java class file
    hudson_custom_package=${CASFW_HOME}/software/hudson-custom-package
    current_hudson_config=${CASFW_HOME}/etc/hudson/config.xml
    java -classpath ${hudson_custom_package} hudson.utilities.HudsonConfigMigration ${CASFW_HOME}/old-version-config-${master_version}.xml ${current_hudson_config}   
    # "Delete temporary config.xml file"
    rm -f ${CASFW_HOME}/old-version-config-${master_version}.xml
else
    echo "WARNING:"
    echo "Didn't find old hudson config.xml."
    echo "No slaves and views configuration will be migrated to the new installed buidcloud."
fi

echo "Split hudson build cloud var dir from the installation dir ..."

# split hudson build cloud var dir from the installation dir
# move the original content to ${CASFW_VAR_DIR_HOME}, make link to the new dir

if [[ ${cygwin} != "true" ]]; then

    CASFW_VAR_DIR_HOME=$(grep casfw_var_home ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
    echo "WARNING:"
    
    echo "if you have intalled the cdi package before, please move the soft link pointing to the original directory. "
    echo "Else the soft link will be pointed to ${CASFW_VAR_DIR_HOME}/var"

    if [ -n "${CASFW_VAR_DIR_HOME}" ]; then
        echo "CASFW_VAR_DIR_HOME variable has been set to ${CASFW_VAR_DIR_HOME}."
        echo "moving the ${CASFW_HOME}/var to ${CASFW_VAR_DIR_HOME}/var"

        if [[ ! -d ${CASFW_VAR_DIR_HOME} ]]; then
            echo "creating CASFW_VAR_DIR_HOME directory: ${CASFW_VAR_DIR_HOME}"
            mkdir -p ${CASFW_VAR_DIR_HOME}
            if [ $? -ne 0 ]; then
                echo "Cannot trying to create CASFW_VAR_DIR_HOME directory: ${CASFW_VAR_DIR_HOME}."
                echo "Please check the user's privileges."
                echo "Aborting."
                exit 30
            fi
        fi
		
        # if CASFW_VAR_DIR_HOME variable is a soft link, reset the value of CASFW_VAR_DIR_HOME to physical directory of the soft link
        if [ -L ${CASFW_VAR_DIR_HOME} ]; then
            echo "${CASFW_VAR_DIR_HOME} is a soft link , get the physical directory"
            CASFW_VAR_DIR_HOME="$(readlink ${CASFW_VAR_DIR_HOME})" 
        fi
        
        if [[ "${CASFW_VAR_DIR_HOME}" = "${CASFW_HOME}/" ]]; then
            echo "ERROR:"
            echo "value of CASFW_VAR_DIR_HOME is same with CASFW_HOME, do not allow, please reset CASFW_VAR_DIR_HOME variable in ${CASFW_HOME}/etc/casfw.properties.*"   
            echo "Aborting."
            exit 31
        fi
        if [[ ! -L ${CASFW_HOME}/var ]]; then
            echo "Removing ${CASFW_HOME}/var and creating soft link ${CASFW_HOME}/var pointing to ${CASFW_VAR_DIR_HOME}/var."
            if [[ -d ${CASFW_VAR_DIR_HOME}/var && "$(ls -A ${CASFW_VAR_DIR_HOME}/var)" ]]; then
                rm -fr ${CASFW_HOME}/var 1>/dev/null 2>/dev/null
                if [ $? -ne 0 ]; then
            	    echo "Cannot delete ${CASFW_HOME}/var . Please check the user's privileges"
            	    echo "Aborting."
            	    exit 32
                fi
            else
                mv ${CASFW_HOME}/var ${CASFW_VAR_DIR_HOME}/.
                if [ $? -ne 0 ]; then
                    echo "Cannot move ${CASFW_HOME}/var ${CASFW_VAR_DIR_HOME}/. Please check the user's privileges"
                    echo "Aborting."
                    exit 33
                fi					
            fi 
            echo "creating soft link ${CASFW_VAR_DIR_HOME}/var pointing to ${CASFW_HOME}/var. "
            ln -sf ${CASFW_VAR_DIR_HOME}/var ${CASFW_HOME}/var
            if [ $? -ne 0 ]; then
                echo "Cannot link the ${CASFW_VAR_DIR_HOME}/var to ${CASFW_HOME}/var. Please check the user's privileges"
            	echo "Aborting."
            	exit 34
            fi
			
        else
            CASFW_VAR_ACTUAL_HOME="$(readlink ${CASFW_HOME}/var)"
            if [[ "${CASFW_VAR_ACTUAL_HOME}" != "${CASFW_VAR_DIR_HOME}/var" ]]; then
                echo "moving ${CASFW_VAR_ACTUAL_HOME} ${CASFW_VAR_DIR_HOME}/. "
                rm -f  ${CASFW_HOME}/var 1>/dev/null 2>/dev/null
                if [ $? -ne 0 ]; then
                    echo "Cannot remove soft link ${CASFW_HOME}/var. Please check the user's privileges"
                    echo "Aborting."
                    exit 35
                fi
                mv ${CASFW_VAR_ACTUAL_HOME} ${CASFW_VAR_DIR_HOME}/. 1>/dev/null 2>/dev/null
                if [ $? -ne 0 ]; then
                    echo "Cannot move ${CASFW_VAR_ACTUAL_HOME} ${CASFW_VAR_DIR_HOME}/. Please check the user's privileges"
            	    echo "Aborting."
                    exit 36
                fi
                echo "redirecting soft link to ${CASFW_HOME}/var. "
                echo "creating soft link ${CASFW_VAR_DIR_HOME}/var pointing to ${CASFW_HOME}/var. "
                ln -sf ${CASFW_VAR_DIR_HOME}/var ${CASFW_HOME}/var
                if [ $? -ne 0 ]; then
                   	echo "Cannot link the ${CASFW_VAR_DIR_HOME}/var to ${CASFW_HOME}/var. Please check the user's privileges"
                	echo "Aborting."
                	exit 37
                fi
            fi
				
        fi
    
    else
        echo "CASFW_VAR_DIR_HOME variable has been not set."

				if [[ -L ${CASFW_HOME}/var ]]; then
					CASFW_VAR_ACTUAL_HOME="$(readlink ${CASFW_HOME}/var)"
					echo "expected var directory is blank ,so moving ${CASFW_VAR_ACTUAL_HOME} back to ${CASFW_HOME}/var. "
					echo "deleting origianl soft links. "
					rm -f  ${CASFW_HOME}/var 1>/dev/null 2>/dev/null
					if [ $? -ne 0 ]; then
						echo "Cannot remove soft link ${CASFW_HOME}/var. Please check the user's privileges"
						echo "Aborting."
						exit 38
					fi
					echo "moving ${CASFW_VAR_ACTUAL_HOME} to ${CASFW_HOME}/. "
					mv ${CASFW_VAR_ACTUAL_HOME} ${CASFW_HOME}/. 1>/dev/null 2>/dev/null
					if [ $? -ne 0 ]; then
						echo "Cannot move ${CASFW_VAR_ACTUAL_HOME} to ${CASFW_HOME}/. Please check the user's privileges"
						echo "Aborting."
						exit 39
					fi					
				fi
    
    fi
fi
echo "Spliting hudson build cloud var dir successfully!"

# Sonar: regenerate the WAR file
SONAR_HOME="$(find ${CASFW_HOME}/software -maxdepth 1 -type d -name "sonar-*")"

echo "Generating ${SONAR_HOME}/war/sonar.war"
pushd ${SONAR_HOME}/war 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err

# We cannot use directly Sonar's build-war.sh as it does not export ANT_HOME which makes building .war fail
# failing in the environments in which ANT is already installed
export ANT_HOME="${SONAR_HOME}/war/apache-ant-1.7.0"
./apache-ant-1.7.0/bin/ant 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err

last_exit_code=$? 
if [ ${last_exit_code} -ne 0 ]; then
	echo "ERROR:"
    echo "  Generating ${SONAR_HOME}/war/sonar.war failed with code ${last_exit_code}."
    echo "  Please check ${CASFW_HOME}/var/log/sonar/sonar-war.err"
    echo "  and ${CASFW_HOME}/var/log/sonar/sonar-war.out for more details."
    exit ${last_exit_code}
fi 

popd 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err
