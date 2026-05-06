pipeline {
    agent { label 'monarch-agent-xlarge' }
    environment {
        HOME = "${env.WORKSPACE}"
        PATH = "/opt/poetry/bin:${env.PATH}"
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        GH_RELEASE_TOKEN = credentials('GITHUB_WORKFLOW_PHENIO')
        GH_TOKEN = credentials('GITHUB_WORKFLOW_PHENIO')
    }
    stages {
        stage('build') {
            steps {
                dir('src/ontology') {
                    sh '''
                        ./run_jenkins.sh make all_release
                    '''
                }
            }
        }
        stage('release') {
            steps {
                dir('src/ontology') {
                    sh '''
                        make public_release_auto
                    '''
                }
            }
        }
    }
}
