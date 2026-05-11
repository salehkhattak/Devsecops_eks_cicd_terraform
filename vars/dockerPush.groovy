def call(String credentialsId, String imageTag) {

    echo "Pushing image to DockerHub: ${imageTag}"

    withCredentials([usernamePassword(
        credentialsId: credentialsId,
        usernameVariable: 'DOCKER_USER',
        passwordVariable: 'DOCKER_PASS'
    )]) {

        sh """
            echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
            docker push ${imageTag}
            docker logout
        """
    }

    echo "Image pushed successfully!"
}