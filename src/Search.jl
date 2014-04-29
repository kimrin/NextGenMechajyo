# thinking time (flat)
const MAXTHINKINGTIME = 12 # (secs)

using IProfile

# NodeType
const Root            = 0
const PV              = 1
const NonPV           = 2
const SplitPointRoot  = 3
const SplitPointPV    = 4
const SplitPointNonPV = 5

# RootMove struct is used for moves at the root of the tree. For each root
# move we store a score, a node count, and a PV (really a refutation in the
# case of moves which fail low). Score is normally set at -VALUE_INFINITE for
# all non-pv moves.
type RootMove
    score::Int64
    prevScore::Int64
    pv::Array{SMove,1}

    function RootMove(m::SMove)
        n = new()
        n.score = -VALUE_INFINITE
        n.prevScore = -VALUE_INFINITE
        n.pv = SMove[]::Array{SMove,1}
        push!(n.pv, m)
        sizehint(n.pv, 600)

        n
    end
end

function perft(pos::SPosition, bb::SContextBB, depth::Int64)
    st = SStateInfo()
    cnt = 0
    #ci = SCheckInfo(pos,bb)

    leaf = (depth == 2 * ONE_PLY)

    sml = SMoveList(pos, bb, LEGAL)    
    for sm in sml.mlist
        move = smove(sm.move)
#        println("$depth: $(move_to_san(move))")
        if captured_of(move) == OU
            throw(string("illegal move:", move_to_san(move)))
        end
    end
    for sm in sml.mlist
        move = smove(sm.move)
        do_move(pos, bb, move, st)
        #pretty(pos, move)
        #println("$depth: $(move_to_san(move))")
        cnt += leaf ? length((SMoveList(pos, bb, LEGAL)).mlist): perft(pos, bb, depth - ONE_PLY)
        undo_move(pos, bb, move)
    end
    
    cnt
end

function do_redo_test(pos::SPosition, bb::SContextBB, depth::Int64)
    st = SStateInfo()
    cnt = 0
    #ci = SCheckInfo(pos,bb)

    leaf = (depth == 2 * ONE_PLY)

    sml = SMoveList(pos, bb, LEGAL)    
    idx = 1
    for sm in sml.mlist
        move = smove(sm.move)
        if idx == idx # for all moves
            do_move(pos, bb, move, st)
            pretty(pos, move)
            println("$(move_to_san(move))")
            undo_move(pos, bb, move)
        end
        idx += 1
    end
    
    cnt
end

function startThinking(pos::SPosition, bb::SContextBB, sock::Base.TcpSocket)
    pos.SearchTime = time_ns() # As early as possible
    RootColor = side_to_move(pos)
    st = SStateInfo()
    rootMoveList = SMoveList(pos, bb, LEGAL)
    RootMoves = RootMove[]::Array{RootMove,1}
    for sm in rootMoveList.mlist
        push!(RootMoves, RootMove(smove(sm.move)))
        #println("$(move_to_san(smove(sm.move)))")
    end

    m = id_loop(pos, bb, sock, RootMoves); # Let's start searching !

    # v = shuffle(sml.mlist)
    # if length(v) <= 0
    #     println(sock, "bestmove resign")
    #     return
    # end

    # m = smove(v[1].move)

    if m == SMOVE_NONE
        println(sock, "bestmove resign")
    else
        bestMove = move_to_usi(pos, bb, m)

        println(sock, "bestmove ", bestMove)

        do_move(pos, bb, m, st)
        pretty(pos,m)
        println("$(move_to_san(m))")
        println("eval = ", EvalMaterial(pos,bb))
        undo_move(pos, bb, m)
    end
end

