from ansible.errors import AnsibleError

class FilterModule(object):
    def filters(self):
        return {
            'k8s_owned_by': k8s_owned_by
        }

def k8s_owned_by(objects, owner):
    owned = []

    for obj in objects:
        if object_owned_by(obj, owner):
            owned.append(obj)
    
    return owned

def object_owned_by(object, owner):
    if owner is None:
        raise AnsibleError('owner is empty')
    if 'metadata' not in owner:
        raise AnsibleError('owner is missing "metadata" field')
    if 'uid' not in owner['metadata']:
        raise AnsibleError('owner is missing "metadata.uid" field')

    if object is None:
        raise AnsibleError('object is empty')
    if 'metadata' not in object:
        raise AnsibleError('object is missing "metadata" field')
    if 'ownerReferences' not in object['metadata']:
        return False

    ownerUID = owner['metadata']['uid']

    if object['metadata']['ownerReferences'] is not None:
        for ref in object['metadata']['ownerReferences']:
            if ref['uid'] == ownerUID:
                return True
    
    return False