TARGET = DylibToolkit
SDK = iphoneos
CC = xcrun --sdk $(SDK) clang
CFLAGS = -fobjc-arc -O2 -Wall -Wextra -miphoneos-version-min=13.0
LDFLAGS = -dynamiclib -framework Foundation -framework UIKit -framework CoreFoundation
SRC = src/main.m

all: $(TARGET).dylib

$(TARGET).dylib:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC)
	codesign --force --sign - --timestamp=none $@

clean:
	rm -f $(TARGET).dylib
