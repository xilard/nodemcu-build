FROM ubuntu
MAINTAINER xilard

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y --fix-missing wget unzip git make python-serial srecord bc xz-utils gcc libncurses5-dev aptitude bison gperf python-pip && \
	aptitude -y install flex && \
	pip install --user --upgrade pip pyserial future cryptography "pyparsing>=2.0.3,<2.4.0" click pyelftools
	
RUN mkdir /opt/nodemcu-firmware

WORKDIR /opt/nodemcu-firmware

CMD \
	BUILD_DATE="$(date +%Y%m%d-%H%M%S)" && \
	IMAGE_NAME=nodemcu_firmware_${BUILD_DATE} && \
	if [ -z "$ESP32" ]; then \
		(if [ ! -d ../esp-open-sdk ]; then \
			if [ -f ./tools/esp-open-sdk.tar.xz ]; then \
				tar -Jxvf ./tools/esp-open-sdk.tar.xz -C ../; \
			else \
				tar -zxvf ./tools/esp-open-sdk.tar.gz -C ../; \
			fi \
		fi && \
		export PATH=$PATH:$PWD/../esp-open-sdk/sdk:$PWD/../esp-open-sdk/xtensa-lx106-elf/bin && \
		if [ -z "$BL_BIN" ]; then \
			BL_BIN=0x00000.bin; \
		fi && \
		if [ -z "$FW_OFFSET" ]; then \
			FW_OFFSET=0x10000; \
		fi && \
		if [ -z "$FW_BIN" ]; then \
			FW_BIN=0x10000.bin; \
		fi && \
		if [ ! -z "$REBUILD" ]; then \
			make clean; \
		fi && \
		if [ -z "$FLOAT" ]; then \
			make EXTRA_CCFLAGS="-DLUA_NUMBER_INTEGRAL" all; \
		else \
			make all; \
		fi && \
		cd bin && \
		srec_cat -output "${IMAGE_NAME}".bin -binary "$BL_BIN" -binary -fill 0xff 0x00000 "${FW_OFFSET}" "${FW_BIN}" -binary -offset "${FW_OFFSET}" && \
		cp -f "${IMAGE_NAME}".bin nodemcu_firmware_latest.bin && \
		cp ../app/mapfile "${IMAGE_NAME}".map && \
		cd ..); \
	else \
		(if [ -z "$PARTITIONS_OFFSET" ]; then \
			PARTITIONS_OFFSET=0x8000; \
		fi && \
		if [ -z "$PARTITIONS_BIN" ]; then \
			PARTITIONS_BIN=build/partitions_singleapp.bin; \
		fi && \
		if [ -z "$FW_BIN" ]; then \
			FW_BIN=build/NodeMCU.bin.bin; \
		fi && \
		if [ -z "$FW_OFFSET" ]; then \
			FW_OFFSET=0x10000; \
		fi && \
		if [ ! -z "$REBUILD" ]; then \
			make clean; \
		fi && \
		make all && \
		mkdir -p bin && \
		if [ -z "$PHY_INIT_OFFSET" ]; then \
			srec_cat -output bin/"${IMAGE_NAME}".bin -binary build/bootloader/bootloader.bin -binary -offset 0x01000 -fill 0xff 0x00000 "${PARTITIONS_OFFSET}" "${PARTITIONS_BIN}" -binary -offset "${PARTITIONS_OFFSET}" -fill 0xff "${PARTITIONS_OFFSET}" "${FW_OFFSET}" build/NodeMCU.bin -binary -offset "${FW_OFFSET}"; \
		else \
			srec_cat -output bin/"${IMAGE_NAME}".bin -binary build/bootloader/bootloader.bin -binary -offset 0x01000 -fill 0xff 0x00000 "${PARTITIONS_OFFSET}" "${PARTITIONS_BIN}" -binary -offset "${PARTITIONS_OFFSET}" -fill 0xff "${PARTITIONS_OFFSET}" "${PHY_INIT_OFFSET}" build/phy_init_data.bin -binary -offset ${PHY_INIT_OFFSET} -fill 0xff "${PHY_INIT_OFFSET}" "${FW_OFFSET}" build/NodeMCU.bin -binary -offset "${FW_OFFSET}"; \
		fi && \
		cp -f bin/"${IMAGE_NAME}".bin bin/nodemcu_firmware_latest.bin && \
		cp build/NodeMCU.map bin/"${IMAGE_NAME}".map); \
	fi
