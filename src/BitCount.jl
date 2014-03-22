function popcount{T}(bb::T)
    count_ones(bb)
end

function popcount_sw(b::Bitboard)
    b -=  (b >> 1) & uint64(0x5555555555555555)
    b  = ((b >> 2) & uint64(0x3333333333333333)) + (b & uint64(0x3333333333333333))
    b  = ((b >> 4) + b) & uint64(0x0F0F0F0F0F0F0F0F)
    (b * uint64(0x0101010101010101)) >> 56
end

# function popcount_hw(b::Bitboard)
#     ccall( (:popcount, "pc"), Int64, (Int64,),b)
# end

# tic()
# for i = 1:100000000
#     x = popcount(rand(Uint64))
# end
# toc()

# tic()
# for i = 1:100000000
#     x = popcount_sw(rand(Uint64))
# end
# toc()

# tic()
# for i = 1:100000000
#     x = popcount_hw(rand(Uint64))
# end
# toc()
