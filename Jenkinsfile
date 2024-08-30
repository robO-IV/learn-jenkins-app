// plugin reminder: Blue Ocean
pipeline {
    agent any

    environment {
        // Section 6: removing netlify deployment and testing stages
        // NETLIFY_SITE_ID = '34e53681-2d1a-4822-b3d7-ce96b95baec1'
        // NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID" //refer to expectedAppVersion in app.spec.js and app.js
        APP_NAME = 'myjenkinsapp'
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_DOCKER_REGISTRY = '025066241473.dkr.ecr.us-east-1.amazonaws.com/myjenkinsapp'
        AWS_ECS_CLUSTER = 'LearnJenkins-Cluster-Prod'
        AWS_ECS_SERVICE = 'LearnJenkins-Service-Prod'
        AWS_ECS_TD = 'LearnJenkins-TaskDefinition-Prod'
    }

    stages {

        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    #ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'my-aws-cli'
                    reuseNode true
                    // add docker.sock to go with installing and building docker image for aws
                    args "-u root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=''" // Section 6 added '-u root' to manage `yum install jq -y`
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        #build docker image
                        docker build -t $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION .
                        # login to docker registery
                        aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_DOCKER_REGISTRY
                        # upload 'push' docker image to registry aws ecr
                        docker push $AWS_DOCKER_REGISTRY/$APP_NAME:$REACT_APP_VERSION
                        #"." in linux for "this directory"
                    '''
                }
            }
        }

        stage('Deploy to AWS') { //temp placement, section 6 moves this before Build
            agent {
                docker {
                    image 'my-aws-cli'
                    reuseNode true
                    args "--entrypoint=''" // Section 6 added '-u root' to manage `yum install jq -y`
                } //dropping -u root from args
            }
            // environment {
            //     //AWS_S3_BUCKET = 'learn-jenkins-20240806' removed in section 6
            // }
            steps {
                withCredentials([usernamePassword(credentialsId: 'my-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        LATEST_TD_REVISION=$(aws ecs register-task-definition --cli-input-json file://aws/task-definition-prod.json | jq '.taskDefinition.revision')
                        echo $LATEST_TD_REVISION
                        aws ecs update-service --cluster $AWS_ECS_CLUSTER --service $AWS_ECS_SERVICE --task-definition $AWS_ECS_TD:$LATEST_TD_REVISION
                        aws ecs wait services-stable --cluster $AWS_ECS_CLUSTER --services $AWS_ECS_SERVICE
                        #aws s3 sync build s3://$AWS_S3_BUCKET original deployment but closed out for ecs section 6
                    ''' 
                }
            }
        }
        // Section 6: removing netlify deployment and testing stages
        // stage('Tests') {
        //     parallel {
        //         stage('Unit Tests') {
        //             agent { //reusing the node.js image in docker
        //                 docker {
        //                     image 'node:18-alpine'
        //                     reuseNode true
        //                 }
        //             }
        //             steps {
        //                 sh '''
        //                     echo "Test stage"
        //                     #test -f build/index.html
        //                     #grep "index.html" build/index.html
        //                     npm test
        //                 '''
        //             }
        //             post {
        //                 always {
        //                     junit 'jest-results/junit.xml'
        //                 }
        //             }
        //         }
        //         stage('E2E') {
        //             agent { 
        //                 docker {
        //                     image 'my-playwright'
        //                     reuseNode true
        //                 }
        //             }
        //             steps {
        //                 sh '''
        //                     echo "E2E stage"
        //                     serve -s build &
        //                     # "&" allows server to run in the background and not prevent the rest of the run
        //                     #relative path of e2e/node_modules/bin/serve
        //                     #SERVER_PID=$!
        //                     #echo "Server PID: $SERVER_PID"                            
        //                     sleep 10
        //                     echo "Running Playwright Test"
        //                     npx playwright test --reporter=html
        //                 '''
        //             }
        //             post {
        //                 always {
        //                     publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright local e2e Report', reportTitles: '', useWrapperFileDirectly: true])
        //                 }
        //             }
        //         }
        //     }
        // }

        // stage('Deploy Staging with E2E') {
        //     agent { //reusing the node.js image in docker 
        //         docker {
        //             image 'my-playwright'
        //             reuseNode true
        //         }
        //     }

        //     environment {
        //         CI_ENVIRONMENT_URL = 'STAGING_URL_TO_BE_SET' //alternative syntax CI_ENVIRONMENT_URL = "$env.STAGING_URL"
        //     }

        //     steps {
        //         sh '''
        //             #npm install netlify-cli jq //not needed with custom docker image
        //             netlify --version
        //             echo "Deploying to staging. SiteId: $NETFLIFY_SITE_ID"
        //             netlify status
        //             netlify deploy --dir=build --json > deploy-output.json
        //             CI_ENVIRONMENT_URL=$(jq -r '.deploy_url' deploy-output.json)
        //             #npm install serve - netlify does this for us
        //             npx playwright test --reporter=html
        //         '''
        //     }
        //     post {
        //         always {
        //             publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Staging e2e Report', reportTitles: '', useWrapperFileDirectly: true])
        //         }
        //     }
        // }
        // // removing approval stage for continuous delivery step
        // // stage('Approval') {

        // //     steps {
        // //         echo 'Approval stage...'
        // //         timeout(time: 15, unit: 'MINUTES') {
        // //             input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'
        // //         }
        // //     }
        // // }

        // stage('Deploy Prod with E2E') {
        //     agent { //reusing the node.js image in docker 
        //         docker {
        //             image 'my-playwright'
        //             reuseNode true
        //         }
        //     }

        //     environment {
        //         CI_ENVIRONMENT_URL = 'https://astounding-gingersnap-515dc0.netlify.app'
        //     }

        //     steps {
        //         sh '''
        //             node --version
        //             npm install netlify-cli
        //             netlify --version
        //             echo "Deploying to production. Site Id: $NETFLIFY_SITE_ID"
        //             netlify status
        //             netlify deploy --dir=build --prod
        //             #npm install serve - netlify does this for us
        //             npx playwright test --reporter=html
        //         '''
        //     }
        //     post {
        //         always {
        //             publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Prod e2e Report', reportTitles: '', useWrapperFileDirectly: true])
        //         }
        //     }
        // }
    }
}
