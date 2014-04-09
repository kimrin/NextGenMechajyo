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
    capturedType::PieceType
    previous::SStateInfo
    function SStateInfo()
        new()
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
    byTypeBB::Array{Bitboard,1}
    byColorBB::Array{Bitboard,1}
    pieceCount::Array{Int32,2}
    pieceList::Array{Square,3}
    index::Array{Int32,1}

    capturedPieces::Array{Int32,2} # color and pieceType(from FU to OU)

    # Other info
    startState::StateInfo
    nodes::Uint64
    gamePly::Int32
    sideToMove::Color
    thisThread::ThreadNumber
    st::StateInfo

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
        n.pieceList = zeros(Square, COLOR_NB, SPIECE_TYPE_NB, 40)
        n.index    =  zeros(Int32, SSQUARE_NB)
        n.capturedPieces = zeros(Int32,COLOR_NB,SPIECE_TYPE_NB)

        set( sbb, n, sf, t)
        n
    end
end

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
                komamoji = KOMASTR[koma&0x0f]
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
                        print("\e[31m+")
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
        p.sideToMove = WHITE
    else # bw == "b"
        p.sideToMove = BLACK
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
end


function put_piece(sbb::SContextBB, sp::SPosition, s::Square, c::Color, pt::PieceType)
    sp.board[s+1]               = smake_piece( c, pt)
    sp.byTypeBB[SALL_PIECES+1] |= sbb.SquareBB[s+1]
    sp.byTypeBB[pt+1]          |= sbb.SquareBB[s+1]
    sp.byColorBB[c+1]          |= sbb.SquareBB[s+1]
    sp.index[s+1]               = sp.pieceCount[c+1,pt+1]
    sp.pieceCount[c+1,pt+1] += 1
    sp.pieceList[c+1,pt+1,sp.index[s+1]+1] = s
end

function put_piece_in_komadai(sp::SPosition, c::Color, pt::PieceType, n::Int)
    sp.capturedPieces[c+1,pt+1] = int32(n)
end


