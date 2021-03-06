VENDOR      = intel
OPTIMIZE    = yes
DEBUG       = no
DEVICE      = gpu



# Standard flags
CFLAGS := -std=c++11 -Wall

# Linker flags
LDFLAGS = -lm

# Codeplay Compiler
ifneq (,$(findstring codeplay,$(VENDOR)))
  CC = compute++
  CFLAGS += -no-serial-memop -sycl -sycl-driver
  LDFLAGS += -lComputeCpp
endif

# Intel DPC++ Compiler
ifneq (,$(findstring intel,$(VENDOR)))
  CC = dpcpp
  CFLAGS += 
  LDFLAGS += 
endif

# Debug Flags
ifeq ($(DEBUG),yes)
  CFLAGS += -g -DDEBUG
endif

# Optimization Flags
ifeq ($(OPTIMIZE),yes)
  CFLAGS += -O3
endif

ifeq ($(DEVICE),gpu)
  CFLAGS +=-DUSE_GPU
endif


b+tree.out:	./main.o \
		./kernel/kernel_wrapper.o \
		./kernel/kernel2_wrapper.o \
		./util/timer/timer.o \
		./util/num/num.o 
	$(CC)	./main.o \
			./kernel/kernel_wrapper.o \
			./kernel/kernel2_wrapper.o \
			./util/timer/timer.o \
			./util/num/num.o \
			$(LDFLAGS) \
	                -o b+tree.out


main.o:	./common.h \
	./main.c
	$(CC) $(CFLAGS) $(KERNEL_DIM) ./main.c \
		-c \
		-o ./main.o


./kernel/kernel_wrapper.o:	./common.h \
	./kernel/kernel_wrapper.h \
	./kernel/kernel_wrapper.c \
	./kernel/findK.sycl
	$(CC) $(CFLAGS)	$(KERNEL_DIM) ./kernel/kernel_wrapper.c \
		-c \
		-o ./kernel/kernel_wrapper.o

./kernel/kernel2_wrapper.o:	./common.h \
	./kernel/kernel2_wrapper.h \
	./kernel/kernel2_wrapper.c \
	./kernel/findRangeK.sycl
	$(CC) $(CFLAGS)	$(KERNEL_DIM) ./kernel/kernel2_wrapper.c \
		-c \
		-o ./kernel/kernel2_wrapper.o 


./util/timer/timer.o:	./common.h \
	./util/timer/timer.h \
	./util/timer/timer.c
	$(CC)	./util/timer/timer.c \
		-c \
		-o ./util/timer/timer.o \
		-O3

./util/num/num.o:	./common.h \
	./util/num/num.h \
	./util/num/num.c
	$(CC)	./util/num/num.c \
		-c \
		-o ./util/num/num.o \
		-O3

run: b+tree.out
	./b+tree.out file ../data/b+tree/mil.txt command ../data/b+tree/command.txt

clean:
	rm -f	*.o *.out \
		./kernel/*.o \
		./util/timer/*.o \
		./util/num/*.o \
		output.txt
