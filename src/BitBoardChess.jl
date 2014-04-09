const ChessBishopMagicFileName = "Chess.Bishop.magic.txt"
const ChessRookMagicFileName = "Chess.Rook.magic.txt"

function file_distance(s1::Square, s2::Square)
    int32(abs(file_of(s1) - file_of(s2)))
end

function rank_distance(s1::Square, s2::Square)
    int32(abs(rank_of(s1) - rank_of(s2)))
end

# shift_bb() moves bitboard one step along direction Delta. Mainly for pawns.
function shift_bb(Delta::Square, b::Bitboard)
  return  (Delta == DELTA_N)  ?  (b             << 8) : ((Delta == DELTA_S)  ?  (b             >> 8)
        : ((Delta == DELTA_NE) ? ((b & ~FileHBB) << 9) : ((Delta == DELTA_SE) ? ((b & ~FileHBB) >> 7)
        : ((Delta == DELTA_NW) ? ((b & ~FileABB) << 7) : ((Delta == DELTA_SW) ? ((b & ~FileABB) >> 9)
        : bitboard(0))))))

end

# rank_bb() and file_bb() take a file or a square as input and return
# a bitboard representing all squares on the given file or rank.

function rank_bb_sq(bb::ContextBB, s::Square)
    bb.RankBB[rank_of(s)+1]
end

function rank_bb(bb::ContextBB, r::Rank)
    bb.RankBB[r+1]
end

function file_bb_sq(bb::ContextBB, s::Square)
    bb.FileBB[file_of(s)+1]
end

function file_bb(bb::ContextBB, f::Rank)
    bb.FileBB[f+1]
end


# adjacent_files_bb() takes a file as input and returns a bitboard representing
# all squares on the adjacent files.
function adjacent_files_bb(bb::ContextBB, f::File)
    bb.AdjacentFilesBB[f+1]
end

# /// Bitboards::pretty() returns an ASCII representation of a bitboard to be
# /// printed to standard output. This is sometimes useful for debugging.
function pretty(bb::ContextBB, b::Bitboard)
    s = "+---+---+---+---+---+---+---+---+\n"

    for rank = RANK_8:int32(-1):RANK_1
        for file = FILE_A:FILE_H
            sq = file_rank(file,rank)
            s *= (((b & bb.SquareBB[sq+1]) > 0) ? "| X " : "|   ")
        end
        s *= "|\n+---+---+---+---+---+---+---+---+\n"
    end
    s
end

function pretty2(bb::ContextBB, b::Bitboard)
    s = "ABCDEFGH\n"

    for rank = RANK_8:int32(-1):RANK_1
        for file = FILE_A:FILE_H
            sq = file_rank(file,rank)
            s *= (((b & bb.SquareBB[sq+1]) > 0) ? "X" : ".")
        end
        s *= "|$(rank+1)\n"
    end
    s
end

function lsb(bb::ContextBB, b::Bitboard)
    bb.BSFTable[bsf_index(b) + 1]
end

function square_distance(bb::ContextBB, s1::Square, s2::Square)
    bb.SquareDistance[s1+1,s2+1]
end

function testBB(bb::ContextBB)
    # for idx = SQ_A1:SQ_H8
    #     ls1 = lsb(bb, bb.SquareBB[idx+1])
    #     ls2 = trailing_zeros(bb.SquareBB[idx+1])
    #     ls3 = leading_zeros(bb.SquareBB[idx+1])
    #     println("lsb($idx)=",ls1)
    #     println("trailing_zeros($idx)=",ls2)
    #     println("leading_zeros($idx)=",ls3)
    #     println()
    # end

    # sqStringArray = [pretty2(bb,bb.SquareBB[s+1]) for s = SQ_A1:SQ_H8]
    # for idxxx = SQ_A1:SQ_H8
    #     println(square_to_string(idxxx))
    #     println(sqStringArray[idxxx+1])
    # end

    # for s = SQ_A1:SQ_H8
    #     println(square_to_string(s))
    #     println(pretty2(bb,bb.SquareBB[bb.BSFTable[s+1] + 1]))
    # end

    # for b = 1:255
    #     println(b,": ", bb.MS1BTable[b])
    # end

    # for f = FILE_A:FILE_H
    #     println(pretty2(bb, bb.FileBB[f+1]))
    # end
    # for r = RANK_1:RANK_8
    #     println(pretty2(bb, bb.RankBB[r+1]))
    # end

    # for f = FILE_A:FILE_H
    #     println(pretty2(bb, bb.AdjacentFilesBB[f+1]))
    # end

    # for r = RANK_1:RANK_8
    #     println("white r=",r);
    #     println(pretty2(bb,bb.InFrontBB[WHITE+1,r+1]))
    #     println("black r=",r);
    #     println(pretty2(bb,bb.InFrontBB[BLACK+1,r+1]))
    # end

    # for c = WHITE:BLACK
    #     for s = SQ_A1:SQ_H8
    #         println((c==WHITE)?"WHITE":"BLACK", " ", "s=", s)
    #         println(pretty2(bb, bb.ForwardBB[c+1,s+1]))
    #         println(pretty2(bb, bb.PawnAttackSpan[c+1,s+1]))
    #         println(pretty2(bb, bb.PassedPawnMask[c+1,s+1]))
    #     end
    # end

    # for s1 = SQ_A1:SQ_H8
    #     for s2 = FILE_A:FILE_H
    #         println("s1=",s1,", s2=",s2,": BB=",pretty2(bb, bb.DistanceRingsBB[s1+1, s2+1]))
    #     end
    # end

    # for c = WHITE:BLACK
    #     for pt = PAWN:KING
    #         for s = SQ_A1:SQ_H8
    #             println("c=",c,",pt=",pt,",sq=",s)
    #             println(pretty2(bb, bb.StepAttacksBB[make_piece(c, pt)+1,s+1]))
    #         end
    #     end
    # end
