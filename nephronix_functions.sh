alerter() {
    echo "System change alert!" | wall
}

netdiff() {

    cp /opt/nephronix/workspace/constate_current.dat /opt/nephronix/workspace/constate_previous.dat || touch /opt/nephronix/workspace/constate_previous.dat

    export CONSTATEP="$(b2sum /opt/nephronix/workspace/constate_previous.dat | cut -d' ' -f1)";

    tulpr="$(ss -tulpan | grep EST)"

    echo "$tulpr" > /opt/nephronix/workspace/constate_current.dat

    export CONSTATEN="$(b2sum /opt/nephronix/workspace/constate_current.dat | cut -d' ' -f1)";

    if [[ "$CONSTATEP" == "$CONSTATEN" ]]; then
        echo "No changes in established connections.";
    else
        echo "Connection state change detected! Diff:"
        diff /opt/nephronix/workspace/constate_previous.dat /opt/nephronix/workspace/constate_current.dat | tee /opt/nephronix/workspace/constate_diff.dat;
    fi

}

procoll() {

    echo "Self PID: $$"

    cp /opt/nephronix/workspace/procoll_current.dat /opt/nephronix/workspace/procoll_previous.dat || touch /opt/nephronix/workspace/procoll_previous.dat
 
    export PROCOLLP="$(b2sum /opt/nephronix/workspace/procoll_previous.dat | cut -d' ' -f1)";

    auxw="$(ps auxwww)"

    echo "$auxw" > /opt/nephronix/workspace/procoll_current.dat

    export PROCOLLN="$(b2sum /opt/nephronix/workspace/procoll_current.dat | cut -d' ' -f1)";

    if [[ "$PROCOLLN" == "$PROCOLLP" ]]; then
        echo "No changes in running processes.";
    else
        echo "Change in running processes detected! Diff:"
        diff /opt/nephronix/workspace/procoll_previous.dat /opt/nephronix/workspace/procoll_current.dat | tee /opt/nephronix/workspace/procoll_diff.dat;
    fi

}


userchk() {

    cp /opt/nephronix/workspace/userchk_current.dat /opt/nephronix/workspace/userchk_previous.dat || touch /opt/nephronix/workspace/userchk_previous.dat
    cp /opt/nephronix/workspace/userchk_stats_current.dat /opt/nephronix/workspace/userchk_stats_previous.dat || touch /opt/nephronix/workspace/userchk_stats_previous.dat

    export USERCHKP="$(b2sum /opt/nephronix/workspace/userchk_previous.dat | cut -d' ' -f1)";

    users="$(users)"
    userstats="$(w)"

    echo "$users" > /opt/nephronix/workspace/userchk_current.dat
    echo "$userstats" > /opt/nephronix/workspace/userchk_stats_current.dat

    export USERCHKN="$(b2sum /opt/nephronix/workspace/userchk_current.dat | cut -d' ' -f1)";

    if [[ "$USERCHKN" == "$USERCHKP" ]]; then
        echo "No changes in logged in users.";
    else
        echo "Change in logged in users detected! Diff:"
        diff /opt/nephronix/workspace/userchk_previous.dat /opt/nephronix/workspace/userchk_current.dat | tee /opt/nephronix/workspace/userchk_diff.dat;
        echo "Comparing user stats..."
        echo "Previously: $(cat /opt/nephronix/workspace/userchk_stats_previous.dat)"
        echo "Now: $(cat /opt/nephronix/workspace/userchk_stats_current.dat)"
    fi

}

kernmodchk() {

    cp /opt/nephronix/workspace/kernmodchk_current.dat /opt/nephronix/workspace/kernmodchk_previous.dat || touch /opt/nephronix/workspace/kernmodchk_previous.dat

    export KERNMODCHKP="$(b2sum /opt/nephronix/workspace/kernmodchk_previous.dat | cut -d' ' -f1)";

    kernmod="$(dmesg | grep -i "module\|bpf")"

    echo "$kernmod" > /opt/nephronix/workspace/kernmodchk_current.dat

    export KERNMODCHKN="$(b2sum /opt/nephronix/workspace/kernmodchk_current.dat | cut -d' ' -f1)";

    if [[ "$KERNMODCHKN" == "$KERNMODCHKP" ]]; then
        echo "No changes in kernel modules or BPF/eBPF detected.";
    else
        echo "Possible change in kernel module or BPF/eBPF detected! Diff:"
        diff /opt/nephronix/workspace/kernmodchk_previous.dat /opt/nephronix/workspace/kernmodchk_current.dat | tee /opt/nephronix/workspace/kernmodchk_diff.dat;
        alerter
    fi

}

bootchk() {

    cp /opt/nephronix/workspace/bootchk_current.dat /opt/nephronix/workspace/bootchk_previous.dat || touch /opt/nephronix/workspace/bootchk_previous.dat

    export BOOTCHKP="$(b2sum /opt/nephronix/workspace/bootchk_previous.dat | cut -d' ' -f1)";

    bootsys="$(nice find /boot -type f -exec b2sum {} \;)"

    echo "$bootsys" > /opt/nephronix/workspace/bootchk_current.dat

    export BOOTCHKN="$(b2sum /opt/nephronix/workspace/bootchk_current.dat | cut -d' ' -f1)";

    if [[ "$BOOTCHKN" == "$BOOTCHKP" ]]; then
        echo "No changes to /boot detected.";
    else
        echo "Changes to one or more files in /boot detected! Diff:"
        diff /opt/nephronix/workspace/bootchk_previous.dat /opt/nephronix/workspace/bootchk_current.dat | tee /opt/nephronix/workspace/bootchk_diff.dat;
        alerter
    fi

}

pkgchk() {

    cp /opt/nephronix/workspace/pkg_current.dat /opt/nephronix/workspace/pkg_previous.dat || touch /opt/nephronix/workspace/pkg_previous.dat

    export PKGP="$(b2sum /opt/nephronix/workspace/pkg_previous.dat | cut -d' ' -f1)";

    packages="$(dpkg -l || rpm -qa)"

    echo "$packages" > /opt/nephronix/workspace/pkg_current.dat

    export PKGN="$(b2sum /opt/nephronix/workspace/pkg_current.dat | cut -d' ' -f1)";

    if [[ "$PKGN" == "$PKGP" ]]; then
        echo "No changes to installed detected.";
    else
        echo "Changes to installed packages detected! Diff:"
        diff /opt/nephronix/workspace/pkg_previous.dat /opt/nephronix/workspace/pkg_current.dat | tee /opt/nephronix/workspace/pkg_diff.dat;
        alerter
    fi

}
