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
const QUIET_CHECKS = int32(2) # pseudo-legal, non-captures and knight underpromotions that give check (Shogi has no underpromotions)
                              #               may be with drops that give check
const EVASIONS     = int32(3) # pseudo-legal, check evasions (when side to move is in check), with check evasion drops
const NON_EVASIONS = int32(4) # pseudo-legal, captures and non-captures, with drops
const LEGAL        = int32(5) # legal,        all the legal moves

using IProfile

# in SMoveList, cur and last are index from beginning, mlist = Array{SExtMove,1}
type SMoveList
    cur::Int32
    last::Int32
    mlist::Array{SExtMove,1}
    function SMoveList(pos::SPosition, bb::SContextBB, gt::GenType)
        n = new() # with garbages
        n.cur  = 0 # zero origin
        n.last = 0 # zero origin
        n.mlist = SExtMove[]::Array{SExtMove,1}
        sizehint(n.mlist, 600)
        n.last = generate(gt, pos, bb, n, true) # only returns zero origin based last index of the array
        # no need to push SMOVE_NONE to the last of the array: because we already know the size of the array
        # println(n)
        n
    end
end

#@iprofile begin
function add!(ml::SMoveList, m::Int64, score::Int32 = int32(0))
    sem = SExtMove(m,score)
    inc(ml)
    push!(ml.mlist, sem)
    #ml.mlist[ml.cur].move = m
    #ml.mlist[ml.cur].score = score
    ml.last = int32(ml.last + 1)
    #println("move_to_san:", move_to_san(m))
end
#end

function inc(ml::SMoveList) # operator ++() in C++
    ml.cur = int32(ml.cur+1)
end

function getSMove(ml::SMoveList) # operator *() in C++
    #println("len=$(length(ml.mlist))", ", cur = ", "$cur")
    ml.mlist[(ml.cur)+1].move
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
    false
end

function move_to_san(m::SMove)
    from = from_sq(m)
    to   = to_sq(m)
    pt   = promotion_type(m)
    capt = captured_of(m)
    #println("capt = ", capt)
    tebanstr = (spiece(m) > B_OFFSET)? "△ ":"▲ "
    captstr = (capt > NO_PIECE_TYPE) ? KOMASTR_SHORT[capt]*"取り":""
    fromstr = square_to_jstring(from)
    tostr   = square_to_jstring(to)
    ptstr   = KOMASTR_SHORT[pt]
    
    if from == SSQ_DROP
        return string(tebanstr,"$(tostr)$(ptstr)打ち")
    else
        return string(tebanstr,"$(tostr)$(ptstr)(",fromstr,")",captstr)
    end
end

function CanBePromoted(from::Square, to::Square, p::Piece)
    pt = stype_of(p)
    if (pt > OU)||(pt == KI)||(pt == OU)
        return false
    end

    us = scolor_of(p)

    if us == WHITE
        return (from >= SSQ_A7)||((from < SSQ_A7)&&(to >= SSQ_A7))
    else # us == BLACK
        return (from <= SSQ_I3)||((from > SSQ_I3)&&(to <= SSQ_I3))
    end
end

function GetMoveMask(bb::SContextBB, p::Piece)
    bb.MoveMask[p+1]
end

#@iprofile begin
function drops_inner(mask::SBitboard, p::Piece, mlist::SMoveList)
    ls = LSBC(0,sbitboard(0))
    ui = uint32(0)
    while mask > sbitboard(0)
        pop_lsb(mask, ls)
        mask = ls.b
        to   = int32(ls.sq)
        ins = make(SSQ_DROP, to, p, ui, NO_PIECE_TYPE)
        add!(mlist, ins)
    end
end
#end

const UINT32ZERO = uint32(0)

function add_drop_moves(to::Int64, p::Piece, mlist::SMoveList)
    ins = make(SSQ_DROP, squareC(to), p,  UINT32ZERO, NO_PIECE_TYPE)
    add!(mlist, ins)
