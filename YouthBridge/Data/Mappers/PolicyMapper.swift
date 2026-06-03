import Foundation

enum PolicyMapper {
    static func toDomain(_ dto: PolicyDTO) -> Policy {
        // 주관기관이 있으면 주관기관, 없으면 운영기관
        let org = [dto.sprvsnInstCdNm, dto.operInstCdNm]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .first ?? ""

        return Policy(
            id:             dto.plcyNo ?? UUID().uuidString,
            name:           dto.plcyNm ?? "",
            category:       dto.lclsfNm ?? "",
            supportContent: dto.plcySprtCn ?? dto.plcyExplnCn ?? "",
            operatingOrg:   org,
            applyPeriod:    dto.aplyYmd ?? "",
            externalUrl:    dto.refUrlAddr1,
            applyUrl:       dto.aplyUrlAddr
        )
    }

    static func toDomainList(_ dtos: [PolicyDTO]) -> [Policy] {
        dtos.map { toDomain($0) }
    }
}
