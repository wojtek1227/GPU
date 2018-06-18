

vcom -reportprogress 300 -work work {D:/Semestr VIII/SDUP/test/GPU/gpu.vhd}
vcom -reportprogress 300 -work work {D:/Semestr VIII/SDUP/test/GPU/simulation/modelsim/tb_gpu.vhd}


vsim work.tb_gpu

view signals
view wave

add wave -noupdate /tb_gpu/uut/m_clock
add wave -noupdate /tb_gpu/uut/m_reset
add wave -noupdate /tb_gpu/uut/m_read
add wave -noupdate /tb_gpu/uut/m_write
add wave -noupdate -radix hex /tb_gpu/uut/m_address
add wave -noupdate /tb_gpu/uut/m_writedata
add wave -noupdate /tb_gpu/uut/m_readdata

add wave -noupdate /tb_gpu/uut/m_busy_flag
add wave -noupdate -radix dec /tb_gpu/uut/m_point_up_left
add wave -noupdate -radix dec /tb_gpu/uut/m_point_up_right
add wave -noupdate -radix dec /tb_gpu/uut/m_point_down_right
add wave -noupdate -radix dec /tb_gpu/uut/m_curr_point
add wave -noupdate /tb_gpu/uut/m_data_ready
add wave -noupdate /tb_gpu/uut/m_data_prepared

add wave -noupdate /tb_gpu/uut/m_curr_state

add wave -noupdate /tb_gpu/uut/slv_clock
add wave -noupdate /tb_gpu/uut/slv_resetn
add wave -noupdate /tb_gpu/uut/slv_read
add wave -noupdate /tb_gpu/uut/slv_write
add wave -noupdate /tb_gpu/uut/slv_address
add wave -noupdate -radix hex /tb_gpu/uut/slv_writedata
add wave -noupdate /tb_gpu/uut/slv_byteenable
add wave -noupdate /tb_gpu/uut/slv_readdata

add wave -noupdate -radix hex /tb_gpu/uut/slv_point_up_left
add wave -noupdate -radix hex /tb_gpu/uut/slv_point_down_right
add wave -noupdate -radix hex /tb_gpu/uut/slv_flag_register

run -all