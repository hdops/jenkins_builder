def node=""
if (env.node){
    node =env.node
}else{
    node ="master"
}
def whether_post="False"
if (env.whether_post){
    whether_post =env.whether_post
}
def toolset_image_version="0.3.0-private"
if (env.toolset_image_version){
    toolset_image_version = env.toolset_image_version
}
pipeline {
    agent {label node}
	options {
	    timeout(time: 2, unit: 'MINUTES')
    }
    stages {
        stage('tps-max') {
			steps{
				script{
                    if (env.on_k8s){
                        container("hdtoolsetcore"){
                            retry(2){
                                sh "DNET_PROFILE=integration_test DNET_PRODUCT=dnet hdops download_toolset --branch ${params.GIT_BRANCH} -p ."
                            }
                            sh "tar zxf toolset.tar.gz -C ${WORKSPACE}"
                            sh "DNET_EXPORT_FILE=${params.DNET_EXPORT_FILE} hdmon statistic --action elktps"
                        }
                    }else {

                        docker.image("harbor.qianfan123.com/toolset/toolsetcore:${toolset_image_version}").inside  {
                            retry(2){
                                sh "DNET_PROFILE=integration_test DNET_PRODUCT=dnet hdops download_toolset --branch ${params.GIT_BRANCH} -p ."
                            }
                            sh "tar zxf toolset.tar.gz -C ${WORKSPACE}"
                            sh "DNET_EXPORT_FILE=${params.DNET_EXPORT_FILE} hdmon statistic --action elktps"
                        }
                    }
                }
			}
        }
        
    }
	post {
    // 构建失败之后钉钉通知
        failure {
            script {
                if (whether_post == "True") {
                    dingTalk accessToken: "${DINGTALK_TOKEN}", imageUrl: '', jenkinsUrl: "${jenkinsUrl}", message: "构建失败 ${new Date().format("yyyy-MM-dd HH:mm:ss")}", notifyPeople: ''
                }
            }
        }
	// 失败转成功之后钉钉通知
        fixed {
            script {
                if (whether_post == "True") {
                    dingTalk accessToken: "${DINGTALK_TOKEN}", imageUrl: '', jenkinsUrl: "${jenkinsUrl}", message: "恢复正常 ${new Date().format("yyyy-MM-dd HH:mm:ss")}", notifyPeople: ''
                }
            }
        }
    }
}