end

function initBB(bb::ContextBB)
    bb.RTable = zeros(Bitboard, 0x19000) # Storage space for rook attacks
    bb.BTable = zeros(Bitboard, 0x1480)  # Storage space for bishop attacks
    bb.RAttacks = Array(Array{Bitboard,1},256)
    bb.BAttacks = Array(Array{Bitboard,1},256)
    bb.RMasks  = zeros(Bitboard,SQUARE_NB)
    bb.BMasks  = zeros(Bitboard,SQUARE_NB)
    bb.RMagics = zeros(Bitboard,SQUARE_NB)
    bb.BMagics = zeros(Bitboard,SQUARE_NB)
    bb.RShifts = zeros(Uint32,SQUARE_NB)
    bb.BShifts = zeros(Uint32,SQUARE_NB)

    bb.SquareBB = Bitboard[bitboard(1<<s) for s = SQ_A1:SQ_H8]

    bb.BSFTable = zeros(Square, SQUARE_NB)
    for s = SQ_A1:SQ_H8
        bb.BSFTable[bsf_index(bb.SquareBB[s+1])+1] = s
    end

    bb.MS1BTable = zeros(Int32,256)
    for b = 1:255
        bb.MS1BTable[b] = (more_than_one(bitboard(b)) > 0) ? bb.MS1BTable[b-1]: lsb(bb, bitboard(b))
    end

    bb.FileBB = Bitboard[FileABB,FileBBB,FileCBB,FileDBB,FileEBB,FileFBB,FileGBB,FileHBB]
    bb.RankBB = Bitboard[Rank1BB,Rank2BB,Rank3BB,Rank4BB,Rank5BB,Rank6BB,Rank7BB,Rank8BB]

    bb.AdjacentFilesBB = Bitboard[(f > FILE_A ? bb.FileBB[f] : 0) | (f < FILE_H ? bb.FileBB[f + 2] : 0) for f = FILE_A:FILE_H]

    bb.InFrontBB = zeros(Bitboard, COLOR_NB, RANK_NB)
    for r = RANK_1:(RANK_8-1)
        bb.InFrontBB[BLACK+1,r+1+1] = bitboard(bb.InFrontBB[BLACK+1,r+1] | bb.RankBB[r+1])
        bb.InFrontBB[WHITE+1,r+1] = bitboard(~bb.InFrontBB[BLACK+1,r+1+1])
    end

    bb.ForwardBB = zeros(Bitboard, COLOR_NB, SQUARE_NB)
    bb.PawnAttackSpan = zeros(Bitboard, COLOR_NB, SQUARE_NB)
    bb.PassedPawnMask = zeros(Bitboard, COLOR_NB, SQUARE_NB)
    for c = WHITE:BLACK
        for s = SQ_A1:SQ_H8
            bb.ForwardBB[c+1,s+1] = bb.InFrontBB[c+1,rank_of(s)+1] & bb.FileBB[file_of(s)+1]
            bb.PawnAttackSpan[c+1,s+1] = bb.InFrontBB[c+1,rank_of(s)+1] & bb.AdjacentFilesBB[file_of(s)+1]
            bb.PassedPawnMask[c+1,s+1] = bb.ForwardBB[c+1,s+1] | bb.PawnAttackSpan[c+1,s+1]
        end
    end

    bb.SquareDistance = zeros(Int32, SQUARE_NB, SQUARE_NB)
    bb.DistanceRingsBB= zeros(Bitboard, SQUARE_NB,8)
    for s1 = SQ_A1:SQ_H8
        for s2 = SQ_A1:SQ_H8
            if s1 != s2
                bb.SquareDistance[s1+1,s2+1] = int32(max(file_distance(s1, s2), rank_distance(s1, s2)))
                bb.DistanceRingsBB[s1+1, bb.SquareDistance[s1+1,s2+1] - 1+1] |= bb.SquareBB[s2+1]
            end
        end
    end

    steps = Int32[0  0   0   0   0   0   0   0;
                  7  9   0   0   0   0   0   0;
                  17 15  10  6  -6 -10 -15 -17;
                  0  0   0   0   0   0   0   0;
                  0  0   0   0   0   0   0   0;
                  0  0   0   0   0   0   0   0;                  
                  9  7  -7  -9   8   1  -1  -8]::Array{Int32,2}

    steplast = Int32[-1,1,7,-1,-1,-1,7]::Array{Int32,1}

    bb.StepAttacksBB = zeros(Bitboard, PIECE_NB, SQUARE_NB)

    for c = WHITE:BLACK
        for pt = PAWN:KING
            for s = SQ_A1:SQ_H8
                for i = 1:steplast[pt+1]+1
                    # println(c,",",pt,",",s,":",i)
                    wstep = steps[pt+1,i]
                    bstep = -steps[pt+1,i]
                    ste = (c == WHITE) ? wstep: bstep
                    to = squareC(s + ste)

                    if is_ok(to) && (square_distance(bb, s, to) < 3)
                        bb.StepAttacksBB[make_piece(c, pt)+1,s+1] |= bb.SquareBB[to+1]
                    end
                end
            end
        end
    end

    RDeltas = Square[DELTA_N,  DELTA_E,  DELTA_S,  DELTA_W]
    BDeltas = Square[DELTA_NE, DELTA_SE, DELTA_SW, DELTA_NW]

    init_magics(bb, ROOK, bb.RTable, bb.RAttacks, bb.RMagics, bb.RMasks, bb.RShifts, RDeltas)
    init_magics(bb, BISHOP, bb.BTable, bb.BAttacks, bb.BMagics, bb.BMasks, bb.BShifts, BDeltas)

    bb.PseudoAttacks = zeros(Bitboard, PIECE_TYPE_NB, SQUARE_NB)
    bb.LineBB = zeros(Bitboard, SQUARE_NB, SQUARE_NB)
    bb.BetweenBB = zeros(Bitboard, SQUARE_NB, SQUARE_NB)

    for s1 = SQ_A1:SQ_H8
        bb.PseudoAttacks[BISHOP+1,s1+1] = attacks_bb(bb, BISHOP, s1, bitboard(0))
        bb.PseudoAttacks[QUEEN+1,s1+1]  = attacks_bb(bb, BISHOP, s1, bitboard(0))

        bb.PseudoAttacks[ROOK+1,s1+1]   = attacks_bb(bb, ROOK,   s1, bitboard(0))
        bb.PseudoAttacks[QUEEN+1,s1+1] |= attacks_bb(bb, ROOK,   s1, bitboard(0))

        for s2 = SQ_A1:SQ_H8
            pc = NO_PIECE
            if (bb.PseudoAttacks[BISHOP+1,s1+1] & bb.SquareBB[s2+1]) > bitboard(0)
                pc = W_BISHOP
            elseif (bb.PseudoAttacks[ROOK+1,s1+1] & bb.SquareBB[s2+1]) > bitboard(0)
                pc = W_ROOK
            end

            if pc == NO_PIECE
                continue
            end
            bb.LineBB[s1+1,s2+1] = (attacks_bb(bb, pc, s1, bitboard(0)) & attacks_bb(bb, pc, s2, bitboard(0)))| bb.SquareBB[s1+1] | bb.SquareBB[s2+1]
            bb.BetweenBB[s1+1,s2+1] = attacks_bb(bb, pc, s1, bb.SquareBB[s2+1]) & attacks_bb(bb, pc, s2, bb.SquareBB[s1+1])
        end
    end

    testBB(bb)
