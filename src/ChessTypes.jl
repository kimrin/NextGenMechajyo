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
move = uint16

const MOVE_NONE = uint16(0)
const MOVE_NULL = uint16(65)

typealias MoveType Uint16
moveType = uint16

const NORMAL    = uint16(0)
const PROMOTION = uint16(1 << 14)
const ENPASSANT = uint16(2 << 14)
const CASTLING  = uint16(3 << 14)

# following definition of (enums) may be changed to Uint32 or Uint64

typealias CastlingFlag Uint16 # Defined as in PolyGlot book hash key
castlingFlag = uint16

const NO_CASTLING = uint16(0)
const WHITE_OO    = uint16(1)
const WHITE_OOO   = uint16(WHITE_OO << 1)
const BLACK_OO    = uint16(WHITE_OO << 2)
const BLACK_OOO   = uint16(WHITE_OO << 3)
const ANY_CASTLING = uint16(WHITE_OO | WHITE_OOO | BLACK_OO | BLACK_OOO)
const CASTLING_FLAG_NB = uint16(16)

typealias CastlingSide Uint16
castlingSide = uint16

const KING_SIDE        = uint16(0)
const QUEEN_SIDE       = uint16(1)
const CASTLING_SIDE_NB = uint16(2)

typealias Phase Uint16
phase = uint16

const PHASE_ENDGAME = uint16(0)
const PHASE_MIDGAME = uint16(128)
const MG            = uint16(0)
const EG            = uint16(1)
const PHASE_NB      = uint16(2)

typealias ScaleFactor Uint16
scaleFactor = uint16

const SCALE_FACTOR_DRAW    = uint16(0)
const SCALE_FACTOR_ONEPAWN = uint16(48)
const SCALE_FACTOR_NORMAL  = uint16(64)
const SCALE_FACTOR_MAX     = uint16(128)
const SCALE_FACTOR_NONE    = uint16(255)

typealias Bound Uint16
bound = uint16

const BOUND_NONE  = uint16(0)
const BOUND_UPPER = uint16(1)
const BOUND_LOWER = uint16(2)
const BOUND_EXACT = uint16(BOUND_UPPER | BOUND_LOWER)

typealias Value Int32
value = int32

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

typealias PieceType Int32
pieceType = int32

const NO_PIECE_TYPE = int32(0)
const PAWN          = int32(1)
const KNIGHT        = int32(2)
const BISHOP        = int32(3)
const ROOK          = int32(4)
const QUEEN         = int32(5)
const KING          = int32(6)
const ALL_PIECES    = int32(0)
const PIECE_TYPE_NB = int32(8)

typealias Piece Int32
piece = int32

const NO_PIECE  = int32(0)
const W_PAWN    = int32(1)
const W_KNIGHT  = int32(2)
const W_BISHOP  = int32(3)
const W_ROOK    = int32(4)
const W_QUEEN   = int32(5)
const W_KING    = int32(6)

const B_PAWN    = int32(9)
const B_KNIGHT  = int32(10)
const B_BISHOP  = int32(11)
const B_ROOK    = int32(12)
const B_QUEEN   = int32(13)
const B_KING    = int32(14)
const PIECE_NB  = int32(16)

typealias Color Int8 # changed from Int32
color = int8

const WHITE    = int8(0)
const BLACK    = int8(1)
const NO_COLOR = int8(2)
const COLOR_NB = int64(2) # may be use as array index...

typealias Depth Int32
const ONE_PLY = int32(2)
const DEPTH_ZERO          = int32(0 * ONE_PLY)
const DEPTH_QS_CHECKS     = int32(0 * ONE_PLY)
const DEPTH_QS_NO_CHECKS  = int32(-1 * ONE_PLY)
const DEPTH_QS_RECAPTURES = int32(-5 * ONE_PLY)

const DEPTH_NONE          = int32(-127 * ONE_PLY)

typealias Square Int32
squareC = int32

