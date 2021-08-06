#include "bp_zynq_pl.h"

extern "C" int bsg_dpi_next();

void bp_zynq_pl::eval() {
    svScope prev;
    prev = svSetScope(top);
    bsg_dpi_next();
    svSetScope(prev);
}
