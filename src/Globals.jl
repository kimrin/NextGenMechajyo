# The TTEntry is the 128 bit transposition table entry, defined as below:
#
# key: 32 bit
# move: 16 bit
# bound type: 8 bit
# generation: 8 bit
# value: 16 bit
# depth: 16 bit
# static value: 16 bit

type TTEntry
    key32::Uint32
    move32::SMove
    bound8::Uint8
    generation8::Uint8
    value16::Int16
    depth16::Int16
    evalValue::Int16

    function TTEntry()
        new() # passing with garbage
    end
end

# One thing should avoid in Julia language is, the global variables.
# So we are gathering all global variables into this Context class
# and carry these references to everywhere.

type ContextBB
    RMasks::Array{Bitboard,1}
    RMagics::Array{Bitboard,1}
    RAttacks::Array{Array{Bitboard,1},1}
    RShifts::Array{Uint32,1}

    BMasks::Array{Bitboard,1}
    BMagics::Array{Bitboard,1}
    BAttacks::Array{Array{Bitboard,1},1}
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

    calcMagic::Bool

    function ContextBB()
        new() # return with garbage
    end
end

type SContextBB
    RMasks::Array{SBitboard,1}
    RMagics::Array{SBitboard,1}
    RAttacks::Array{Array{SBitboard,1},1}
    RShifts::Array{Uint32,1}

    BMasks::Array{SBitboard,1}
    BMagics::Array{SBitboard,1}
    BAttacks::Array{Array{SBitboard,1},1}
    BShifts::Array{Uint32,1}

    SquareBB::Array{SBitboard,1}
    FileBB::Array{SBitboard,1}
    RankBB::Array{SBitboard,1}
    AdjacentFilesBB::Array{SBitboard,1}
    InFrontBB::Array{SBitboard,2}
    StepAttacksBB::Array{SBitboard,2}
    BetweenBB::Array{SBitboard,2}
    LineBB::Array{SBitboard,2}
    DistanceRingsBB::Array{SBitboard,2}
    ForwardBB::Array{SBitboard,2}
    PassedPawnMask::Array{SBitboard,2}
    PawnAttackSpan::Array{SBitboard,2}
    PseudoAttacks::Array{SBitboard,2}

    SquareDistance::Array{Int32,2}

    MS1BTable::Array{Int32,1}
    BSFTable::Array{Square,1}
    RTable::Array{SBitboard,1}
    BTable::Array{SBitboard,1}

    calcMagic::Bool

    MoveMask::Array{SBitboard,1}
    DropTable::Array{Int64,2}
    DropList::Array{(Piece,PieceType),2}
    PieceValue::Array{Int64,1}

    TT::Dict{Uint64,TTEntry}
    generation::Int64

    function SContextBB()
        new() # return with garbage
    end
end

type ContextPos
    
    function ContextPos()
        new()
    end
end

type SContextPos
    
    function SContextPos()
        new()
    end
end

type Context
    bb::ContextBB
    sbb::SContextBB
    cpos::ContextPos
    scpos::SContextPos
    function Context(game::Uint64)
        n = new()
        if game == Shogi
            sbb = SContextBB()
            n.sbb = sbb
            n.sbb.calcMagic = false
            scpos = SContextPos()
            n.scpos = scpos
        else
            bb = ContextBB()
            n.bb = bb
            n.bb.calcMagic = false
            cpos = ContextPos()
            n.cpos = cpos
        end
        return n
    end
end

include("BitBoardChess.jl")
include("BitBoardShogi.jl")
