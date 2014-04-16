# generate<CAPTURES> generates all pseudo-legal captures and queen
# promotions. Returns a pointer to the end of the move list.
#
# generate<QUIETS> generates all pseudo-legal non-captures and
# underpromotions. Returns a pointer to the end of the move list.
#
# generate<QUIET_CHECKS> generates all pseudo-legal non-captures and knight
# underpromotions that give check. Returns a pointer to the end of the move list.
#
# generate<EVASIONS> generates all pseudo-legal check evasions when the side
# to move is in check. Returns a pointer to the end of the move list.
#
# generate<NON_EVASIONS> generates all pseudo-legal captures and
# non-captures. Returns a pointer to the end of the move list.
#
# generate<LEGAL> generates all the legal moves in the given position

typealias GenType Int32

const CAPTURES     = int32(0) # pseudo-legal, captures, queen promotions (in Shogi, may be all pieces), no drops
const QUIETS       = int32(1) # pseudo-legal, non-captures, underpromotions (Shogi has no underpromotions), with drops
const QUIET_CHECKS = int32(2) # pseudo-legal, non-captures, knight underpromotions that give check (Shogi has no underpromotions)
                              #               may be with drops that give check
const EVASIONS     = int32(3) # pseudo-legal, check evasions (when side to move is in check), with check evasion drops
const NON_EVASIONS = int32(4) # pseudo-legal, captures and non-captures, with drops
const LEGAL        = int32(5) # legal,        all the legal moves


# in SMoveList, cur and last are index from beginning, mlist = Array{SExtMove,1}
type SMoveList
    cur::Int32
    last::Int32
    mlist::Array{SExtMove,1}
    function SMoveList(pos::SPosition, bb::SContextBB, gt::GenType)
        n = new() # with garbages
        n.cur = 0 # zero origin
        n.mlist = SExtMove[]::Array{SExtMove,1}
        n.last = generate(pos, gt, bb, n.mlist) # only returns zero origin based last index of the array
        # no need to push SMOVE_NONE to the last of the array: because we already know the size of the array
        n
    end
end

function inc(ml::SMoveList) # operator ++() in C++
    ml.cur = int32(ml.cur+1)
end

function getSMove(ml::SMoveList) # operator *() in C++
    ml.mlist[cur+1].move
end

function size(ml::SMoveList) # size() in C++
    int32(ml.last + 1)
end

function contains(ml::SMoveList, m::SMove) # contains(Move m) in C++
    for exm in ml.mlist
        if exm.move == m
            return true
        end
    end
    return false
end

# there are no castling related functions in MoveGen.jl: we focused on the Shogi Playing Program

function generate(pos::SPosition, gt::GenType, bb::SContextBB, mlist::SMoveList)
    if gt == CAPTURES # pseudo-legal, captures, queen promotions (in Shogi, may be all pieces), no drops
        return generateCAPTURES(pos, bb, mlist)
    elseif gt == QUIETS # pseudo-legal, non-captures, underpromotions (Shogi has no underpromotions), with drops
        return generateQUIETS(pos, bb, mlist)
    elseif gt == QUIET_CHECKS # pseudo-legal, non-captures, knight underpromotions that give check
        # (Shogi has no underpromotions)
        # may be with drops that give check
        return generateQUIET_CHECKS(pos, bb, mlist)
    elseif gt == EVASIONS # pseudo-legal, check evasions (when side to move is in check), with check evasion drops
        return generateEVASIONS(pos, bb, mlist)
    elseif gt == NON_EVASIONS # pseudo-legal, captures and non-captures, with drops
        return generateNON_EVASIONS(pos, bb, mlist)
    elseif gt == LEGAL # legal,        all the legal moves
        return generateLEGAL(pos, bb, mlist)
    end
end

function generateCAPTURES(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

function generateQUIETS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

function generateQUIET_CHECKS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

function generateEVASIONS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

function generateNON_EVASIONS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

function generateLEGAL(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    st = pos.st
    cur = int32(0)
    ende = int32(0)
    pinned = pinned_pieces(pos, bb, pos.side_to_move())
    ksq = king_square(pos, pos.side_to_move())

    ende = checkers(st) > sbitboard(0) ? generateEVASIONS(pos, bb, mlist): generateNON_EVASIONS(pos, bb, mlist) 

    while cur != ende
        if (pinned || from_sq(getSMove(mlist)) || false) && !legal(pos, from_sq(getSMove(mlist)), pinned)
            println("cur->move = (--end)->move")
        else
            cur = int32(cur+1)
        end
    end

    ende
end
