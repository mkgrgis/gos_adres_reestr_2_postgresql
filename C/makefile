# Makefile
# Перегрузчик данных Государственного Адресного Реестра в БД PostgreSQL

# Compiler
CC = gcc

# Check distribution
#DISTRO := $(shell cat /etc/os-release | grep '^NAME' | cut -d '=' -f 2)

PGINC_DIR := $(shell pkg-config --cflags libpq)
XINC_DIR := $(shell pkg-config --cflags libxml-2.0)

PGLIB_DIR := $(shell pkg-config --libs libpq)
XLIB_DIR := $(shell pkg-config --libs libxml-2.0)

# Compiler flags
CFLAGS = -Wall -Wextra -pedantic $(XINC_DIR) $(PGINC_DIR)

# Source files
SRC = helper.c pg_in.c ГАР_XML2CSV.c

# Output executable
OUT = гар_xml2csv

# Default target
all: $(OUT)

# Build the executable
$(OUT): $(SRC)
	$(CC) $(CFLAGS) -o $(OUT) $(SRC) $(XLIB_DIR) $(PGLIB_DIR);
	mv $(OUT) ../$(OUT)

# Clean target to remove the executable
clean:
	rm -f ../$(OUT)

# Phony targets
.PHONY: all clean
