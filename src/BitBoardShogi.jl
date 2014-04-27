const BishopMagicFileName = "Bishop.magic.txt"
const RookMagicFileName = "Rook.magic.txt"

function sfile_distance(s1::Square, s2::Square)
    int32(abs(sfile_of(s1) - sfile_of(s2)))
end

function srank_distance(s1::Square, s2::Square)
    int32(abs(srank_of(s1) - srank_of(s2)))
end

# shift_bb() moves bitboard one step along direction Delta. Mainly for pawns.
function shift_bb(Delta::Square, b::SBitboard)
  return  (Delta == SDELTA_N)  ?  (b             << 9) : ((Delta == SDELTA_S)  ?  (b             >> 9)
        : ((Delta == SDELTA_NE) ? ((b & ~SFileIBB)<< 10) : ((Delta == SDELTA_SE) ? ((b & ~SFileIBB) >> 8)
        : ((Delta == SDELTA_NW) ? ((b & ~SFileABB) << 8) : ((Delta == SDELTA_SW) ? ((b & ~SFileABB) >> 10)
        : sbitboard(0))))))

end

# rank_bb() and file_bb() take a file or a square as input and return
# a bitboard representing all squares on the given file or rank.

function rank_bb_sq(bb::SContextBB, s::Square)
    bb.RankBB[srank_of(s)+1]
end

function rank_bb(bb::SContextBB, r::Rank)
    bb.RankBB[r+1]
end

function file_bb_sq(bb::SContextBB, s::Square)
    bb.FileBB[sfile_of(s)+1]
end

function file_bb(bb::SContextBB, f::Rank)
    bb.FileBB[f+1]
end


# adjacent_files_bb() takes a file as input and returns a bitboard representing
# all squares on the adjacent files.
function adjacent_files_bb(bb::SContextBB, f::File)
    bb.AdjacentFilesBB[f+1]
end


# between_bb() returns a bitboard representing all squares between two squares.
# For instance, between_bb(SQ_C4, SQ_F7) returns a bitboard with the bits for
# square d5 and e6 set.  If s1 and s2 are not on the same rank, file or diagonal,
# 0 is returned.
function between_bb(bb::SContextBB, s1::Square, s2::Square)
    bb.BetweenBB[s1+1,s2+1]
end

# forward_bb() takes a color and a square as input, and returns a bitboard
# representing all squares along the line in front of the square, from the
# point of view of the given color. Definition of the table is:
# ForwardBB[c][s] = in_front_bb(c, s) & file_bb(s)

function forward_bb(bb::SContextBB, c::Color, s::Square)
    bb.ForwardBB[c+1,s+1]
end

# /// Bitboards::pretty() returns an ASCII representation of a bitboard to be
# /// printed to standard output. This is sometimes useful for debugging.
function pretty(bb::SContextBB, b::SBitboard)
    s = "+---+---+---+---+---+---+---+---+---+\n"

    for rank = RANK_9:int32(-1):RANK_1
        for file = FILE_A:FILE_I
            sq = sfile_rank(file,rank)
            s *= (((b & bb.SquareBB[sq+1]) > 0) ? "| X " : "|   ")
        end
        s *= "|\n+---+---+---+---+---+---+---+---+---+\n"
    end
    s
end

function pretty2(bb::SContextBB, b::SBitboard)
    s = "ABCDEFGHI\n"

    for rank = RANK_9:int32(-1):RANK_1
        for file = FILE_A:FILE_I
            sq = sfile_rank(file,rank)
            s *= (((b & bb.SquareBB[sq+1]) > 0) ? "X" : ".")
        end
        s *= "|$(rank+1)\n"
    end
    s
end

using IProfile

type LSBC
    sq::Int64
    b::SBitboard
end

# lsb()/msb() finds the least/most significant bit in a non-zero bitboard.
# pop_lsb() finds and clears the least significant bit in a non-zero bitboard.
#@iprofile begin
function pop_lsb(b::SBitboard,li::LSBC)
    bb = b
    ret = trailing_zeros(b)
    b = bb & (bb - 1)

    li.sq = ret
    li.b  = b
