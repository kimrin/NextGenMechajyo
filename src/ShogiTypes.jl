# Shogi Moves need 32bit Integer:
# 0--6bits: destination of the piece
# 7bit: reserved
# 8--14bits: source destination of the piece
# 15bit: reserved
# 16--19bits: moving piece (including promoted)
# 20bit White(0) or Black (1)
# 21--23bits: reserved
# 24bit: TORU = capture flag
# 25bit: NARU = promoted flag
# 26bit: UTSU = reuse captured pieces flag
# 27bit: reserved
# 28--31bit: captured piece (when captured=including promoted)

# |CAPT xUNT|xxxT PIEC|xSOU RCES|xDES TINAT|
#  |     |||   | |     |         |Destination Square
#  |     |||   | |     |        
#  |     |||   | |     |Source Square
#  |     |||   | |Piece Type
#  |     |||   |W/B
#  |     |||
#  |     |||TORU
#  |     ||NARU
#  |     |UTSU
#  |Captured piece type

typealias SMove Uint32
smove = uint32

const SMOVE_NONE = uint32(0)
const SMOVE_NULL = uint32(0x0101)

typealias SMoveType Uint32
smoveType = uint32

const SNORMAL    = uint32(0)
const SCAPTURED  = uint32(1 << 24)
const SPROMOTION = uint32(1 << 25)
const SDROPS     = uint32(1 << 26)

const SCAPTPIECE_OFFSET = uint32(1 << 28)
const SCAPTPIECE_MASK   = uint32(0xf << 28)

const SPIECE_OFFSET = uint32(1 << 16)
const SPIECE_MASK   = uint32(0x1f << 16)

const SSOURCE_OFFSET    = uint32(1 << 8)
const SSOURCE_MASK      = uint32(0x7f << 8)

const SWHITE            = uint32(0)
const SBLACK            = uint32(1 << 20)

#const SDESTINATION_OFFSET = uint32(0)
const SDESTINATION_MASK = uint32(0x7f)

#const NO_PIECE_TYPE = int32(0)
const FU            = int32(1)       # pawn
const KY            = int32(2)       # lance
const KE            = int32(3)       # knight
const GI            = int32(4)       # silver
const KI            = int32(5)       # gold
const KA            = int32(6)       # bishop
const HI            = int32(7)       # rook
const OU            = int32(8)       # king
const PT_PROMOTE_OFFSET = int32(8)
const TO            = int32(9)       # prom. pawn
const NY            = int32(10)      # prom. lance
const NK            = int32(11)      # prom. knight
const NG            = int32(12)      # prom. silver
const NariKin       = int32(13)      # prom. gold (=nonexistable piece)
const UM            = int32(14)      # prom. bishop
const RY            = int32(15)      # prom. rook
const SALL_PIECES   = int32(0)
const SPIECE_TYPE_NB= int32(16)

const W_FU            = int32(1)       # pawn
const W_KY            = int32(2)       # lance
const W_KE            = int32(3)       # knight
const W_GI            = int32(4)       # silver
const W_KI            = int32(5)       # gold
const W_KA            = int32(6)       # bishop
const W_HI            = int32(7)       # rook
const W_OU            = int32(8)       # king
const W_PROMOTE_OFFSET= int32(8)
const W_TO            = int32(9)       # prom. pawn
const W_NY            = int32(10)      # prom. lance
const W_NK            = int32(11)      # prom. knight
const W_NG            = int32(12)      # prom. silver
const W_NariKin       = int32(13)      # prom. gold (=nonexistable piece)
const W_UM            = int32(14)      # prom. bishop
const W_RY            = int32(15)      # prom. rook

const B_OFFSET        = int32(16)
const B_FU            = int32(17)       # pawn
const B_KY            = int32(18)       # lance
const B_KE            = int32(19)       # knight
const B_GI            = int32(20)       # silver
const B_KI            = int32(21)       # gold
const B_KA            = int32(22)       # bishop
const B_HI            = int32(23)       # rook
const B_OU            = int32(24)       # king
const B_TO            = int32(25)       # prom. pawn
const B_NY            = int32(26)       # prom. lance
const B_NK            = int32(27)       # prom. knight
const B_NG            = int32(28)       # prom. silver
const B_NariKin       = int32(29)       # prom. gold (=nonexistable piece)
const B_UM            = int32(30)       # prom. bishop
const B_RY            = int32(31)       # prom. rook
const SPIECE_NB  = int32(32)

