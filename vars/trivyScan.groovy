def call() {
    sh "trivy fs --severity HIGH,CRITICAL ."
}