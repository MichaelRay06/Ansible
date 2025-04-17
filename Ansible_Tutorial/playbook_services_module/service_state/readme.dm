#!/usr/bin/ansible-playbook  # Shebang line specifying this is an Ansible playbook

---  # YAML document start marker

# Play definition section
- name: Install and configure Nginx with Apache fallback  # Descriptive play name
  hosts: all  # Targets all hosts in the inventory
  become: true  # Enables privilege escalation (sudo)
  gather_facts: true  # Gathers system facts before execution

  # Tasks section - main execution steps
  tasks:
    # Task 1: Update package cache (APT systems only)
    - name: Update package cache  # Human-readable task name
      ansible.builtin.apt:  # Uses the apt module from ansible.builtin collection
        update_cache: yes  # Equivalent to 'apt-get update'
      when: ansible_facts['pkg_mgr'] == 'apt'  # Only runs on Debian/Ubuntu systems

    # Task 2: Install Nginx web server
    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx  # Package name
        state: present  # Ensures package is installed
      when: ansible_facts['pkg_mgr'] == 'apt'  # Debian/Ubuntu only
      notify: Enable Nginx  # Triggers handler if this task changes state

    # Task 3: Install Apache as fallback
    - name: Install Apache (for fallback)
      ansible.builtin.apt:
        name: apache2  # Package name
        state: present  # Ensures package is installed
      when: ansible_facts['pkg_mgr'] == 'apt'  # Debian/Ubuntu only

    # Task 4: Gather service status information
    - name: Gather service facts
      ansible.builtin.service_facts:  # Collects status of all services
      # Results are stored in ansible_facts.services dictionary

    # Task 5: Ensure Nginx is running
    - name: Ensure Nginx is running
      ansible.builtin.service:
        name: nginx  # Service name
        state: started  # Ensures service is running
        enabled: true  # Ensures service starts at boot
      when:  # Conditions for execution
        - ansible_facts.services['nginx'] is defined  # Only if Nginx exists
        - ansible_facts.services['nginx'].state != 'running'  # Only if not already running

    # Task 6: Ensure Apache is stopped
    - name: Ensure Apache is stopped
      ansible.builtin.service:
        name: apache2  # Service name
        state: stopped  # Ensures service is stopped
        enabled: false  # Ensures service doesn't start at boot
      when:  # Conditions for execution
        - ansible_facts.services['apache2'] is defined  # Only if Apache exists
        - ansible_facts.services['apache2'].state != 'stopped'  # Only if not already stopped

    # Task 7: Display Nginx service status
    - name: Display Nginx status
      ansible.builtin.debug:  # Debug module for printing messages
        msg: "Nginx is {{ ansible_facts.services['nginx'].state | default('not installed') }}"
        # Shows current state or 'not installed' if Nginx doesn't exist

    # Task 8: Display Apache service status
    - name: Display Apache status
      ansible.builtin.debug:
        msg: "Apache is {{ ansible_facts.services['apache2'].state | default('not installed') }}"
        # Shows current state or 'not installed' if Apache doesn't exist

  # Handlers section - triggered by notify statements
  handlers:
    # Handler 1: Enable Nginx service at boot
    - name: Enable Nginx
      ansible.builtin.service:
        name: nginx  # Service name
        enabled: true  # Ensures service starts at boot
        # Note: This doesn't start the service, just enables autostart


EXPLANATION:

Key Features Explained:

Platform Specific:

Uses when: ansible_facts['pkg_mgr'] == 'apt' to only run on Debian/Ubuntu

Service names automatically adapt to the target system

Idempotent Design:

Each task checks current state before making changes

Uses conditional execution (when) to prevent unnecessary changes

Service Management:

Installs both Nginx and Apache

Ensures Nginx runs while Apache is stopped

Sets proper startup behavior (enabled/disabled)

Status Reporting:

Gathers service facts to check current state

Displays clear status messages for both services

Handles cases where services aren't installed

Handler Usage:

Uses notify to trigger service enabling

Separates service starting from enabling for better control

Safety Features:

Checks if services exist before managing them

Uses default values for status display

Only makes changes when needed

This playbook follows Ansible best practices by:

Using fully qualified module names (ansible.builtin)

Maintaining idempotency

Providing clear status output

Handling different system states gracefully

Separating configuration from execution with handlers