function id_loop(pos::SPosition, bb::SContextBB, sock::Base.TcpSocket, RootMoves::Array{RootMove,1})
    bestValue = -VALUE_INFINITE
    alpha     = -VALUE_INFINITE
    beta      = VALUE_INFINITE
    delta     = -VALUE_INFINITE
    depth     = 0
    BestMoveChanges = 0
    new_search(bb)
    empty!(bb.TT)
    pos.nodes = 0
    pos.stop = false

    while  depth <= MAX_PLY
        BestMoveChanges *= 0.5
        i = 1
        for rm in RootMoves
            RootMoves[i].prevScore = RootMoves[i].score
            i += 1
        end

        if pos.stop == true
            break
        end
        
        for PVIdx = 1:1
            # Reset aspiration window starting size
            if depth >= 2
                delta = value(16)
                alpha = max(RootMoves[PVIdx].prevScore - delta,-VALUE_INFINITE)
                beta  = min(RootMoves[PVIdx].prevScore + delta, VALUE_INFINITE)
            end

            # Start with a small aspiration window and, in the case of a fail
            # high/low, re-search with a bigger window until we're not failing
            # high/low anymore.
            while true
                bestValue = searchX(Root, pos, bb, 0, value(alpha), value(beta), depth * ONE_PLY, false, 0, RootMoves) # ss is dummy

                # Bring the best move to the front. It is critical that sorting
                # is done with a stable algorithm because all the values but the
                # first and eventually the new best one are set to -VALUE_INFINITE
                # and we want to keep the same order for all the moves except the
                # new PV that goes to the front. Note that in case of MultiPV
                # search the already searched PV lines are preserved.

                #   std::stable_sort(RootMoves.begin() + PVIdx, RootMoves.end());

                # Write PV back to transposition table in case the relevant
                # entries have been overwritten during the search.
                for i = 1:1
                    #insert_pv_in_tt(pos, bb, RootMoves[i]
                end

                # If search has been stopped break immediately. Sorting and
                # writing PV back to TT is safe because RootMoves is still
                # valid, although it refers to previous iteration.
                if pos.stop == true
                    break
                end

                # When failing high/low give some update (without cluttering
                # the UI) before a re-search.
                if (  (bestValue <= alpha || bestValue >= beta)
                    && time_ns() - pos.SearchTime > (1000000000*3))

                    uci_pv(pos, bb, depth, value(alpha), value(beta), int64(bestValue), sock, RootMoves)
                end

                # In case of failing low/high increase aspiration window and
                # re-search, otherwise exit the loop.
                if (bestValue <= alpha)
                    alpha = max(bestValue - delta, -VALUE_INFINITE)
                    #Signals.failedLowAtRoot = true;
                    #Signals.stopOnPonderhit = false;
                elseif (bestValue >= beta)
                    beta = min(bestValue + delta, VALUE_INFINITE)

                else
                    break;
                end

                delta += value(delta / 2)

            end

            # Sort the PV lines searched so far and update the GUI
            # std::stable_sort(RootMoves.begin(), RootMoves.begin() + PVIdx + 1);

            if time_ns() - pos.SearchTime > (1000000000*3)
                uci_pv(pos, bb, depth, value(alpha), value(beta), int64(bestValue), sock, RootMoves)
            end
        end

        depth += 1
    end

    if length(RootMoves) == 0
        return SMOVE_NONE
    else
        return RootMoves[1].pv[1]
    end
end

# uci_pv() formats PV information according to the UCI protocol. UCI
# requires that all (if any) unsearched PV lines are sent using a previous
# search score.
function uci_pv(pos::SPosition, bb::SContextBB, depth::Int64, alpha::Value, beta::Value, score::Int64, sock::Base.TcpSocket, RootMoves)
    elapsed = time_ns() - pos.SearchTime + 1;
    #size_t uciPVSize = std::min((size_t)Options["MultiPV"], RootMoves.size());
    selDepth = 0
    usiPVSize = min(1,length(RootMoves))

    #for (size_t i = 0; i < Threads.size(); ++i)
    #    if (Threads[i]->maxPly > selDepth)
    #        selDepth = Threads[i]->maxPly;

    if (length(RootMoves) == 0 )||(RootMoves[1].pv[1] == SMOVE_NONE)
        #println(sock, "bestmove resign")
        return
    end

    for i = 1:usiPVSize
        d   = true ? depth : depth - 1;
        v   = true ? RootMoves[i].score : RootMoves[i].prevScore;

        print(sock, "info time ",int(elapsed / (1000000.0))," depth ", int(depth), " nodes ", pos.nodes, " score cp ", score, " nps ", int(pos.nodes / (elapsed / 1000000000))," pv")

        #s << "info depth " << d
        #<< " seldepth "  << selDepth
        #<< " score "     << (i == PVIdx ? score_to_uci(v, alpha, beta) : score_to_uci(v))
        #<< " nodes "     << pos.nodes_searched()
        #<< " nps "       << pos.nodes_searched() * 1000 / elapsed
        #<< " time "      << elapsed
        #<< " multipv "   << i + 1
        #<< " pv";
        
        for j = 1:length(RootMoves[i].pv)
            print(sock, " " * move_to_usi(pos, bb, RootMoves[i].pv[j]))
        end
        println(sock)
    end
