# nephronix

Nephronix is a simple linux system daemon for checking various aspects of the local system. 

High priority (sends a wall notice by default, could be replaced with email or text alerts etc):

- changes to installed packages (rpm or deb)
- changes to loaded kernel modules or BPF/eBPF
- changes to files within /boot (kernel and bootstrapping syscheck)

Second priority (log only):

- changes in ESTABLISHED network connections
- changes in logged in users
- changes in running processes

Nephronix prioritizes interoperability, simplicity, and customization over performance. The same concepts could be
made to be more performant by rewriting in c or rust etc. I might upload such a version to github, or perhaps not.
Nephronix does use "nice" to deprioritize the the heavier operation it uses which is a `find` with a `b2sum` exec.
The rest of the child processes are at standard priority. Data is stored on the disk in /opt/nephronix/ which
hold all needed files except for the nephronix executable and the live log. See the usage section for more details.

Nephronix does not syscheck the entire system by default, only sycheck of /boot. It is possible to expand the syscheck targets, 
but keep in mind the resource cosumption and impact to cycle time.

### Installation

Example script installation method:

```
sudo bash installer
```

I'll likely add .deb and .rpm packages for this eventually.

## Usage

The daemon is started automatically by systemd after the network is up. The startup could be switched to another init system as desired.

The daemon will exit in error if the the functions file (/opt/nephronix/lib/nephronix_functions.sh) is changed unless the BLAKE2 hash of it is 
set as the "expectedhash" variable within the executable `/usr/local/bin/nephronix` file. Note the future packaged version (/usr/local/bin/nephronix) will likely move to /usr/bin/ instead, however the functions file and everything else will remain in place.

The live log file /var/log/nephronix.log contains the detailed event data. The /var/log/nephronix.log file is truncated after nephronix detects it to be 100,000 bytes or larger, after it has made a gzipped copy in /opt/nephronix/archive. Additionally, archive files older than 30 days are deleted by default. 

The output of the instrumentation is stored in .dat files in /opt/nephronix/workspace/. These files are used by nephronix for comparing current to previous states and can also be read by other programs or people etc.

While it largely depends on the activity of a given system, and whether nephronix has been tuned such as with nephronix_light, we might expect roughly 0.3 MB per hour, 7.2 MB per day, and 216 MB per 30 days (sizes estimates are for gzip -9 compressed, which is default) for the archive files for a nephronix instance. Only 30 days of archives is held by nephronix by default, so the usage might hover around 216 MB and not grow significantly beyond that.

 Adjust data retention and/or polling interval (sleep) appropriately for the use-case. See the nephronix_light example which cuts the two noiseist checks to prioritize more significant events and use less resources.

Example checking on previous events in the archive:

```
$ zgrep detected! *.gz | grep -v processes
nephronix_20230607182309.log.gz:20230607-18:23:03 NEPHRONIX - 71c059e9-8a79-648e-13c9-52397e491d1d - Connection state change detected! Diff:
nephronix_20230607182309.log.gz:20230607-18:23:03 NEPHRONIX - 71c059e9-8a79-648e-13c9-52397e491d1d - Change in logged in users detected! Diff:
nephronix_20230607182309.log.gz:20230607-18:23:03 NEPHRONIX - 71c059e9-8a79-648e-13c9-52397e491d1d - Possible change in kernel module or BPF/eBPF detected! Diff:
nephronix_20230607182309.log.gz:20230607-18:23:04 NEPHRONIX - 71c059e9-8a79-648e-13c9-52397e491d1d - Changes to one or more files in /boot detected! Diff:
nephronix_20230607182309.log.gz:20230607-18:23:06 NEPHRONIX - 71c059e9-8a79-648e-13c9-52397e491d1d - Changes to installed packages detected! Diff:
nephronix_20230607182404.log.gz:20230607-18:23:26 NEPHRONIX - b5abe29a-fcc2-a7e2-9125-f1c3217da6cb - Connection state change detected! Diff:
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - Connection state change detected! Diff:
nephronix_20230607182614.log.gz:20230607-18:25:19 NEPHRONIX - 35bf3037-5276-2e60-94bf-ec4a2a0a84b7 - Connection state change detected! Diff:
nephronix_20230607182614.log.gz:20230607-18:25:26 NEPHRONIX - d3c0aab3-f48d-5af6-b57d-b48b00bbdcff - Connection state change detected! Diff:
nephronix_20230607182614.log.gz:20230607-18:25:55 NEPHRONIX - ef402044-5d3d-1a62-5da1-7df47a1aff6c - Connection state change detected! Diff:
nephronix_20230607182614.log.gz:20230607-18:25:59 NEPHRONIX - 51406eda-53d6-3610-ab30-6df74a481cda - Connection state change detected! Diff:
nephronix_20230607182839.log.gz:20230607-18:27:29 NEPHRONIX - 03f51467-faaf-9762-b580-c590b4b9e085 - Connection state change detected! Diff:
nephronix_20230607182839.log.gz:20230607-18:27:36 NEPHRONIX - 845ed726-b368-7a20-7f1b-370db937f4e6 - Connection state change detected! Diff:
nephronix_20230607182839.log.gz:20230607-18:28:12 NEPHRONIX - 6e8581a5-1a9d-1951-f5a2-cd01016522df - Connection state change detected! Diff:
nephronix_20230607182839.log.gz:20230607-18:28:15 NEPHRONIX - ab2f12a8-8f47-5d8e-3514-676717689c8e - Connection state change detected! Diff:
nephronix_20230607183106.log.gz:20230607-18:30:35 NEPHRONIX - 9bfb4ffe-c658-35bb-453f-a226268ee742 - Connection state change detected! Diff:
nephronix_20230607183106.log.gz:20230607-18:30:53 NEPHRONIX - c601a71c-177d-498c-49e8-c95d0084cdd3 - Connection state change detected! Diff:
nephronix_20230607183106.log.gz:20230607-18:31:04 NEPHRONIX - ae29ed91-82fa-3fd7-ff64-a547eb48a05c - Connection state change detected! Diff:
$ nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - Connection state change detected! Diff:
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - Connection state change detected! Diff:
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 1,8c1,8
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < udp   ESTAB     0      0      192.168.86.64%ens33:68      192.168.86.1:67   users:(("NetworkManager",pid=935,fd=25))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:44990  192.168.86.65:22   users:(("ssh",pid=2175,fd=3))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:44002   34.117.65.55:443  users:(("firefox",pid=2227,fd=162))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:57386  192.168.86.65:22   users:(("ssh",pid=2768,fd=3))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:60890  140.82.113.21:443  users:(("firefox",pid=2227,fd=94))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:47198  140.82.114.26:443  users:(("firefox",pid=2227,fd=82))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:37236 192.30.255.117:443  users:(("firefox",pid=2227,fd=102))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < tcp   ESTAB     0      0            192.168.86.64:52886 192.30.255.113:443  users:(("firefox",pid=2227,fd=84))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > udp   ESTAB  0      0      192.168.86.64%ens33:68      192.168.86.1:67   users:(("NetworkManager",pid=935,fd=25))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:44990  192.168.86.65:22   users:(("ssh",pid=2175,fd=3))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:44002   34.117.65.55:443  users:(("firefox",pid=2227,fd=162))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:57386  192.168.86.65:22   users:(("ssh",pid=2768,fd=3))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:60890  140.82.113.21:443  users:(("firefox",pid=2227,fd=94))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:47198  140.82.114.26:443  users:(("firefox",pid=2227,fd=82))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:37236 192.30.255.117:443  users:(("firefox",pid=2227,fd=102))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > tcp   ESTAB  0      0            192.168.86.64:52886 192.30.255.113:443  users:(("firefox",pid=2227,fd=84))
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - Self PID: 2999
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - Change in running processes detected! Diff:
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 180c180
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < adminw+   1530  1.3  8.7 2070680 336032 ?      Ssl  17:47   0:30 /usr/bin/plasmashell --no-respawn
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > adminw+   1530  1.3  8.7 2070680 336032 ?      Ssl  17:47   0:31 /usr/bin/plasmashell --no-respawn
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 213c213
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < adminw+   2227  4.6 11.5 3151980 442604 ?      Sl   18:00   1:05 /usr/lib64/firefox/firefox
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > adminw+   2227  4.5 11.5 3151964 442436 ?      Sl   18:00   1:06 /usr/lib64/firefox/firefox
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 219c219
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < adminw+   2478  2.0  6.2 2657052 237664 ?      Rl   18:00   0:29 /usr/lib64/firefox/firefox -contentproc -childID 4 -isForBrowser -prefsLen 29501 -prefMapSize 234602 -jsInitLen 238780 -parentBuildID 20230522134052 -appDir /usr/lib64/firefox/browser {a7fd4825-dc76-41e0-a4b6-f48cf5d31092} 2227 true tab
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > adminw+   2478  2.0  5.8 2648860 225212 ?      Rl   18:00   0:29 /usr/lib64/firefox/firefox -contentproc -childID 4 -isForBrowser -prefsLen 29501 -prefMapSize 234602 -jsInitLen 238780 -parentBuildID 20230522134052 -appDir /usr/lib64/firefox/browser {a7fd4825-dc76-41e0-a4b6-f48cf5d31092} 2227 true tab
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 227c227
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < root       2818  0.0  0.0      0     0 ?        I    18:15   0:00 [kworker/3:1-events]
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > root       2818  0.0  0.0      0     0 ?        R    18:15   0:00 [kworker/3:1-events]
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - 239,241c239,241
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < root      16440  0.0  0.0   7488  1852 ?        S    18:24   0:00 bash /usr/local/bin/nephronix
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < root      16441  0.0  0.0   7356  1852 ?        S    18:24   0:00 bash /usr/local/bin/nephronix
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - < root      16447  0.0  0.0  10080  3456 ?        R    18:24   0:00 ps auxwww
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - ---
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > root      16942  0.0  0.0   7356  1852 ?        R    18:24   0:00 bash /usr/local/bin/nephronix
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > root      16943  0.0  0.0   7356  1852 ?        S    18:24   0:00 bash /usr/local/bin/nephronix
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - > root      16949  0.0  0.0  10080  3456 ?        R    18:24   0:00 ps auxwww
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - No changes in logged in users.
nephronix_20230607182509.log.gz:20230607-18:24:28 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - No changes in kernel modules or BPF/eBPF detected.
nephronix_20230607182509.log.gz:20230607-18:24:29 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - No changes to /boot detected.
nephronix_20230607182509.log.gz:20230607-18:24:29 NEPHRONIX - a5497a72-d5a0-e9a3-5d55-ac8eff53983d - No changes to installed detected.
```

The log lines have a timestamp as well as a UUIDv4. The UUID is set per round of checks.

Note that when nephronix is first run (when it has no historic .dat files in /opt/nephronix/workspace/ to reference) the first round of checks will always be marked as a possible detection event because
it will be comparing against NULL (empty) data. After the first round, rounds are every 2 seconds by default, then the detections are only on
differences in instrumentation output. We can expect that `ps auxwww` output used for process checking will always have a change, so there
will always be a process change detection event. Those events are still useful, but also continuous as kernel processes and nephronix itself,
as well as other system process, will trigger a diff.

The .dat files in /opt/nephronix/workspace/ are the current and previous round data output. This data can be analyzed directly in addition to the logs.
Within we'll find the BLAKE2 hashes of all files in /boot, all the running processes, network connections, system users, and messages from the kernel buffer
container either "module" or "bpf" (not case sensitive). The kernel buffer check filter (grep) could be lifted to hunt for any kernel message buffer changes,
or the grep filter could be adjusted such as to include additional matches. The kernel message buffer checks are among the most useful aspects
of nephronix, as many other security systems do not have features to check for newly loaded eBPF maps and kernel modules. It is also possible that the kernel is compiled to not log these events, in which case this check would not yield events. But by default (and best practice) we'll log such events as they are
important security events for the system.

Nephronix may be best suited as a redundant checking system, while the primary checking is done by a separate (EDR, HIDS, etc) software. However,
nephronix can be used as the primary if needed. If so, customization may be desired. The alerter function might updated to ship to syslog
such as by ussing `logger` instead of `wall` and perhaps text or email notifications. 

Remember, a security system is useful if people are engaged in responding, analyzing, and reviewing the data!

#### nephronix_light

Another version of nephronix in the file `nephronix_light` is included, which can be copied over `/usr/local/bin/nephronix` which does not do process checks or network connection checks. This eliminates the two noisiest event types so events are more meaningful and the data files in the log and archive are smaller. 
While this does mean that the light version misses out on auditing both of those areas, this is an example of tuning for a given situation, focusing on higher severity events only.

#### Adding reactive functions

Nephronix can of course be expanded to include reactive functionality instead of just alerting or logging. An example might be to revert changes or even power off or reboot the system. If drastic reactions are added, ensure that maintenance playbooks take in to account those settings!

#### Why is it called "nephronix"?

A nephron is a structure in the mammalian kideny that filters blood. This program was inspired by the human kidney functionality, sifting through ~ 150 quarts of blood per day. Nephronix sifts through ~ 43,000 cycles of system information per day :)