end

function generate_drops_inner(pos::SPosition, bb::SContextBB, Us::Color, pity::PieceType, p::Piece, mlist::SMoveList, mask::SBitboard, bi::SBitboard)
    if pos.capturedPieces[Us+1,pity+1] > 0
        while mask > sbitboard(0)
            to = trailing_zeros(mask)
            mask = mask & (mask-1)
            ra = srank_of(int32(to))
            if (pity == FU)&&(bb.DropTable[ra+1,p] == 1)&&(bi & bb.SquareBB[to+1] > sbitboard(0))
                add_drop_moves(to, p, mlist)
            elseif (pity == KY || pity == KE)&&(bb.DropTable[ra+1,p] == 1)
                add_drop_moves(to, p, mlist)
            elseif (pity == GI)||(pity == KI)||(pity == KA)||(pity == HI)
                add_drop_moves(to, p, mlist)
            else
                # do nothing
            end
        end
    else
        # do nothing
    end
end

#@iprofile begin
function generate_drops(Us::Color, gt::GenType, pos::SPosition, bb::SContextBB,
                        mlist::SMoveList, target::SBitboard, ci = 0)
    ui = uint32(0)

    if gt == CAPTURES
        return mlist.last
    end

    if gt != EVASIONS
        target = MaskOfBoard
    end

    pl = list(pos, Us, FU)
    bi = sbitboard(0)
    for sq in pl
        fi = sfile_of(sq)
        bi |= bb.FileBB[fi+1]
    end
    bi = ~bi & MaskOfBoard

    mask = ~pieces(pos) & target
    
    for pity = FU:HI
        generate_drops_inner(pos, bb, Us, pity, smake_piece(Us, pity), mlist, mask, bi)
    end

    mlist.last
end
#end

#@iprofile begin
function fumoves(from::Square, b::SBitboard, pos::SPosition, mlist::SMoveList, piece::Piece, ppiece::Piece)
    ls = LSBC(0,sbitboard(0))
    while b > sbitboard(0)
        #println("b=",bin(b))
        pop_lsb(b, ls)
        b = ls.b
        add!(mlist, make(from, int32(ls.sq), piece, uint32(0), stype_of(pos.board[ls.sq+1])))
        if CanBePromoted(from, int32(ls.sq), piece)
            add!(mlist, make(from, int32(ls.sq), ppiece, SPROMOTION, stype_of(pos.board[ls.sq+1])))
        end
    end
end
#end

function fu_gen(Us::Color, pos::SPosition, bb::SContextBB, mlist::SMoveList, target::SBitboard, piece::Piece, ppiece::Piece)
    pl = list(pos, Us, FU)
    for from in pl
        b = attacks_from(pos, bb, piece, from) & target
        fumoves(from, b, pos, mlist, piece, ppiece)
    end

end

# there are no castling related functions in MoveGen.jl: we focused on the Shogi Playing Program
function generate_fu_moves(Us::Color, gt::GenType, pos::SPosition, bb::SContextBB,
                           mlist::SMoveList, target::SBitboard, ci=0)
    Them = color(Us$1)
    piece = smake_piece(Us, FU)
    ppiece = smake_piece(Us, TO)

    enemies = (gt == EVASIONS)?pieces(pos,Them) & target: (gt == CAPTURES): target: pieces(pos,Them)

    if gt != CAPTURES
        #emptySquares = ((gt == QUIETS)||(gt == QUIET_CHECKS)) ? target: (~pieces(pos)&MaskOfBoard)
        fu_gen(Us, pos, bb, mlist, target, piece, ppiece)
    end
    mlist.last
end

# returns SlideType, isKY
function GetSlideType(Pt::PieceType)
    if Pt == KY
        return ROOK, true
    elseif Pt == HI || Pt == RY
        return ROOK, false
    elseif Pt == KA || Pt == UM
        return BISHOP, false
    end
    return (NO_PIECE_TYPE, false)
