# /// RKISS is our pseudo random number generator (PRNG) used to compute hash keys.
# /// George Marsaglia invented the RNG-Kiss-family in the early 90's. This is a
# /// specific version that Heinz van Saanen derived from some public domain code
# /// by Bob Jenkins. Following the feature list, as tested by Heinz.
# ///
# /// - Quite platform independent
# /// - Passes ALL dieharder tests! Here *nix sys-rand() e.g. fails miserably:-)
# /// - ~12 times faster than my *nix sys-rand()
# /// - ~4 times faster than SSE2-version of Mersenne twister
# /// - Average cycle length: ~2^126
# /// - 64 bit seed
# /// - Return doubles with a full 53 bit mantissa
# /// - Thread safe

type RKISS
    a::Uint64
    b::Uint64
    c::Uint64
    d::Uint64
    function RKISS(seed::Int32 = int32(73))
        ins = new(uint64(0xF1EA5EED), uint64(0xD4E12C77), uint64(0xD4E12C77), uint64(0xD4E12C77))
        for i=1:seed
            dummy = rand64(ins)
        end
        return ins
    end
end

function rotate_L(x::Uint64, k::Uint32)
    uint64((x << k) | (x >> (64 - k)))
end

function rotate_L(x::Uint128, k::Uint32)
    uint128((x << k) | (x >> (81 - k))) & MaskOfBoard
end

function rand64(r::RKISS)
    e = r.a - rotate_L(r.b, uint32(7))
    r.a = r.b $ rotate_L(r.c, uint32(13))
    r.b = r.c + rotate_L(r.d, uint32(37))
    r.c = r.d + e
    r.d = e + r.a

    r.d
end

function randkiss(T::Type,r::RKISS)
    oftype(T,rand64(r))
end

function rand81()
    rand(Uint128) & rand(Uint128) & rand(Uint128) & MaskOfBoard
end


# /// Special generator used to fast init magic numbers. Here the
# /// trick is to rotate the randoms of a given quantity 's' known
# /// to be optimal to quickly find a good magic candidate.
function magic_rand(T::Type, r::RKISS, s::Int32)
    rotate_L(rotate_L(randkiss(T,r), uint32(uint32(s >>> 0) & uint32(0x3F))) & randkiss(T,r)
             , uint32(uint32(s >>> 6) & uint32(0x3F) & randkiss(T,r)))
end

# system RNG version of magic_rand
function magic_rand(T::Type, s::Int32)
    rotate_L(rotate_L(rand81(), uint32(((s >> 0) & uint32(0x3F)) & rand81()))
             , uint32((s >> 6) & uint32(0x3F) & rand81()))
end

#r = RKISS()
#println(hex(rand64(r)))
#println(hex(randkiss(Uint32,r)))
#println(bits(magic_rand(Uint64,int32(12456789))))

# following code is proved that Julia's system RNG is faster than 
# porting of RKiss above
# so I decided to use system RNG :)

# tic()
# for i = 1:100000000
#     x = rand(Uint64)
# end
# toc()

# tic()
# for i = 1:100000000
#     x = rand64(r)
# end
# toc()

# elapsed time: 0.714120117 seconds in my mac (system RNG)
# elapsed time: 3.457055139 seconds in my mac (RKISS)

#rn = rand81()
#println("before:",bin(rn))
#println("after:",bin(rotate_L(rn,uint32(25))))
