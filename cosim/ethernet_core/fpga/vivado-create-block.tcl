set project_name shell_bd_proj

create_project -force ${project_name} [pwd] -part xc7z020clg484-1
create_bd_design "shell_bd_1"
update_compile_order -fileset sources_1
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
open_bd_design ${project_name}.srcs/sources_1/bd/shell_bd_1/shell_bd_1.bd}
set_property  ip_repo_paths  fpga_build [current_project]
update_ip_catalog
startgroup
create_bd_cell -type ip -vlnv user.org:user:top:1.0 top_0
endgroup
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0
endgroup
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells smartconnect_0]
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins smartconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_0/M00_AXI] [get_bd_intf_pins top_0/s00_axi]
regenerate_bd_layout
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (50 MHz)" }  [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins top_0/s00_axi_aresetn] [get_bd_pins smartconnect_0/aresetn]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
endgroup
startgroup
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (50 MHz)" }  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
endgroup
connect_bd_net [get_bd_pins top_0/s00_axi_aclk] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins smartconnect_0/aresetn]
assign_bd_address

## ethernet_core
set_property -dict [list CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {250} CONFIG.PCW_EN_CLK1_PORT {1}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} CONFIG.PCW_EN_CLK2_PORT {1}] [get_bd_cells processing_system7_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins top_0/clk250_i]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins top_0/iodelay_ref_clk]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rx_clk_0_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rxd_0_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rx_ctl_0_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rx_clk_1_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rxd_1_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_rx_ctl_1_i]
make_bd_pins_external  [get_bd_pins top_0/rgmii_tx_clk_0_o]
make_bd_pins_external  [get_bd_pins top_0/rgmii_txd_0_o]
make_bd_pins_external  [get_bd_pins top_0/rgmii_tx_ctl_0_o]
make_bd_pins_external  [get_bd_pins top_0/rgmii_tx_clk_1_o]
make_bd_pins_external  [get_bd_pins top_0/rgmii_txd_1_o]
make_bd_pins_external  [get_bd_pins top_0/rgmii_tx_ctl_1_o]
set_property name rgmii_rx_clk_0_i [get_bd_ports rgmii_rx_clk_0_i_0]
set_property name rgmii_rxd_0_i [get_bd_ports rgmii_rxd_0_i_0]
set_property name rgmii_rx_ctl_0_i [get_bd_ports rgmii_rx_ctl_0_i_0]
set_property name rgmii_rx_clk_1_i [get_bd_ports rgmii_rx_clk_1_i_0]
set_property name rgmii_rxd_1_i [get_bd_ports rgmii_rxd_1_i_0]
set_property name rgmii_rx_ctl_1_i [get_bd_ports rgmii_rx_ctl_1_i_0]
set_property name rgmii_tx_clk_0_o [get_bd_ports rgmii_tx_clk_0_o_0]
set_property name rgmii_txd_0_o [get_bd_ports rgmii_txd_0_o_0]
set_property name rgmii_tx_ctl_0_o [get_bd_ports rgmii_tx_ctl_0_o_0]
set_property name rgmii_tx_clk_1_o [get_bd_ports rgmii_tx_clk_1_o_0]
set_property name rgmii_txd_1_o [get_bd_ports rgmii_txd_1_o_0]
set_property name rgmii_tx_ctl_1_o [get_bd_ports rgmii_tx_ctl_1_o_0]

create_bd_port -dir O -type rst eth0_resetn_o
create_bd_port -dir O -type rst eth1_resetn_o
connect_bd_net [get_bd_ports eth0_resetn_o] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net [get_bd_ports eth1_resetn_o] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

validate_bd_design
make_wrapper -files [get_files ${project_name}.srcs/sources_1/bd/shell_bd_1/shell_bd_1.bd] -top
add_files -norecurse ${project_name}.srcs/sources_1/bd/shell_bd_1/hdl/shell_bd_1_wrapper.v
delete_bd_objs [get_bd_nets reset_rtl_0_1] [get_bd_ports reset_rtl_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]

save_bd_design


add_files -fileset constrs_1 -norecurse {/mnt/users/ssd3/homes/ymchueh/bsg/zynq-parrot/cosim/import/eth_1g_test/syn/alex/ethernet.xdc /mnt/users/ssd3/homes/ymchueh/bsg/zynq-parrot/cosim/import/eth_1g_test/syn/alex/zedboard_master_XDC_RevC_D_v3.xdc}
import_files -fileset constrs_1 {/mnt/users/ssd3/homes/ymchueh/bsg/zynq-parrot/cosim/import/eth_1g_test/syn/alex/ethernet.xdc /mnt/users/ssd3/homes/ymchueh/bsg/zynq-parrot/cosim/import/eth_1g_test/syn/alex/zedboard_master_XDC_RevC_D_v3.xdc}

set_property used_in_synthesis false [get_files  /mnt/users/ssd3/homes/ymchueh/bsg/zynq-parrot/cosim/ethernet_core/fpga/shell_bd_proj.srcs/constrs_1/imports/alex/ethernet.xdc]
#launch_runs impl_1 -to_step write_bitstream -jobs 4
#wait_on_run impl_1
