# Code to create DRBD.

# This requires DRBD configuration present!
create_drbd() {
    local drbd disk resource device junk
    read drbd disk resource device junk < <(grep "^drbd $1 " "$LAYOUT_FILE")

    cat >> "$LAYOUT_CODE" <<EOF
if [ ! -e /proc/drbd ] ; then
    modprobe drbd
fi

mkdir -p /var/lib/drbd

LogPrint "Creating DRBD resource $resource"
if ! drbdadm role $resource &>/dev/null ; then
   drbdadm -- --force create-md $resource
fi

EOF

    # Ask if we need to become primary.
    user_input="$( UserInput -p "Type 'yes' if you want DRBD resource $resource to become primary" )"
    if [ "$user_input" = "yes" ] ; then
        cat >> "$LAYOUT_CODE" <<-EOF
        if ! drbdadm role $resource &>/dev/null ; then
           drbdadm up $resource
           drbdadm -- --overwrite-data-of-peer primary $resource
        fi
	EOF
    else
        # Mark things which depend on this drbd resource as "done" (recursively).
        mark_tree_as_done "$disk"
        EXCLUDE_RESTORE=( "${EXCLUDE_RESTORE[@]}" "$disk" )
    fi
}
