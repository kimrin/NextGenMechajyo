function unlikely(x)
    (x)
end

const IS_64BIT = int64(1)
const CACHE_LINE_SIZE = int64(64)

const HasPopCnt = true
const Is64Bit = true

typealias Key Uint64
keyC = uint64

# for Chess pieces
typealias Bitboard Uint64
bitboard = uint64

# for Shogi pieces
typealias SBitboard Uint128
sbitboard = uint128

const MaskOfBoard = parseint(Uint128,"1ffffffffffffffffffff",16)::Uint128

const MAX_MOVES      = int32(700) # max shogi available moves = about 640moves!
const MAX_PLY        = int32(120)
const MAX_PLY_PLUS_6 = int32(MAX_PLY + 6)

include("ChessTypes.jl")
include("ShogiTypes.jl")