end

function generate_moves(Pt::PieceType, Checks::Bool, pos::SPosition, bb::SContextBB,
                        Us::Color, mlist::SMoveList, target::SBitboard, isSlide::Bool, ci=0)

    pl = list(pos, Us, Pt)

    for from in pl
        if Checks == true
            slideType, isKY = GetSlideType(Pt)

            if (isSlide == true && bb.PseudoAttacks[slideType+1,from+1] & ((isKY == true)?forward_bb(bb, c, ksq+1):MaskOfBoard) & ci.checkSq[Pt+1] > sbitboard(0))
                
                continue
            end

            if unlikely(ci.dcCandidates) && (ci.dcCandidastes & bb.SquareBB[from+1])
                continue
            end
        end

        b = ((isSlide == true) ? attacks_from(pos, bb, smake_piece(Us,Pt), from, true):
             attacks_from(pos, bb, smake_piece(Us, Pt), from))

        #println("from = ", square_to_jstring(from))
        #println("isSlide=",isSlide,"BB:")
        #println(pretty2(bb,b))

        #if isSlide == true
        #    println(KOMASTR[Pt],":",bin(b))
        #end
        b = b & target
        #if isSlide == true
        #println(KOMASTR[Pt],":",bin(b))
        #end

        if Checks == true
            b = b & ci.checkSQ[Pt+1]
        end

        #println("isSlide=",isSlide,"Checks=",Checks,"BB:")
        #println(pretty2(bb,b))
        
        piece = smake_piece(Us, Pt)
        ppiece = smake_piece(Us, pieceType(Pt+PT_PROMOTE_OFFSET))
        ls = LSBC(0,sbitboard(0))
        while b > sbitboard(0)
            pop_lsb(b, ls)
            b = ls.b
            #if stype_of(pos.board[ls.sq+1]) > NO_PIECE_TYPE
            #    println("*")
            #    println("HEX:", hex(smove(make(from, int32(ls.sq), piece, uint32(0), stype_of(pos.board[ls.sq+1])))))
            #    println("$(move_to_san(smove(make(from, int32(ls.sq), piece, uint32(0), stype_of(pos.board[ls.sq+1])))))")
            #end
            add!(mlist, make(from, int32(ls.sq), piece, uint32(0), stype_of(pos.board[ls.sq+1])))
            if CanBePromoted(from, int32(ls.sq), piece)
                add!(mlist, make(from, int32(ls.sq), ppiece, SPROMOTION, stype_of(pos.board[ls.sq+1])))
            end
        end
    end
    mlist.last
end

