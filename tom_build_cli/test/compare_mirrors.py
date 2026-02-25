#!/usr/bin/env python3
import re
import sys

def extract_class_mirrors(filepath):
    """Extract ClassMirror data from a reflectable.dart file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Pattern to match ClassMirrorImpl with name and const <int>[] arrays
    pattern = r"r\.(Generic|NonGeneric)ClassMirrorImpl<[^>]+>\(\s*r'([^']+)',\s*r'([^']+)',\s*(\d+),\s*(\d+),\s*const \w+\.\w+\(\),\s*const <int>\[([^\]]*)\],\s*const <int>\[([^\]]*)\],\s*const <int>\[([^\]]*)\]"
    
    mirrors = {}
    for match in re.finditer(pattern, content, re.DOTALL):
        mirror_type = match.group(1)
        class_name = match.group(2)
        qualified_name = match.group(3)
        declarations = match.group(6).strip()
        instance_members = match.group(7).strip()
        static_members = match.group(8).strip()
        
        decl_count = len([x for x in declarations.split(',') if x.strip()]) if declarations else 0
        inst_count = len([x for x in instance_members.split(',') if x.strip()]) if instance_members else 0
        static_count = len([x for x in static_members.split(',') if x.strip()]) if static_members else 0
        
        mirrors[class_name] = {
            'type': mirror_type,
            'qualified': qualified_name,
            'declarations': decl_count,
            'instance_members': inst_count,
            'static_members': static_count,
        }
    
    return mirrors

def main():
    original = sys.argv[1]
    new = sys.argv[2]
    
    orig_mirrors = extract_class_mirrors(original)
    new_mirrors = extract_class_mirrors(new)
    
    print("# ClassMirror Comparison Report\n")
    print("## Summary\n")
    print(f"- **Original file (.reflectable.dart)**: {len(orig_mirrors)} class mirrors")
    print(f"- **New file (.reflection.dart)**: {len(new_mirrors)} class mirrors\n")
    
    only_original = set(orig_mirrors.keys()) - set(new_mirrors.keys())
    only_new = set(new_mirrors.keys()) - set(orig_mirrors.keys())
    common = set(orig_mirrors.keys()) & set(new_mirrors.keys())
    
    print("## Classes\n")
    if only_original:
        print(f"### Only in Original ({len(only_original)})\n")
        for name in sorted(only_original):
            print(f"- `{name}`")
        print()
    
    if only_new:
        print(f"### Only in New ({len(only_new)})\n")
        for name in sorted(only_new):
            print(f"- `{name}`")
        print()
    
    differences = []
    same = []
    
    for name in sorted(common):
        orig = orig_mirrors[name]
        new = new_mirrors[name]
        
        if (orig['declarations'] != new['declarations'] or 
            orig['instance_members'] != new['instance_members'] or
            orig['static_members'] != new['static_members']):
            differences.append((name, orig, new))
        else:
            same.append(name)
    
    if differences:
        print(f"### Classes with Differences ({len(differences)})\n")
        print("| Class | Array | Original | New | Difference |")
        print("|-------|-------|----------|-----|------------|")
        for name, orig, new in differences:
            if orig['declarations'] != new['declarations']:
                diff = new['declarations'] - orig['declarations']
                sign = '+' if diff > 0 else ''
                print(f"| `{name}` | declarations | {orig['declarations']} | {new['declarations']} | {sign}{diff} |")
            if orig['instance_members'] != new['instance_members']:
                diff = new['instance_members'] - orig['instance_members']
                sign = '+' if diff > 0 else ''
                print(f"| `{name}` | instance_members | {orig['instance_members']} | {new['instance_members']} | {sign}{diff} |")
            if orig['static_members'] != new['static_members']:
                diff = new['static_members'] - orig['static_members']
                sign = '+' if diff > 0 else ''
                print(f"| `{name}` | static_members | {orig['static_members']} | {new['static_members']} | {sign}{diff} |")
        print()
    
    print(f"### Classes with Identical Arrays ({len(same)})\n")
    for name in sorted(same):
        orig = orig_mirrors[name]
        print(f"- `{name}` (decl: {orig['declarations']}, inst: {orig['instance_members']}, static: {orig['static_members']})")

if __name__ == '__main__':
    main()
