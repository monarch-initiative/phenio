pipeline {
    agent { label 'monarch-agent-xlarge' }
    environment {
        HOME = "${env.WORKSPACE}"
        PATH = "/opt/poetry/bin:${env.PATH}"
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')        
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        GH_RELEASE_TOKEN = credentials('GH_RELEASE_TOKEN')
    }
    stages {
        stage('build') {
            steps {
                sh '''
                    ls -la
                    ./run.sh make all_release
                '''
            }
        }
        stage('release') {
            // Cut a public GitHub release with the freshly built assets.
            // gh runs on the Jenkins host (not inside docker) so it can read
            // GH_TOKEN — the GH_RELEASE_TOKEN credential aliased below.
            steps {
                withEnv(["GH_TOKEN=${GH_RELEASE_TOKEN}"]) {
                    sh '''
                        cd src/ontology
                        make public_release_auto
                    '''
                }
            }
        }
    }
}
