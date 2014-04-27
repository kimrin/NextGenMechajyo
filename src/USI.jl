function int(o::Option)
    if o.otype == "check" || o.otype == "spin"
        return (o.otype == "spin") ? Int64(o.currentValue): (o.currentValue == "true")
    end
    return -1 # not happen!
end
function string(o::Option)
    if o.otype == "string"
        return o.currentValue
    end
    return "no string" # not happen!
end

function on_logger(opt::Option)
    println("start logger")
end

function on_eval(opt::Option)
    println("Eval::init()")
end

function on_threads(opt::Option)
    println("Threads.read_usi_options()")
end

function on_hash_size(opt::Option)
    println("TT.resize(o)")
end

function on_clear_hash(opt::Option)
    println("TT.clear()")
end

function on_callback_do_nothing(opt::Option)
    println("dummy callback is called($opt)")
end

function initialize(usi::USI)
    usi.is_callback_enable = false

    o = OptionMap()
    
    o["Write Debug Log"]             = Option(false, usi, on_logger)
    o["Write Search Log"]            = Option(false, usi)
    o["Search Log Filename"]         = Option("SearchLog.txt", usi)
    o["Book File"]                   = Option("book.bin", usi)
    o["Best Book Move"]              = Option(false, usi)
    o["Contempt Factor"]             = Option(0, -50, 50, usi)
    o["Min Split Depth"]             = Option(0, 0, 12, usi, on_threads)
    o["Max Threads per Split Point"] = Option(5, 4,  8, usi, on_threads)
    o["Threads"]                     = Option(1, 1, MAX_THREADS, usi, on_threads)
    o["Idle Threads Sleep"]          = Option(true, usi)
    o["Hash"]                        = Option(32, 1, 16384, usi, on_hash_size)
    o["Clear Hash"]                  = Option(usi, on_clear_hash)
    o["Ponder"]                      = Option(true, usi)
    o["OwnBook"]                     = Option(false, usi)
    o["MultiPV"]                     = Option(1, 1, 500, usi)
    o["Skill Level"]                 = Option(20, 0, 20, usi)
    o["Emergency Base Time"]         = Option(60, 0, 30000, usi)
    o["Emergency Move Time"]         = Option(30, 0, 5000, usi)
    o["Minimum Thinking Time"]       = Option(20, 0, 5000, usi)
    o["Slow Mover"]                  = Option(80, 10, 1000, usi)

    usi.is_callback_enable = true
    
    o
end
# Initial SFEN board representations:

#const StartSFEN= "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1"::ASCIIString # normal initial board
const StartSFEN= "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1"::ASCIIString # normal initial board
#const FestivalSFEN = "l6nl/5+P1gk/2np1S3/p1p4Pp/3P2Sp1/1PPb2P1P/P5GS1/R8/LN4bKL b RGgsn5p 1"::ASCIIString # so many available moves..
const FestivalSFEN = "l6nl/5+P1gk/2np1S3/p1p4Pp/3P2Sp1/1PPb2P1P/P5GS1/R8/LN4bKL w GR5pnsg 1"::ASCIIString # so many available moves..
const NanaRokuFUSFEN = "lnsgkgsnl/1r5b1/ppppppppp/9/9/2P6/PP1PPPPPP/1B5R1/LNSGKGSNL w - 1"::ASCIIString # after +7776FU
const AnnosanSFEN = "lns+B1gg+Rl/4L4/p1ppk3p/1p4p2/9/PP1PP1P+pP/2SKG2r1/+bN3s1+pL b GNPn2p 1"::ASCIIString # checkmate in 9moves
const RyuOSatoWatanabe = "8l/1l+R2P3/p2pBG1pp/kps1p4/Nn1P2G2/P1P1P2PP/1PS6/1KSG3+r1/LN2+p3L w Sbgn3p 124"::ASCIIString

const EvasionsCheck    = "lnsgkgsnl/1r5b1/pppp1pppp/9/9/4R4/PPPPPPPPP/1B7/LNSGKGSNL w p 1"::ASCIIString

