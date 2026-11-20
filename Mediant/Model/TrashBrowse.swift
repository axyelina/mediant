/// Which Trash item the viewer shows after a Restore takes the current one out.
enum TrashBrowse {
    /// `count` is the number of items before the restore. The item after the restored one moves
    /// into its place; after the last one the previous one shows; nil when nothing is left.
    static func index(afterRestoring index: Int, count: Int) -> Int? {
        let remaining = count - 1
        guard remaining > 0 else { return nil }
        return min(index, remaining - 1)
    }
}
