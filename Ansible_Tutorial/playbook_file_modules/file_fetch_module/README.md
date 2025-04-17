#!/usr/bin/ansible-playbook  # Shebang line indicating this is an Ansible playbook

---  # YAML document start marker

# Play definition with description and basic settings
- name: Create, verify, and fetch a log file with checksum validation  # Play name shown during execution
  hosts: all  # Applies to all hosts in inventory
  become: true  # Uses privilege escalation (sudo)
  gather_facts: true  # Collects system facts before executing tasks

  # Variables section (reusable throughout the playbook)
  vars:
    log_path: /var/log/example.log  # Path to log file on remote hosts
    expected_checksum: "sha256:9e107d9d372bb6826bd81d3542a419d6"  # Pre-computed checksum value
    checksum_algorithm: sha256  # Hashing algorithm to use for validation

  # Tasks section (main execution steps)
  tasks:

    # TASK 1: Directory preparation
    # Ensures the log directory exists with correct permissions
    - name: Ensure /var/log exists on managed nodes  # Human-readable task description
      ansible.builtin.file:  # Uses the file module from ansible.builtin collection
        path: /var/log/  # Target directory path
        state: directory  # Ensures this is a directory
        mode: '0755'  # Sets permissions (rwxr-xr-x)

    # TASK 2: Log file creation
    # Creates the log file with sample content (idempotent operation)
    - name: Create example log file on remote host
      ansible.builtin.shell: |  # Uses shell module for command execution
        echo "this is my log content" > {{ log_path }}  # Creates file with content
      args:  # Additional arguments for the shell module
        creates: "{{ log_path }}"  # Makes task idempotent - skips if file exists

    # TASK 3: Checksum verification (part 1)
    # Gathers file stats including checksum
    - name: Calculate and validate the checksum of the log file
      ansible.builtin.stat:  # Uses stat module to get file info
        path: "{{ log_path }}"  # File to examine
        checksum_algorithm: "{{ checksum_algorithm }}"  # Uses specified hash algorithm
      register: log_file_stat  # Saves results in variable for later use

    # TASK 4: Checksum verification (part 2)
    # Validates the checksum matches expected value
    - name: Fail if checksum does not match
      ansible.builtin.fail:  # Fails the playbook if condition is met
        msg: "Checksum mismatch! Expected {{ expected_checksum }}, got {{ log_file_stat.stat.checksum }}"
      when:  # Conditional execution
        log_file_stat.stat.checksum is defined and  # Checks if checksum exists
        log_file_stat.stat.checksum != expected_checksum  # Compares values

    # TASK 5: File transfer
    # Copies the log file from remote to control node
    - name: Fetch log file to control node
      ansible.builtin.fetch:  # Uses fetch module to download files
        src: "{{ log_path }}"  # Source file on remote host
        dest: /tmp/logs/  # Destination directory on control node
        flat: yes  # Keeps original filename (no hostname subdirectories)
        validate_checksum: yes  # Verifies file integrity during transfer




#NOTE:

Key Components Explained:

Structure: The playbook has three main sections - play definition (name, hosts, settings), variables, and tasks.

Idempotency:

The creates argument prevents file recreation if it exists

All modules are designed to be safe for multiple runs

Safety Checks:

Validates file checksum before transfer

Explicitly fails on checksum mismatch

Uses proper file permissions (0755)

File Handling:

Creates directory if needed

Generates file with specific content

Verifies file integrity

Securely transfers file to control node

Error Handling:

Checks if checksum exists before comparison

Provides clear error messages on failure

Validates transfers with checksums

Note: The example checksum value should be replaced with an actual checksum of your expected file content for production use. You can generate this by creating the file manually first and running sha256sum on it.









