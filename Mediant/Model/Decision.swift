/// What the user decided for one photo. Undecided photos have no entry.
enum Decision: String, Codable {
    case kept
    case trashed
}