function mainLoop(bbb::SContextBB, uci::USI, omap::OptionMap, sock::Base.TcpSocket)
    # Position pos(StartFEN, false, Threads.main()); // The root position
    # pos = SPosition(bbb, StartSFEN, threadNumber(0))
    # pos = SPosition(bbb, FestivalSFEN, threadNumber(0))
    # pos = SPosition(bbb, NanaRokuFUSFEN, threadNumber(0))
    # pos = SPosition(bbb, AnnosanSFEN, threadNumber(0))
    # pos = SPosition(bbb, RyuOSatoWatanabe, threadNumber(0))
    pos = SPosition(bbb, EvasionsCheck, threadNumber(0))

    mov = false ? make(squareC(20), squareC(29), FU, uint32(0), pieceType(0)): SMOVE_NULL # if true, make +7776FU

    # move piece from 77 to 76 (+FU)
    #move_piece(bbb, pos, squareC(20), squareC(29), WHITE, FU)

    # print board!
    pretty(pos,mov)

    #tic()

    #for i = 1:100000
    #    sml = SMoveList(pos, bbb, LEGAL)
    #end
    #Profile.print()
    #toc()
    sml = SMoveList(pos, bbb, LEGAL)
    println("generated ",sml.last, " moves!")
    for s in sml.mlist
        println("$(move_to_san(smove(s.move)))")
    end

    tic()
    for i = 1:10000
        sml = SMoveList(pos, bbb, LEGAL)
    end
    t = toc()
    println("generate ",10000.0 / t, " genmoves/sec")
    #@iprofile report

    # pos.sideToMove = color(pos.sideToMove$1)

    while true
        line = readline(sock)
        comlist = split(line)
        token = comlist[1]
        if token == "quit" || token == "stop" || token == "ponderhit"
            # The GUI sends 'ponderhit' to tell us to ponder on the same move the
            # opponent has played. In case Signals.stopOnPonderhit is set we are
            # waiting for 'ponderhit' to stop the search (for instance because we
            # already ran out of time), otherwise we should continue searching but
            # switch from pondering to normal search.
            if token != "ponderhit" || false #Search::Signals.stopOnPonderhit
                # Search::Signals.stop = true;
                # Threads.main()->notify_one(); // Could be sleeping
                return token
            else
                # Search::Limits.ponder = false;
            end

        elseif token == "perft"
            pos = ""
            blist = [Options["Hash"],Options["Threads"], int(comlist[2]), "current", "perft"]
            # benchmark(pos, blist)
        elseif token == "key"
            #sync_cout << hex << uppercase << setfill('0')
            #        << "position key: "   << setw(16) << pos.key()
            #        << "\nmaterial key: " << setw(16) << pos.material_key()
            #        << "\npawn key:     " << setw(16) << pos.pawn_key()
            #        << dec << sync_endl;
        elseif token == "usi"
            print( sock, engine_info(true, Shogi))
            # println("len of omap = $(length(omap))")
            for k in sort(collect(keys(omap)))
                v = omap[k]

                ostr = "option name $(k) type $(v.otype) "
                if v.otype != "button"
                    ostr *= "default $(v.defaultValue) "
                end
                if v.otype == "spin"
                    ostr *= "min $(v.min) max $(v.max)"
                end
                println(sock, ostr)
            end
            # sync_cout << "id name " << engine_info(true)
            #    << "\n"       << Options
            # << "\nuciok"  << sync_endl;
            println(sock, "usiok")
        elseif token == "eval"
            # Search::RootColor = pos.side_to_move(); // Ensure it is set
            # sync_cout << Eval::trace(pos) << sync_endl;
        elseif token == "usinewgame"
            # TT.clear();
        elseif token == "go"
            # go(pos, is);
        elseif token == "position"
            # position(pos, is);
        elseif token == "setoption"
            # setoption(is);
        elseif token == "flip"
            # pos.flip();
        elseif token == "bench"
            # benchmark(pos, is);
        elseif token == "d"
            # pos.pretty()
            pretty(pos,SMOVE_NULL)
        elseif token == "isready"
            println(sock, "readyok")
        else
          println("Unknown command: ", comlist)
        end
    end
end
