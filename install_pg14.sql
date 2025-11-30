---
- name: "Install PostgreSQL 14"
  hosts: pg14

  tasks:

    - name: "1) Download PostgreSQL Repository RPM"
      get_url:
        url: https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
        dest: /etc/yum.repos.d/pgdg-redhat-repo-latest.noarch.rpm
        validate_certs: no

    - name: "2) Configure repository"
      yum:
        name: /etc/yum.repos.d/pgdg-redhat-repo-latest.noarch.rpm
        state: present

    - name: "3) Update repository"
      shell: yum -y update

    - name: "4) Add EPEL repository"
      yum:
        state: latest
        name: epel-release
      vars:
        ansible_python_interpreter: /bin/python
        
    - name: "5) Enable EPEL repository"
      ini_file:
        dest: /etc/yum.repos.d/epel.repo
        section: epel
        option: enabled
        value: 1
 
    - name: "6) Install PostgreSQL 14"
      yum:
        state: latest
        name:
          - postgresql14
          - postgresql14-server
          - postgresql14-contrib
          - postgresql14-devel
          - postgresql14-libs
          - centos-release-scl
          - llvm5.0-devel
          - llvm-toolset-7-clang
      vars:
        ansible_python_interpreter: /bin/python
pg14_init.yml:
---
- name: "Initialize PostgreSQL 14 database cluster"
  hosts: pg14

  tasks:

   - name: "1) Initialize database cluster"
     shell: /usr/pgsql-14/bin/postgresql-14-setup initdb

   - name: "2) Start PostgreSQL service"
     service:
       name: postgresql-14
       state: started

   - name: "3) Create DBA user"
     become: yes
     become_user: postgres
     postgresql_user:
       name: dba
       db: postgres
       password: "pass123"
       priv: "ALL"

   - name: "4) Configure pg_hba.conf"
     become: yes
     become_user: postgres
     blockinfile:
       dest: "/var/lib/pgsql/14/data/pg_hba.conf"
       insertafter: "# TYPE  DATABASE        USER            ADDRESS                 METHOD"
       block: |
         local   all             dba                 trust

   - name: "5) Reload configuration"
     become: yes
     become_user: postgres
     shell: /usr/pgsql-14/bin/pg_ctl reload -D /var/lib/pgsql/14/data
pg14_main.yml:
---
- import_playbook: pg14_install.yml
- import_playbook: pg14_init.yml-