end

# /// Functions for computing sliding attack bitboards. Function attacks_bb() takes
# /// a square and a bitboard of occupied squares as input, and returns a bitboard
# /// representing all squares attacked by Pt (bishop or rook) on the given square.
function magic_index(bb::ContextBB, Pt::PieceType, s::Square, occ::Bitboard)
    Masks  = (Pt == ROOK)? bb.RMasks: bb.BMasks
    Magics = (Pt == ROOK)? bb.RMagics: bb.BMagics
    Shifts = (Pt == ROOK)? bb.RShifts: bb.BShifts

    uint(((occ & Masks[s+1]) * Magics[s+1]) >>> Shifts[s+1])
end

function attacks_bb(bb::ContextBB, Pt::PieceType, s::Square, occ::Bitboard)
    ar = (Pt == ROOK ? bb.RAttacks : bb.BAttacks)
    (ar[s+1])[magic_index(bb, Pt, s, occ)+1]
end

function sliding_attack(bb::ContextBB,
                        deltas::Array{Square,1},
                        sq::Square,
                        occupied::Bitboard)
    attack = bitboard(0)
    for i = 0:(4-1)
        s = squareC(sq + deltas[i+1])
        dis = 
        while is_ok(s) && is_ok(squareC(s - deltas[i+1])) && (square_distance(bb, s, squareC(s - deltas[i+1])) == int32(1))
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