#@iprofile begin
function generate_all(Us::Color, gt::GenType, pos::SPosition, bb::SContextBB,
                      mlist::SMoveList, target::SBitboard, ci=0)
    Checks = bool(gt == QUIET_CHECKS)
    #println("target = ", bin(target))
    last = int64(0)
    last = generate_fu_moves(Us, gt, pos, bb, mlist, target, ci)
    last = generate_moves(KY, Checks, pos, bb, Us, mlist, target, true,  ci)
    last = generate_moves(KE, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(GI, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(KI, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(KA, Checks, pos, bb, Us, mlist, target, true,  ci)
    last = generate_moves(HI, Checks, pos, bb, Us, mlist, target, true,  ci)
    # OU is generated in later
    last = generate_moves(TO, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(NY, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(NK, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(NG, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(UM, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(RY, Checks, pos, bb, Us, mlist, target, false, ci)
    last = generate_moves(UM, Checks, pos, bb, Us, mlist, target, true,  ci)
    last = generate_moves(RY, Checks, pos, bb, Us, mlist, target, true,  ci)

    last = generate_drops(Us, gt, pos, bb, mlist, target, ci)

    if (gt != QUIET_CHECKS) && (gt != EVASIONS)
        ksq = king_square(pos, Us)
        b   = attacks_from(pos, bb, smake_piece(Us,OU), ksq) & target
        ls = LSBC(0,sbitboard(0))
        while b > sbitboard(0)
            pop_lsb(b, ls)
            b = ls.b
            add!(mlist, make(ksq, int32(ls.sq), smake_piece(Us, OU), uint32(0), stype_of(pos.board[ls.sq+1])))
        end
    end
    mlist.last
end
#end

function generate(gt::GenType, pos::SPosition, bb::SContextBB, mlist::SMoveList, dummy::Bool)
    if gt == CAPTURES # pseudo-legal, captures, queen promotions (in Shogi, may be all pieces), no drops
        return generate(gt, pos, bb, mlist)
    elseif gt == QUIETS # pseudo-legal, non-captures, underpromotions (Shogi has no underpromotions), with drops
        return generate(gt, pos, bb, mlist)
    elseif gt == QUIET_CHECKS # pseudo-legal, non-captures, knight underpromotions that give check
        # (Shogi has no underpromotions)
        # may be with drops that give check
        return generateQUIET_CHECKS(pos, bb, mlist)
    elseif gt == EVASIONS # pseudo-legal, check evasions (when side to move is in check), with check evasion drops
        return generateEVASIONS(pos, bb, mlist)
    elseif gt == NON_EVASIONS # pseudo-legal, captures and non-captures, with drops
        return generate(gt, pos, bb, mlist)
    elseif gt == LEGAL # legal,        all the legal moves
        return generateLEGAL(pos, bb, mlist)
    end
end

# gt = CAPTURES, QUIETS, NON_EVASIONS
#@iprofile begin
function generate(gt::GenType, pos::SPosition, bb::SContextBB, mlist::SMoveList)
    us = side_to_move(pos)

    target = sbitboard(0)
    if gt == CAPTURES
        target = pieces(pos,color(us$1))
    elseif gt == QUIETS
        target = ~pieces(pos) & MaskOfBoard
    elseif gt == NON_EVASIONS
        target = ~pieces(pos,us) & MaskOfBoard
    end

    if us == WHITE
        t = generate_all(WHITE, gt, pos, bb, mlist, target)
        #Profile.print()
        return t
    else
        t = generate_all(BLACK, gt, pos, bb, mlist, target)
        #Profile.print()
        return t
    end
end
#end

function generateQUIET_CHECKS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    return 0
end

# generate<EVASIONS> generates all pseudo-legal check evasions when the side
# to move is in check. Returns a pointer to the end of the move list.
function generateEVASIONS(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    #println("evasions")
    us = pos.sideToMove
    ksq = king_square(pos, us)
    sliderAttacks = sbitboard(0)
    che = attackers_to(pos, bb, ksq) & pieces(pos,color(side_to_move(pos)$1))
    sliders = che & (pieces(pos,KY)|pieces(pos,KA)|pieces(pos,HI)|pieces(pos,UM)|pieces(pos,RY))

    # Find all the squares attacked by slider checkers. We will remove them from
    # the king evasions in order to skip known illegal moves, which avoids any
    # useless legality checks later on.
    while sliders > sbitboard(0)
        checksq = trailing_zeros(sliders)
        sliders = sliders & (sliders-1)
        sliderAttacks |= bb.LineBB[checksq+1,ksq+1] $ bb.SquareBB[checksq+1]
    end

    # ki = attacks_from(pos, bb, smake_piece(us,OU), ksq)

    # boo = true
    # while ki > sbitboard(0)
    #     sq = squareC(trailing_zeros(ki))
    #     ki = ki & (ki - 1)
    #     if attackers_to(pos, bb, sq, MaskOfBoard) == sbitboard(0)
    #         boo = false
    #     end
    # end

    # tentatively commented out
    #if boo == true
    #    return mlist.last # check mate!
    #end

    # Generate evasions for king, capture and non capture moves
    b = attacks_from(pos, bb, smake_piece(us,OU), ksq) & (~pieces(pos,us)&MaskOfBoard) & (~sliderAttacks&MaskOfBoard)

    while b > sbitboard(0)
        sq = trailing_zeros(b)
        b = b & (b - 1)
        add!(mlist, make(ksq, squareC(sq), smake_piece(us, OU), UINT32ZERO, stype_of(pos.board[sq+1])))
    end

    if more_than_one(che) > sbitboard(0)
        return mlist.last # Double check, only a king move can save the day
    end

    # Generate blocking evasions or captures of the checking piece
    checksq = trailing_zeros(che)
    target = between_bb(bb, squareC(checksq), ksq) | bb.SquareBB[checksq+1]
    if us == WHITE
        t = generate_all(WHITE, EVASIONS, pos, bb, mlist, target)
        return t
    else
        t = generate_all(BLACK, EVASIONS, pos, bb, mlist, target)
        return t
    end
end

function filterPredicate(k::SExtMove, v::Bool)
    v
end

function generateLEGAL(pos::SPosition, bb::SContextBB, mlist::SMoveList)
    st = pos.st
    curr = 1
    ende = 0
    pinned = pinned_pieces(pos, bb, side_to_move(pos))
    ksq = king_square(pos, side_to_move(pos))

    #println("checkers:")
    #println(pretty2(bb,checkers(st)))

    che = attackers_to(pos, bb, ksq) & pieces(pos,color(side_to_move(pos)$1))

    ende = che > sbitboard(0) ? generateEVASIONS(pos, bb, mlist): generate(NON_EVASIONS, pos, bb, mlist) 
    #println("ende=$ende")

    newml = SExtMove[]::Array{SExtMove,1}
    sizehint(newml,ende)

    for sm in mlist.mlist
        #println("s1:", (from_sq(smove(sm.move)) == ksq)||(pinned > sbitboard(0)))
        #println("s2:", (!legal(pos, bb, smove(sm.move), pinned)))
        if !(((from_sq(smove(sm.move)) == ksq)||(pinned > sbitboard(0)))&&(!legal(pos, bb, smove(sm.move), pinned)))
            push!(newml,sm)
        else
            # println("ignored: $(move_to_san(smove(sm.move)))")
        end

    end

    mlist.mlist = poorSort(pos, bb, newml, che > sbitboard(0)) # reverse(newml)
    mlist.last = length(newml)
    # while curr != ende
    #     #println("hi")
    #     m = smove(mlist.mlist[curr].move)
    #     fsq = from_sq(m)
    #     #println("hi")
    #     if ((fsq==ksq) || (pinned>sbitboard(0)) || false) && !legal(pos, bb, m, pinned)
    #         #println("cur->move = (--end)->move")
    #         println("ignored: $(move_to_san(m))")
    #         splice!(mlist.mlist, curr)
    #         ende -= 1
    #         mlist.mlist[curr] = mlist.mlist[ende]
    #     else
    #         #println("curr=$curr, ende=$ende")
    #         curr += 1
    #     end
    # end
    mlist.last
end

function poorSort(pos::SPosition, bb::SContextBB, mlist::Array{SExtMove,1}, eva::Bool)
    li = mlist
    newList = SExtMove[]::Array{SExtMove,1}

    if eva == true # not sorting if node is in check
        return li
    end

    for em in li
        move = smove(em.move)
        em.score = 0
        b = attackers_to(pos, bb, king_square(pos, color(pos.sideToMove$1)))
        from = from_sq(move)
        if from == SSQ_DROP
            continue
        end
        c = bb.SquareBB[from+1]
        if (b & c) > sbitboard(0)
            em.score = 5000000
            push!(newList,em)
        end
    end

    # pick up capture moves
    for em in li
        move = smove(em.move)
        if piece_on(pos, to_sq(move)) > NO_PIECE
            em.score = 1000000
            push!(newList,em)
        end
    end
        
    # salvage other moves
    for em in li
        if em.score <= 0
            push!(newList,em)
        end
    end

    newList
end
