import Testing
@testable import Mediant

struct TrashBrowseTests {
    @Test func restoringInTheMiddleShowsTheItemThatMovesIntoItsPlace() {
        #expect(TrashBrowse.index(afterRestoring: 1, count: 3) == 1)
    }

    @Test func restoringTheLastShowsThePreviousOne() {
        #expect(TrashBrowse.index(afterRestoring: 2, count: 3) == 1)
    }

    @Test func restoringTheOnlyItemLeavesNothing() {
        #expect(TrashBrowse.index(afterRestoring: 0, count: 1) == nil)
    }
}
