import Foundation
import Testing
@testable import Mediant

struct ByteFormatTests {
    let en = Locale(identifier: "en_US")

    @Test func formatsMegabytes() {
        #expect(ByteFormat.string(4_200_000, locale: en) == "4.2 MB")
    }

    @Test func formatsGigabytesWithOneDecimal() {
        #expect(ByteFormat.string(38_200_000_000, locale: en) == "38.2 GB")
    }

    @Test func formatsKilobytesWithoutDecimals() {
        #expect(ByteFormat.string(512_300, locale: en) == "512 KB")
    }

    @Test func usesLocaleDecimalSeparator() {
        #expect(ByteFormat.string(4_200_000, locale: Locale(identifier: "de_DE")) == "4,2 MB")
    }

    @Test func russianUnits() {
        #expect(ByteFormat.string(4_200_000, locale: Locale(identifier: "ru_RU")) == "4,2 МБ")
        #expect(ByteFormat.string(512_300, locale: Locale(identifier: "ru")) == "512 КБ")
        #expect(ByteFormat.string(38_200_000_000, locale: Locale(identifier: "ru_RU")) == "38,2 ГБ")
    }

    @Test func zeroIsZeroKilobytes() {
        #expect(ByteFormat.string(0, locale: en) == "0 KB")
    }

    @Test func missingSizeShowsDash() {
        #expect(ByteFormat.string(nil) == "—")
    }
}
