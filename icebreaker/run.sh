yosys -m ghdl -p "ghdl ../src/uart.vhd ../src/receiver.vhd ../src/unpacker.vhd ../src/top.vhd -e top; synth_ice40 -json top.json" && \
nextpnr-ice40 --up5k --package sg48 --json top.json --pcf icebreaker.pcf --asc top.asc && \
icepack top.asc top.bin
