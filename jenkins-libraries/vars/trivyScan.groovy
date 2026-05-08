def trivy_fs() {
    sh "trivy fs ."
}
def trivy_image(image) {
    sh "trivy image --severity HIGH,CRITICAL ${image}"
}