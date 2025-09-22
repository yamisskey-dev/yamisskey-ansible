# Watch Role

Watch role provides system-level monitoring components that need to be installed directly on the host system. This role complements the `monitor` role which provides centralized monitoring services.

## Purpose

This role handles monitoring agents and exporters that require:
- Direct system access
- Host-level service installation
- Package manager compatibility across different distributions

## Components

### Node Exporter
- **Purpose**: System metrics collection (CPU, memory, disk, network)
- **Installation**: System service (systemd)
- **Port**: 9100

### cAdvisor
- **Purpose**: Container resource monitoring
- **Installation**: Docker container with privileged access
- **Port**: 8085

### Blackbox Exporter
- **Purpose**: External service monitoring (HTTP, DNS, TCP, ICMP)
- **Installation**: Docker container
- **Port**: 9115

## Usage

```yaml
- hosts: monitor_targets
  roles:
    - yamisskey.servers.watch
```

## Variables

See `defaults/main.yml` for configuration options.

## Dependencies

- Docker (for cAdvisor and Blackbox Exporter)
- systemd (for Node Exporter service management)

## Tags

- `node_exporter`: Node Exporter specific tasks
- `cadvisor`: cAdvisor specific tasks
- `blackbox_exporter`: Blackbox Exporter specific tasks