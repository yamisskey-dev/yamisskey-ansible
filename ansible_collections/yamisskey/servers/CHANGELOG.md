# Changelog

All notable changes to the yamisskey.servers collection will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- integration-test role with comprehensive testing suite
- repository-manager role with backup and restore capabilities  
- migration-validator role for deployment validation
- operations role for Docker operations and health checks
- system-init role for system initialization and dependency management
- system-test role for basic system validation

### Changed
- Refactored monolithic playbooks into modular role-based architecture
- Improved code organization with 86% line reduction (1,124→158 lines)
- Enhanced error handling and validation throughout all roles
- Upgraded Jinja2 templates to follow ansible-lint best practices

### Fixed
- Resolved all ansible-lint violations for production-ready code quality
- Fixed Docker template syntax issues in shell commands
- Corrected boolean comparison patterns for Ansible compliance
- Improved FQCN usage for all community collection modules

## [1.0.0] - 2024-12-09

### Added
- Initial release of yamisskey.servers collection
- Basic playbook structure for Yamisskey deployment
- System initialization and testing functionality