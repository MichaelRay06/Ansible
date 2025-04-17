Key Components Explained:
slurp Module:

Reads remote file and returns content as base64 encoded string

Stores result in nginx_config variable with metadata

Does NOT transfer the file - only reads content into memory

Base64 Decoding:

Uses b64decode filter to convert content to readable text

Applied both for display and file saving

Local File Handling:

Creates destination directory with proper permissions

Saves decoded content to specified local path

Uses delegate_to: localhost to run on control node

Safety Features:

Checks if content exists before decoding/saving

Sets appropriate file permissions (0644 for config)

run_once prevents duplicate directory creation

Idempotency:

Directory creation is safe for multiple runs

File content will be overwritten if different



///////////////////////////////////////////////////////////////
#!/usr/bin/env ansible-playbook  # Specifies the interpreter for executing this playbook

---  # YAML document start marker

# Main play definition
- name: Create, deploy and schedule log cleanup script  # Human-readable play description
  hosts: all                  # Targets all hosts in the inventory
  become: true                # Enables privilege escalation (sudo)
  gather_facts: true          # Gathers system facts before execution

  # Task section begins
  tasks:
    # TASK 1: Ensure source directory exists on control node
    - name: Ensure source directory /folder/myfiles exists  # Task description
      ansible.builtin.file:    # Uses Ansible's file module
        path: /folder/myfiles  # Directory path to create/maintain
        state: directory       # Ensures this is a directory
        mode: '0755'           # Sets permissions to rwxr-xr-x
      delegate_to: localhost   # Executes on the control node
      run_once: true           # Only runs once, even with multiple hosts

    # TASK 2: Create default cleanup script if missing
    - name: Create default cleanup script if missing  # Task description
      ansible.builtin.copy:    # Uses copy module to create file
        dest: /folder/myfiles/cleanup_logs.sh  # Destination path
        content: |             # Multi-line file content
          #!/bin/bash
          # Auto-generated log cleanup script
          # Deletes log files older than 30 days
          find /var/log -name "*.log" -type f -mtime +30 -delete
          echo "$(date): Log cleanup completed" >> /var/log/cleanup.log
        mode: '0755'           # Makes script executable
        owner: "{{ ansible_user_id }}"  # Uses current Ansible user
        group: "{{ ansible_user_id }}"  # Uses current Ansible group
      delegate_to: localhost   # Executes on control node
      run_once: true           # Only runs once
      when: not lookup('file', '/folder/myfiles/cleanup_logs.sh', errors='ignore')  # Only if file doesn't exist

    # TASK 3: Ensure destination directory exists on managed nodes
    - name: Ensure /usr/local/bin exists on managed nodes  # Task description
      ansible.builtin.file:    # Uses file module
        path: /usr/local/bin   # Directory path on managed nodes
        state: directory       # Ensures directory exists
        mode: '0755'           # Sets permissions to rwxr-xr-x

    # TASK 4: Deploy the cleanup script to managed nodes
    - name: Copy cleanup script to managed nodes  # Task description
      ansible.builtin.copy:    # Uses copy module
        src: /folder/myfiles/cleanup_logs.sh  # Source on control node
        dest: /usr/local/bin/cleanup_logs.sh  # Destination on managed nodes
        mode: '0755'           # Makes script executable
        owner: root            # Sets owner to root
        group: root            # Sets group to root
        backup: yes            # Creates backup if file exists

    # TASK 5: Schedule cron job
    - name: Create weekly log cleanup cron job  # Task description
      ansible.builtin.cron:    # Uses cron module
        name: "Log cleanup job"  # Descriptive cron job name
        job: "/usr/local/bin/cleanup_logs.sh"  # Command to execute
        minute: "30"           # Runs at 30 minutes past the hour
        hour: "16"             # Runs at 4 PM (16:00)
        weekday: "1"           # 1 = Monday (0-6 where 0 is Sunday)
        user: root             # Runs as root user
        cron_file: "log_cleanup"  # Creates in /etc/cron.d/log_cleanup
To use this playbook:

Save as fetch_nginx.yml

Run with: ansible-playbook -i inventory fetch_nginx.yml

Find the downloaded config at: /playbook_file_modules/folder/myfiles/nginx.conf

Note: The slurp module is useful for small files as it loads the entire content into memory. For large files, consider using the fetch module instead.


/////////////////////////////////////////////////////



Key Improvements:
Automatic Script Creation:

Checks if source script exists (/folder/myfiles/cleanup_logs.sh)

Creates a default script if missing with basic log rotation logic

Sets proper permissions (0755) for the new script

Directory Management:

Ensures source directory exists on control node

Ensures destination directory exists on managed nodes

Safety Features:

Only creates script if it doesn't exist (when condition)

Uses delegate_to: localhost for control node operations

run_once: true prevents duplicate operations

Default Script Content:

Includes basic log cleanup functionality (deletes logs >30 days old)

Adds logging of cleanup operations to /var/log/cleanup.log

Verification Steps:
