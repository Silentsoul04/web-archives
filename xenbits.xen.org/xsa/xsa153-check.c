/*
 * Program to test whether a domain is potentially vulnerable to
 * XSA-153.
 *
 * Build and run:
 *   gcc -Wall xsa153-check.c -lxenctrl
 *   ./a.out `xl domid NAME-OF-YOUR-GUEST-DOMAIN`
 *
 * For building against a built Xen source tree, rather than installed
 * headers and libraries:
 *   gcc -Wall -I ../xen.git/dist/install/usr/include/ xsa153-check.c -L ../xen.git/dist/install/usr/lib/ -lxenctrl
 *
 * Xen 4.0 and earlier lack xc_domain_get_pod_target, so this utility
 * can only be built against Xen 4.1 and later.
 *
 * IMPORTANT: Read the notes in advisory-153.txt to understand meaning
 * of the output!
 */

#include <xenctrl.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef XENCTRL_HAS_XC_INTERFACE
static xc_interface *xch;
#define BAD_XCH (xch == NULL)
#define OPENXCH xc_interface_open(0,0,0)
#else
static int xch;
#define BAD_XCH (xch <= 0)
#define OPENXCH xc_interface_open()
#endif

int main(int argc, const char **argv) {
    int domid, estatus, r;
    uint64_t tot_pages, pod_cache_pages, pod_entries;

    if (argc!=2 || !(domid = atoi(argv[1]))) {
        fputs("bad usage\n",stderr);
        exit(-1);
    }

    xch = OPENXCH;
    if (BAD_XCH) {
        perror("xc_interface_open");
        exit(-1);
    }

    r = xc_domain_get_pod_target(xch, domid,
                                 &tot_pages,
                                 &pod_cache_pages,
                                 &pod_entries);
    if (r) {
        perror("xc_domain_get_pod_target");
        exit(-1);
    }

    printf("checked domain %d for XSA-153: ", domid);
    if (pod_cache_pages < pod_entries) {
        uint64_t difference = pod_entries - pod_cache_pages;
        estatus = 1;
        printf("VULNERABLE (%lu more outstanding pages)\n",
               (unsigned long)difference);
        if (difference <= 256) {
            printf("try using   xl mem-set   to reduce its memory by 1 (Mby)\n"
                   "or perhaps reduce /local/domain/%d/memory/target by %lu",
               domid,
               (unsigned long)difference * 4);
        } else {
            printf("difference is >1Mby\n"
                   "ballon driver not running or guest still booting?");
        }
    } else if (pod_cache_pages > pod_entries) {
        estatus = 2;
        printf("SHOULD NOT HAPPEN!!! cache=%lu > outstanding=%lu",
               (unsigned long)pod_cache_pages, (unsigned long)pod_entries);
    } else if (!pod_cache_pages) {
        estatus = 0;
        printf("NOT vulnerable (not using PoD (any more))");
    } else {
        estatus = 0;
        printf("NOT vulnerable");
    }
    printf("\n");

    if (ferror(stdout) || fclose(stdout)) {
        perror("stdout");
        exit(-1);
    }
    exit(estatus);
}
