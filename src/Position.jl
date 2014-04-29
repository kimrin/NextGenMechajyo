typealias ThreadNumber Uint32
threadNumber = uint32

# The StateInfo struct stores information needed to restore a Position
# object to its previous state when we retract a move. Whenever a move
# is made on the board (by calling Position::do_move), a StateInfo
# object must be passed as a parameter.
#
type StateInfo
    pawnKey::Key
    materialKey::Key
    npMaterial::Array{Value,1}
    castlingRights::Int32
    rule50::Int32
    pliesFromNull::Int32
    psq::Score
    epSquare::Square
    key::Key
    checkersBB::Bitboard
    capturedType::PieceType
    previous::StateInfo
    function StateInfo()
        new()
    end
end

type SStateInfo # for Shogi
    # may be nothing without followings...
    checkersBB::SBitboard
    capturedType::PieceType
    pliesFromNull::Int64
    previous::SStateInfo
    function SStateInfo()
        new(sbitboard(0),NO_PIECE_TYPE,int32(0))
    end
end

# The Position class stores the information regarding the board representation
# like pieces, side to move, hash keys, castling info, etc. The most important
# methods are do_move() and undo_move(), used by the search to update node info
# when traversing the search tree.
#
type Position
    # Board and pieces
    board::Array{Piece,1}
    byTypeBB::Array{Bitboard,1}
    byColorBB::Array{Bitboard,1}
    pieceCount::Array{Int32,2}
    pieceList::Array{Square,3}
    index::Array{Int32,1}

    # Other info
    castlingRightsMask::Array{Int32,1}
    castlingRookSquare::Array{Square,1}
    castlingPath::Array{Bitboard,1}
    startState::StateInfo
    nodes::Uint64
    gamePly::Int32
    sideToMove::Color
    thisThread::ThreadNumber
    st::StateInfo
    chess960::Bool

    function Position(p::Position, t::ThreadNumber)
        p.thisThread = t
        p
    end
    function Position(f::ASCIIString, c960::Bool, t::ThreadNumber)
        n = new()
        set( n, f, c960, t)
    end
end

type SPosition
    # Board and pieces
    board::Array{Piece,1}
    byTypeBB::Array{SBitboard,1}
    byColorBB::Array{SBitboard,1}
    pieceCount::Array{Int32,2}
    pieceList::Array{Square,3}
    index::Array{Int32,1}

    capturedPieces::Array{Int32,2} # color and pieceType(from FU to OU)

    # Other info
    startState::SStateInfo
    nodes::Uint64
    gamePly::Int64
    sideToMove::Color
    thisThread::ThreadNumber
    st::SStateInfo
    stop::Bool
    SearchTime::Int64
    nodes::Int64

    function SPosition(p::Position, t::ThreadNumber)
        p.thisThread = t
        p
    end

    function SPosition(sbb::SContextBB, sf::ASCIIString, t::ThreadNumber)
        n = new()

        n.board = zeros(Piece, SSQUARE_NB)
        n.byTypeBB = zeros(SBitboard, SPIECE_TYPE_NB+1)
        n.byColorBB = zeros(SBitboard, COLOR_NB)
        n.pieceCount = zeros(Int32, COLOR_NB, SPIECE_TYPE_NB)
        n.pieceList = zeros(Square, 41, SPIECE_TYPE_NB, COLOR_NB) # reverse order (column-maj)
        n.index    =  zeros(Int32, SSQUARE_NB)
        n.capturedPieces = zeros(Int32,COLOR_NB,SPIECE_TYPE_NB)
        n.stop = false

        set( sbb, n, sf, t)
        n
    end
end

# The checkInfo struct is initialized at c'tor time and keeps info used
# to detect if a move gives check.
type SCheckInfo
    dcCandidates::SBitboard
    pinned::SBitboard
    checkSq::Array{SBitboard,1}
    ksq::Square

    # CheckInfo c'tor
    function SCheckInfo(pos::SPosition, bb::SContextBB)
        n = new()
        them = color(side_to_move(pos)$1)
        n.ksq = king_square(pos,them)
        ksq = n.ksq

        n.checkSq = zeros(SBitboard, SPIECE_TYPE_NB)

        n.pinned = pinned_pieces(pos, bb, side_to_move(pos))
        n.dcCandidates = discovered_check_candidates(pos, bb)

        n.checkSq[FU] = attacks_from(pos, bb, smake_piece(them,FU), ksq)
        n.checkSq[KE] = attacks_from(pos, bb, smake_piece(them,KE), ksq)
        n.checkSq[GI] = attacks_from(pos, bb, smake_piece(them,GI), ksq)
        n.checkSq[KI] = attacks_from(pos, bb, smake_piece(them,KI), ksq)
        n.checkSq[OU] = sbitboard(0)
        n.checkSq[TO] = attacks_from(pos, bb, smake_piece(them,TO), ksq)
        n.checkSq[NY] = attacks_from(pos, bb, smake_piece(them,NY), ksq)
        n.checkSq[NK] = attacks_from(pos, bb, smake_piece(them,NK), ksq)
        n.checkSq[NG] = attacks_from(pos, bb, smake_piece(them,NG), ksq)
        n.checkSq[UM] = attacks_from(pos, bb, smake_piece(them,UM), ksq)
        n.checkSq[RY] = attacks_from(pos, bb, smake_piece(them,RY), ksq)

        # sliding pieces
        n.checkSq[KY] = attacks_from(pos, bb, smake_piece(them,KY), ksq, true)
        n.checkSq[KA] = attacks_from(pos, bb, smake_piece(them,KA), ksq, true)
        n.checkSq[HI] = attacks_from(pos, bb, smake_piece(them,HI), ksq, true)
        n.checkSq[UM] |= attacks_from(pos, bb, smake_piece(them,UM), ksq, true)
        n.checkSq[RY] |= attacks_from(pos, bb, smake_piece(them,RY), ksq, true)

        # for p = FU:RY
        #     if n.checkSq[p] > sbitboard(0)
        #         println(KOMASTR_SHORT[p])
        #         println(pretty2(bb, n.checkSq[p]))
        #     end
        # end

        n
    end
