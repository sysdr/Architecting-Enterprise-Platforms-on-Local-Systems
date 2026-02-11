#!/usr/bin/env python3
"""
Script to show the API JSON output of the Priority Monitor project
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
print("🎯 Priority Monitor - API Endpoint Outputs")
print("=" * 80)
print()

# API Endpoint 1: /api/priorityclasses
print("1️⃣  GET /api/priorityclasses")
print("-" * 80)
try:
    priority_classes = scheduling_v1.list_priority_class()
    
    results = []
    for pc in priority_classes.items:
        results.append({
            "name": pc.metadata.name,
            "value": pc.value,
            "global_default": pc.global_default or False,
            "description": pc.description,
            "preemption_policy": pc.preemption_policy
        })
    
    results.sort(key=lambda x: x["value"], reverse=True)
    print(json.dumps(results, indent=2))
except ApiException as e:
    print(json.dumps({"error": str(e)}, indent=2))

print()
print()

# API Endpoint 2: /api/stats
print("2️⃣  GET /api/stats")
print("-" * 80)
try:
    pods = v1.list_pod_for_all_namespaces()
    priority_classes = {
        pc.metadata.name: pc.value 
        for pc in scheduling_v1.list_priority_class().items
    }
    
    stats = {}
    for pod in pods.items:
        priority_class = pod.spec.priority_class_name or "tenant-default"
        
        if priority_class not in stats:
            stats[priority_class] = {
                "count": 0,
                "priority_value": priority_classes.get(priority_class, 0),
                "running": 0,
                "pending": 0,
                "failed": 0
            }
        
        stats[priority_class]["count"] += 1
        
        if pod.status.phase == "Running":
            stats[priority_class]["running"] += 1
        elif pod.status.phase == "Pending":
            stats[priority_class]["pending"] += 1
        elif pod.status.phase == "Failed":
            stats[priority_class]["failed"] += 1
    
    print(json.dumps(stats, indent=2))
except ApiException as e:
    print(json.dumps({"error": str(e)}, indent=2))

print()
print()

# API Endpoint 3: /api/pods/priorities (sample)
print("3️⃣  GET /api/pods/priorities (showing first 10 pods)")
print("-" * 80)
try:
    priority_classes = {
        pc.metadata.name: pc.value 
        for pc in scheduling_v1.list_priority_class().items
    }
    
    if "tenant-default" in priority_classes:
        default_priority = priority_classes["tenant-default"]
    else:
        default_priority = 0
    
    results = []
    pods = v1.list_pod_for_all_namespaces()
    
    for pod in pods.items:
        priority_class = pod.spec.priority_class_name or "tenant-default"
        priority_value = priority_classes.get(priority_class, default_priority)
        
        results.append({
            "pod_name": pod.metadata.name,
            "namespace": pod.metadata.namespace,
            "priority_class": priority_class,
            "priority_value": priority_value,
            "memory_usage": None,  # Would require metrics server
            "status": pod.status.phase
        })
    
    results.sort(key=lambda x: x["priority_value"], reverse=True)
    print(json.dumps(results[:10], indent=2))
    print(f"\n... and {len(results) - 10} more pods")
    
except ApiException as e:
    print(json.dumps({"error": str(e)}, indent=2))

print()
print("=" * 80)
print("✅ API Output complete!")
print("=" * 80)

