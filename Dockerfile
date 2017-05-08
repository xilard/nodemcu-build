FROM ubuntu
MAINTAINER xilard

RUN apt-get update && apt-get install -y wget unzip git make python-serial srecord bc xz-utils gcc
RUN mkdir /opt/nodemcu-firmware
WORKDIR /opt/nodemcu-firmware

CMD BUILD_DATE="$(date +%Y%m%d-%H%M)" && \
    IMAGE_NAME=nodemcu_firmware_${BUILD_DATE} && \
	if [ ! -d ../esp-open-sdk ]; then \
		if [ -f tools/esp-open-sdk.tar.xz ]; then \
			tar -Jxvf esp-open-sdk.tar.xz -C ../; \
		else \
			tar -zxvf esp-open-sdk.tar.gz -C ../; \
		fi \
	fi && \
    export PATH=$PATH:$PWD/../esp-open-sdk/sdk:$PWD/../esp-open-sdk/xtensa-lx106-elf/bin  && \
    if [ -z "$FLOAT" ]; then \
		make EXTRA_CCFLAGS="-DLUA_NUMBER_INTEGRAL" clean all; \
	else \
		make clean all; \
	fi && \
	cd bin  && \
	srec_cat -output "${IMAGE_NAME}".bin -binary 0x00000.bin -binary -fill 0xff 0x00000 0x2000 0x02000.bin -binary -offset 0x2000 && \
	cp ../app/mapfile "${IMAGE_NAME}".map && \
	cd ..
