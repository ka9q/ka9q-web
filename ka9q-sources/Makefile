OBJS = misc.o multicast.o rtp.o status.o decode_status.o


all: libka9q.a

clean:
	rm -f libka9q.a $(OBJS)

libka9q.a: $(OBJS)
	ar rv $@ $^
	ranlib $@