end
#end

function lsb(b::SBitboard)
    trailing_zeros(b)
end

function square_distance(bb::SContextBB, s1::Square, s2::Square)
    bb.SquareDistance[s1+1,s2+1]
end

# for debbug purpose
function testBB(bb::SContextBB)
    # sqStringArray = [pretty2(bb,bb.SquareBB[s+1]) for s = SSQ_A1:SSQ_I9]
    # for idxxx = SSQ_A1:SSQ_I9
    #     println(ssquare_to_string(idxxx))
    #     println(sqStringArray[idxxx+1])
    # end

    # for f = FILE_A:FILE_I
    #     println(pretty2(bb, bb.FileBB[f+1]))
    # end
    # for r = RANK_1:RANK_9
    #     println(pretty2(bb, bb.RankBB[r+1]))
    # end

    # for f = FILE_A:FILE_I
    #     println(pretty2(bb, bb.AdjacentFilesBB[f+1]))
    # end

    # for r = RANK_1:RANK_9
    #     println("white r=",r);
    #     println(pretty2(bb,bb.InFrontBB[WHITE+1,r+1]))
    #     println("black r=",r);
    #     println(pretty2(bb,bb.InFrontBB[BLACK+1,r+1]))
    # end

    # println("forward")
    # for c = WHITE:BLACK
    #     for s = SSQ_A1:SSQ_I9
    #         println((c==WHITE)?"WHITE":"BLACK", " ", "s=", square_to_jstring(s))
    #         println(pretty2(bb, bb.ForwardBB[c+1,s+1]))
    #         #println(pretty2(bb, bb.PawnAttackSpan[c+1,s+1]))
    #         #println(pretty2(bb, bb.PassedPawnMask[c+1,s+1]))
    #     end
    #  end

    # for s1 = SSQ_A1:SSQ_I9
    #     for s2 = FILE_A:FILE_I
    #         println("s1=",s1,", s2=",s2,": BB=",pretty2(bb, bb.DistanceRingsBB[s1+1, s2+1]))
    #     end
    # end

    # for c = WHITE:BLACK
    #     for pt = FU:RY
    #         for s = SSQ_A1:SSQ_I9
    #             println("c=",c,",pt=",pt,",sq=",s)
    #             println(pretty2(bb, bb.StepAttacksBB[smake_piece(c, pt)+1,s+1]))
    #         end
    #     end
    # end

    # for c = WHITE:BLACK
    #     for pt = FU:RY
    #         p = smake_piece(c,pt)
    #         println(((c==WHITE)?"▲":"△"),KOMASTR_SHORT[pt])
    #         println(pretty2(bb, bb.MoveMask[p]))
    #     end
    # end

    println(bb.DropTable)
end

