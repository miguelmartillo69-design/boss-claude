#!/bin/bash
# Setup script for Docker permissions + NVIDIA container toolkit
# Run with: sudo bash ~/Claude/setup-docker-gpu.sh

set -e

echo "=== Step 1: Add claw to docker group ==="
usermod -aG docker claw
echo "Done. (You'll need to run 'newgrp docker' or re-login after this script.)"

echo ""
echo "=== Step 2: Install nvidia-container-toolkit ==="
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg --yes

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit

echo ""
echo "=== Step 3: Configure Docker NVIDIA runtime ==="
cat > /etc/docker/daemon.json <<'EOF'
{
  "runtimes": {
    "nvidia": {
      "args": [],
      "path": "nvidia-container-runtime"
    }
  }
}
EOF

echo ""
echo "=== Step 4: Restart Docker ==="
systemctl restart docker

echo ""
echo "=== All done ==="
echo "Now run: newgrp docker"
echo "Then verify with: docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi"
