import os
import sys

def validate_rules(rules_file):
    if not os.path.exists(rules_file):
        print(f"SKIPPING: {rules_file} not found.")
        return True
    
    with open(rules_file, 'r') as f:
        content = f.read()
    
    # Simple DAST-like checks for common misconfigurations
    secure = True
    if "allow read, write: if true" in content:
        print(f"CRITICAL: {rules_file} allows public read/write access!")
        secure = False
    
    if "allow write: if request.auth != null" in content and "allow write: if true" not in content:
        print(f"INFO: {rules_file} requires authentication for writes. Good.")
    
    return secure

if __name__ == "__main__":
    firestore_ok = validate_rules('firestore.rules')
    storage_ok = validate_rules('storage.rules')
    
    if not (firestore_ok and storage_ok):
        sys.exit(1)
    print("Security rules validation passed.")
