#!/usr/bin/env python3
"""
Spec Coverage Reporter

This script compares BDD feature specifications with implementation status
documented in FEATURE_REGISTRY.md and provides a coverage report.

Usage:
    python3 scripts/spec-coverage.py
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

# ANSI color codes
GREEN = '\033[92m'
YELLOW = '\033[93m'
RED = '\033[91m'
BLUE = '\033[94m'
RESET = '\033[0m'


def parse_feature_files(features_dir: Path) -> Dict[str, List[str]]:
    """Parse all .feature files and extract scenario IDs."""
    scenarios = {}
    
    for feature_file in features_dir.rglob("*.feature"):
        area = feature_file.parent.name
        if area not in scenarios:
            scenarios[area] = []
        
        content = feature_file.read_text()
        # Find all scenario IDs like @SE-001, @HO-005, etc.
        ids = re.findall(r'@([A-Z]{2}-\d{3})', content)
        scenarios[area].extend(ids)
    
    return scenarios


def parse_feature_registry(registry_path: Path) -> Dict[str, Tuple[str, str]]:
    """Parse FEATURE_REGISTRY.md and extract implementation status."""
    registry = {}
    
    if not registry_path.exists():
        print(f"{RED}Error: FEATURE_REGISTRY.md not found at {registry_path}{RESET}")
        return registry
    
    content = registry_path.read_text()
    
    # Parse the registry table
    in_table = False
    for line in content.split('\n'):
        if line.startswith('| Area |'):
            in_table = True
            continue
        if in_table and line.startswith('|'):
            parts = [p.strip() for p in line.split('|')[1:-1]]  # Remove empty first/last
            if len(parts) >= 4 and parts[0] and parts[0] != '---':
                area = parts[0]
                status = parts[3]
                notes = parts[4] if len(parts) > 4 else ""
                registry[area] = (status, notes)
    
    return registry


def find_swift_files_for_features(ios_dir: Path, features: List[str]) -> Set[str]:
    """Find Swift implementation files referenced in the codebase."""
    swift_files = set()
    
    for swift_file in ios_dir.rglob("*.swift"):
        swift_files.add(swift_file.name)
    
    return swift_files


def print_report(scenarios: Dict[str, List[str]], registry: Dict[str, Tuple[str, str]], swift_files: Set[str]):
    """Print the coverage report."""
    
    print(f"\n{BLUE}{'='*80}{RESET}")
    print(f"{BLUE}Specification Coverage Report{RESET}")
    print(f"{BLUE}{'='*80}{RESET}\n")
    
    total_scenarios = sum(len(ids) for ids in scenarios.values())
    print(f"Total scenarios found in .feature files: {total_scenarios}\n")
    
    # Group scenarios by area
    print(f"{BLUE}Scenarios by Area:{RESET}")
    for area, ids in sorted(scenarios.items()):
        print(f"  {area}: {len(ids)} scenario(s)")
        for scenario_id in sorted(ids):
            print(f"    - {scenario_id}")
    
    print(f"\n{BLUE}{'='*80}{RESET}")
    print(f"{BLUE}Implementation Status (from FEATURE_REGISTRY.md):{RESET}\n")
    
    if not registry:
        print(f"{YELLOW}Warning: No registry entries found. Update FEATURE_REGISTRY.md.{RESET}\n")
        return
    
    # Status categories
    implemented = []
    in_progress = []
    planned = []
    
    for area, (status, notes) in sorted(registry.items()):
        status_lower = status.lower()
        
        if 'implemented' in status_lower:
            status_color = GREEN
            implemented.append((area, status, notes))
        elif 'in progress' in status_lower:
            status_color = YELLOW
            in_progress.append((area, status, notes))
        else:
            status_color = RED
            planned.append((area, status, notes))
        
        print(f"{status_color}● {area}{RESET}")
        print(f"  Status: {status}")
        if notes:
            print(f"  Notes: {notes}")
        print()
    
    # Summary
    print(f"{BLUE}{'='*80}{RESET}")
    print(f"{BLUE}Summary:{RESET}\n")
    print(f"{GREEN}Implemented:{RESET} {len(implemented)}")
    print(f"{YELLOW}In Progress:{RESET} {len(in_progress)}")
    print(f"{RED}Planned:{RESET} {len(planned)}")
    
    total = len(implemented) + len(in_progress) + len(planned)
    if total > 0:
        coverage_pct = (len(implemented) / total) * 100
        print(f"\n{BLUE}Coverage: {coverage_pct:.1f}%{RESET}")
    
    print(f"\n{BLUE}Swift Implementation Files:{RESET} {len(swift_files)}")
    
    # Recommendations
    print(f"\n{BLUE}{'='*80}{RESET}")
    print(f"{BLUE}Recommendations:{RESET}\n")
    
    if in_progress:
        print(f"{YELLOW}⚠ Features in progress:{RESET}")
        for area, status, _ in in_progress:
            print(f"  - {area}: Complete implementation and mark as 'Implemented'")
    
    if planned:
        print(f"\n{RED}✗ Planned features not started:{RESET}")
        for area, status, _ in planned:
            print(f"  - {area}: Start implementation")
    
    print(f"\n{GREEN}✓ Next step:{RESET} Add XCUITest cases for implemented features")
    print(f"  See issue #16 for testing infrastructure setup\n")


def main():
    # Determine repository root
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    
    features_dir = repo_root / "features"
    registry_path = repo_root / "features" / "FEATURE_REGISTRY.md"
    ios_dir = repo_root / "ios"
    
    if not features_dir.exists():
        print(f"{RED}Error: features/ directory not found{RESET}")
        sys.exit(1)
    
    # Parse feature files
    print("Parsing feature files...")
    scenarios = parse_feature_files(features_dir)
    
    # Parse registry
    print("Parsing FEATURE_REGISTRY.md...")
    registry = parse_feature_registry(registry_path)
    
    # Find Swift files
    print("Finding Swift implementation files...")
    swift_files = find_swift_files_for_features(ios_dir, list(scenarios.keys()))
    
    # Print report
    print_report(scenarios, registry, swift_files)


if __name__ == "__main__":
    main()