end

#@iprofile begin
function searchX(NT::Int64, pos::SPosition, bb::SContextBB, ss::Int64, alpha::Value, beta::Value, depth::Int64, cutNode::Bool, ply::Int64, RootMoves::Array{RootMove,1}) # ss is dummy
    PvNode   = (NT == PV || NT == Root || NT == SplitPointPV || NT == SplitPointRoot)
    SpNode   = (NT == SplitPointPV || NT == SplitPointNonPV || NT == SplitPointRoot)
    RootNode = (NT == Root || NT == SplitPointRoot)

    ttMove = MOVE_NONE
    ttValue = VALUE_NONE
    moveCount = 0
    quietCount = 0
    bestValue = -VALUE_INFINITE
    pos.nodes +=1

    if pos.stop == true
        return alpha
    end

    if ((pos.nodes % 128) == 0)
        if time_ns() - pos.SearchTime > (1000000000*MAXTHINKINGTIME)
            pos.stop = true
            return alpha
        end
    end

    if (!RootNode)
    end

    # moves_loop
    valueX = bestValue
    ci = SCheckInfo(pos,bb)
    st = SStateInfo()

    legalList = SMoveList(pos, bb, LEGAL)
    if length(legalList.mlist) > 0
        bestMove = smove((legalList.mlist[1]).move)
    else
        bestMove = SMOVE_NONE
    end
    # Step 11. Loop through moves
    # Loop through all pseudo-legal moves until no moves remain or a beta cutoff occurs
    for sm in legalList.mlist
        m = smove(sm.move)
        ext = 0
        # Update the current move (this must be done after singular extension search)
        newDepth = depth - ONE_PLY + ext;

        # Step 14. Make the move
        do_move(pos, bb, m, st)

        # value = (newDepth < ONE_PLY)? true ? -EvalMaterial(pos, bb): -EvalMaterial(pos, bb): - search(NonPV, pos, 0, -(alpha+1), -alpha, newDepth, !cutNode)

        if newDepth < ONE_PLY
            valueX = -1 * EvalMaterial(pos, bb)
        else
            valueX =  -searchX(NonPV, pos, bb, 0, value(-(beta)), value(-alpha), newDepth, !cutNode, ply+1, RootMoves)
        end

        #value = (newDepth < ONE_PLY)? (true ? -EvalMaterial(pos, bb): -EvalMaterial(pos, bb)): -searchX(NonPV, pos, bb, 0, value(-(beta)), value(-alpha), newDepth, !cutNode)

        # Step 17. Undo move
        undo_move(pos, bb, m)

        if (valueX > bestValue)
            bestValue = valueX

            if (valueX > alpha)
                bestMove = m

                if PvNode && (valueX < beta)
                    alpha = valueX
                else
                    break
                end
            end
        end
    end

    # If we have pruned all the moves without searching return a fail-low score
    if (bestValue == -VALUE_INFINITE)
        bestValue = alpha
    end

    # TT store (not implemented yet)

    if length(RootMoves) > 0
        if (length(RootMoves[1].pv) <= (ply+1))
            push!(RootMoves[1].pv,bestMove)
        else
            RootMoves[1].pv[ply+1] = bestMove
        end
    end

    bestValue
end
#end