function initBB(bb::SContextBB)
    bb.RTable = zeros(SBitboard, 0x19000) # Storage space for rook attacks
    bb.BTable = zeros(SBitboard, 0x1480)  # Storage space for bishop attacks
    bb.RAttacks = Array(Array{SBitboard,1},256)
    bb.BAttacks = Array(Array{SBitboard,1},256)
    bb.RMasks  = zeros(SBitboard,SSQUARE_NB)
    bb.BMasks  = zeros(SBitboard,SSQUARE_NB)
    bb.RMagics = zeros(SBitboard,SSQUARE_NB)
    bb.BMagics = zeros(SBitboard,SSQUARE_NB)
    bb.RShifts = zeros(Uint32,SSQUARE_NB)
    bb.BShifts = zeros(Uint32,SSQUARE_NB)

    bb.SquareBB = SBitboard[(sbitboard(1)<<s) for s = SSQ_A1:SSQ_I9]

    # BSFTable and MS1BTable are omitted

    bb.FileBB = SBitboard[SFileABB,SFileBBB,SFileCBB,SFileDBB,SFileEBB,SFileFBB,SFileGBB,SFileHBB,SFileIBB]
    bb.RankBB = SBitboard[SRank1BB,SRank2BB,SRank3BB,SRank4BB,SRank5BB,SRank6BB,SRank7BB,SRank8BB,SRank9BB]

    bb.AdjacentFilesBB = SBitboard[(f > FILE_A ? bb.FileBB[f] : 0) | (f < FILE_I ? bb.FileBB[f + 2] : 0) for f = FILE_A:FILE_I]

    bb.InFrontBB = zeros(SBitboard, COLOR_NB, SRANK_NB)
    for r = RANK_1:(RANK_9-1)
        bb.InFrontBB[BLACK+1,r+1+1] = sbitboard(bb.InFrontBB[BLACK+1,r+1] | bb.RankBB[r+1])
        bb.InFrontBB[WHITE+1,r+1] = sbitboard(~bb.InFrontBB[BLACK+1,r+1+1]&MaskOfBoard)
    end

    bb.ForwardBB = zeros(SBitboard, COLOR_NB, SSQUARE_NB)
    bb.PawnAttackSpan = zeros(SBitboard, COLOR_NB, SSQUARE_NB)
    bb.PassedPawnMask = zeros(SBitboard, COLOR_NB, SSQUARE_NB)
    for c = WHITE:BLACK
        for s = SSQ_A1:SSQ_I9
            bb.ForwardBB[c+1,s+1] = bb.InFrontBB[c+1,srank_of(s)+1] & bb.FileBB[sfile_of(s)+1]
            bb.PawnAttackSpan[c+1,s+1] = bb.InFrontBB[c+1,srank_of(s)+1] & bb.AdjacentFilesBB[sfile_of(s)+1]
            bb.PassedPawnMask[c+1,s+1] = bb.ForwardBB[c+1,s+1] | bb.PawnAttackSpan[c+1,s+1]
        end
    end

    bb.SquareDistance = zeros(Int32, SSQUARE_NB, SSQUARE_NB)
    bb.DistanceRingsBB= zeros(SBitboard, SSQUARE_NB,9)
    for s1 = SSQ_A1:SSQ_I9
        for s2 = SSQ_A1:SSQ_I9
            if s1 != s2
                bb.SquareDistance[s1+1,s2+1] = int32(max(sfile_distance(s1, s2), srank_distance(s1, s2)))
                bb.DistanceRingsBB[s1+1, bb.SquareDistance[s1+1,s2+1] - 1+1] |= bb.SquareBB[s2+1]
            end
        end
    end

    steps = Int32[0  0   0   0   0   0   0   0; #NONE
                  9  0   0   0   0   0   0   0; #FU
                  0  0   0   0   0   0   0   0; #KY
                  19 17  0   0   0   0   0   0; #KE
                  10 9   8  -8 -10   0   0   0; #GI
                  10 9   8   1  -1  -9   0   0; #KI
                  0  0   0   0   0   0   0   0; #KA
                  0  0   0   0   0   0   0   0; #HI
                  10 9   8   1  -1  -8  -9 -10; #OU
                  10 9   8   1  -1  -9   0   0; #TO
                  10 9   8   1  -1  -9   0   0; #NY
                  10 9   8   1  -1  -9   0   0; #NK
                  10 9   8   1  -1  -9   0   0; #NG
                  0  0   0   0   0   0   0   0; #NariKin
                  9  1  -1  -9   0   0   0   0; #UM
                  10 8  -8 -10   0   0   0   0  #RY
                  ]::Array{Int32,2}

    steplast = Int32[-1,0,-1,1,4,5,-1,-1,7,5,5,5,5,-1,3,3]::Array{Int32,1}

    bb.StepAttacksBB = zeros(SBitboard, SPIECE_NB, SSQUARE_NB)

    for c = WHITE:BLACK
        for pt = FU:RY
            for s = SSQ_A1:SSQ_I9
                for i = 1:steplast[pt+1]+1
                    # println(c,",",pt,",",s,":",i)
                    wstep = steps[pt+1,i]
                    bstep = -steps[pt+1,i]
                    ste = (c == WHITE) ? wstep: bstep
                    to = squareC(s + ste)

                    if sis_ok(to) && (square_distance(bb, s, to) < 3)
                        bb.StepAttacksBB[smake_piece(c, pt)+1,s+1] |= bb.SquareBB[to+1]
                    end
                end
            end
        end
    end

    RDeltas = Square[SDELTA_N,  SDELTA_E,  SDELTA_S,  SDELTA_W]
    BDeltas = Square[SDELTA_NE, SDELTA_SE, SDELTA_SW, SDELTA_NW]

    init_magics(bb, ROOK, bb.RTable, bb.RAttacks, bb.RMagics, bb.RMasks, bb.RShifts, RDeltas)
    init_magics(bb, BISHOP, bb.BTable, bb.BAttacks, bb.BMagics, bb.BMasks, bb.BShifts, BDeltas)

    # PseudoAttacks remain index = ROOK, BISHOP, and QUEEN (QUEEN is actuall not used)
    # but attacks_bb is using Shogi Pieces Notation (HI,KA)
    bb.PseudoAttacks = zeros(SBitboard, SPIECE_TYPE_NB, SSQUARE_NB)
    bb.LineBB = zeros(SBitboard, SSQUARE_NB, SSQUARE_NB)
    bb.BetweenBB = zeros(SBitboard, SSQUARE_NB, SSQUARE_NB)

    for s1 = SSQ_A1:SSQ_I9
        bb.PseudoAttacks[BISHOP+1,s1+1] = attacks_bb(bb, KA, s1, sbitboard(0))
        #println("PseudoAttacks(BISHOP,$s1):")
        #println(pretty2(bb,bb.PseudoAttacks[BISHOP+1,s1+1]))
        bb.PseudoAttacks[QUEEN+1,s1+1]  = attacks_bb(bb, KA, s1, sbitboard(0))

        bb.PseudoAttacks[ROOK+1,s1+1]   = attacks_bb(bb, HI,   s1, sbitboard(0))
        #println("PseudoAttacks(ROOK,$s1):")
        #println(pretty2(bb,bb.PseudoAttacks[ROOK+1,s1+1]))
        bb.PseudoAttacks[QUEEN+1,s1+1] |= attacks_bb(bb, HI,   s1, sbitboard(0))

        #println("PseudoAttacks($s1):")
        #println(pretty2(bb,bb.PseudoAttacks[QUEEN+1,s1+1]))

        for s2 = SSQ_A1:SSQ_I9
            pc = NO_PIECE
            if (bb.PseudoAttacks[BISHOP+1,s1+1] & bb.SquareBB[s2+1]) > sbitboard(0)
                pc = W_KA
            elseif (bb.PseudoAttacks[ROOK+1,s1+1] & bb.SquareBB[s2+1]) > sbitboard(0)
                pc = W_HI
            end

            if pc == NO_PIECE
                continue
            end
            bb.LineBB[s1+1,s2+1] = (attacks_bb(bb, pc, s1, sbitboard(0)) & attacks_bb(bb, pc, s2, sbitboard(0)))| bb.SquareBB[s1+1] | bb.SquareBB[s2+1]
            bb.BetweenBB[s1+1,s2+1] = attacks_bb(bb, pc, s1, bb.SquareBB[s2+1]) & attacks_bb(bb, pc, s2, bb.SquareBB[s1+1])
            
            #println("LineBB(","$(s1+1),$(s2+1)","):")
            #println(pretty2(bb,bb.LineBB[s1+1,s2+1]))
            #println("BetweenBB(","$(s1+1),$(s2+1)","):")
            #println(pretty2(bb,bb.BetweenBB[s1+1,s2+1]))
        end
    end
    
    bb.MoveMask = SBitboard[MaskOfBoard for p = W_FU:B_RY]
    bb.MoveMask[W_FU] = bb.InFrontBB[BLACK+1,RANK_9+1]
    bb.MoveMask[W_KY] = bb.InFrontBB[BLACK+1,RANK_9+1]
    bb.MoveMask[W_KE] = bb.InFrontBB[BLACK+1,RANK_8+1]

    bb.MoveMask[B_FU] = bb.InFrontBB[WHITE+1,RANK_1+1]
    bb.MoveMask[B_KY] = bb.InFrontBB[WHITE+1,RANK_1+1]
    bb.MoveMask[B_KE] = bb.InFrontBB[WHITE+1,RANK_2+1]
    
    bb.DropTable = [((bb.MoveMask[p] & bb.RankBB[r+1] > sbitboard(0)) ? 1: 0) for r = RANK_1:RANK_9, p = W_FU:B_RY]
    
    testBB(bb)
