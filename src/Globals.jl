# One thing should avoid in Julia language is, the global variables.
# So we are gathering all global variables into this Context class
# and carry these references to everywhere.

type ContextBB
    RMasks::Array{Bitboard,1}
    RMagics::Array{Bitboard,1}
    RAttacks::Array{Bitboard,2}
    RShifts::Array{Uint32,1}

    BMasks::Array{Bitboard,1}
    BMagics::Array{Bitboard,1}
    BAttacks::Array{Bitboard,2}
    BShifts::Array{Uint32,1}

    SquareBB::Array{Bitboard,1}
    FileBB::Array{Bitboard,1}
    RankBB::Array{Bitboard,1}
    AdjacentFilesBB::Array{Bitboard,1}
    InFrontBB::Array{Bitboard,2}
    StepAttacksBB::Array{Bitboard,2}
    BetweenBB::Array{Bitboard,2}
    LineBB::Array{Bitboard,2}
    DistanceRingsBB::Array{Bitboard,2}
    ForwardBB::Array{Bitboard,2}
    PassedPawnMask::Array{Bitboard,2}
    PawnAttackSpan::Array{Bitboard,2}
    PseudoAttacks::Array{Bitboard,2}

    SquareDistance::Array{Int32,2}

    MS1BTable::Array{Int32,1}
    BSFTable::Array{Square,1}
    RTable::Array{Bitboard,1}
    BTable::Array{Bitboard,1}

    function ContextBB()
        new() # return with garbage
    end
end

type Context
    bb::ContextBB
    function Context(game::Uint64)
        n = new()
        bb = ContextBB()
        n.bb = bb
        return n
    end
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

function init(bb::ContextBB)
    bb.SquareBB = Bitboard[bitboard(1<<s) for s = SQ_A1:SQ_H8]

    sqStringArray = [pretty2(bb,bb.SquareBB[s+1]) for s = SQ_A1:SQ_H8]

    # for idxxx = SQ_A1:SQ_H8
    #     println(square_to_string(idxxx))
    #     println(sqStringArray[idxxx+1])
    # end

    bb.BSFTable = zeros(Square, SQUARE_NB)
    for s = SQ_A1:SQ_H8
        bb.BSFTable[bsf_index(bb.SquareBB[s+1])+1] = s
    end

    # for s = SQ_A1:SQ_H8
    #     println(square_to_string(s))
    #     println(pretty2(bb,bb.SquareBB[bb.BSFTable[s+1] + 1]))
    # end

    bb.MS1BTable = zeros(Int32,256)
    for b = 1:255
        bb.MS1BTable[b] = (more_than_one(bitboard(b)) > 0) ? bb.MS1BTable[b-1]: lsb(bb, bitboard(b))
        println(b,": ", bb.MS1BTable[b])
    end

    bb.FileBB = Bitboard[FileABB,FileBBB,FileCBB,FileDBB,FileEBB,FileFBB,FileGBB,FileHBB]
    bb.RankBB = Bitboard[Rank1BB,Rank2BB,Rank3BB,Rank4BB,Rank5BB,Rank6BB,Rank7BB,Rank8BB]

    for f = FILE_A:FILE_H
        println(pretty2(bb, bb.FileBB[f+1]))
    end
    for r = RANK_1:RANK_8
        println(pretty2(bb, bb.RankBB[r+1]))
    end

    bb.AdjacentFilesBB = Bitboard[(f > FILE_A ? bb.FileBB[f] : 0) | (f < FILE_H ? bb.FileBB[f + 2] : 0) for f = FILE_A:FILE_H]

    bb.InFrontBB = zeros(Bitboard, COLOR_NB, RANK_NB)
    for r = RANK_1:(RANK_8-1)
        bb.InFrontBB[BLACK+1,r+1+1] = bb.InFrontBB[BLACK+1,r+1] | bb.RankBB[r+1]
        bb.InFrontBB[WHITE+1,r+1] = ~bb.InFrontBB[BLACK+1,r+1+1]
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
                bb.SquareDistance[s1+1,s2+1] = max(file_distance(s1, s2), rank_distance(s1, s2))
                bb.DistanceRingsBB[s1+1, bb.SquareDistance[s1+1,s2+1] - 1+1] |= s2
            end
        end
    end
end



# void Bitboards::init() {

#   int steps[][9] = { {}, { 7, 9 }, { 17, 15, 10, 6, -6, -10, -15, -17 },
#                      {}, {}, {}, { 9, 7, -7, -9, 8, 1, -1, -8 } };

#   for (Color c = WHITE; c <= BLACK; ++c)
#       for (PieceType pt = PAWN; pt <= KING; ++pt)
#           for (Square s = SQ_A1; s <= SQ_H8; ++s)
#               for (int i = 0; steps[pt][i]; ++i)
#               {
#                   Square to = s + Square(c == WHITE ? steps[pt][i] : -steps[pt][i]);

#                   if (is_ok(to) && square_distance(s, to) < 3)
#                       StepAttacksBB[make_piece(c, pt)][s] |= to;
#               }

#   Square RDeltas[] = { DELTA_N,  DELTA_E,  DELTA_S,  DELTA_W  };
#   Square BDeltas[] = { DELTA_NE, DELTA_SE, DELTA_SW, DELTA_NW };

#   init_magics(RTable, RAttacks, RMagics, RMasks, RShifts, RDeltas, magic_index<ROOK>);
#   init_magics(BTable, BAttacks, BMagics, BMasks, BShifts, BDeltas, magic_index<BISHOP>);

#   for (Square s1 = SQ_A1; s1 <= SQ_H8; ++s1)
#   {
#       PseudoAttacks[QUEEN][s1]  = PseudoAttacks[BISHOP][s1] = attacks_bb<BISHOP>(s1, 0);
#       PseudoAttacks[QUEEN][s1] |= PseudoAttacks[  ROOK][s1] = attacks_bb<  ROOK>(s1, 0);

#       for (Square s2 = SQ_A1; s2 <= SQ_H8; ++s2)
#       {
#           Piece pc = (PseudoAttacks[BISHOP][s1] & s2) ? W_BISHOP :
#                      (PseudoAttacks[ROOK][s1]   & s2) ? W_ROOK   : NO_PIECE;

#           if (pc == NO_PIECE)
#               continue;

#           LineBB[s1][s2] = (attacks_bb(pc, s1, 0) & attacks_bb(pc, s2, 0)) | s1 | s2;
#           BetweenBB[s1][s2] = attacks_bb(pc, s1, SquareBB[s2]) & attacks_bb(pc, s2, SquareBB[s1]);
#       }
#   }
# }
