def node="master"
if (env.node){
    node =env.node
}

def GIT_BRANCH="erp"
if (env.GIT_BRANCH){
    GIT_BRANCH=env.GIT_BRANCH
}
 
def git_base_url="http://github.app.hd123.cn:10080"
if (env.git_base_url){
    git_base_url =env.git_base_url
}
def credentialsId="17643215-09f8-4a9a-b0ea-c8e49777ce1d"
if (env.credentials_id){
  credentialsId = env.credentials_id
}

def git_project = "qianfanops/toolset_h6std"
if (env.git_project){
   git_project = env.git_project
}

def docker_image="harborka.qianfan123.com/component/ka-toolset-runenv:latest"
if (env.docker_image){
   docker_image = env.docker_image
}

def CD_NEW_BRANCH="cd_new_develop"
if (env.CD_NEW_BRANCH){
    CD_NEW_BRANCH=env.CD_NEW_BRANCH
}

def inventory = "group_vars/mmshosts"
if (env.inventory) {
    inventory = env.inventory
}

def group_vars = "group_vars/mms.yaml"
if (env.group_vars) {
    group_vars = env.group_vars
}

def add_args = " "
if (env.add_args) {
    add_args = env.add_args
}


if (env.subsystem) {
    //echo "add_args is ${add_args}"
	//echo "subsystem is ${subsystem}"
	add_args+="  -e systems_from_job="+env.subsystem
	add_args+="  -e mms_version_from_job="+env.mms_version
}

pipeline {
    agent {label node}
    options {
	    timeout(time: 1, unit: 'HOURS')
    }                          
    stages {
        stage('delete workspace') {
            steps{
                deleteDir()
            }
        } 
        stage('checkout'){
            steps {
                retry(3){
				checkout([$class: 'GitSCM', branches: [[name: "*/${GIT_BRANCH}"]],extensions: [[$class: 'CloneOption', depth: 1, shallow: true]], userRemoteConfigs: [[credentialsId: "${credentialsId}",url: "${git_base_url}/${git_project}.git"]]])
				}
            }
        }

        stage('ansible-playbook on ka-toolset-runenv') {
            steps{
                script {
                    sh "docker pull ${docker_image}"
                    withDockerContainer(args: "-v /root/.ssh:/root/.ssh", image: "${docker_image}") {  
						sh "curl -O http://ka-storage.oss-cn-hangzhou.aliyuncs.com/cd_new/init_cd_new.sh"
						sh "sh init_cd_new.sh ${CD_NEW_BRANCH}"

						sh "rm -rf /opt/ka-toolset/ka_deploy/group_vars"
						sh "ln -s ${WORKSPACE}/${envname} /opt/ka-toolset/ka_deploy/group_vars"

						echo "inventory is ${inventory}"
						echo "playbook is ${playbook}"
						echo "group_vars is ${group_vars}"
						echo "add_args is ${add_args}"

						sh "cd /opt/ka-toolset/ka_deploy/ &&  ansible-playbook -i ${inventory}  ${playbook} -e '@${group_vars}' ${add_args}"
                    }
                }
            }
        }
    }
	post {
        always {
			script {
				archiveArtifacts allowEmptyArchive: true, artifacts: '*.envfile,*.log', followSymlinks: false
                currentBuild.description = "${envname}:${subsystem}"
			}
		}
    }
}
