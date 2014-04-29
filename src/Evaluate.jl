const DPawn         =   87
const DLance        =  232
const DKnight       =  257
const DProPawn      =  534
const DProLance     =  489
const DSilver       =  369
const DProKnight    =  510
const DProSilver    =  495
const DGold         =  444
const DBishop       =  569
const DRook         =  642
const DHorse        =  827
const DDragon       =  945
const DKing         = 15000

function EvalMaterial(pos::SPosition, bb::SContextBB)
    material = 0
    for pt = FU:RY
        itemp = pos.pieceCount[WHITE+1,pt+1] + pos.capturedPieces[WHITE+1,pt+1]
        itemp -= pos.pieceCount[BLACK+1,pt+1] + pos.capturedPieces[BLACK+1,pt+1]
        material += itemp * bb.PieceValue[pt+1]
    end

    if pos.sideToMove == WHITE
        return value(material)
    else
        return value(-material)
    end
end
