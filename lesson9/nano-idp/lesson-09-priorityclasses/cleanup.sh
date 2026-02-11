#!/bin/bash
set -euo pipefail

echo "🧹 Cleaning up Lesson 9 resources..."

# Delete test workloads
echo "Removing test workloads..."
kubectl delete pods -l app=memory-test --ignore-not-found=true

# Delete application
echo "Removing Priority Monitor application..."
kubectl delete namespace priority-monitor --ignore-not-found=true

# Note: We keep PriorityClasses because they're used by platform components
echo ""
echo "⚠️  Note: PriorityClasses are preserved (platform components depend on them)"
echo "    To remove them: kubectl delete priorityclass platform-critical platform-core tenant-default"

echo ""
echo "✅ Cleanup complete!"