# init_magics() computes all rook and bishop attacks at startup. Magic
# bitboards are used to look up attacks of sliding pieces. As a reference see
# chessprogramming.wikispaces.com/Magic+Bitboards. In particular, here we
# use the so called "fancy" approach.
function init_magics(bb::ContextBB,
                     Pt::PieceType,
                     table::Array{Bitboard,1},
                     attacks::Array{Array{Bitboard,1},1},
                     magics::Array{Bitboard,1},
                     masks::Array{Bitboard,1},
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

    MagicBoosters = Int32[969 1976 2850  542 2069 2852 1708  164;
                          3101 552 3555  926  834   26 2131 1117]::Array{Int32,2}

    rk = RKISS()
    occupancy = zeros(Bitboard,4096)
    reference = zeros(Bitboard,4096)
    b = bitboard(0)

    # attacks[s] is a pointer to the beginning of the attacks table for square 's'
    attacks[SQ_A1+1] = table

    for s = SQ_A1:SQ_H8
        # Board edges are not considered in the relevant occupancies
        edges = ((Rank1BB | Rank8BB) & ~rank_bb_sq(bb,s)) | ((FileABB | FileHBB) & ~file_bb_sq(bb,s))::Bitboard

        # Given a square 's', the mask is the bitboard of sliding attacks from
        # 's' computed on an empty board. The index must be big enough to contain
        # all the attacks for each possible subset of the mask and so is 2 power
        # the number of 1s of the mask. Hence we deduce the size of the shift to
        # apply to the 64 or 32 bits word to get the index.
        masks[s+1]  = sliding_attack(bb, deltas, s, bitboard(0)) & ~edges
        shifts[s+1] = ((Is64Bit == true)? 64 : 32) - popcount(masks[s+1])

        println("s=",s)
        # println("shifts=", shifts[s+1])
        # println(pretty2(bb,masks[s+1]))

        # Use Carry-Rippler trick to enumerate all subsets of masks[s] and
        # store the corresponding sliding attack bitboard in reference[].
        size = 0
        begin
            occupancy[size+1] = b
            size += 1
            reference[size] = sliding_attack(bb, deltas, s, b) # intentionally size is not size+1
            b = (b - masks[s+1]) & masks[s+1]
        end
        while b > bitboard(0)
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

        #if (s < SQ_H8)
        #    attacks[s+1+1] = zeros(Bitboard,size)
        #end
        booster = MagicBoosters[Is64Bit?2:1,rank_of(s)+1]

        # Find a magic for square 's' picking up an (almost) random number
        # until we find the one that passes the verification test.

        idx = 0

        begin
            magics[s+1] = magic_rand(Bitboard,rk,booster)
            while popcount((magics[s+1] * masks[s+1]) >>> 56) < 6
                magics[s+1] = magic_rand(Bitboard,rk,booster)
            end

            attacks[s+1] = zeros(Bitboard,size)

            for i = 0:(size-1)
                idx = i
                magIdx = magic_index(bb, Pt, s, occupancy[i+1]) + 1
                attack = (attacks[s+1])[magIdx]

                if attack > bitboard(0) && attack != reference[i+1]
                    break
                end
                (attacks[s+1])[magIdx] = reference[i+1]
            end
            if idx == (size-1)
                idx = size
                #println("idx=",idx)
                #println(pretty2(bb,reference[idx]))
            end
        end
        while idx < size
            magics[s+1] = magic_rand(Bitboard,rk,booster)
            while popcount((magics[s+1] * masks[s+1]) >>> 56) < 6
                magics[s+1] = magic_rand(Bitboard,rk,booster)
            end

            attacks[s+1] = zeros(Bitboard,size)

            for i = 0:(size-1)
                idx = i
                magIdx = magic_index(bb, Pt, s, occupancy[i+1]) + 1
                attack = (attacks[s+1])[magIdx]

                if attack > bitboard(0) && attack != reference[i+1]
                    break
                end
                (attacks[s+1])[magIdx] = reference[i+1]
            end
            if idx == (size-1)
                idx = size
            end
        end
    end
    SaveMagicsUsingSerialize(bb, Pt)
end
