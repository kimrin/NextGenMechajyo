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

function lsb(bb::SContextBB, b::SBitboard)
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

    # for c = WHITE:BLACK
    #     for s = SSQ_A1:SSQ_I9
    #         println((c==WHITE)?"WHITE":"BLACK", " ", "s=", s)
    #         println(pretty2(bb, bb.ForwardBB[c+1,s+1]))
    #         println(pretty2(bb, bb.PawnAttackSpan[c+1,s+1]))
    #         println(pretty2(bb, bb.PassedPawnMask[c+1,s+1]))
    #     end
    # end

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
        bb.InFrontBB[WHITE+1,r+1] = sbitboard(~bb.InFrontBB[BLACK+1,r+1+1])
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

    testBB(bb)
end

# /// Functions for computing sliding attack bitboards. Function attacks_bb() takes
# /// a square and a bitboard of occupied squares as input, and returns a bitboard
# /// representing all squares attacked by Pt (bishop or rook) on the given square.
function magic_index(bb::SContextBB, Pt::PieceType, s::Square, occ::SBitboard)
    Masks  = (Pt == ROOK)? bb.RMasks: bb.BMasks
    Magics = (Pt == ROOK)? bb.RMagics: bb.BMagics
    Shifts = (Pt == ROOK)? bb.RShifts: bb.BShifts

    uint((((occ & Masks[s+1]) * Magics[s+1]) & MaskOfBoard) >>> Shifts[s+1])
end

function attacks_bb(bb::SContextBB, Pt::PieceType, s::Square, occ::SBitboard)
    ar = (Pt == ROOK ? bb.RAttacks : bb.BAttacks)
    (ar[s+1])[magic_index(bb, Pt, s, occ)+1]
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


    # original magic boosters: for RKiss
    MagicBoosters = Int32[969 1976 2850  542 2069 2852 1708  164;
                          3101 552 3555  926  834   26 2131 1117]::Array{Int32,2}

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

        #println("s=",s)
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

        #println("size=",size)

        # Set the offset for the table of the next square. We have individual
        # table sizes for each square with "Fancy Magic Bitboards".
        # (original C++ code)
        #         if (s < SQ_H8)
        #             attacks[s + 1] = attacks[s] + size;
        if (s < SSQ_I9)
            attacks[s+1+1] = zeros(SBitboard,size)
        end
        booster = int32(1023) # MagicBoosters[Is64Bit?2:1,rank_of(s)+1] # calculate in later...

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
                attack = (attacks[s+1])[magic_index(bb, Pt, s, occupancy[i+1]) + 1]

                if attack > sbitboard(0) && attack != reference[i+1]
                    break
                end
                attack = reference[i+1]
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
                attack = (attacks[s+1])[magic_index(bb, Pt, s, occupancy[i+1]) + 1]

                if attack > sbitboard(0) && attack != reference[i+1]
                    break
                end
                attack = reference[i+1]
                #println("idx=",idx)
            end
            if idx == (size-1)
                idx = size
                #println("idx=",idx)
            end
        end
    end
end
