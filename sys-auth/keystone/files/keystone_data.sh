#!/bin/bash
#
# from devstack (top commit e87f7fc0c1e15ad1c72a96c0f239ac4bdf5147de) - drobbins
# this file required tweaks to error out on failure
#
# Initial data for Keystone using python-keystoneclient
#
# Tenant               User      Roles
# ------------------------------------------------------------------
# admin                admin     admin
# service              glance    admin
# service              nova      admin, [ResellerAdmin (swift only)]
# service              quantum   admin        # if enabled
# service              swift     admin        # if enabled
# demo                 admin     admin
# demo                 demo      Member, anotherrole
# invisible_to_admin   demo      Member
#
# Variables set before calling this script:
# SERVICE_TOKEN - aka admin_token in keystone.conf
# SERVICE_ENDPOINT - local Keystone admin endpoint
# SERVICE_TENANT_NAME - name of tenant containing service accounts
# ENABLED_SERVICES - stack.sh's list of services to start
# DEVSTACK_DIR - Top-level DevStack directory

source /etc/init.d/functions.sh

ADMIN_PASSWORD=${ADMIN_PASSWORD:-secrete}
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$ADMIN_PASSWORD}
export SERVICE_TOKEN=$SERVICE_TOKEN
export SERVICE_ENDPOINT=$SERVICE_ENDPOINT
SERVICE_TENANT_NAME=${SERVICE_TENANT_NAME:-service}

try() {
        ebegin "$@"
	"$@" 
        if [ $? -ne 0 ]; then
                echo "!!! Command failure: $@"
                exit 1
        fi
	eend 0
}

get_id() {
	# this function grabs the UID of the thing that just got created. It also checks for
	# command failure and will exit the script on error with a script exit code of 1
	local varname=$1
	shift
	ebegin "keystone $@"
	# quotes around "$@" allows passwords with spaces to be handled properly:
	keystone "$@" > /tmp/devstack.id.out
       	[ $? -ne 0 ] && echo "!!! Command failure: keystone $@" && exit 1
	eval $varname="$( cat /tmp/devstack.id.out | awk '/ id / { print $4 }' )"
	eend 0
	# extra verbosity isn't bad.... enable if you need it:
	ebegin "Set $varname to $(eval echo \$$varname)"; eend 0
}

# Tenants
get_id ADMIN_TENANT tenant-create --name=admin
get_id SERVICE_TENANT tenant-create --name=$SERVICE_TENANT_NAME
get_id DEMO_TENANT tenant-create --name=demo
get_id INVIS_TENANT tenant-create --name=invisible_to_admin

# Users
get_id ADMIN_USER user-create --pass="$ADMIN_PASSWORD" --name=admin --email=admin@example.com
get_id DEMO_USER user-create --pass="$ADMIN_PASSWORD" --name=demo --email=demo@example.com

# Roles
get_id ADMIN_ROLE role-create --name=admin
get_id KEYSTONEADMIN_ROLE role-create --name=KeystoneAdmin
get_id KEYSTONESERVICE_ROLE role-create --name=KeystoneServiceAdmin
# ANOTHER_ROLE demonstrates that an arbitrary role may be created and used
# TODO(sleepsonthefloor): show how this can be used for rbac in the future!
get_id ANOTHER_ROLE role-create --name=anotherrole

# Add Roles to Users in Tenants
try keystone user-role-add --user $ADMIN_USER --role $ADMIN_ROLE --tenant_id $ADMIN_TENANT
try keystone user-role-add --user $ADMIN_USER --role $ADMIN_ROLE --tenant_id $DEMO_TENANT
try keystone user-role-add --user $DEMO_USER --role $ANOTHER_ROLE --tenant_id $DEMO_TENANT

# TODO(termie): these two might be dubious
try keystone user-role-add --user $ADMIN_USER --role $KEYSTONEADMIN_ROLE --tenant_id $ADMIN_TENANT
try keystone user-role-add --user $ADMIN_USER --role $KEYSTONESERVICE_ROLE --tenant_id $ADMIN_TENANT


# The Member role is used by Horizon and Swift so we need to keep it:
get_id MEMBER_ROLE role-create --name=Member
try keystone user-role-add --user $DEMO_USER --role $MEMBER_ROLE --tenant_id $DEMO_TENANT
try keystone user-role-add --user $DEMO_USER --role $MEMBER_ROLE --tenant_id $INVIS_TENANT


# Configure service users/roles
get_id NOVA_USER user-create --pass="$SERVICE_PASSWORD" --name=nova \
                                        --tenant_id $SERVICE_TENANT \
                                        --email=nova@example.com
try keystone user-role-add --tenant_id $SERVICE_TENANT \
                       --user $NOVA_USER \
                       --role $ADMIN_ROLE

get_id GLANCE_USER user-create \
					--pass="$SERVICE_PASSWORD" \
					--name=glance \
                                          --tenant_id $SERVICE_TENANT \
                                          --email=glance@example.com
try keystone user-role-add --tenant_id $SERVICE_TENANT \
                       --user $GLANCE_USER \
                       --role $ADMIN_ROLE

if [[ "$ENABLED_SERVICES" =~ "swift" ]]; then
    get_id SWIFT_USER user-create \
                                             --pass="$SERVICE_PASSWORD" \
					--name=swift \
                                             --tenant_id $SERVICE_TENANT \
                                             --email=swift@example.com
try keystone user-role-add --tenant_id $SERVICE_TENANT \
                           --user $SWIFT_USER \
                           --role $ADMIN_ROLE
    # Nova needs ResellerAdmin role to download images when accessing
    # swift through the s3 api. The admin role in swift allows a user
    # to act as an admin for their tenant, but ResellerAdmin is needed
    # for a user to act as any tenant. The name of this role is also
    # configurable in swift-proxy.conf
    get_id RESELLER_ROLE role-create --name=ResellerAdmin
    try keystone user-role-add --tenant_id $SERVICE_TENANT \
                           --user $NOVA_USER \
                           --role $RESELLER_ROLE
fi

if [[ "$ENABLED_SERVICES" =~ "quantum" ]]; then
    get_id QUANTUM_USER user-create \
				--pass="$SERVICE_PASSWORD" \
    				--name=quantum \
                                               --tenant_id $SERVICE_TENANT \
                                               --email=quantum@example.com
    try keystone user-role-add --tenant_id $SERVICE_TENANT \
                           --user $QUANTUM_USER \
                           --role $ADMIN_ROLE
fi
