import Foundation

struct PolicyListResponseDTO: Codable {
    let resultCode: Int?
    let resultMessage: String?
    let result: ResultDTO?
}

struct ResultDTO: Codable {
    let pagging: PaggingDTO?
    let youthPolicyList: [PolicyDTO]?
}

struct PaggingDTO: Codable {
    let totCount: Int?
    let pageNum: Int?
    let pageSize: Int?
}

struct PolicyDTO: Codable {
    let plcyNo: String?
    let plcyNm: String?
    let plcyExplnCn: String?
    let lclsfNm: String?
    let mclsfNm: String?
    let plcySprtCn: String?
    let sprvsnInstCdNm: String?
    let operInstCdNm: String?
    let aplyYmd: String?
    let bizPrdEndYmd: String?
    let refUrlAddr1: String?
    let aplyUrlAddr: String?
    let plcyKywdNm: String?
    let sprtTrgtMinAge: String?
    let sprtTrgtMaxAge: String?
    let zipCd: String?             // 지역 코드 (쉼표 구분, 앞 2자리 = 시도 코드)
}