end

# aligned() returns true if the squares s1, s2 and s3 are aligned
# either on a straight or on a diagonal line.
function aligned(bb::SContextBB, s1::Square, s2::Square, s3::Square)
    bb.LineBB[s1+1,s2+1] & bb.SquareBB[s3+1]
end

# Functions for computing sliding attack bitboards. Function attacks_bb() takes
# a square and a bitboard of occupied squares as input, and returns a bitboard
# representing all squares attacked by Pt (bishop or rook) on the given square.
function magic_index(bb::SContextBB, p::Piece, s::Square, occ::SBitboard)
    Pt = stype_of(p)

    Masks  = (Pt == ROOK)? bb.RMasks: bb.BMasks
    Magics = (Pt == ROOK)? bb.RMagics: bb.BMagics
    Shifts = (Pt == ROOK)? bb.RShifts: bb.BShifts

    uint((((occ & Masks[s+1]) * Magics[s+1]) & MaskOfBoard) >>> Shifts[s+1])
end

# isSliding is only for distinguish from attacks_bb(4)
function attacks_bb(bb::SContextBB, p::Piece, s::Square, occ::SBitboard, isSliding::Bool=true)
    Pt = stype_of(p)
    boo = (Pt == HI || Pt == KY || Pt == RY)
    ar = (boo == true ? bb.RAttacks : bb.BAttacks)
    PtChess = boo == true ? ROOK:BISHOP
    (ar[s+1])[magic_index(bb, PtChess, s, occ)+1] & ((Pt == KY)?bb.ForwardBB[(scolor_of(p))+1,s+1]:MaskOfBoard)
