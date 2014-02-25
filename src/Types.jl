function unlikely(x)
    (x)
end

const IS_64BIT = int64(1)
const CACHE_LINE_SIZE = int64(64)

const HasPopCnt = true
const Is64Bit = true

typealias Key Uint64

# for Chess pieces
typealias Bitboard Uint64

# for Shogi pieces
typealias SBitboard Uint128

const MAX_MOVES      = int32(256)
const MAX_PLY        = int32(120)
const MAX_PLY_PLUS_6 = int32(MAX_PLY + 6)

# A move needs 16 bits to be stored
#
# bit  0- 5: destination square (from 0 to 63)
# bit  6-11: origin square (from 0 to 63)
# bit 12-13: promotion piece type - 2 (from KNIGHT-2 to QUEEN-2)
# bit 14-15: special move flag: promotion (1), en passant (2), castling (3)
# NOTE: EN-PASSANT bit is set only when a pawn can be captured
#
# Special cases are MOVE_NONE and MOVE_NULL. We can sneak these in because in
# any normal move destination square is always different from origin square
# while MOVE_NONE and MOVE_NULL have the same origin and destination square.

typealias Move Uint16
const MOVE_NONE = uint16(0)
const MOVE_NULL = uint16(65)

typealias MoveType Uint16
const NORMAL    = uint16(0)
const PROMOTION = uint16(1 << 14)
const ENPASSANT = uint16(2 << 14)
const CASTLING  = uint16(3 << 14)

# following definition of (enums) may be changed to Uint32 or Uint64

typealias CastlingFlag Uint16 # Defined as in PolyGlot book hash key
const NO_CASTLING = uint16(0)
const WHITE_OO    = uint16(1)
const WHITE_OOO   = uint16(WHITE_OO << 1)
const BLACK_OO    = uint16(WHITE_OO << 2)
const BLACK_OOO   = uint16(WHITE_OO << 3)
const ANY_CASTLING = uint16(WHITE_OO | WHITE_OOO | BLACK_OO | BLACK_OOO)
const CASTLING_FLAG_NB = uint16(16)

typealias CastlingSide Uint16
const KING_SIDE        = uint16(0)
const QUEEN_SIDE       = uint16(1)
const CASTLING_SIDE_NB = uint16(2)

typealias Phase Uint16
const PHASE_ENDGAME = uint16(0)
const PHASE_MIDGAME = uint16(128)
const MG            = uint16(0)
const EG            = uint16(1)
const PHASE_NB      = uint16(2)

typealias ScaleFactor Uint16
const SCALE_FACTOR_DRAW    = uint16(0)
const SCALE_FACTOR_ONEPAWN = uint16(48)
const SCALE_FACTOR_NORMAL  = uint16(64)
const SCALE_FACTOR_MAX     = uint16(128)
const SCALE_FACTOR_NONE    = uint16(255)

typealias Bound Uint16
const BOUND_NONE  = uint16(0)
const BOUND_UPPER = uint16(1)
const BOUND_LOWER = uint16(2)
const BOUND_EXACT = uint16(BOUND_UPPER | BOUND_LOWER)

typealias Value Int32
const VALUE_ZERO      = int32(0)
const VALUE_DRAW      = int32(0)
const VALUE_KNOWN_WIN = int32(10000)
const VALUE_MATE      = int32(30000)
const VALUE_INFINITE  = int32(30001)
const VALUE_NONE      = int32(30002)

const VALUE_MATE_IN_MAX_PLY  = int32(VALUE_MATE - MAX_PLY)
const VALUE_MATED_IN_MAX_PLY = int32(-VALUE_MATE + MAX_PLY)

const VALUE_ENSURE_INTEGER_SIZE_P = typemax(Int32)
const VALUE_ENSURE_INTEGER_SIZE_N = typemin(Int32)

const PawnValueMg   = int32(198)
const KnightValueMg = int32(817)
const BishopValueMg = int32(836)
const RookValueMg   = int32(1270)
const QueenValueMg  = int32(2521)

const PawnValueEg   = int32(258)
const KnightValueEg = int32(846)
const BishopValueEg = int32(857)
const RookValueEg   = int32(1278)
const QueenValueEg  = int32(2558) 

typealias PieceType Uint16
const NO_PIECE_TYPE = uint16(0)
const PAWN          = uint16(1)
const KNIGHT        = uint16(2)
const BISHOP        = uint16(3)
const ROOK          = uint16(4)
const QUEEN         = uint16(5)
const KING          = uint16(6)
const ALL_PIECES    = uint16(0)
const PIECE_TYPE_NB = uint16(8)

typealias Piece Uint16
const NO_PIECE  = uint16(0)
const W_PAWN    = uint16(1)
const W_KNIGHT  = uint16(2)
const W_BISHOP  = uint16(3)
const W_ROOK    = uint16(4)
const W_QUEEN   = uint16(5)
const W_KING    = uint16(6)

const B_PAWN    = uint16(9)
const B_KNIGHT  = uint16(10)
const B_BISHOP  = uint16(11)
const B_ROOK    = uint16(12)
const B_QUEEN   = uint16(13)
const B_KING    = uint16(14)
const PIECE_NB  = uint16(16)

typealias Color Uint16
const WHITE    = uint16(0)
const BLACK    = uint16(1)
const NO_COLOR = uint16(2)
const COLOR_NB = uint16(2)










