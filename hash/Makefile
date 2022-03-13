
all: ha

src = $(wildcard ./*.c)  
obj = $(patsubst %.c, %.o, $(src))  
#obj = $(src:%.c=%.o)  

target = ha

ha: hash.o a.o
	gcc a.o hash.o -o ha

# for test
hash.o:
	gcc -c hash.c -o hash.o


a.o:
	gcc -c a.c -o a.o

.PHONY: clean
clean:
	rm -rf $(obj) $(target)
	clear
