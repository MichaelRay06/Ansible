Use the latest Ansible version to write a playbook: to update all packages on all managed nodes and check if the managed nodes
need rebooting after the package update, and use ignore error, if the managed node does not need to reboot and also a task to 
wait for the servers to reconnect. Write a task in a different separate YAML file to reboot the servers if needed, and another
task in a different separate  YAML file to confirm the servers are up and running, and the include_tasks module to include the
two saparstes YAML tasks in the  main  playbook



1. Main Playbook (main_update.yml) 

---
- name: Update packages and handle reboots
  hosts: all
  become: true
  gather_facts: true

  tasks:
    # Update all packages
    - name: Update system packages
      package:
        name: "*"
        state: latest
      register: pkg_update
      ignore_errors: yes  # Continue if some packages fail to update

    # Check reboot requirement
    - name: Check if reboot is needed
      ansible.builtin.stat:
        path: /var/run/reboot-required
      register: reboot_required
      ignore_errors: yes  # Continue if file doesn't exist
      changed_when: false

    # Conditionally include reboot tasks
    - name: Include reboot tasks if needed
      ansible.builtin.include_tasks: reboot_nodes.yml
      when: 
        - reboot_required.stat.exists
        - pkg_update is changed

    # Always include connection check
    - name: Include post-reboot verification
      ansible.builtin.include_tasks: verify_nodes.yml

2. Reboot Task File (reboot_nodes.yml)

---
- name: Reboot management block
  block:
    - name: Reboot servers if needed
      ansible.builtin.reboot:
        msg: "Rebooting after package updates"
        connect_timeout: 5
        reboot_timeout: 600
        pre_reboot_delay: 30
        post_reboot_delay: 60
      register: reboot_result

    - name: Display reboot status
      ansible.builtin.debug:
        msg: "Reboot initiated on {{ inventory_hostname }}"

  rescue:
    - name: Handle reboot failure
      ansible.builtin.debug:
        msg: "Reboot failed on {{ inventory_hostname }}"



3. Verification Task File (verify_nodes.yml) 

---
- name: Server verification block
  block:
    - name: Wait for servers to reconnect
      ansible.builtin.wait_for_connection:
        delay: 15
        timeout: 300
        sleep: 5

    - name: Verify system status
      ansible.builtin.ping:

    - name: Confirm services are running
      ansible.builtin.command: systemctl is-system-running
      register: system_status
      changed_when: false

    - name: Display system status
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} status: {{ system_status.stdout }}"

  rescue:
    - name: Handle verification failure
      ansible.builtin.debug:
        msg: "Verification failed for {{ inventory_hostname }}" 




Key Features:
Modular Design:

Separates concerns into logical files

Allows reuse of reboot/verification tasks

Clean main playbook structure

Error Handling:

ignore_errors on critical steps

Dedicated rescue blocks in included files

Safe execution even if some nodes fail

Modern Practices:

Uses ansible.builtin namespace

Proper reboot management with timeouts

Connection resilience with wait_for_connection

Execution Flow:

Main Playbook → Updates → Check Reboot → Conditional Include → 
  Reboot (if needed) → Always Verify


Verification:

Active ping test

Systemd status check

Connection waiting with retries









