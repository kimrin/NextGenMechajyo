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
    bb.RankBB[rank_of(s)+1]
end

function rank_bb(bb::SContextBB, r::Rank)
    bb.RankBB[r+1]
end

function file_bb_sq(bb::SContextBB, s::Square)
    bb.FileBB[file_of(s)+1]
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

    for c = WHITE:BLACK
        for pt = FU:RY
            for s = SSQ_A1:SSQ_I9
                println("c=",c,",pt=",pt,",sq=",s)
                println(pretty2(bb, bb.StepAttacksBB[smake_piece(c, pt)+1,s+1]))
            end
        end
    end
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

    testBB(bb)
end

