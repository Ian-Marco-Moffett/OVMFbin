CFLAGS = -Ignu-efi/inc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args
LDFLAGS = -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o
CFILES = $(shell find src/ -name "*.c")
KERNEL_FILE = base/kernel.sys
OUTPUT_IMG = Divine.img

.PHONY: cleanup
cleanup: mkefi
	rm *.o
	rm *.so

.PHONY: mkefi
mkefi: link
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 main.so BOOTX64.EFI
	dd if=/dev/zero of=$(OUTPUT_IMG) bs=512 count=93750
	mformat -i $(OUTPUT_IMG)
	mmd -i $(OUTPUT_IMG) ::/EFI
	mmd -i $(OUTPUT_IMG) ::/EFI/BOOT
	mcopy -i $(OUTPUT_IMG) BOOTX64.EFI ::/EFI/BOOT
	mcopy -i $(OUTPUT_IMG) base/startup.nsh ::
	mcopy -i $(OUTPUT_IMG) base/font.psf ::
	rm *.EFI

.PHONY: link
link: buildc
	ld *.o $(LDFLAGS) -lgnuefi -lefi -o main.so

.PHONY: buildc
buildc: $(CFILES)
	@ git submodule init
	@ git submodule update
	cd gnu-efi; make
	gcc $(CFLAGS) -c $^

.PHONY: run
run:
	@ git submodule init
	@ git submodule update
	qemu-system-x86_64 -drive file=$(OUTPUT_IMG) -m 512M -cpu qemu64 -drive if=pflash,format=raw,unit=0,file="OVMFbin/OVMF_CODE-pure-efi.fd",readonly=on -drive if=pflash,format=raw,unit=1,file="OVMFbin/OVMF_VARS-pure-efi.fd" -net none -d int -no-reboot
