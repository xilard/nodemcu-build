FROM ubuntu
MAINTAINER xilard

RUN apt-get update && apt-get install -y wget unzip git make python-serial srecord bc xz-utils gcc libncurses5-dev aptitude bison gperf && aptitude -y install flex
RUN mkdir /opt/nodemcu-firmware
WORKDIR /opt/nodemcu-firmware

CMD \
	BUILD_DATE="$(date +%Y%m%d-%H%M%S)" && \
	IMAGE_NAME=nodemcu_firmware_${BUILD_DATE} && \
	if [ -z "$ESP32"]; then \
		if [ ! -d ../esp-open-sdk ]; then \
			if [ -f ./tools/esp-open-sdk.tar.xz ]; then \
				tar -Jxvf ./tools/esp-open-sdk.tar.xz -C ../; \
			else \
				tar -zxvf ./tools/esp-open-sdk.tar.gz -C ../; \
			fi \
		fi && \
		export PATH=$PATH:$PWD/../esp-open-sdk/sdk:$PWD/../esp-open-sdk/xtensa-lx106-elf/bin && \
		if [ -z "$BL_BIN"]; then \
			BL_BIN=0x00000.bin; \
		fi && \
		if [ -z "$FW_OFFSET"]; then \
			FW_OFFSET=0x10000; \
		fi && \
		if [ -z "$FW_BIN"]; then \
			FW_BIN=0x10000.bin; \
		fi && \
		if [ -z "$FLOAT" ]; then \
			make EXTRA_CCFLAGS="-DLUA_NUMBER_INTEGRAL" clean all; \
		else \
			make clean all; \
		fi && \
		cd bin  && \
		srec_cat -output "${IMAGE_NAME}".bin -binary "$BL_BIN" -binary -fill 0xff 0x00000 "${FW_OFFSET}" "${FW_BIN}" -binary -offset "${FW_OFFSET}" && \
		cp ../app/mapfile "${IMAGE_NAME}".map && \
		cd ..); \
	else \
		(make clean all && \
		mkdir -p bin && \
		srec_cat -output bin/"${IMAGE_NAME}".bin -binary build/bootloader/bootloader.bin -binary -offset 0x01000 -fill 0xff 0x00000 0x08000 build/partitions_singleapp.bin -binary -offset 0x08000 -fill 0xff 0x08000 0x10000 build/NodeMCU.bin -binary -offset 0x10000 && \
		cp build/NodeMCU.map bin/"${IMAGE_NAME}".map); \
	fi
