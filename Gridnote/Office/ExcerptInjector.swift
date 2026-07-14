import Foundation

struct InjectedExcerpt: Equatable {
    let startBlockIndex: Int
    let valuesByRow: [Int: String]
    let nextBlockIndex: Int?
}

struct ExcerptChapterIndex: Equatable {
    let id: String
    let startBlockIndex: Int
}

struct ExcerptBlockLocation: Equatable {
    let chapterID: String
    let blockIndex: Int
}

enum ExcerptPositionMapper {
    static func globalBlockIndex(
        chapterID: String,
        blockIndex: Int,
        chapters: [ExcerptChapterIndex],
        totalBlockCount: Int
    ) -> Int {
        guard let chapter = chapters.first(where: { $0.id == chapterID }), totalBlockCount > 0 else { return 0 }
        return min(max(chapter.startBlockIndex + blockIndex, 0), totalBlockCount - 1)
    }

    static func location(
        forGlobalBlockIndex index: Int,
        chapters: [ExcerptChapterIndex]
    ) -> ExcerptBlockLocation? {
        guard let chapter = chapters.last(where: { $0.startBlockIndex <= index }) else { return nil }
        return ExcerptBlockLocation(chapterID: chapter.id, blockIndex: max(index - chapter.startBlockIndex, 0))
    }
}

enum ExcerptInjector {
    static func inject(blocks: [TextBlock], startBlockIndex: Int, rowCount: Int = 5) -> InjectedExcerpt {
        guard !blocks.isEmpty else { return InjectedExcerpt(startBlockIndex: 0, valuesByRow: [:], nextBlockIndex: nil) }
        let start = min(max(startBlockIndex, 0), blocks.count - 1)
        let end = min(start + max(rowCount, 1), blocks.count)
        var rows: [Int: String] = [:]
        for (offset, block) in blocks[start..<end].enumerated() {
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            rows[offset + 1] = text
        }
        return InjectedExcerpt(startBlockIndex: start, valuesByRow: rows, nextBlockIndex: end < blocks.count ? end : nil)
    }
}

/// Plausible operations notes shown while the embedded reader is concealed.
enum OfficeExcerptMasker {
    private static let entries = [
        "已核对 IMEI 与设备成色，等待门店补充交接照片。",
        "客户续租意向待回访，优先确认下期租金与保障方案。",
        "风控复核通过，物流单号已同步至履约工作表。",
        "本批设备电池健康度符合标准，建议按 A 档报价。",
        "异常押金订单已标记，等待客服完成身份补充材料。"
    ]

    static func value(forRow row: Int) -> String {
        entries[abs(row - 1) % entries.count]
    }
}
