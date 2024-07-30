// plugin reminder: Blue Ocean
pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = '34e53681-2d1a-4822-b3d7-ce96b95baec1'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
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
                    agent { //reusing the node.js image in docker 
                        docker {
                            image 'mcr.microsoft.com/playwright:v1.45.1-jammy'
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "E2E stage"
                            npm install serve
                            node_modules/.bin/serve -s build &
                            # "&" allows server to run in the background and not prevent the rest of the run
                            #relative path of e2e/node_modules/bin/serve
                            SERVER_PID=$!
                            echo "Server PID: $SERVER_PID"                            
                            sleep 15
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
                    image 'mcr.microsoft.com/playwright:v1.45.1-jammy'
                    reuseNode true
                }
            }

            environment {
                CI_ENVIRONMENT_URL = 'STAGING_URL_TO_BE_SET' //alternative syntax CI_ENVIRONMENT_URL = "$env.STAGING_URL"
            }

            steps {
                sh '''
                    npm install netlify-cli node-jq
                    node_modules/.bin/netlify --version
                    echo "Deploying to staging. SiteId: $NETFLIFY_SITE_ID"
                    node_modules/.bin/netlify status
                    node_modules/.bin/netlify deploy --dir=build --json > deploy-output.json
                    CI_ENVIRONMENT_URL=$(node_modules/.bin/node-jq -r '.deploy_url' deploy-output.json)
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

        stage('Approval') {

            steps {
                echo 'Approval stage...'
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Do you wish to deploy to production?', ok: 'Yes, I am sure!'
                }
            }
        }

        stage('Deploy Prod with E2E') {
            agent { //reusing the node.js image in docker 
                docker {
                    image 'mcr.microsoft.com/playwright:v1.45.1-jammy'
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
                    node_modules/.bin/netlify --version
                    echo "Deploying to production. Site Id: $NETFLIFY_SITE_ID"
                    node_modules/.bin/netlify status
                    node_modules/.bin/netlify deploy --dir=build --prod
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