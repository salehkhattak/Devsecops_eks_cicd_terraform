def call(String image) {

    echo "Deploying image to Kubernetes: ${image}"

    sh """
        sed -i 's|IMAGE_PLACEHOLDER|${image}|g' myk8s/deployment.yaml

        kubectl apply -f myk8s/

        kubectl rollout status deployment/flask-app
    """
}