const SSQ_A1 =  int32(0)
const SSQ_B1 =  int32(1)
const SSQ_C1 =  int32(2)
const SSQ_D1 =  int32(3)
const SSQ_E1 =  int32(4)
const SSQ_F1 =  int32(5)
const SSQ_G1 =  int32(6)
const SSQ_H1 =  int32(7)
const SSQ_I1 =  int32(8)
const SSQ_A2 =  int32(9)
const SSQ_B2 = int32(10)
const SSQ_C2 = int32(11)
const SSQ_D2 = int32(12)
const SSQ_E2 = int32(13)
const SSQ_F2 = int32(14)
const SSQ_G2 = int32(15)
const SSQ_H2 = int32(16)
const SSQ_I2 = int32(17)
const SSQ_A3 = int32(18)
const SSQ_B3 = int32(19)
const SSQ_C3 = int32(20)
const SSQ_D3 = int32(21)
const SSQ_E3 = int32(22)
const SSQ_F3 = int32(23)
const SSQ_G3 = int32(24)
const SSQ_H3 = int32(25)
const SSQ_I3 = int32(26)
const SSQ_A4 = int32(27)
const SSQ_B4 = int32(28)
const SSQ_C4 = int32(29)
const SSQ_D4 = int32(30)
const SSQ_E4 = int32(31)
const SSQ_F4 = int32(32)
const SSQ_G4 = int32(33)
const SSQ_H4 = int32(34)
const SSQ_I4 = int32(35)
const SSQ_A5 = int32(36)
const SSQ_B5 = int32(37)
const SSQ_C5 = int32(38)
const SSQ_D5 = int32(39)
const SSQ_E5 = int32(40)
const SSQ_F5 = int32(41)
const SSQ_G5 = int32(42)
const SSQ_H5 = int32(43)
const SSQ_I5 = int32(44)
const SSQ_A6 = int32(45)
const SSQ_B6 = int32(46)
const SSQ_C6 = int32(47)
const SSQ_D6 = int32(48)
const SSQ_E6 = int32(49)
const SSQ_F6 = int32(50)
const SSQ_G6 = int32(51)
const SSQ_H6 = int32(52)
const SSQ_I6 = int32(53)
const SSQ_A7 = int32(54)
const SSQ_B7 = int32(55)
const SSQ_C7 = int32(56)
const SSQ_D7 = int32(57)
const SSQ_E7 = int32(58)
const SSQ_F7 = int32(59)
const SSQ_G7 = int32(60)
const SSQ_H7 = int32(61)
const SSQ_I7 = int32(62)
const SSQ_A8 = int32(63)
const SSQ_B8 = int32(64)
const SSQ_C8 = int32(65)
const SSQ_D8 = int32(66)
const SSQ_E8 = int32(67)
const SSQ_F8 = int32(68)
const SSQ_G8 = int32(69)
const SSQ_H8 = int32(70)
const SSQ_I8 = int32(71)
const SSQ_A9 = int32(72)
const SSQ_B9 = int32(73)
const SSQ_C9 = int32(74)
const SSQ_D9 = int32(75)
const SSQ_E9 = int32(76)
const SSQ_F9 = int32(77)
const SSQ_G9 = int32(78)
const SSQ_H9 = int32(79)
const SSQ_I9 = int32(80)
const SSQ_NONE = int32(81)

const SSQUARE_NB = int32(81)

const SDELTA_N =  int32(9)
const SDELTA_E =  int32(1)
const SDELTA_S =  int32(-9)
const SDELTA_W =  int32(-1)

const SDELTA_NN = int32(SDELTA_N + SDELTA_N)
const SDELTA_NE = int32(SDELTA_N + SDELTA_E)
const SDELTA_SE = int32(SDELTA_S + SDELTA_E)
const SDELTA_SS = int32(SDELTA_S + SDELTA_S)
const SDELTA_SW = int32(SDELTA_S + SDELTA_W)
const SDELTA_NW = int32(SDELTA_N + SDELTA_W)

function sflip(s::Square) # cannot overwritten ~(Int32,) so tentative name "sflip" is given
    squareC(SSQ_I9-s)     # Vertical flip SSQ_A1 -> SSQ_I9
end

immutable type SExtMove
    move::SMove
    score::Int32
end

function sfile_rank(f::File, r::Rank) # cannot overwritten |(Int32,Int32) so tentative name sfile_rank is given
    squareC(r*9+f)
end

function smake_piece(c::Color, pt::PieceType)
    piece((c << 4) | pt)
end

function stype_of(p::Piece)
    pieceType(p & 15)
end

function scolor_of(p::Piece)
    color(p >> 4)
end

function sis_ok(s::Square)
    bool((s >= SSQ_A1) && (s <= SSQ_I9))
end

function sfile_of(s::Square)
    fileC(s % 9)
end

function srank_of(s::Square)
    #println("srank_of($s)")
    #println("ans = ", rankC(ifloor(s/9.0)))
    rankC(ifloor(s / 9.0))
end

# These 4 functions are tentatively stab function...

function srelative_square(c::Color, s::Square)
end

function srelative_rank(c::Color, r::Rank)
end

function srelative_rank(c::Color, s::Square)
end

function sopposite_colors(s1::Square, s2::Square)
end

function fu_push(c::Color)
    c == WHITE ? SDELTA_N : SDELTA_S
end

function from_sq(m::SMove)
    squareC((m >> 8) & 0x7F)
end

function to_sq(m::SMove)
    squareC(m & 0x7F)
end

function type_of(m::SMove)
    MoveType(m & (7 << 24))
end

function promotion_type(m::SMove) # in Shogi, promotion type is identical to piece type
    PieceType(((m >> 25) & 0x1 == 0x1) ? (m >> 16) & 0xf: 0)
end

function smake_move(from::Square, to::Square)
    Move(to | (from << 8))
end

function make(from::Square, to::Square, p::Piece, flag::Uint32, capt::PieceType) # re-arrange function list! Also not included &ing with masks!
    Move(to | (from << 8) | (p << 16) | (flag << 24) | (capt << 28))
end

function is_ok(m::SMove)
    (from_sq(m) != to_sq(m)) # Catches also SMOVE_NULL and SMOVE_NONE
end

function ssquare_to_string(s::Square)
    fi = file_to_char(sfile_of(s))
    ra = rank_to_char(srank_of(s))
    "$(fi)$(ra)"
end