end

# 64bit hash function of the position (SPosition)
hash(p::SPosition) = hash(p.board)$hash(p.capturedPieces)$hash(p.sideToMove)

const MOCHISTR = UTF8String["歩",
                            "香",
                            "桂",
                            "銀",
                            "金",
                            "角",
                            "飛",
                            "王"]::Array{UTF8String,1}

# show captured pieces in Japanese
function DisplayMochiGoma(pos::SPosition, color::Color)
    num::Int = 0
    if color != WHITE && color != BLACK
        println("Illegal Mochi Goma!")
        return
    end

    if color == WHITE
        print("\e[34m", "▲", "\e[30m 持駒　")
    else
        print("△", " 持駒　")
    end
    for i = OU:-1:FU
        mochi = pos.capturedPieces[color+1,i+1]
        if mochi > 0
            num += 1

            print(MOCHISTR[i])
            if mochi > 1
                print(mochi)
            end
        end
    end
    if num == 0
        print("なし")
    end
    println()
end

const doubleZenkakuSpace = "　　"::UTF8String
const KOMASTR = UTF8String["歩　",
                           "香　",
                           "桂　",
                           "銀　",
                           "金　",
                           "角　",
                           "飛　",
                           "王　",
                           "と　",
                           "成香",
                           "成桂",
                           "成銀",
                           "成金",
                           "馬　",
                           "龍　"]::Array{UTF8String,1}

const KOMASTR_SHORT = UTF8String["歩",
                                 "香",
                                 "桂",
                                 "銀",
                                 "金",
                                 "角",
                                 "飛",
                                 "王",
                                 "と",
                                 "成香",
                                 "成桂",
                                 "成銀",
                                 "成金",
                                 "馬",
                                 "龍"]::Array{UTF8String,1}

const DANSTR = UTF8String["一",
                          "二",
                          "三",
                          "四",
                          "五",
                          "六",
                          "七",
                          "八",
                          "九"]::Array{UTF8String,1}


function pretty(pos::SPosition, move::SMove)
    println()
    DisplayMochiGoma(pos, BLACK)
    println(" ９　  ８　  ７　  ６　  ５　  ４　  ３　  ２　  １　 ")
    sq::Int = 0
    tosq = to_sq(move)

    for r = RANK_9:-1:RANK_1
        for f = FILE_A:FILE_I
            sq = sfile_rank(fileC(f),rankC(r))

            if is_ok(move)
                moveFlag = (tosq == sq)?true:false
            else
                moveFlag = false
            end
            koma = pos.board[sq+1]
            komamoji::UTF8String = doubleZenkakuSpace
            if koma == NO_PIECE
	        print("\e[36m ..  \e[30m ")
            else
                ko = koma& 0x0000000f
                if (koma <= 0)||(koma > 0x1f)||(koma == 0x10)
                    println("bound error: koma=", koma)
                    quit()
                end
                if (ko <= 0)||(ko > 15)
                    println("bounderror:ko=",ko)
                    quit()
                end
                komamoji = KOMASTR[ko]
                if koma < B_OFFSET
                    if moveFlag
                        print("\e[31m+")
                        print(KOMASTR[koma&0x0f],"\e[30m ")
                    else
                        print("\e[34m+")
                        print(KOMASTR[koma&0x0f],"\e[30m ")
                    end
                elseif B_OFFSET < koma < SPIECE_NB
                    if moveFlag
                        print("\e[31m-")
                        print(KOMASTR[koma&0x0f],"\e[30m ")
                    else
                        print("\e[30m-")
                        print(KOMASTR[koma&0x0f],"\e[30m ")
                    end
                end
            end
        end
        println(DANSTR[9-r])
    end
    DisplayMochiGoma(pos, WHITE)
    # println("Material = ", bo.Material)
    println(pos.sideToMove == WHITE? "先手番":"後手番")
    println()
