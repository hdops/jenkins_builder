def credentialsId="qianfan"

//  主要需要 git + dokcer 环境
def build_image= "harbor.qianfan123.com/base/node:v8.9.4"
if (env.build_image){
    build_image =env.build_image
}


pipeline {
    // agent {label node}
    agent {
		docker {
            image "${build_image}"
            args '-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
          }
	}
    options {
	//     buildDiscarder(logRotator(numToKeepStr: '10'))
	//     disableConcurrentBuilds()
	//     disableResume()
	    timeout(time: 1, unit: 'HOURS')
    } 
    stages {
        stage('delete workspace'){
		    when {
			    expression {'Y' == "${params.deleteWorkspace}"}
			}
			steps{
			    deleteDir()
			}
		}
         stage('checkout') {
             steps{ 
				echo "checkout http://github.app.hd123.cn:10080/${git_project}.git  branch:${build_branch}"
				git branch: "${build_branch}", credentialsId: "${credentialsId}", url: 'http://github.app.hd123.cn:10080/${git_project}.git'
             }
         }  
		stage('build') {
		    steps{
				script{  
					sh "  docker -v" 
					if (env.docker_build_tag){
						echo "docker_build_tag is ${docker_build_tag}"
						docker_build_shell = "docker build -t " + env.docker_build_tag + " -f build/Dockerfile . && docker login -u admin -p hoS9sTHXQhpGvwa2  harbor.qianfan123.com && docker push " + env.docker_build_tag
							//echo "docker_build_shell is ${docker_build_shell}"
						sh "  ${docker_build_shell}"  
					}
				}
			} 
		} 
    }
}