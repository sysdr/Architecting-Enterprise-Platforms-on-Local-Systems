#!/bin/bash

NAMESPACE="storage-demo"

echo "🧹 Cleaning up Lesson 8 resources..."

kubectl delete namespace ${NAMESPACE} --ignore-not-found=true
kubectl delete storageclass local-ssd --ignore-not-found=true

echo "✅ Cleanup complete!"
