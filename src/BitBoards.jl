const FileABB = 0x0101010101010101::Bitboard
const FileBBB = bitboard(FileABB << 1)
const FileCBB = bitboard(FileABB << 2)
const FileDBB = bitboard(FileABB << 3)
const FileEBB = bitboard(FileABB << 4)
const FileFBB = bitboard(FileABB << 5)
const FileGBB = bitboard(FileABB << 6)
const FileHBB = bitboard(FileABB << 7)

const Rank1BB = bitboard(0xFF)
const Rank2BB = bitboard(Rank1BB << (8 * 1))
const Rank3BB = bitboard(Rank1BB << (8 * 2))
const Rank4BB = bitboard(Rank1BB << (8 * 3))
const Rank5BB = bitboard(Rank1BB << (8 * 4))
const Rank6BB = bitboard(Rank1BB << (8 * 5))
const Rank7BB = bitboard(Rank1BB << (8 * 6))
const Rank8BB = bitboard(Rank1BB << (8 * 7))

# println(bin(FileABB))
# println(bin(FileBBB))
# println(bin(FileCBB))
# println(bin(FileDBB))
# println(bin(FileEBB))
# println(bin(FileFBB))
# println(bin(FileGBB))
# println(bin(FileHBB))
# println()
# println(bin(Rank1BB))
# println(bin(Rank2BB))
# println(bin(Rank3BB))
# println(bin(Rank4BB))
# println(bin(Rank5BB))
# println(bin(Rank6BB))
# println(bin(Rank7BB))
# println(bin(Rank8BB))

# De Bruijn sequences. See chessprogramming.wikispaces.com/BitScan
const DeBruijn_64 = uint64(0x3F79D71B4CB0A89)
const DeBruijn_32 = uint32(0x783A9B23)


function file_distance(s1::Square, s2::Square)
    int32(abs(file_of(s1) - file_of(s2)))
end

function rank_distance(s1::Square, s2::Square)
    int32(abs(rank_of(s1) - rank_of(s2)))
end

function bsf_index(b::Bitboard)
    # Matt Taylor's folding for 32 bit systems, extended to 64 bits by Kim Walisch
    b $= (b - 1)
    return (Is64Bit == true) ? uint32((b * DeBruijn_64) >> 58) : uint32(((uint32(b) ^ uint32(b >> 32)) * DeBruijn_32) >> 26)
end

function init_magics(table::Array{Bitboard,1},
                     attacks::Array{Bitboard,2},
                     magics::Array{Bitboard,1},
                     masks::Array{Bitboard,1},
                     shifts::Array{Uint32,1},
                     deltas::Array{Square,1},
                     index::Function)
    # initialization of magics are coming here!


end

