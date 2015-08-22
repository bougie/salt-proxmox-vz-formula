# -*- coding: utf-8 -*-
'''
Support for OpenVZ container on proxmox host
'''

from __future__ import absolute_import

import logging
# import salt.utils
# from salt.exceptions import CommandExecutionError, SaltInvocationError

try:
    from proxmoxer import ProxmoxAPI
except ImportError:
    HAS_DEP = False
else:
    HAS_DEP = True

log = logging.getLogger(__name__)

__virtualname__ = 'proxmox-vz'


def __virtual__():
    '''
    Return false if proxmoxer is not installed
    '''
    if HAS_DEP:
        return __virtualname__
    else:
        return False


def _connect(host='localhost', user='root@pam', password='', **kwargs):
    '''
    Connect to proxmox API
    '''
    accepted_keywords = ['verify_ssl']

    args = {'host': host,
            'user': user,
            'password': password}
    for k in accepted_keywords:
        if k in kwargs:
            args[k] = kwargs[k]

    return ProxmoxAPI(**args)


def containers(**kwargs):
    '''
    List OpenVZ containers on local proxmox host

    CLI Example:

    .. code-block:: bash

        salt '*' proxmox-vz.containers
    '''
    ret = []

    try:
        proxmox = _connect(**kwargs)
    except Exception, e:
        log.error(str(e))
        raise e
    else:
        nodename = __salt__['grains.get']('nodename')
        for vm in proxmox.nodes(nodename).openvz.get():
            ret.append({'vmid': vm['vmid'],
                        'name': vm['name'],
                        'status': vm['status']})

    return ret


if __name__ == "__main__":
    __salt__ = ''

    import sys
    sys.exit(0)