end

# Position::set() initializes the position object with the given FEN string.
# This function is not very robust - make sure that input FENs are correct,
# this is assumed to be the responsibility of the GUI.

# for Chess
function set(p::Position, fen::ASCIIString, c960::Bool, t::ThreadNumber)
#
#   A FEN string defines a particular position using only the ASCII character set.
#
#   A FEN string contains six fields separated by a space. The fields are:
#
#   1) Piece placement (from white's perspective). Each rank is described, starting
#      with rank 8 and ending with rank 1. Within each rank, the contents of each
#      square are described from file A through file H. Following the Standard
#      Algebraic Notation (SAN), each piece is identified by a single letter taken
#      from the standard English names. White pieces are designated using upper-case
#      letters ("PNBRQK") whilst Black uses lowercase ("pnbrqk"). Blank squares are
#      noted using digits 1 through 8 (the number of blank squares), and "/"
#      separates ranks.
#
#   2) Active color. "w" means white moves next, "b" means black.
#
#   3) Castling availability. If neither side can castle, this is "-". Otherwise,
#      this has one or more letters: "K" (White can castle kingside), "Q" (White
#      can castle queenside), "k" (Black can castle kingside), and/or "q" (Black
#      can castle queenside).
#
#   4) En passant target square (in algebraic notation). If there's no en passant
#      target square, this is "-". If a pawn has just made a 2-square move, this
#      is the position "behind" the pawn. This is recorded regardless of whether
#      there is a pawn in position to make an en passant capture.
#
#   5) Halfmove clock. This is the number of halfmoves since the last pawn advance
#      or capture. This is used to determine if a draw can be claimed under the
#      fifty-move rule.
#
#   6) Fullmove number. The number of the full move. It starts at 1, and is
#      incremented after Black's move.
#
    # tentative stub function...

end


# for Shogi
# for English Information, check SFEN notation descriptions of http://www.glaurungchess.com/shogi/usi.html
# following Japanese descriptions are cited from http://www.geocities.jp/shogidokoro/usi.html

