from ansible.errors import AnsibleError

class FilterModule(object):
    def filters(self):
        return {
            'k8s_inject_ownership': k8s_inject_ownership
        }

def k8s_inject_ownership(objects, owner):
    owner_ref = {
        "apiVersion": owner["apiVersion"],
        "kind": owner["kind"],
        "name": owner['metadata']["name"],
        "uid": owner['metadata']['uid']
    }
    ownerUID = owner['metadata']['uid']

    for obj in objects:
        if obj['metadata']['ownerReferences'] is not None:
            found = False
            for index, ref in enumerate(obj['metadata']['ownerReferences']):
                if ref['uid'] == ownerUID:
                    obj["metadata"]["ownerReferences"][index] = owner_ref
                    found = True
                    break

            if not found:
                obj['metadata']['ownerReferences'].append(owner_ref)
        else:
            obj['metadata']['ownerReferences'] = [owner_ref]            
    
    return objects
