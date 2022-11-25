def node="master"
if (env.node){
    node =env.node
}

def run_on_public="None"
if (env.run_on_public){
    run_on_public=env.run_on_public
}
if (!env.on_k8s){
    env.on_k8s="False"
}
if (env.set_on_k8s) {
    env.on_k8s=env.set_on_k8s
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
 
// qianfanops/toolset
def git_project = "xxx"
if (env.git_project){
   git_project = env.git_project
}

def docker_image="harborka.qianfan123.com/component/ka-toolset-runenv:latest"
if (env.docker_image){
   docker_image = env.docker_image
}

def add_args = " "
if (env.add_args) {
    add_args = env.add_args
}

if (env.subsystem) {
    //echo "add_args is ${add_args}"
	//echo "subsystem is ${subsystem}"
	add_args+="  -e mms_system_from_job="+env.subsystem
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
						sh "sh init_cd_new.sh cd_new_develop"

						sh "rm -rf /opt/ka-toolset/ka_deploy/group_vars"
						sh "ln -s ${WORKSPACE}/${envname} /opt/ka-toolset/ka_deploy/group_vars"

						echo "playbook is ${playbook}"
						echo "add_args is ${add_args}"
						
						sh "cd /opt/ka-toolset/ka_deploy/ &&  ansible-playbook -i group_vars/mmshosts  ${playbook} -e '@group_vars/mms.yaml' ${add_args}" 
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