end

# when we call this function, we recognized that this piece(p) is no sliding piece.
function attacks_bb(bb::SContextBB, p::Piece, s::Square, occ::SBitboard)
    t = stype_of(p)
    if t == KA
        return attacks_bb(bb, p, s, occ, true)
    elseif t == HI
        return attacks_bb(bb, p, s, occ, true)
    elseif t == KY # for KyouSha, only forward attacks are enabled
        return attacks_bb(bb, p, s, occ, true)&bb.ForwardBB[scolor_of(p)+1,s+1]
    else
        return bb.StepAttacksBB[p+1,s+1]
    end
end

function sliding_attack(bb::SContextBB,
                        deltas::Array{Square,1},
                        sq::Square,
                        occupied::SBitboard)
    attack = sbitboard(0)
    for i = 0:(4-1)
        s = squareC(sq + deltas[i+1])
        dis = 
        while sis_ok(s) && sis_ok(squareC(s - deltas[i+1])) && (square_distance(bb, s, squareC(s - deltas[i+1])) == int32(1))
            attack |= bb.SquareBB[s+1]

            if occupied & bb.SquareBB[s+1] != bitboard(0)
                break
            end
            # increments
            s = squareC(s+deltas[i+1])
        end
    end

    attack
end

# LoadMagics loads magic values from plain file(s)
function LoadMagics{T}(bb::T, Pt::PieceType)
    if Pt == ROOK
        if T == SContextBB
            fn = RookMagicFileName
        else
            fn = ChessRookMagicFileName
        end
        fi = open(fn,"r")
        bb.RMasks  = deserialize(fi)
        bb.RMagics = deserialize(fi)
        bb.RShifts = deserialize(fi)
        bb.RAttacks= deserialize(fi)
        close(fi)
    elseif Pt == BISHOP
        if T == SContextBB
            fn = BishopMagicFileName
        else
            fn = ChessBishopMagicFileName
        end
        fi = open(fn,"r")
        bb.BMasks  = deserialize(fi)
        bb.BMagics = deserialize(fi)
        bb.BShifts = deserialize(fi)
        bb.BAttacks= deserialize(fi)
        close(fi)
    else
        println("LoadMagics: Illegal Piece Type ($Pt)")
    end