function set(sbb::SContextBB, p::SPosition, sfen::ASCIIString, t::ThreadNumber)
# 
# 駒の種類は、それぞれ１文字のアルファベットで表され、先手の駒は大文字、後手の駒は小文字になります。
# 
# 先手の玉：K、後手の玉：k （Kingの頭文字）
# 先手の飛車：R、後手の飛車：r （Rookの頭文字）
# 先手の角：B、後手の角：b （Bishopの頭文字）
# 先手の金：G、後手の金：g （Goldの頭文字）
# 先手の銀：S、後手の銀：s （Silverの頭文字）
# 先手の桂馬：N、後手の桂馬：n （kNightより）
# 先手の香車：L、後手の香車：l （Lanceの頭文字）
# 先手の歩：P、後手の歩：p （Pawnの頭文字）
# 
# 駒が成った状態を表記するには、駒の文字の前に+をつけます。先手のと金は+Pとなります。
# 
# 盤面を表記するとき、１段目の左側（９筋側）から駒の種類を書いていきます。空白の升は、空白が続く個数の数字を書きます。
# 平手初期局面の場合、１段目は、左から後手の駒が香桂銀金玉金銀桂香と並んでいるので、lnsgkgsnlとなります。
# ２段目は、空白が１升、後手の飛車、空白が５升、後手の角、空白が１升というように並んでいるので、1r5b1となります。
# 各段がそのように表記され、１段目から９段目まで、それぞれの段の表記を/（半角スラッシュ）でつなげて書くと、
# 盤面の表記になります。平手初期局面であれば
# 
# lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL
# 
# ということになります。
# しかし局面表記にはこれだけでは不十分で、次の手番と、持ち駒についても表記する必要があります。
# 次の手番については、先手番ならb、後手番ならwと表記します。（Black、Whiteの頭文字）
# 
# 持ち駒については、先手後手のそれぞれの持ち駒の種類と、その枚数を表記します。
# 枚数は、２枚以上であれば、駒の種類の前にその数字を表記します。先手側が銀１枚歩２枚、後手側が角１枚歩３枚であれば、
# S2Pb3pと表記されます。どちらも持ち駒がないときは-（半角ハイフン）を表記します。
# 
# さらにSFENの原案によると、次の手が何手目かという数字も表記する必要があります。ただし、任意局面から開始する場合など、
# 次の手が何手目かという情報に意味がないので、これが必要なものかどうかよくわかりません。将棋所の場合、
# この数字は必ず１にしています。
# 以上によりSFENによる任意局面の表記方法が定義されます。香落ち初期局面であれば、
# 
# lnsgkgsn1/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1
# 
# というように表記されます。
# 
# 次に、指し手の表記について解説します。筋に関しては１から９までの数字で表記され、段に関してはaからiまでのアルファベット
# （１段目がa、２段目がb、・・・、９段目がi）というように表記されます。位置の表記は、この２つを組み合わせます。
# ５一なら5a、１九なら1iとなります。
# そして、指し手に関しては、駒の移動元の位置と移動先の位置を並べて書きます。７七の駒が７六に移動したのであれば、
# 7g7fと表記します。
# （駒の種類を表記する必要はありません。）
# 駒が成るときは、最後に+を追加します。８八の駒が２二に移動して成るなら8h2b+と表記します。
# 持ち駒を打つときは、最初に駒の種類を大文字で書き、それに*を追加し、さらに打った場所を追加します。
# 金を５二に打つ場合はG*5bとなります
#

    # we use WHITE=SENTE(First move) and BLACK=GOTE(2nd move) in Shogi code! (same as Chess!)
    # (usually Black = SENTE and White = GOTE in Shogi Records)

    rank = rankC(8)
    file = fileC(0)
    promote::Int = 0
    sengo::Int = WHITE # SENTE

    fen, bw, mochi, num = split(sfen)

    for s in fen
        # println(s)
        if s == '/'
            rank = rankC(rank-1)
            file = fileC(FILE_A)
        elseif s == '+'
            promote = PT_PROMOTE_OFFSET
        elseif s >= '1' && s <= '9'
            file = fileC(file+(s-'0'))

            # WHITE

        elseif s == 'P'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(FU+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'L'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(KY+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'N'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(KE+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'S'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(GI+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'G'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(KI))
            file = fileC(file+1)
            promote = 0
        elseif s == 'B'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(KA+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'R'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(HI+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'K'
            put_piece(sbb, p, sfile_rank(file,rank), WHITE, pieceType(OU))
            file = fileC(file+1)
            promote = 0

            # BLACK

        elseif s == 'p'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(FU+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'l'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(KY+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'n'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(KE+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 's'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(GI+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'g'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(KI))
            file = fileC(file+1)
            promote = 0
        elseif s == 'b'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(KA+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'r'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(HI+promote))
            file = fileC(file+1)
            promote = 0
        elseif s == 'k'
            put_piece(sbb, p, sfile_rank(file,rank), BLACK, pieceType(OU))
            file = fileC(file+1)
            promote = 0
        end
    end

    if bw == "w"
        p.sideToMove = BLACK
    else # bw == "b"
        p.sideToMove = WHITE
    end

    numberOfMochi::Int = 0
    for s in mochi
        if s == '-'
            break # No captured pieces
        elseif s == '1'
            if numberOfMochi == 1
                numberOfMochi = 11
            else
                numberOfMochi = 1
            end
        elseif s == '0'
            if numberOfMochi == 1
                numberOfMochi = 10
            end
        elseif '2' <= s <= '9'
            if numberOfMochi == 1
                numberOfMochi = 10 + int(s - '0')
            else
                numberOfMochi = int(s - '0')
            end

            # WHITE

        elseif s == 'P'
            put_piece_in_komadai(p, WHITE, FU, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'L'
            put_piece_in_komadai(p, WHITE, KY, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'N'
            put_piece_in_komadai(p, WHITE, KE, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'S'
            put_piece_in_komadai(p, WHITE, GI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'G'
            put_piece_in_komadai(p, WHITE, KI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'B'
            put_piece_in_komadai(p, WHITE, KA, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'R'
            put_piece_in_komadai(p, WHITE, HI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'K' # may be checkmate puzzles...
            put_piece_in_komadai(p, WHITE, OU, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0

            # BLACK

        elseif s == 'p'
            put_piece_in_komadai(p, BLACK, FU, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'l'
            put_piece_in_komadai(p, BLACK, KY, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'n'
            put_piece_in_komadai(p, BLACK, KE, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 's'
            put_piece_in_komadai(p, BLACK, GI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'g' 
            put_piece_in_komadai(p, BLACK, KI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'b'
            put_piece_in_komadai(p, BLACK, KA, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'r'
            put_piece_in_komadai(p, BLACK, HI, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        elseif s == 'k' # may be checkmate puzzles...
            put_piece_in_komadai(p, BLACK, OU, (numberOfMochi == 0) ? 1: numberOfMochi)
            numberOfMochi = 0
        end
    end
    set_state(p, sbb, SStateInfo())
end

function set_state(pos::SPosition, bb::SContextBB, si::SStateInfo)
    # calculations for Zobrist are omitted
    si.checkersBB = pieces(pos, int8(pos.sideToMove$1)) & attackers_to(pos, bb, king_square(pos, pos.sideToMove)) 
    pos.st = si
end

function put_piece(sbb::SContextBB, sp::SPosition, s::Square, c::Color, pt::PieceType)
    if pt == 0
        println("illegal piece: pieceType = ", pt)
        quit()
    end
    sp.board[s+1]               = smake_piece( c, pt)
    sp.byTypeBB[SALL_PIECES+1] |= sbb.SquareBB[s+1]
    sp.byTypeBB[pt+1]          |= sbb.SquareBB[s+1]
    sp.byColorBB[c+1]          |= sbb.SquareBB[s+1]
    sp.index[s+1]               = sp.pieceCount[c+1,pt+1]
    sp.pieceCount[c+1,pt+1] += 1
    #println("$(sp.index[s+1]+1),$(pt+1),$(c+1) = s")
    sp.pieceList[sp.index[s+1]+1,pt+1,c+1] = s
end

function nodes_searched(p::SPosition)
    p.nodes
end

function set_nodes_searched(s::SPosition, n::Uint64)
    p.nodes = n
end

function piece_on(sp::SPosition, s::Square)
    sp.board[s+1]
end

function moved_piece(sp::SPosition, m::SMove)
    sp.board[from_sq(m)]
end

function empty(sp::SPosition, s::Square)
    sp.board[s+1] == NO_PIECE
end

function side_to_move(sp::SPosition)
    sp.sideToMove
end

# following pieces functions returns SBitboard

function pieces(sp::SPosition)
    sp.byTypeBB[SALL_PIECES+1]
end

function pieces(sp::SPosition, pt::PieceType)
    sp.byTypeBB[pt+1]
end

function pieces(sp::SPosition, pt1::PieceType, pt2::PieceType)
    sp.byTypeBB[pt1+1] | sp.byTypeBB[pt2+1]
end

function pieces(sp::SPosition, c::Color)
    sp.byColorBB[c+1]
end

function pieces(sp::SPosition, c::Color, pt::PieceType)
    sp.byColorBB[c+1] & sp.byTypeBB[pt+1]
end

function pieces(sp::SPosition, c::Color, pt1::PieceType, pt2::PieceType)
    sp.byColorBB[c+1] & (sp.byTypeBB[pt1+1] | sp.byTypeBB[pt2+1])
end

function count(sp::SPosition, c::Color, pt::PieceType)
    sp.pieceCount[c+1,pt+1]
end

# in Julialang, no need to investigate array length by count() before touch the list:
# actual lists have their sizes. (returns one dimensional array)
function list(sp::SPosition, c::Color, pt::PieceType)
    sp.pieceList[1:sp.pieceCount[c+1,pt+1],pt+1,c+1]
end

function king_square(sp::SPosition, c::Color)
    ksq = sp.pieceList[1, OU+1, c+1]
    if (ksq >= SSQ_NONE)
        throw("illegal OU position in pieceList")
    end
    ksq
end

function checkers(st::SStateInfo)
    st.checkersBB
end

# Position::check_blockers() returns a bitboard of all the pieces with color
# 'c' that are blocking check on the king with color 'kingColor'. A piece
# blocks a check if removing that piece from the board would result in a
# position where the king is in check. A check blocking piece can be either a
# pinned or a discovered check piece, according if its color 'c' is the same
# or the opposite of 'kingColor'.

function check_blockers(pos::SPosition, bb::SContextBB, c::Color, kingColor::Color)
    b       = sbitboard(0)
    pinners = sbitboard(0)
    result  = sbitboard(0)
    ksq = king_square(pos, kingColor)
    if ksq >= SSQ_NONE
        println("ksq overflow:", ksq)
        throw("ksq in check_blockers")
    end

    # Pinners are sliders that give check when a pinned piece is removed

    # TODO: Should be verifing in another times!
    pinners = (pieces(pos,HI,RY) & bb.PseudoAttacks[ROOK+1,ksq+1]
               | pieces(pos,KA,UM) & bb.PseudoAttacks[BISHOP+1,ksq+1]
               | pieces(pos,KY) & bb.PseudoAttacks[ROOK+1,ksq+1] & forward_bb(bb, c, ksq)) & pieces(pos,color(kingColor$1))

    ls = LSBC(0,sbitboard(0))
    while (pinners > sbitboard(0))
        pop_lsb(pinners, ls)
        pinners = ls.b
        b = between_bb(bb, ksq, squareC(ls.sq)) & pieces(pos)
        if more_than_one(b) == sbitboard(0)
            result |= b & pieces(pos,c)
        end
    end
    result
end

function discovered_check_candidates(pos::SPosition, bb::SContextBB)
    check_blockers(pos, bb, pos.sideToMove, color(pos.sideToMove$1))
end

function pinned_pieces(pos::SPosition, bb::SContextBB, c::Color)
    check_blockers(pos, bb, c, c)
end

# dummy is ... dummy argument!
function attacks_from(sp::SPosition, bb::SContextBB, p::Piece, s::Square, dummy::Bool)
    pt = stype_of(p)
    if pt == KA || pt == HI || pt == UM || pt == RY || pt == KY
        return attacks_bb(bb, p, s, sp.byTypeBB[SALL_PIECES+1], true)
    else
        println("This function must call with piece type = KA or HI!")
        return sbitboard(0)
    end
end

function attacks_from(sp::SPosition, bb::SContextBB, p::Piece, s::Square)
    attacks_bb(bb, p, s, sp.byTypeBB[SALL_PIECES+1])
end

function attackers_to(sp::SPosition, bb::SContextBB, s::Square)
    attackers_to(sp, bb, s, sp.byTypeBB[SALL_PIECES+1])
end

# Position::attackers_to() computes a bitboard of all pieces which attack a
# given square. Slider attacks use the occ bitboard to indicate occupancy.
function attackers_to(sp::SPosition, bb::SContextBB, s::Square, occ::SBitboard)
    sum = sbitboard(0)
    #println("attackers_to: occ:")
    #println(pretty2(bb,occ))
    for c = WHITE:BLACK
        for pt = FU:RY
            p = smake_piece(c,pt)
            sum |= attacks_from(sp, bb, p, s) & pieces(sp, color(c$1), pt)
        end
        sum |= attacks_bb(bb, smake_piece(c,KY), s, occ, true) & pieces(sp, color(c$1), KY)
        sum |= attacks_bb(bb, smake_piece(c,HI), s, occ, true) & pieces(sp, c, HI)
        sum |= attacks_bb(bb, smake_piece(c,KA), s, occ, true) & pieces(sp, c, KA)
        sum |= attacks_bb(bb, smake_piece(c,RY), s, occ, true) & pieces(sp, c, RY)
        sum |= attacks_bb(bb, smake_piece(c,UM), s, occ, true) & pieces(sp, c, UM)
    end
        
    #println(pretty2(bb, sum))
    sum
end

# Position::legal() tests whether a pseudo-legal move is legal

function legal(pos::SPosition, bb::SContextBB, m::SMove, pinned::SBitboard)
    us = pos.sideToMove
    from = from_sq(m)
    to   = to_sq(m)
    pi   = spiece(m)
    #println("from=",from)

    if from == SSQ_DROP # all drop moves are treat as legal
        return true
    end

    # reject illegal moves that cannot be going to anywhere when moved
    if (srank_of(to) == RANK_1)&&((pi == B_FU)||(pi == B_KY)||(pi == B_KE))
        return false
    end
    if (srank_of(to) == RANK_2)&&(pi == B_KE)
        return false
    end
    if (srank_of(to) == RANK_9)&&((pi == W_FU)||(pi == W_KY)||(pi == W_KE))
        return false
    end
    if (srank_of(to) == RANK_8)&&(pi == W_KE)
        return false
    end

    # If the moving piece is a king, check whether the destination
    # square is attacked by the opponent. Castling moves are checked
    # for legality during move generation.

    #println("attackers_to: joken bitboard")
    #println(pretty2(bb,((attackers_to(pos, bb, to_sq(m), pieces(pos,us)) & pieces(pos,color(us$1))))))
    #println("joken = ", (attackers_to(pos, bb, to_sq(m), pieces(pos,color(us$1))))== sbitboard(0))

    if stype_of(piece_on(pos, from)) == OU
        return false || (attackers_to(pos, bb, to_sq(m), pieces(pos,us)) & pieces(pos,color(us$1)))== sbitboard(0)
    end

    # A non-king move is legal if and only if it is not pinned or it
    # is moving along the ray towards or away from the king.
    return (pinned == sbitboard(0)
            || (pinned & bb.SquareBB[from+1]) == sbitboard(0)
            || (aligned(bb, from, to_sq(m), king_square(pos, us)))>sbitboard(0))
end

# Position::pseudo_legal() takes a random move and tests whether the move is
# pseudo legal. It is used to validate moves from TT that can be corrupted
# due to SMP concurrent access or hash position key aliasing.
function pseudo_legal(pos::SPosition, bb::SContextBB, st::SStateInfo, m::SMove)
    us = pos.sideToMove
    from = from_sq(m)
    to   = to_sq(m)
    pc   = moved_piece(pos, m)

    # Use a slower but simpler function for uncommon cases
    if type_of(m) != NORMAL
      return contains(SMoveList(pos, LEGAL),m)
    end

    # Is not a promotion, so promotion piece must be empty
    # if (promotion_type(m) - 2 != NO_PIECE_TYPE)
    #  return false;
    # not implemented...

    # If the 'from' square is not occupied by a piece belonging to the side to
    # move, the move is obviously not legal.
    if pc == NO_PIECE || scolor_of(pc) != us
      return false
    end

    # The destination square cannot be occupied by a friendly piece
    if pieces(us) & bb.SquareBB[to+1]
      return false
    end

    # Handle the special case of a pawn move
    if stype_of(pc) == FU
        # not implemented...
    elseif attacks_from(pos, bb, pc, from) == sbitboard(0)
        return false
    end

    # Evasions generator already takes care to avoid some kind of illegal moves
    # and legal() relies on this. We therefore have to take care that the same
    # kind of moves are filtered out here.
    if checkers(st) > sbitboard(0)
        if stype_of(pc) != OU
            # Double check? In this case a king move is required
            if more_than_one(checkers(st))
                return false
            end
            
            # Our move must be a blocking evasion or a capture of the checking piece
            if (((between_bb(bb, lsb(checkers(st)), king_square(pos, us)) | checkers(st)) & bb.SquareBB[to+1]) == sbitboard(0))
                return false
            end
            # In case of king moves under check we have to remove king so as to catch
            # invalid moves like b1a1 when opposite queen is on c1.
        elseif attackers_to(pos, bb, to, pieces(pos) $ bb.SquareBB[from+1]) & pieces(us$1)
            return false
        end
    end

    true
end

# for first SFEN placements
function put_piece_in_komadai(sp::SPosition, c::Color, pt::PieceType, n::Int)
    sp.capturedPieces[c+1,pt+1] = int32(n)
end

function put_piece_in_komadai(sp::SPosition, c::Color, pt::PieceType)
    sp.capturedPieces[c+1,pt+1] = int32(sp.capturedPieces[c+1,pt+1] + 1) 
end

function remove_piece_from_komadai(sp::SPosition, c::Color, pt::PieceType)
    #println("remove_piece_from_komadai: c = ", c, ", pt = ", pt)
    num = sp.capturedPieces[c+1,pt+1] - 1
    if num < 0
        println("!!!underflow komadai!!!")
        println("c=",c,",pt=",pt)
        throw("")
        return
    end
    sp.capturedPieces[c+1,pt+1] = int32(num)
end

function move_piece(sbb::SContextBB, sp::SPosition, from::Square, to::Square, c::Color, pt::PieceType)
    # index[from] is not updated and becomes stale. This works as long
    # as index[] is accessed just by known occupied squares.

    from_to_bb = sbb.SquareBB[from+1] $ sbb.SquareBB[to+1]
    sp.byTypeBB[SALL_PIECES+1] $= from_to_bb
    sp.byTypeBB[pt+1] $= from_to_bb
    sp.byColorBB[c+1] $= from_to_bb
    sp.board[from+1] = NO_PIECE
    if pt == 0
        println("move_piece: pt = 0")
        throw("move_piece pt is zero error!")
    end
    sp.board[to+1]   = smake_piece(c, pt)
    sp.index[to+1]   = sp.index[from+1]
    sp.pieceList[sp.index[to+1]+1,pt+1,c+1] = to
end

function remove_piece(sbb::SContextBB, sp::SPosition, s::Square, c::Color, pt::PieceType)
    # WARNING: This is not a reversible operation. If we remove a piece in
    # do_move() and then replace it in undo_move() we will put it at the end of
    # the list and not in its original place, it means index[] and pieceList[]
    # are not guaranteed to be invariant to a do_move() + undo_move() sequence.
    sp.byTypeBB[SALL_PIECES+1] $= sbb.SquareBB[s+1]
    sp.byTypeBB[pt+1] $= sbb.SquareBB[s+1]
    sp.byColorBB[c+1] $= sbb.SquareBB[s+1]
    sp.board[s+1] = NO_PIECE # Not needed, will be overwritten by capturing
    pc = int32(sp.pieceCount[c+1,pt+1] - 1)
    sp.pieceCount[c+1,pt+1] = pc
    lastSquare = sp.pieceList[pc+1,pt+1,c+1]
    sp.index[lastSquare+1] = sp.index[s+1]
    sp.pieceList[sp.index[lastSquare+1]+1,pt+1,c+1] = lastSquare
    sp.pieceList[pc+1,pt+1,c+1] = SSQ_NONE
    #println("$(pc+1),$(pt+1),$(c+1)] = SSQ_NONE")
end

function gives_check(pos::SPosition, bb::SContextBB, m::SMove, ci::SCheckInfo)
    from = from_sq(m)
    to   = to_sq(m)
    if from != SSQ_DROP
        pt = stype_of(piece_on(pos,from))
    else
        pt = promotion_type(m)
    end
    pt2  = promotion_type(m) 

    # Is there a direct check?
    if (ci.checkSq[pt+1] & bb.SquareBB[to+1]) > sbitboard(0)
        return true
    end

    # Is there a discovered check?
    if (from != SSQ_DROP)&&((unlikely(ci.dcCandidates) > sbitboard(0))
        && ((ci.dcCandidates & bb.SquareBB[from+1])  > sbitboard(0))
        && (!(aligned(bb, from, to, ci.ksq) > sbitboard(0))))

        return true
    end
    
    if pt != pt2 # promote!
        if pt2 == RY || pt2 == UM
            return ((attacks_bb(bb, spiece(m), to, pieces(pos) $ bb.SquareBB[from+1], true) & bb.SquareBB[ci.ksq+1]) > sbitboard(0))
        else
            return ((attacks_bb(bb, spiece(m), to, pieces(pos) $ bb.SquareBB[from+1]) & bb.SquareBB[ci.ksq+1]) > sbitboard(0))
        end
    end

    false
end

function do_move(pos::SPosition, bb::SContextBB, m::SMove, newSt::SStateInfo)
    ci = SCheckInfo(pos,bb)
    do_move(pos, bb, m, newSt, ci, gives_check(pos, bb, m, ci))
end

function do_move(pos::SPosition, bb::SContextBB, m::SMove, newSt::SStateInfo, ci::SCheckInfo, moveIsCheck::Bool)
    newSt.previous = pos.st
    pos.st = newSt

    pos.gamePly += 1
    pos.st.pliesFromNull += 1

    #println("do_move: ",move_to_san(m))
    
    us = pos.sideToMove
    them = color(us$1)
    from = from_sq(m)
    to   = to_sq(m)
    if from != SSQ_DROP
        pc   = piece_on(pos,from)
        pt   = stype_of(pc)
        if pt == 0
            println("pt=0x0")
            throw("pt==0")
        end
    else
        pc = spiece(m)
        pt = stype_of(pc)
    end
    pt2  = promotion_type(m) 
    captured = captured_of(m) # stype_of(piece_on(pos,to))
    flag = type_of(m)

    if captured > NO_PIECE_TYPE
        capsq = to

        # Update board and piece lists
        remove_piece(bb, pos, capsq, them, captured)
        put_piece_in_komadai(pos, us, (captured>OU)? pieceType(captured - PT_PROMOTE_OFFSET):captured)
    end

    if from == SSQ_DROP
        remove_piece_from_komadai(pos, us, pt2)
        put_piece(bb, pos, to, us, pt2)
    else
        move_piece(bb, pos, from, to, us, pt)
    end

    if flag == SPROMOTION # promotion!
        remove_piece(bb, pos, to, us, pt)
        put_piece(bb, pos, to, us, pt2)
    end

    pos.st.capturedType = captured

    pos.st.checkersBB = sbitboard(0)
    pos.st.checkersBB = pieces(pos, color(pos.sideToMove$1)) & attackers_to(pos, bb, king_square(pos, pos.sideToMove))

    if moveIsCheck
        if pt != pt2
            pos.st.checkersBB = attackers_to(pos, bb, king_square(pos,them)) & pieces(pos,us)
        else
            if (ci.checkSq[pt] & bb.SquareBB[to+1]) > sbitboard(0)
                pos.st.checkersBB |= bb.SquareBB[to+1]
                #println("update checkers(1)")
            end

            if (from != SSQ_DROP)&&(ci.dcCandidates > sbitboard(0)) && (ci.dcCandidates & bb.SquareBB[from+1]) > sbitboard(0)
                if (pt != HI)&&(pt != RY)
                    pos.st.checkersBB |= attacks_from(pos, bb, smake_piece(us,HI), king_square(pos,them), true) & pieces(pos, pos.sideToMove, HI, RY)
                    #println("update checkers(2)")
                end

                if (pt != KA)&&(pt != UM)
                    pos.st.checkersBB |= attacks_from(pos, bb, smake_piece(us,KA), king_square(pos,them), true) & pieces(pos, pos.sideToMove, KA, UM)
                    #println("update checkers(3)")
                end
            end
        end
    end
    #println("after updated checkersBB") # It's too late for avoiding checks...
    #println(pretty2(bb,pos.st.checkersBB))
    pos.sideToMove = color(pos.sideToMove $ 1)
end


# Position::undo_move() unmakes a move. When it returns, the position should
# be restored to exactly the same state as before the move was made.

function undo_move(pos::SPosition, bb::SContextBB, m::SMove)
    pos.sideToMove = color(pos.sideToMove $ 1)

    us = pos.sideToMove
    them = color(us $ 1)
    from = from_sq(m)
    to   = to_sq(m)
    pc   = piece_on(pos,to)
    pt   = stype_of(pc)
    pt2  = promotion_type(m) 
    # captured = pos.st.capturedType
    captured = captured_of(m)
    flag = type_of(m)

    if flag == SPROMOTION
        promotion = pt2
        remove_piece(bb, pos, to, us, promotion)
        pt = pieceType(promotion - PT_PROMOTE_OFFSET)
        put_piece(bb, pos, to, us, pt)
    end

    if from == SSQ_DROP
        remove_piece(bb, pos, to, us, pt2)
        put_piece_in_komadai(pos, us, pt2)
    else
        move_piece(bb, pos, to, from, us, pt) # Put the piece back at the source square
    end

    #println("redo:", bool(captured > NO_PIECE_TYPE))

    if captured > NO_PIECE_TYPE
        capsq = to
        # Update board and piece lists
        remove_piece_from_komadai(pos, us, (captured > OU)? pieceType(captured - PT_PROMOTE_OFFSET): captured)
        put_piece(bb, pos, capsq, them, captured) # Restore the captured piece
    end

    # Finally point our state pointer back to the previous state
    pos.st = pos.st.previous

    pos.gamePly -= 1
end
