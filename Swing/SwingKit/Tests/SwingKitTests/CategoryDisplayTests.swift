import Testing
import SwingKit

struct CategoryDisplayTests {
    @Test func noCategoryShowsAsGeneral() {
        #expect(categoryName(nil) == "General")
        #expect(categoryColorHex(nil) == "#8E8E93")
    }

    @Test func categoryShowsItsOwnNameAndColor() {
        let writing = Category(name: "Writing", colorHex: "#C2502F")
        #expect(categoryName(writing) == "Writing")
        #expect(categoryColorHex(writing) == "#C2502F")
    }
}

struct RGBComponentsTests {
    @Test func readsHexWithOrWithoutHash() throws {
        let color = try #require(rgbComponents(fromHex: "#FF8000"))
        #expect(color.red == 1)
        #expect(color.green == 128.0 / 255)
        #expect(color.blue == 0)
        #expect(rgbComponents(fromHex: "ff8000")?.red == 1)
    }

    @Test func rejectsBadHex() {
        #expect(rgbComponents(fromHex: "#FF80") == nil)
        #expect(rgbComponents(fromHex: "#GG8000") == nil)
        #expect(rgbComponents(fromHex: "") == nil)
    }
}