end

function SaveArray{T}(fi::IO, a::Array{T,1})
    println(fi,size(a)[1]) # first line is the size of the array
    for i = 1:size(a)[1]
        println(fi,hex(a[i]))
    end
end

function SaveArrayOfArray{T}(fi::IO, a::Array{Array{T,1},1},size)
    println(fi,size) # first line is the size of the array
    for i = 1:size
        println("i=$i")
        ar = a[i]
        SaveArray(fi, ar)
        #println(fi,"undef")
    end
end

function SaveMagics(bb::SContextBB, Pt::PieceType)
    if Pt == ROOK
        fi = open(RookMagicFileName,"w")
        println(fi, "#RMasks")
        SaveArray(fi, bb.RMasks)
        println(fi, "#RMagics")
        SaveArray(fi, bb.RMagics)
        println(fi, "#RShifts")
        SaveArray(fi, bb.RShifts)
        println(fi, "#RAttacks")
        SaveArrayOfArray(fi, bb.RAttacks,SSQUARE_NB)
        close(fi)
    elseif Pt == BISHOP
        fi = open(BishopMagicFileName,"w")
        println(fi, "#BMasks")
        SaveArray(fi, bb.BMasks)
        println(fi, "#BMagics")
        SaveArray(fi, bb.BMagics)
        println(fi, "#BShifts")
        SaveArray(fi, bb.BShifts)
        println(fi, "#BAttacks")
        SaveArrayOfArray(fi, bb.BAttacks,SSQUARE_NB)
        close(fi)
    else
        println("LoadMagics: Illegal Piece Type ($Pt)")
    end
end

function SaveMagicsUsingSerialize{T}(bb::T, Pt::PieceType)
    if Pt == ROOK
        if T == SContextBB
            fn = RookMagicFileName
        else
            fn = ChessRookMagicFileName
        end
        fi = open(fn,"w")
        serialize(fi, bb.RMasks)
        serialize(fi, bb.RMagics)
        serialize(fi, bb.RShifts)
        serialize(fi, bb.RAttacks)
        close(fi)
    elseif Pt == BISHOP
        if T == SContextBB
            fn = BishopMagicFileName
        else
            fn = ChessBishopMagicFileName
        end
        fi = open(fn,"w")
        serialize(fi, bb.BMasks)
        serialize(fi, bb.BMagics)
        serialize(fi, bb.BShifts)
        serialize(fi, bb.BAttacks)
        close(fi)
    else
        println("LoadMagics: Illegal Piece Type ($Pt)")
    end
end