const SQ_A1 =  int32(0)
const SQ_B1 =  int32(1)
const SQ_C1 =  int32(2)
const SQ_D1 =  int32(3)
const SQ_E1 =  int32(4)
const SQ_F1 =  int32(5)
const SQ_G1 =  int32(6)
const SQ_H1 =  int32(7)
const SQ_A2 =  int32(8)
const SQ_B2 =  int32(9)
const SQ_C2 = int32(10)
const SQ_D2 = int32(11)
const SQ_E2 = int32(12)
const SQ_F2 = int32(13)
const SQ_G2 = int32(14)
const SQ_H2 = int32(15)
const SQ_A3 = int32(16)
const SQ_B3 = int32(17)
const SQ_C3 = int32(18)
const SQ_D3 = int32(19)
const SQ_E3 = int32(20)
const SQ_F3 = int32(21)
const SQ_G3 = int32(22)
const SQ_H3 = int32(23)
const SQ_A4 = int32(24)
const SQ_B4 = int32(25)
const SQ_C4 = int32(26)
const SQ_D4 = int32(27)
const SQ_E4 = int32(28)
const SQ_F4 = int32(29)
const SQ_G4 = int32(30)
const SQ_H4 = int32(31)
const SQ_A5 = int32(32)
const SQ_B5 = int32(33)
const SQ_C5 = int32(34)
const SQ_D5 = int32(35)
const SQ_E5 = int32(36)
const SQ_F5 = int32(37)
const SQ_G5 = int32(38)
const SQ_H5 = int32(39)
const SQ_A6 = int32(40)
const SQ_B6 = int32(41)
const SQ_C6 = int32(42)
const SQ_D6 = int32(43)
const SQ_E6 = int32(44)
const SQ_F6 = int32(45)
const SQ_G6 = int32(46)
const SQ_H6 = int32(47)
const SQ_A7 = int32(48)
const SQ_B7 = int32(49)
const SQ_C7 = int32(50)
const SQ_D7 = int32(51)
const SQ_E7 = int32(52)
const SQ_F7 = int32(53)
const SQ_G7 = int32(54)
const SQ_H7 = int32(55)
const SQ_A8 = int32(56)
const SQ_B8 = int32(57)
const SQ_C8 = int32(58)
const SQ_D8 = int32(59)
const SQ_E8 = int32(60)
const SQ_F8 = int32(61)
const SQ_G8 = int32(62)
const SQ_H8 = int32(63)
const SQ_NONE = int32(64)

const SQUARE_NB = int32(64)

const DELTA_N =  int32(8)
const DELTA_E =  int32(1)
const DELTA_S =  int32(-8)
const DELTA_W =  int32(-1)

const DELTA_NN = int32(DELTA_N + DELTA_N)
const DELTA_NE = int32(DELTA_N + DELTA_E)
const DELTA_SE = int32(DELTA_S + DELTA_E)
const DELTA_SS = int32(DELTA_S + DELTA_S)
const DELTA_SW = int32(DELTA_S + DELTA_W)
const DELTA_NW = int32(DELTA_N + DELTA_W)

typealias File Int32
fileC = int32

const FILE_A = int32(0)
const FILE_B = int32(1)
const FILE_C = int32(2)
const FILE_D = int32(3)
const FILE_E = int32(4)
const FILE_F = int32(5)
const FILE_G = int32(6)
const FILE_H = int32(7)
const FILE_NB= int32(8)
# for Shogi
const FILE_I = int32(8)
const SFILE_NB=int32(9) 

typealias Rank Int32
rankC = int32

const RANK_1 = int32(0)
const RANK_2 = int32(1)
const RANK_3 = int32(2)
const RANK_4 = int32(3)
const RANK_5 = int32(4)
const RANK_6 = int32(5)
const RANK_7 = int32(6)
const RANK_8 = int32(7)
const RANK_NB= int32(8)
# for Shogi
const RANK_9 = int32(8)
const SRANK_NB=int32(9)

# The Score enum stores a middlegame and an endgame value in a single integer
# (enum). The least significant 16 bits are used to store the endgame value
# and the upper 16 bits are used to store the middlegame value. The compiler
# is free to choose the enum type as long as it can store the data, so we
# ensure that Score is an integer type by assigning some big int values.
typealias Score Int32
scoreC = int32

