LUVI_TAG=$(shell git describe --tags)
LUVI_VERSION:=$(shell git describe --tags --abbrev=0)
LUVI_ARCH=$(shell uname -s)-$(shell uname -m)
LUVI_PUBLISH_USER?=luvit
LUVI_PUBLISH_REPO?=luvi
LUVI_PREFIX?=/usr/local
LUVI_BINDIR?=$(LUVI_PREFIX)/bin

OS:=$(shell uname -s)

_PWD:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
override CMAKE_FLAGS+= -H. -Bbuild -DCMAKE_BUILD_TYPE=Release -D"CMAKE_C_FLAGS=-I$(_PWD)/src -U_FORTIFY_SOURCE -pthread -D_GNU_SOURCE" -DWithZLIB=ON -DWithSharedZLIB=OFF -DWithSqlite=ON -DWithSharedSqlite=OFF -DWithCjson=ON -DWithYaml=ON -DWithSharedYaml=OFF

ifdef GENERATOR
	CMAKE_FLAGS+= -G"${GENERATOR}"
endif

ifdef WITHOUT_AMALG
	CMAKE_FLAGS+= -DWITH_AMALG=OFF
endif

WITH_SHARED_LIBLUV ?= OFF

CMAKE_FLAGS += \
	-DWithSharedLibluv=$(WITH_SHARED_LIBLUV)

CPACK_FLAGS=-DWithPackageSH=ON -DWithPackageTGZ=ON -DWithPackageTBZ2=ON
ifdef CPACK_DEB
	CPACK_FLAGS=-DWithPackageDEB=ON
endif

ifdef CPACK_RPM
	CPACK_FLAGS=-DWithPackageRPM=ON
endif

ifdef CPACK_NSIS
	CPACK_FLAGS=-DWithPackageNSIS=ON
endif

ifdef CPACK_BUNDLE
	CPACK_FLAGS=-DWithPackageBUNDLE=ON
endif

ifndef NPROCS
ifeq ($(OS),Linux)
	NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
else ifeq ($(OS),Darwin)
	NPROCS:=$(shell sysctl hw.ncpu | awk '{print $$2}')
endif
endif

ifdef NPROCS
  EXTRA_OPTIONS:=-j${NPROCS}
endif

# This does the actual build and configures as default flavor is there is no build folder.
luvi: build
	cmake --build build -- ${EXTRA_OPTIONS}

build:
	@echo "Please run tiny' or 'regular' make target first to configure"

# Configure the build with minimal dependencies
tiny: deps/luv/CMakeLists.txt
	cmake $(CMAKE_FLAGS) $(CPACK_FLAGS)

# Configure the build with openssl statically included
regular: deps/luv/CMakeLists.txt
	cmake $(CMAKE_FLAGS) $(CPACK_FLAGS) -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF

regular-asm: deps/luv/CMakeLists.txt
	cmake $(CMAKE_FLAGS) $(CPACK_FLAGS) -DWithOpenSSL=ON -DWithSharedOpenSSL=OFF -DWithOpenSSLASM=ON -DWithPCRE=ON -DWithLPEG=ON -DWithSharedPCRE=OFF

package: deps/luv/CMakeLists.txt
	cmake --build build -- package

# In case the user forgot to pull in submodules, grab them.
deps/luv/CMakeLists.txt:
	git submodule update --init --recursive

clean:
	rm -rf build luvi-*

test: luvi
	rm -f test.bin
	build/luvi samples/test.app -- 1 2 3 4
	build/luvi samples/test.app -o test.bin
	./test.bin 1 2 3 4
	rm -f test.bin

install: luvi
	install -p build/luvi $(LUVI_BINDIR)/

uninstall:
	rm -f /usr/local/bin/luvi

reset:
	git submodule update --init --recursive && \
	git clean -f -d && \
	git checkout .

luvi-src.tar.gz:
	echo ${LUVI_TAG} > VERSION && \
	COPYFILE_DISABLE=true tar -czvf ../luvi-src.tar.gz \
	  --exclude 'luvi-src.tar.gz' --exclude '.git*' --exclude build . && \
	mv ../luvi-src.tar.gz . && \
	rm VERSION

linux-build: linux-build-box-regular linux-build-box32-regular linux-build-box-tiny linux-build-box32-tiny

alpine-build-box-regular:
	rm -rf build && mkdir -p build
	./alpine.sh bash -c 'cd /src && apk add --no-cache cmake make git gcc musl-dev binutils g++ && make GENERATOR=Ninja regular && make GENERATOR=Ninja'
	mv build/luvi luvi-regular-Linux_musl_x86_64

linux-build-box-regular: luvi-src.tar.gz
	rm -rf build && mkdir -p build
	cp packaging/holy-build.sh luvi-src.tar.gz build
	mkdir -p build
	docker run -t -i --rm \
		  -v `pwd`/build:/io phusion/holy-build-box-64:latest bash /io/holy-build.sh regular-asm
	mv build/luvi luvi-regular-Linux_x86_64

