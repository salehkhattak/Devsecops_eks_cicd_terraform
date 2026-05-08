def call(String image) {

    echo "Deploying image to Kubernetes: ${image}"

    sh """
        cp myk8s/deployment.yaml myk8s/deployment.yaml.bak
        sed -i 's|IMAGE_PLACEHOLDER|${image}|g' myk8s/deployment.yaml

        kubectl apply -f myk8s/

        kubectl rollout status deployment/flask-app

        mv myk8s/deployment.yaml.bak myk8s/deployment.yaml
    """
}