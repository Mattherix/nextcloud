Role Name
=========

Install nextcloud in a VM for my homelab

Role Variables
--------------

- nextcloud_version: The nextcloud version to used
- nextcloud_admin: The nextcloud admin username
- nextcloud_admin_password: The nextcloud admin password
- nextcloud_data_directory: The data directory used to store all users files

- nextcloud_s3_name: The nextcloud bucket name if s3 primary storage is used
- nextcloud_s3_key: The nextcloud bucket key if s3 primary storage is used
- nextcloud_s3_secret: The nextcloud bucket secret key if s3 primary storage is used
- nextcloud_s3_domain: The nextcloud bucket domain if s3 primary storage is used
- nextcloud_s3_region: The nextcloud bucket region if s3 primary storage is used

Dependencies
------------

- install_apache2: Install and configure apache2
- install_php: Install and configure php

License
-------

EFL-2.0, free and open-sourced licensed.

Please read the LICENSE file.

Compatible with the GNU GPL https://directory.fsf.org/wiki/License:EFL-2.0