linux-build-box32-regular: luvi-src.tar.gz
	rm -rf build && mkdir -p build
	cp packaging/holy-build.sh luvi-src.tar.gz build
	docker run -t -i --rm \
		  -v `pwd`/build:/io phusion/holy-build-box-32:latest bash /io/holy-build.sh regular-asm
	mv build/luvi luvi-regular-Linux_i686

linux-build-box-tiny: luvi-src.tar.gz
	rm -rf build && mkdir -p build
	cp packaging/holy-build.sh luvi-src.tar.gz build
	mkdir -p build
	docker run -t -i --rm \
		  -v `pwd`/build:/io phusion/holy-build-box-64:latest bash /io/holy-build.sh tiny
	mv build/luvi luvi-tiny-Linux_x86_64

linux-build-box32-tiny: luvi-src.tar.gz
	rm -rf build && mkdir -p build
	cp packaging/holy-build.sh luvi-src.tar.gz build
	docker run -t -i --rm \
		  -v `pwd`/build:/io phusion/holy-build-box-32:latest bash /io/holy-build.sh tiny
	mv build/luvi luvi-tiny-Linux_i686

arm-build-box-regular:
	rm -rf build && mkdir -p build
	./arm.sh bash -c 'cd /src && make "CMAKE_FLAGS=-DCMAKE_TOOLCHAIN_FILE=$${CMAKE_TOOLCHAIN_FILE} " GENERATOR=Ninja regular && make "CMAKE_FLAGS=-DCMAKE_TOOLCHAIN_FILE=$${CMAKE_TOOLCHAIN_FILE}" GENERATOR=Ninja'
	mv build/luvi luvi-regular-Linux_armv7l

publish-src: reset luvi-src.tar.gz
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file luvi-src.tar.gz --name luvi-src-${LUVI_TAG}.tar.gz

publish-upstream:
	$(MAKE) clean publish-tiny
	$(MAKE) clean publish-regular

publish-linux: reset
	$(MAKE) linux-build && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file luvi-regular-Linux_i686 --name luvi-regular-Linux_i686 && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file luvi-regular-Linux_x86_64 --name luvi-regular-Linux_x86_64 && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file luvi-tiny-Linux_x86_64 --name luvi-tiny-Linux-x86_64 && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file luvi-tiny-Linux_i686 --name luvi-tiny-Linux-i686

publish-tiny: reset
	$(MAKE) tiny test && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file build/luvi --name luvi-tiny-${LUVI_ARCH}

publish-regular: reset
	$(MAKE) regular-asm test && \
	github-release upload --user ${LUVI_PUBLISH_USER} --repo ${LUVI_PUBLISH_REPO} --tag ${LUVI_TAG} \
	  --file build/luvi --name luvi-regular-${LUVI_ARCH}


LUVI_FNAME=luvi.$(or $(1),$(LUVI_ARCH))-$(LUVI_VERSION).gz
publish: reset
	$(MAKE) regular test && \
	gzip -c < build/luvi > "$(LUVI_FNAME)" && \
	aws --profile distelli-mvn-repo s3 cp "$(LUVI_FNAME)" "s3://distelli-mvn-repo/exe/$(LUVI_ARCH)/$(LUVI_FNAME)"

publish-distelli-linux: reset
	$(MAKE) alpine-build-box-regular linux-build-box-regular linux-build-box32-regular arm-build-box-regular
	gzip -c < luvi-regular-Linux_musl_x86_64 > "$(call LUVI_FNAME,Linux_musl-x86_64)"
	aws --profile distelli-mvn-repo s3 cp "$(call LUVI_FNAME,Linux_musl-x86_64)" "s3://distelli-mvn-repo/exe/Linux_musl-x86_64/$(call LUVI_FNAME,Linux_musl-x86_64)"
	gzip -c < luvi-regular-Linux_i686 > "$(call LUVI_FNAME,Linux-i686)"
	aws --profile distelli-mvn-repo s3 cp "$(call LUVI_FNAME,Linux-i686)" "s3://distelli-mvn-repo/exe/Linux-i686/$(call LUVI_FNAME,Linux-i686)"
	gzip -c < luvi-regular-Linux_x86_64 > "$(call LUVI_FNAME,Linux-x86_64)"
	aws --profile distelli-mvn-repo s3 cp "$(call LUVI_FNAME,Linux-x86_64)" "s3://distelli-mvn-repo/exe/Linux-x86_64/$(call LUVI_FNAME,Linux-x86_64)"
	gzip -c < luvi-regular-Linux_armv7l > "$(call LUVI_FNAME,Linux-armv7l)"
	aws --profile distelli-mvn-repo s3 cp "$(call LUVI_FNAME,Linux-armv7l)" "s3://distelli-mvn-repo/exe/Linux-armv7l/$(call LUVI_FNAME,Linux-armv7l)"


