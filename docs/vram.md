# VRAM

VRAM consists of a 320x240 pixel framebuffer where each pixel is 1 byte
(RRRGGGBB format).

Internally, the framebuffer handles requests in blocks of 64 bits (or 8 bytes).
This also makes up the width of a cache line.

## Caching

Each core has a private L1 cache which is read only. Read requests from a core
will either return data directly from L1, or cause L1 to request data from L2
before storing it and returning it. Write requests from a core will pass through
to L2 which will invalidate the cache line inside of each L1.

### L1 Cache

As mentioned, cache lines are 64 bits (8 bytes) wide. The L1 caches contain 64
cache lines for a total of 512 bytes per cache. The L1 cache is implemented as a
direct-mapped cache. This means that memory requests are of the following
format:

```
   tag (8)    index (6)   offset (3)
   xxxxxxxx    xxxxxx        xxx
MSB                             LSB
```

Here, the `offset` field indexes the byte inside of the cache line, the `index`
field indexes the cache line inside the L1 cache, and the `tag` field is used to
differentiate between indices.

For a read request, the L1 controller will index the tag storage using `index`
and compare the request tag with the stored tag. If the stored tag is marked
invalid or if it is different from the request tag, the L1 controller will issue
a refill request to L2 using the address from the outstanding read request. This
request to L2 will include the `tag` and `index` (but not the `offset`). When
the request returns from L2, L1 will store the tag in the corresponding index of
the tag memory and overwrite the old cache line stored at `index`. It will, of
course, mark this cache line valid.

For a write request, the L1 controller will again check if the requested line is
in L1. If not, it requests a refill and stores the cache line. To complete the
write, the L1 controller reads back the cache line, modifies it, writes it back
to L1, and requests a write to L2. L2 may not send an invalidation to the
writer, as this results in thrashing.

### L2 Cache

The L2 cache is shared between all the cores. In this implementation, the L2 is
not included. Instead, memory is arbitrated between L1 and VRAM. The memory
arbiter follows a simple round robin scheme. The arbiter will search through the
list of active requests. When one is found, it is "granted". The arbiter keeps
track of the last core to which a request was granted. On the next grant cycle,
the arbiter searches for active requests starting at the core after the previous
grant (`(last_grant + 1) % N_CORES`) and wraps around until an active request is
found.
