{% from "proxmox-vz/default.yml" import rawmap with context %}
{% set rawmap = salt['pillar.get']('proxmox-vz', rawmap, merge=True) %}

{% if salt['grains.get']('os') in rawmap.ifx_file %}
    {% set ifx_cfg_file = rawmap.ifx_file[salt['grains.get']('os')] %}
{% else %}
    {% set ifx_cfg_file = rawmap.ifx_file['default'] %}
{% endif %}

{% if rawmap.containers is defined %}
    {% for ctid, ctcfg in rawmap.containers.items() %}
        {% if ctcfg.network is defined %}
            {% set ctifx = [] %}
            {% for ifx, ifxcfg in ctcfg.network.items() %}
                {% if ifxcfg.gateway is defined %}
                    {% do ctifx.append({'name': ifx,
                                        'ip': ifxcfg.ip,
                                        'mask': ifxcfg.mask,
                                        'gateway': ifxcfg.gateway}) %}
                {% else %}
                    {% do ctifx.append({'name': ifx,
                                        'ip': ifxcfg.ip,
                                        'mask': ifxcfg.mask}) %}
                {% endif %}
            {% endfor %}
        {% endif %}

        {% if ctifx is defined %}
            {% if ctcfg.type is defined and ctcfg.type in rawmap.ifx_file %}
            {#
             # RedHat / centos like container
             #}
                {% for ifx in ctifx %}
{{ctid ~ '_ct_network_' ~ ifx.name}}:
    file.managed:
        - name: {{rawmap.vz_root_dir ~ '/' ~ ctid ~ rawmap.ifx_file[ctcfg.type] % ifx.name}}
        - source: salt://proxmox-vz/files/{{ctcfg.type ~ '_ifcfg.j2'}}
        - template: jinja
        - context:
            interface: {{ifx}}
                    {% if ifx.gateway is defined %}
{{ctid ~ '_ct_network_' ~ ifx.name ~ '_gwdev'}}:
    file.replace:
        - name: {{rawmap.vz_root_dir ~ '/' ~ ctid ~ '/etc/sysconfig/network'}}
        - pattern: |
            (GATEWAYDEV=".+")
        - repl: {{'GATEWAYDEV="' ~ ifx.name ~ '"'}}\n
                    {% endif %}
                {% endfor %}
            {% else %}
            {#
             # debian like container
             #}
{{ctid ~ '_ct_network'}}:
    file.managed:
        - name: {{rawmap.vz_root_dir ~ '/' ~ ctid ~ rawmap.ifx_file['default']}}
        - source: salt://proxmox-vz/files/interfaces.j2
        - template: jinja
        - context:
            interfaces: {{ctifx}}
            {% endif %}
        {% endif %}
    {% endfor %}
{% endif %}
