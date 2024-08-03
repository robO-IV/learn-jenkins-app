// plugin reminder: Blue Ocean
pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '34e53681-2d1a-4822-b3d7-ce96b95baec1'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        REACT_APP_VERSION = "1.0.$BUILD_ID" //refer to expectedAppVersion in app.spec.js and app.js
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
        stage('Tests') {
            parallel {
                stage('Unit Tests') {
                    agent { //reusing the node.js image in docker
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "Test stage"
                            #test -f build/index.html
                            #grep "index.html" build/index.html
                            npm test
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }
                stage('E2E') {
                    agent { 
                        docker {
                            image 'my-playwright'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "E2E stage"
                            serve -s build &
                            # "&" allows server to run in the background and not prevent the rest of the run
                            #relative path of e2e/node_modules/bin/serve
                            #SERVER_PID=$!
                            #echo "Server PID: $SERVER_PID"                            
                            sleep 10
                            echo "Running Playwright Test"
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright local e2e Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
                    }
                }
            }
        }

        stage('Deploy Staging with E2E') {
            agent { //reusing the node.js image in docker 
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'STAGING_URL_TO_BE_SET' //alternative syntax CI_ENVIRONMENT_URL = "$env.STAGING_URL"
            }

            steps {
                sh '''
                    #npm install netlify-cli node-jq //not needed with custom docker image
                    netlify --version
                    echo "Deploying to staging. SiteId: $NETFLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(node-jq -r '.deploy_url' deploy-output.json)
                    #npm install serve - netlify does this for us
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Staging e2e Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
        // removing approval stage for continuous delivery step
        // stage('Approval') {

        //     steps {
        //         echo 'Approval stage...'
        //         timeout(time: 15, unit: 'MINUTES') {
        //             input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'
        //         }
        //     }
        // }

        stage('Deploy Prod with E2E') {
            agent { //reusing the node.js image in docker 
                docker {
                    image 'my-playwright'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'https://astounding-gingersnap-515dc0.netlify.app'
            }

            steps {
                sh '''
                    node --version
                    npm install netlify-cli
                    netlify --version
                    echo "Deploying to production. Site Id: $NETFLIFY_SITE_ID"
                    netlify status
                    netlify deploy --dir=build --prod
                    #npm install serve - netlify does this for us
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright Prod e2e Report', reportTitles: '', useWrapperFileDirectly: true])
                }
            }
        }
    }
}