# init_magics() computes all rook and bishop attacks at startup. Magic
# bitboards are used to look up attacks of sliding pieces. As a reference see
# chessprogramming.wikispaces.com/Magic+Bitboards. In particular, here we
# use the so called "fancy" approach.
# (Shogi version)
function init_magics(bb::SContextBB,
                     Pt::PieceType,
                     table::Array{SBitboard,1},
                     attacks::Array{Array{SBitboard,1},1},
                     magics::Array{SBitboard,1},
                     masks::Array{SBitboard,1},
                     shifts::Array{Uint32,1},
                     deltas::Array{Square,1})

    if bb.calcMagic == false
        if Pt == ROOK
            LoadMagics(bb,ROOK)
        elseif Pt == BISHOP
            LoadMagics(bb,BISHOP)
        end
        return
    end


    # original magic boosters: for RKiss
    #MagicBoosters = Int32[969 1976 2850  542 2069 2852 1708  164;
    #                      3101 552 3555  926  834   26 2131 1117]::Array{Int32,2}

    # rk = RKISS()
    occupancy = zeros(SBitboard,65536)
    reference = zeros(SBitboard,65536)
    b = sbitboard(0)

    # attacks[s] is a pointer to the beginning of the attacks table for square 's'
    attacks[SSQ_A1+1] = table

    for s = SSQ_A1:SSQ_I9
        # Board edges are not considered in the relevant occupancies
        edges = ((SRank1BB | SRank9BB) & (~rank_bb_sq(bb,s)&MaskOfBoard)) | ((SFileABB | SFileIBB) & (~file_bb_sq(bb,s)&MaskOfBoard))::SBitboard
        ##println(pretty2(bb,edges))
        # Given a square 's', the mask is the bitboard of sliding attacks from
        # 's' computed on an empty board. The index must be big enough to contain
        # all the attacks for each possible subset of the mask and so is 2 power
        # the number of 1s of the mask. Hence we deduce the size of the shift to
        # apply to the 64 or 32 bits word to get the index.
        masks[s+1]  = sliding_attack(bb, deltas, s, sbitboard(0)) & ~edges
        shifts[s+1] = 81 - popcount(masks[s+1]) # uncertainly...

        println("s=",s)
        #println("shifts=", shifts[s+1])
        #println(pretty2(bb,masks[s+1]))

        # Use Carry-Rippler trick to enumerate all subsets of masks[s] and
        # store the corresponding sliding attack bitboard in reference[].
        size = 0
        begin
            occupancy[size+1] = b
            size += 1
            reference[size] = sliding_attack(bb, deltas, s, b) # intentionally size is not size+1
            b = (b - masks[s+1]) & masks[s+1]
        end
        while b > sbitboard(0)
            occupancy[size+1] = b
            size += 1
            reference[size] = sliding_attack(bb, deltas, s, b) # intentionally size is not size+1
            b = (b - masks[s+1]) & masks[s+1]
        end

        println("size=",size)

        # Set the offset for the table of the next square. We have individual
        # table sizes for each square with "Fancy Magic Bitboards".
        # (original C++ code)
        #         if (s < SQ_H8)
        #             attacks[s + 1] = attacks[s] + size;

        #if (s < SSQ_I9)
        #    attacks[s+1+1] = zeros(SBitboard,size)
        #end
        booster = int32(0) # MagicBoosters[Is64Bit?2:1,rank_of(s)+1] # calculate in later...

        # Find a magic for square 's' picking up an (almost) random number
        # until we find the one that passes the verification test.

        idx = 0

        begin
            magics[s+1] = magic_rand(SBitboard,booster)
            while popcount((MaskOfBoard&(magics[s+1] * masks[s+1])) >>> SSQ_A9) < 6
                magics[s+1] = magic_rand(SBitboard,booster)
                #println("magic=",hex(magics[s+1]))
            end

            attacks[s+1] = zeros(SBitboard,size)

            for i = 0:(size-1)
                idx = i
                magIdx = magic_index(bb, Pt, s, occupancy[i+1]) + 1
                attack = (attacks[s+1])[magIdx]

                if attack > sbitboard(0) && attack != reference[i+1]
                    break
                end
                #attack = reference[i+1]
                (attacks[s+1])[magIdx] = reference[i+1]
                #println("idx=",idx,"/",size)
            end
            if idx == (size-1)
                idx = size
                #println("idx=",idx)
                #println(pretty2(bb,reference[idx]))
            end
        end
        while idx < size
            magics[s+1] = magic_rand(SBitboard,booster)
            while popcount((MaskOfBoard&(magics[s+1] * masks[s+1])) >>> SSQ_A9) < 6
                magics[s+1] = magic_rand(SBitboard,booster)
            end

            attacks[s+1] = zeros(SBitboard,size)

            for i = 0:(size-1)
                idx = i
                magIdx = magic_index(bb, Pt, s, occupancy[i+1]) + 1
                attack = (attacks[s+1])[magIdx]

                if attack > sbitboard(0) && attack != reference[i+1]
                    break
                end
                #attack = reference[i+1]
                (attacks[s+1])[magIdx] = reference[i+1]
                #println("idx=",idx,"/",size)
            end
            if idx == (size-1)
                idx = size
                #println("idx=",idx)
            end
        end
    end
    SaveMagicsUsingSerialize(bb, Pt)
end
