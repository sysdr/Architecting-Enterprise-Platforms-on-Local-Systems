#!/usr/bin/env python3
"""
Script to show the output of the Priority Monitor project
"""
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import json

try:
    config.load_kube_config()
except:
    config.load_incluster_config()

v1 = client.CoreV1Api()
scheduling_v1 = client.SchedulingV1Api()

print("=" * 80)
print("🎯 Priority Monitor - Project Output")
print("=" * 80)
print()

# Get PriorityClasses
print("📋 Priority Classes:")
print("-" * 80)
try:
    priority_classes = scheduling_v1.list_priority_class()
    pcs = []
    for pc in priority_classes.items:
        pcs.append({
            "name": pc.metadata.name,
            "value": pc.value,
            "global_default": pc.global_default or False,
            "description": pc.description,
            "preemption_policy": pc.preemption_policy
        })
    
    pcs.sort(key=lambda x: x["value"], reverse=True)
    
    for pc in pcs:
        default_mark = "✓ (Global Default)" if pc["global_default"] else ""
        print(f"  • {pc['name']:30} Value: {pc['value']:>12,} {default_mark}")
        if pc["description"]:
            print(f"    Description: {pc['description']}")
        if pc["preemption_policy"]:
            print(f"    Preemption Policy: {pc['preemption_policy']}")
        print()
except ApiException as e:
    print(f"  Error: {e}")

print()

# Build priority class lookup
priority_classes = {
    pc.metadata.name: pc.value 
    for pc in scheduling_v1.list_priority_class().items
}

# Get Pod Statistics
print("📊 Pod Statistics by Priority Class:")
print("-" * 80)
try:
    pods = v1.list_pod_for_all_namespaces()
    stats = {}
    
    for pod in pods.items:
        priority_class = pod.spec.priority_class_name or "tenant-default"
        
        if priority_class not in stats:
            stats[priority_class] = {
                "count": 0,
                "priority_value": priority_classes.get(priority_class, 0),
                "running": 0,
                "pending": 0,
                "failed": 0,
                "other": 0
            }
        
        stats[priority_class]["count"] += 1
        
        if pod.status.phase == "Running":
            stats[priority_class]["running"] += 1
        elif pod.status.phase == "Pending":
            stats[priority_class]["pending"] += 1
        elif pod.status.phase == "Failed":
            stats[priority_class]["failed"] += 1
        else:
            stats[priority_class]["other"] += 1
    
    # Sort by priority value
    sorted_stats = sorted(stats.items(), key=lambda x: x[1]["priority_value"], reverse=True)
    
    for priority_class, stat in sorted_stats:
        print(f"  {priority_class:30} (Value: {stat['priority_value']:>12,})")
        print(f"    Total: {stat['count']:3}  Running: {stat['running']:3}  Pending: {stat['pending']:3}  Failed: {stat['failed']:3}  Other: {stat['other']:3}")
        print()
    
    total_pods = sum(s["count"] for s in stats.values())
    total_running = sum(s["running"] for s in stats.values())
    print(f"  Total Pods: {total_pods}")
    print(f"  Total Running: {total_running}")
    
except ApiException as e:
    print(f"  Error: {e}")

print()
print()

# Get Pod Priority Assignments (sample)
print("🔍 Pod Priority Assignments (showing first 15 pods):")
print("-" * 80)
try:
    pods = v1.list_pod_for_all_namespaces()
    
    pod_priorities = []
    for pod in pods.items:
        priority_class = pod.spec.priority_class_name or "tenant-default"
        priority_value = priority_classes.get(priority_class, 0)
        
        pod_priorities.append({
            "pod_name": pod.metadata.name,
            "namespace": pod.metadata.namespace,
            "priority_class": priority_class,
            "priority_value": priority_value,
            "status": pod.status.phase
        })
    
    pod_priorities.sort(key=lambda x: x["priority_value"], reverse=True)
    
    print(f"{'Pod Name':<40} {'Namespace':<20} {'Priority Class':<25} {'Value':>12} {'Status':<10}")
    print("-" * 120)
    
    for pod in pod_priorities[:15]:
        print(f"{pod['pod_name']:<40} {pod['namespace']:<20} {pod['priority_class']:<25} {pod['priority_value']:>12,} {pod['status']:<10}")
    
    if len(pod_priorities) > 15:
        print(f"\n  ... and {len(pod_priorities) - 15} more pods")
    
except ApiException as e:
    print(f"  Error: {e}")

print()
print("=" * 80)
print("✅ Output complete!")
print("=" * 80)