const SCORE_ZERO = int32(0)
const SCORE_ENSURE_INTEGER_SIZE_P = typemax(Int32)
const SCORE_ENSURE_INTEGER_SIZE_N = typemin(Int32)

function make_score(mg::Int32, eg::Int32)
    scoreC((mg << 16) + eg)
end

# Extracting the signed lower and upper 16 bits is not so trivial because
# according to the standard a simple cast to short is implementation defined
# and so is a right shift of a signed integer.
function mg_value(s::Score)
    value(((s + 0x8000) & ~0xffff) / 0x10000)
end

function eg_value(s::Score)
    value(int16(s & 0xFFFF))
end

function (/)(s::Score, i::Int32)
    make_score(mg_value(s) / i, eg_value(s) / i)
end

immutable type ExtMove
    move::Move
    score::Int32
end

function (<)(f::ExtMove, s::ExtMove)
    f.score < s.score
end

function opp(c::Color) # cannot overwritten ~(Int32,), so tentative name "opp" is given
    color(c $ BLACK)
end

function flip(s::Square) # cannot overwritten ~(Int32,) so tentative name "flip" is given
    squareC(s $ SQ_A8)   # Vertical flip SQ_A1 -> SQ_A8
end

function file_rank(f::File, r::Rank) # cannot overwritten |(Int32,Int32) so tentative name file_rank is given
    squareC((r << 3)|f)
end

function mate_in(ply::Int32)
    VALUE_MATE - ply
end

function mated_in(ply::Int32)
    -VALUE_MATE + ply
end

function make_piece(c::Color, pt::PieceType)
    piece((c << 3) | pt)
end

function make_castling_flag(c::Color, s::CastlingSide)
    castlingFlag(WHITE_OO << (int32(s == QUEEN_SIDE) + 2 * c))
end

function type_of(p::Piece)
    pieceType(p & 7)
end

function color_of(p::Piece)
    #assert(p != NO_PIECE);
    color(p >> 3)
end

function is_ok(s::Square)
    bool((s >= SQ_A1) && (s <= SQ_H8))
end

function file_of(s::Square)
    fileC(s & 7)
end

function rank_of(s::Square)
    rankC(s >> 3)
end

function relative_square(c::Color, s::Square)
    squareC(s $ (c*56))
end

function relative_rank(c::Color, r::Rank)
    Rank(r $ (c * 7))
end

function relative_rank(c::Color, s::Square)
    relative_rank(c, rank_of(s))
end

function opposite_colors(s1::Square, s2::Square)
    s = int(int(s1) $ int(s2))
    ((s >> 3) $ s) & 1
end

function file_to_char(f::File, tolower::Bool = true)
    char(f - FILE_A + (tolower ? int('a') : int('A')))
end

function rank_to_char(r::Rank)
    char(r - RANK_1 + int('1'))
end

function pawn_push(c::Color)
    c == WHITE ? DELTA_N : DELTA_S
end

function from_sq(m::Move)
    squareC((m >> 6) & 0x3F)
end

function to_sq(m::Move)
    squareC(m & 0x3F)
end

function type_of(m::Move)
    MoveType(m & (3 << 14))
end

function promotion_type(m::Move)
    PieceType(((m >> 12) & 3) + 2)
end

function make_move(from::Square, to::Square)
    Move(to | (from << 6))
end

function make(from::Square, to::Square, T::MoveType, pt::PieceType = KNIGHT) # re-arrange function list!
    Move(to | (from << 6) | T | ((pt - KNIGHT) << 12))
end

function is_ok(m::Move)
    (from_sq(m) != to_sq(m)) # Catches also MOVE_NULL and MOVE_NONE
end

function square_to_string(s::Square)
    fi = file_to_char(file_of(s))
    ra = rank_to_char(rank_of(s))
    "$(fi)$(ra)"
end

function more_than_one(b::Bitboard)
    b & (b - 1)
end
